defmodule LiveSlidesWeb.PresentationLiveTest do
  use LiveSlidesWeb.ConnCase

  import Phoenix.LiveViewTest
  import LiveSlides.PresentationsFixtures

  alias LiveSlides.Presentations
  alias LiveSlides.Presentations.PresentationServer

  describe "PresentationLive" do
    setup do
      deck = deck_fixture()
      start_supervised!({DynamicSupervisor, name: TestSupervisor})
      {:ok, id} = Presentations.present(deck, TestSupervisor)

      %{deck: deck, id: id}
    end

    test "gets state from genserver", %{conn: conn, deck: deck, id: id} do
      [first_slide | _rest] = deck.slides
      {:ok, live_view, html} = live(conn, ~p"/presentations/#{id}")

      assert page_title(live_view) =~ deck.title
      assert html =~ first_slide.body
    end

    test "handles when presentation is not found", %{conn: conn} do
      id = Ecto.UUID.generate()

      assert_raise LiveSlidesWeb.PresentationLive.NotFound, fn ->
        live(conn, ~p"/presentations/#{id}")
      end
    end

    test "subscribes to presentation", %{conn: conn, deck: deck, id: id} do
      [first_slide, second_slide | _rest] = deck.slides
      {:ok, live_view, _html} = live(conn, ~p"/presentations/#{id}")

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

    test "change-slide buttons update PresentationServer state", %{conn: conn, deck: deck, id: id} do
      [first_slide, second_slide | _rest] = deck.slides
      {:ok, live_view, _html} = live(conn, ~p"/presentations/#{id}")
      assert first_slide == PresentationServer.get_slide(id)
      assert live_view |> element("button", "Next Slide") |> render_click()

      assert second_slide == PresentationServer.get_slide(id)
      assert live_view |> element("button", "Previous Slide") |> render_click()
      assert first_slide == PresentationServer.get_slide(id)
    end
  end
end
