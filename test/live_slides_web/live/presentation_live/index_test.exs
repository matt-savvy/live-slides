defmodule LiveSlidesWeb.PresentationLive.IndexTest do
  use LiveSlidesWeb.ConnCase

  import LiveSlides.TestSupervisorHelper
  import LiveSlides.PresentationsFixtures
  import Phoenix.LiveViewTest
  alias LiveSlides.Presentations

  setup_all :set_env_test_supervisor

  setup :start_test_supervisor

  describe "Index" do
    setup [:register_and_log_in_user]

    test "lists all presentations", %{conn: conn, user: user} do
      user_id = user.id
      %{id: id_1} = pres_1 = presentation_fixture(%{title: "first deck", user_id: user_id})
      %{id: id_2} = presentation_fixture(%{title: "second deck", user_id: user_id})

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

    test "copy to clipboard link for live presentations", %{conn: conn, user: user} do
      user_id = user.id
      %{id: id_1} = pres_1 = presentation_fixture(%{title: "first deck", user_id: user_id})
      %{id: id_2} = presentation_fixture(%{title: "second deck", user_id: user_id})

      assert {:ok, ^id_1} = Presentations.present(pres_1)

      {:ok, index_live, _html} = live(conn, ~p"/presentations")

      assert index_live |> element(~s{[data-id="copy-link-#{id_1}}) |> render_click()
      assert index_live |> element(~s{[data-id="copy-link-#{id_2}}) |> render_click()
    end
  end
end
