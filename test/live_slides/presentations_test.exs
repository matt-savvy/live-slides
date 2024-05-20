defmodule LiveSlides.PresentationsTest do
  use LiveSlides.DataCase, async: false

  alias LiveSlides.Presentations

  alias LiveSlides.Presentations.{
    Deck,
    Deck.Slide,
    Presentation,
    PresentationServer,
    PresentationState
  }

  alias LiveSlides.Repo

  import LiveSlides.TestSupervisorHelper
  import LiveSlides.AccountsFixtures
  import LiveSlides.PresentationsFixtures

  setup_all :set_env_test_supervisor

  setup :start_test_supervisor

  describe "decks" do
    @invalid_attrs %{title: nil, user_id: nil, slides: nil}

    test "list_decks/0 returns all decks for user" do
      deck = deck_fixture()

      %{id: other_user_id} = user_fixture()
      _other_deck = deck_fixture(%{user_id: other_user_id})

      assert Presentations.list_decks(%{user_id: deck.user_id}) == [deck]
    end

    test "get_deck!/1 returns the deck with given id" do
      deck = deck_fixture()
      assert Presentations.get_deck!(deck.id, %{user_id: deck.user_id}) == deck
    end

    test "get_deck!/1 raises for wrong user id" do
      deck = deck_fixture()
      %{id: other_user_id} = user_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Presentations.get_deck!(deck.id, %{user_id: other_user_id})
      end
    end

    test "create_deck/1 with valid data creates a deck" do
      user = user_fixture()

      valid_attrs = %{
        title: "some title",
        user_id: user.id,
        slides: [%{body: "this is the first slide"}, %{body: "this is the second slide"}]
      }

      assert {:ok, %Deck{} = deck} = Presentations.create_deck(valid_attrs)
      assert deck.title == "some title"
      assert deck.user_id == user.id

      assert [
               %Slide{body: "this is the first slide"},
               %Slide{body: "this is the second slide"}
             ] = deck.slides
    end

    test "create_deck/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Presentations.create_deck(@invalid_attrs)
    end

    test "update_deck/2 with valid data updates the deck" do
      deck = deck_fixture()
      update_attrs = %{title: "some updated title"}

      assert {:ok, %Deck{} = deck} = Presentations.update_deck(deck, update_attrs)
      assert deck.title == "some updated title"
    end

    test "update_deck/2 with invalid data returns error changeset" do
      deck = deck_fixture()
      assert {:error, %Ecto.Changeset{}} = Presentations.update_deck(deck, @invalid_attrs)
      assert deck == Presentations.get_deck!(deck.id, %{user_id: deck.user_id})
    end

    test "delete_deck/1 deletes the deck" do
      deck = deck_fixture()
      assert {:ok, %Deck{}} = Presentations.delete_deck(deck)

      assert_raise Ecto.NoResultsError, fn ->
        Presentations.get_deck!(deck.id, %{user_id: deck.user_id})
      end
    end

    test "change_deck/1 returns a deck changeset" do
      deck = deck_fixture()
      assert %Ecto.Changeset{} = Presentations.change_deck(deck)
    end
  end

  describe "presentations" do
    test "list_presentations/1 returns all presentations for user" do
      presentation = presentation_fixture()
      %{id: other_user_id} = user_fixture()
      _other_presentation = presentation_fixture(%{user_id: other_user_id})
      assert Presentations.list_presentations(%{user_id: presentation.user_id}) == [presentation]
    end

    test "get_presentation!/1 returns the presentation with given id" do
      presentation = presentation_fixture()
      assert Presentations.get_presentation!(presentation.id) == presentation
    end

    test "create_presentation/1 from deck creates presentation" do
      deck = deck_fixture()

      assert {:ok, %Presentation{} = presentation} = Presentations.create_presentation(deck)
      assert presentation.title == deck.title
      assert presentation.user_id == deck.user_id

      assert Enum.map(presentation.slides, &Map.delete(&1, :id)) ==
               Enum.map(deck.slides, &Map.delete(&1, :id))
    end
  end

  describe "live presentations" do
    test "present/2 starts a PresentationServer for a deck" do
      deck = deck_fixture()

      {:ok, id} = Presentations.present(deck)
      assert [_presentation_server] = DynamicSupervisor.which_children(TestSupervisor)

      assert %Presentation{} = Repo.get(Presentation, id)
    end

    test "present/2 starts a PresentationServer for a presentation if needed" do
      %{id: id} = presentation = presentation_fixture()

      assert {:ok, ^id} = Presentations.present(presentation)
      assert [_presentation_server] = DynamicSupervisor.which_children(TestSupervisor)

      assert {:error, :already_started} = Presentations.present(presentation)
    end

    test "tag_live_presentations/1 returns live presentations" do
      deck = deck_fixture()

      [id_1, id_2, id_3] =
        0..2
        |> Enum.map(fn _ ->
          {:ok, id} = Presentations.present(deck)
          id
        end)

      Presentations.finish(id_2)

      presentations = Presentations.list_presentations(%{user_id: deck.user_id})

      assert [
               {:live, %Presentation{id: ^id_1}},
               {:not_live, %Presentation{id: ^id_2}},
               {:live, %Presentation{id: ^id_3}}
             ] = Presentations.tag_live_presentations(presentations)
    end

    test "finish/2 stops a PresentationServer and broadcasts" do
      deck = deck_fixture()

      {:ok, id} = Presentations.present(deck)
      assert :ok = Presentations.subscribe(id)

      :ok = Presentations.finish(id)

      refute PresentationServer.exists?(id)

      assert_receive {:finished, %PresentationState{}}
    end

    test "finish/2 handles not found" do
      assert {:error, :not_found} = Presentations.finish(Ecto.UUID.generate())
    end

    test "subscribe/broadcast" do
      id = Ecto.UUID.generate()
      assert :ok = Presentations.subscribe(id)
      ref = make_ref()
      Presentations.broadcast!(id, ref)
      assert_receive ^ref
    end
  end
end
