defmodule LiveSlidesWeb.PresentationLiveTest do
  use LiveSlidesWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import LiveSlides.AccountsFixtures
  import LiveSlides.PresentationsFixtures

  alias LiveSlides.Presentations
  alias LiveSlides.Presentations.PresentationServer

  describe "PresentationLive.View" do
    @next_button_selector ~s{[data-id="change-slide-next"]}
    @prev_button_selector ~s{[data-id="change-slide-prev"]}
    @finish_button_selector ~s{[data-id="finish-presentation"]}

    setup do
      start_supervised!({DynamicSupervisor, name: TestSupervisor})

      Application.put_env(:live_slides, :supervisor, TestSupervisor)

      on_exit(fn ->
        Application.delete_env(:live_slides, :supervisor)
      end)

      deck = deck_fixture()
      {:ok, id} = Presentations.present(deck)

      %{deck: deck, id: id}
    end

    test ":view / :present gets state from genserver", %{conn: conn, deck: deck, id: id} do
      [first_slide | _rest] = deck.slides
      {:ok, live_view, html} = live(conn, ~p"/presentations/#{id}")

      assert page_title(live_view) =~ deck.title
      assert html =~ first_slide.body
    end

    test ":view_solo gets state from deck", %{conn: conn, deck: deck, id: id} do
      [first_slide | _rest] = deck.slides
      assert Presentations.finish(id)

      {:ok, live_view, html} = live(conn, ~p"/presentations/view_solo/#{id}")

      assert page_title(live_view) =~ deck.title
      assert html =~ first_slide.body
    end

    test ":view / :present handles when presentation is not found", %{conn: conn} do
      id = Ecto.UUID.generate()

      assert_raise LiveSlidesWeb.PresentationLive.NotFound, fn ->
        live(conn, ~p"/presentations/#{id}")
      end

      user = user_fixture()
      conn = log_in_user(conn, user)

      assert_raise LiveSlidesWeb.PresentationLive.NotFound, fn ->
        live(conn, ~p"/present/#{id}")
      end
    end

    test "subscribes to presentation", %{conn: conn, deck: deck, id: id} do
      [first_slide, second_slide | _rest] = deck.slides
      {:ok, live_view, html} = live(conn, ~p"/presentations/#{id}")

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

    test ":view_solo is not subscribed to presentation", %{conn: conn, id: id} do
      {:ok, live_view, _html} = live(conn, ~p"/presentations/view_solo/#{id}")

      assert :ok = Presentations.broadcast!(id, :finished)

      # force test process to wait until the server and live view
      # processes have handled these messages.
      # we can safely assume the live view has received our
      # pubsub message
      _ = :sys.get_state(live_view.pid)

      refute render(live_view) =~ "The presentation has ended."
    end

    test "buttons not rendered for :view", %{conn: conn, id: id} do
      {:ok, live_view, _html} = live(conn, ~p"/presentations/#{id}")

      refute live_view |> has_element?(@next_button_selector)
      refute live_view |> has_element?(@prev_button_selector)
      refute live_view |> has_element?(@finish_button_selector)
    end

    test "change-slide buttons update PresentationServer state", %{conn: conn, deck: deck, id: id} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      [first_slide, second_slide | _rest] = deck.slides
      {:ok, live_view, _html} = live(conn, ~p"/present/#{id}")

      assert live_view |> has_element?(@next_button_selector)
      assert live_view |> has_element?(@prev_button_selector)

      assert first_slide == PresentationServer.get_slide(id)
      assert live_view |> element(@next_button_selector) |> render_click()

      assert second_slide == PresentationServer.get_slide(id)
      assert live_view |> element(@prev_button_selector) |> render_click()
      assert first_slide == PresentationServer.get_slide(id)
    end

    test ":view_solo change-slide buttons update LV state", %{conn: conn, deck: deck, id: id} do
      assert Presentations.finish(id)

      [first_slide, second_slide | _rest] = deck.slides
      {:ok, live_view, _html} = live(conn, ~p"/presentations/view_solo/#{id}")

      assert live_view |> has_element?(@next_button_selector)
      assert live_view |> has_element?(@prev_button_selector)

      assert live_view |> element(@next_button_selector) |> render_click() =~ second_slide.body

      assert live_view |> element(@prev_button_selector) |> render_click() =~ first_slide.body
    end

    test "finish button finishes presentation", %{conn: conn, id: id} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, live_view, _html} = live(conn, ~p"/present/#{id}")

      assert live_view |> element(@finish_button_selector) |> render_click()

      refute PresentationServer.exists?(id)
    end

    test ":view_solo not shown finish button", %{conn: conn, id: id} do
      {:ok, live_view, _html} = live(conn, ~p"/presentations/view_solo/#{id}")

      refute live_view |> has_element?(@finish_button_selector)
    end

    test "handles :finished", %{conn: conn, id: id} do
      {:ok, live_view, _html} = live(conn, ~p"/presentations/#{id}")

      send(live_view.pid, :finished)

      assert render(live_view) =~ "The presentation has ended."
    end
  end
end
