defmodule LiveSlidesWeb.PresentationLiveTest do
  use LiveSlidesWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import LiveSlides.TestSupervisorHelper
  import LiveSlides.AccountsFixtures
  import LiveSlides.PresentationsFixtures

  alias LiveSlides.Presentations
  alias LiveSlides.Presentations.{PresentationServer, PresentationState}

  setup_all :set_env_test_supervisor

  setup :start_test_supervisor

  defp create_and_present(%{user: user}) do
    deck = deck_fixture(%{user: user})
    {:ok, id} = Presentations.present(deck)

    %{deck: deck, id: id}
  end

  describe "PresentationLive.View" do
    @next_button_selector ~s{[data-id="change-slide-next"]}
    @prev_button_selector ~s{[data-id="change-slide-prev"]}
    @finish_button_selector ~s{[data-id="finish-presentation"]}
    @copy_clipboard_selector ~s{[data-id="copy-link"]}

    setup [:register_and_log_in_user, :create_and_present]

    test ":live gets state", %{conn: conn, deck: deck, id: id} do
      [first_slide | _rest] = deck.slides
      {:ok, live_view, html} = live(conn, ~p"/presentations/live/#{id}")

      assert page_title(live_view) =~ deck.title
      assert html =~ first_slide.body
    end

    test ":live gets redirected if not live" do
      conn = Phoenix.ConnTest.build_conn()

      %{id: id} = presentation_fixture()

      redirect_path = ~p"/presentations/view/#{id}"

      assert {:error, {:live_redirect, %{to: ^redirect_path}}} =
               live(conn, ~p"/presentations/live/#{id}")
    end

    test ":present gets state", %{conn: conn, deck: deck, id: id} do
      [first_slide | _rest] = deck.slides
      {:ok, live_view, html} = live(conn, ~p"/presentations/present/#{id}")

      assert page_title(live_view) =~ deck.title
      assert html =~ first_slide.body
    end

    test ":view gets state from presentation", %{conn: conn} do
      %{id: id, slides: slides, title: title} = presentation_fixture()
      [first_slide | _rest] = slides
      refute PresentationServer.exists?(id)

      {:ok, live_view, html} = live(conn, ~p"/presentations/view/#{id}")

      assert page_title(live_view) =~ title
      assert html =~ first_slide.body
    end

    test ":present raises NotFound when presentation is not found", %{conn: conn} do
      id = Ecto.UUID.generate()

      assert_raise LiveSlidesWeb.PresentationLive.NotFound, fn ->
        live(conn, ~p"/presentations/present/#{id}")
      end
    end

    test ":present raises NotFound when wrong user", %{id: id} do
      conn =
        Phoenix.ConnTest.build_conn()
        |> log_in_user(user_fixture())

      assert_raise LiveSlidesWeb.PresentationLive.NotFound, fn ->
        live(conn, ~p"/presentations/present/#{id}")
      end
    end

    test "subscribes to presentation", %{conn: conn, deck: deck, id: id} do
      [first_slide, second_slide | _rest] = deck.slides
      {:ok, live_view, html} = live(conn, ~p"/presentations/live/#{id}")

      assert html =~ first_slide.body
      PresentationServer.next_slide(id)

      # force test process to wait until the server and live view
      # processes have handled these messages.
      # we can safely assume the live view has received our
      # pubsub message
      _ = PresentationServer.get_slide(id)
      _ = :sys.get_state(live_view.pid)

      assert render(live_view) =~ second_slide.body

      PresentationServer.prev_slide(id)

      # same as above
      _ = PresentationServer.get_slide(id)
      _ = :sys.get_state(live_view.pid)

      assert render(live_view) =~ first_slide.body
    end

    test ":view is not subscribed to presentation", %{conn: conn, id: id} do
      {:ok, live_view, _html} = live(conn, ~p"/presentations/view/#{id}")

      assert :ok = Presentations.broadcast!(id, :finished)

      # force test process to wait until the server and live view
      # processes have handled these messages.
      # we can safely assume the live view has received our
      # pubsub message
      _ = :sys.get_state(live_view.pid)

      refute render(live_view) =~ "The presentation has ended."
    end

    test "buttons not rendered for :live", %{conn: conn, id: id} do
      {:ok, live_view, _html} = live(conn, ~p"/presentations/live/#{id}")

      refute live_view |> has_element?(@next_button_selector)
      refute live_view |> has_element?(@prev_button_selector)
      refute live_view |> has_element?(@finish_button_selector)
    end

    test "change-slide buttons update PresentationServer state", %{conn: conn, deck: deck, id: id} do
      [first_slide, second_slide | _rest] = deck.slides
      {:ok, live_view, _html} = live(conn, ~p"/presentations/present/#{id}")

      assert live_view |> has_element?(@next_button_selector)
      assert live_view |> has_element?(@prev_button_selector)

      assert first_slide == PresentationServer.get_slide(id)
      assert live_view |> element(@next_button_selector) |> render_click()

      assert second_slide == PresentationServer.get_slide(id)
      assert live_view |> element(@prev_button_selector) |> render_click()
      assert first_slide == PresentationServer.get_slide(id)
    end

    test ":view change-slide buttons update LV state", %{conn: conn, deck: deck, id: id} do
      assert Presentations.finish(id)

      [first_slide, second_slide | _rest] = deck.slides
      {:ok, live_view, _html} = live(conn, ~p"/presentations/view/#{id}")

      assert live_view |> has_element?(@next_button_selector)
      assert live_view |> has_element?(@prev_button_selector)

      assert live_view |> element(@next_button_selector) |> render_click() =~ second_slide.body

      assert live_view |> element(@prev_button_selector) |> render_click() =~ first_slide.body
    end

    test "finish button finishes presentation", %{conn: conn, id: id} do
      {:ok, live_view, _html} = live(conn, ~p"/presentations/present/#{id}")

      assert live_view
             |> element(@finish_button_selector)
             |> render_click()

      refute PresentationServer.exists?(id)
    end

    test ":view not shown finish button", %{conn: conn, id: id} do
      {:ok, live_view, _html} = live(conn, ~p"/presentations/view/#{id}")

      refute live_view |> has_element?(@finish_button_selector)
    end

    test ":view not shown copy url", %{conn: conn, id: id} do
      {:ok, live_view, _html} = live(conn, ~p"/presentations/view/#{id}")

      refute live_view |> has_element?(@copy_clipboard_selector)
    end

    test "handles :finished", %{conn: conn, id: id} do
      {:ok, live_view, _html} = live(conn, ~p"/presentations/live/#{id}")

      send(live_view.pid, {:finished, %PresentationState{}})

      assert render(live_view) =~ "The presentation has ended."

      assert live_view |> has_element?(@next_button_selector)
      assert live_view |> has_element?(@prev_button_selector)
    end

    test "copy to clipboard link", %{conn: conn, id: id} do
      {:ok, live_view, _html} = live(conn, ~p"/presentations/present/#{id}")

      assert live_view |> element(@copy_clipboard_selector) |> render_click()
    end
  end
end
