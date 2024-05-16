defmodule LiveSlidesWeb.PresentationLive.IndexTest do
  use LiveSlidesWeb.ConnCase

  import LiveSlides.PresentationsFixtures
  import Phoenix.LiveViewTest
  alias LiveSlides.Presentations

  setup_all do
    Application.put_env(:live_slides, :supervisor, TestSupervisor)

    on_exit(fn ->
      Application.delete_env(:live_slides, :supervisor)
    end)
  end

  setup do
    start_supervised!({DynamicSupervisor, name: TestSupervisor})
    :ok
  end

  describe "Index" do
    setup [:register_and_log_in_user]

    test "lists all presentations", %{conn: conn} do
      %{id: id_1} = pres_1 = presentation_fixture(%{title: "first deck"})
      %{id: id_2} = presentation_fixture(%{title: "second deck"})

      assert {:ok, ^id_1} = Presentations.present(pres_1)

      {:ok, index_live, html} = live(conn, ~p"/presentations")

      assert html =~ "Listing Presentations"

      assert html =~ pres_1.title
      assert index_live |> element(~s{[data-id="live-#{id_1}"]}) |> has_element?
      assert index_live |> element(~s{[data-id="present-#{id_1}"]}) |> has_element?
      refute index_live |> element(~s{[data-id="view-#{id_1}"]}) |> has_element?
      refute index_live |> element(~s{[data-id="start-presentation-#{id_1}"]}) |> has_element?

      assert html =~ pres_1.title
      refute index_live |> element(~s{[data-id="live-#{id_2}"]}) |> has_element?
      refute index_live |> element(~s{[data-id="present-#{id_2}"]}) |> has_element?
      assert index_live |> element(~s{[data-id="view-#{id_2}"]}) |> has_element?
      assert index_live |> element(~s{[data-id="start-presentation-#{id_2}"]}) |> render_click()
      assert_redirect(index_live, ~p"/presentations/present/#{id_2}")
    end
  end
end
