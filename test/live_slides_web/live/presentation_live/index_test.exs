defmodule LiveSlidesWeb.PresentationLive.IndexTest do
  use LiveSlidesWeb.ConnCase

  import LiveSlides.PresentationsFixtures
  import Phoenix.LiveViewTest
  alias LiveSlides.Presentations

  setup do
    start_supervised!({DynamicSupervisor, name: TestSupervisor})

    Application.put_env(:live_slides, :supervisor, TestSupervisor)

    on_exit(fn ->
      Application.delete_env(:live_slides, :supervisor)
    end)
  end

  defp create_deck(_) do
    deck = deck_fixture()
    %{deck: deck}
  end

  describe "Index" do
    setup [:create_deck, :register_and_log_in_user]

    test "lists all presentations", %{conn: conn, deck: deck} do
      {:ok, id} = Presentations.present(deck)

      {:ok, index_live, html} = live(conn, ~p"/presentations")

      assert html =~ "Listing Presentations"
      assert html =~ deck.title

      assert index_live
             |> element(~s{[data-id="present-#{id}"]})
             |> render_click()

      assert_redirect(index_live, ~p"/present/#{id}")

      {:ok, index_live, _html} = live(conn, ~p"/presentations")

      assert index_live
             |> element(~s{[data-id="presentation-#{id}"]})
             |> render_click()

      assert_redirect(index_live, ~p"/presentations/#{id}")
    end
  end
end
