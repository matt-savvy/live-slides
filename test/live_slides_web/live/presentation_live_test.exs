defmodule LiveSlidesWeb.PresentationLiveTest do
  use LiveSlidesWeb.ConnCase

  import Phoenix.LiveViewTest
  import LiveSlides.PresentationsFixtures

  alias LiveSlides.Presentations.PresentationServer

  describe "PresentationLive" do
    setup do
      deck = deck_fixture()
      id = Ecto.UUID.generate()
      start_supervised({PresentationServer, {id, deck}}, id: id)

      %{deck: deck, id: id}
    end

    test "gets state from genserver", %{conn: conn, deck: deck, id: id} do
      {:ok, live_view, _html} = live(conn, ~p"/presentations/#{id}")

      assert page_title(live_view) =~ deck.title
    end

    test "handles when presentation is not found", %{conn: conn} do
      id = Ecto.UUID.generate()

      assert_raise LiveSlidesWeb.PresentationLive.NotFound, fn ->
        live(conn, ~p"/presentations/#{id}")
      end
    end
  end
end
