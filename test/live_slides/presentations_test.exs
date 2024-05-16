defmodule LiveSlides.PresentationsTest do
  use LiveSlides.DataCase, async: false

  alias LiveSlides.Presentations
  alias LiveSlides.Presentations.{Deck, Deck.Slide, Presentation, PresentationServer}
  alias LiveSlides.Repo

  import LiveSlides.PresentationsFixtures

  describe "decks" do
    @invalid_attrs %{title: nil}

    test "list_decks/0 returns all decks" do
      deck = deck_fixture()
      assert Presentations.list_decks() == [deck]
    end

    test "get_deck!/1 returns the deck with given id" do
      deck = deck_fixture()
      assert Presentations.get_deck!(deck.id) == deck
    end

    test "create_deck/1 with valid data creates a deck" do
      valid_attrs = %{
        title: "some title",
        slides: [%{body: "this is the first slide"}, %{body: "this is the second slide"}]
      }

      assert {:ok, %Deck{} = deck} = Presentations.create_deck(valid_attrs)
      assert deck.title == "some title"

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
      assert deck == Presentations.get_deck!(deck.id)
    end

    test "delete_deck/1 deletes the deck" do
      deck = deck_fixture()
      assert {:ok, %Deck{}} = Presentations.delete_deck(deck)
      assert_raise Ecto.NoResultsError, fn -> Presentations.get_deck!(deck.id) end
    end

    test "change_deck/1 returns a deck changeset" do
      deck = deck_fixture()
      assert %Ecto.Changeset{} = Presentations.change_deck(deck)
    end
  end

  describe "presentations" do
    test "create_presentation/1 from deck creates presentation" do
      deck = deck_fixture()

      assert {:ok, %Presentation{} = presentation} = Presentations.create_presentation(deck)
      assert presentation.title == deck.title

      assert Enum.map(presentation.slides, &Map.delete(&1, :id)) ==
               Enum.map(deck.slides, &Map.delete(&1, :id))
    end
  end

  describe "live presentations" do
    setup do
      start_supervised!({DynamicSupervisor, name: TestSupervisor})

      Application.put_env(:live_slides, :supervisor, TestSupervisor)

      on_exit(fn ->
        Application.delete_env(:live_slides, :supervisor)
      end)
    end

    test "present/2 starts a PresentationServer" do
      deck = deck_fixture()

      {:ok, id} = Presentations.present(deck)
      assert [_presentation_server] = DynamicSupervisor.which_children(TestSupervisor)

      assert %Presentation{} = Repo.get(Presentation, id)
    end

    test "list_live_presentations/0 lists PresentationServers" do
      {:ok, id_1} = Presentations.present(deck_fixture(%{title: "first title"}))
      {:ok, id_2} = Presentations.present(deck_fixture(%{title: "second title"}))

      assert [{"first title", ^id_1}, {"second title", ^id_2}] =
               Presentations.list_live_presentations()
    end

    test "finish/2 stops a PresentationServer and broadcasts" do
      deck = deck_fixture()

      {:ok, id} = Presentations.present(deck)
      assert :ok = Presentations.subscribe(id)

      :ok = Presentations.finish(id)

      refute PresentationServer.exists?(id)

      assert_receive :finished
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
