defmodule LiveSlidesWeb.DeckLiveTest do
  use LiveSlidesWeb.ConnCase

  import LiveSlides.TestSupervisorHelper
  import Phoenix.LiveViewTest
  import LiveSlides.PresentationsFixtures

  @create_attrs %{title: "some title"}
  @update_attrs %{title: "some updated title"}
  @invalid_attrs %{title: nil}

  setup_all :set_env_test_supervisor

  setup :start_test_supervisor

  defp create_deck(%{user: user}) do
    deck = deck_fixture(%{user: user})
    %{deck: deck}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_deck]

    test "lists all decks", %{conn: conn, deck: deck} do
      {:ok, _index_live, html} = live(conn, ~p"/decks")

      assert html =~ "Listing Decks"
      assert html =~ deck.title
    end

    test "saves new deck", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/decks")

      assert index_live |> element("a", "New Deck") |> render_click() =~
               "New Deck"

      assert_patch(index_live, ~p"/decks/new")

      assert index_live
             |> form("#deck-form", deck: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#deck-form", deck: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/decks")

      html = render(index_live)
      assert html =~ "Deck created successfully"
      assert html =~ "some title"
    end

    test "updates deck in listing", %{conn: conn, deck: deck} do
      {:ok, index_live, _html} = live(conn, ~p"/decks")

      assert index_live |> element("#decks-#{deck.id} a", "Edit") |> render_click() =~
               "Edit Deck"

      assert_patch(index_live, ~p"/decks/#{deck}/edit")

      assert index_live
             |> form("#deck-form", deck: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#deck-form", deck: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/decks")

      html = render(index_live)
      assert html =~ "Deck updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes deck in listing", %{conn: conn, deck: deck} do
      {:ok, index_live, _html} = live(conn, ~p"/decks")

      assert index_live |> element("#decks-#{deck.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#decks-#{deck.id}")
    end

    test "starts presentation and redirects", %{conn: conn, deck: deck} do
      {:ok, index_live, _html} = live(conn, ~p"/decks")

      {:ok, present_live, _html} =
        index_live
        |> element(~s{[data-present-deck="#{deck.id}"]})
        |> render_click()
        |> follow_redirect(conn)

      assert [{:undefined, _pid, :worker, [LiveSlides.Presentations.PresentationServer]}] =
               DynamicSupervisor.which_children(TestSupervisor)

      assert %{module: LiveSlidesWeb.PresentationLive.View} = present_live
    end
  end

  describe "Show" do
    @present_button_selector ~s{[data-id="present"]}
    setup [:register_and_log_in_user, :create_deck]

    test "displays deck", %{conn: conn, deck: deck} do
      {:ok, _show_live, html} = live(conn, ~p"/decks/#{deck}")

      assert html =~ "Show Deck"
      assert html =~ deck.title
    end

    test "updates deck within modal", %{conn: conn, deck: deck} do
      {:ok, show_live, _html} = live(conn, ~p"/decks/#{deck}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Deck"

      assert_patch(show_live, ~p"/decks/#{deck}/show/edit")

      assert show_live
             |> form("#deck-form", deck: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#deck-form", deck: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/decks/#{deck}")

      html = render(show_live)
      assert html =~ "Deck updated successfully"
      assert html =~ "some updated title"
    end

    test "starts presentation and redirects", %{conn: conn, deck: deck} do
      {:ok, show_live, _html} = live(conn, ~p"/decks/#{deck}")

      {:ok, present_live, _html} =
        show_live
        |> element(@present_button_selector)
        |> render_click()
        |> follow_redirect(conn)

      assert [{:undefined, _pid, :worker, [LiveSlides.Presentations.PresentationServer]}] =
               DynamicSupervisor.which_children(TestSupervisor)

      assert %{module: LiveSlidesWeb.PresentationLive.View} = present_live
    end
  end
end
