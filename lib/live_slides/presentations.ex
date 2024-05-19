defmodule LiveSlides.Presentations do
  @moduledoc """
  The Presentations context.
  """

  import Ecto.Query, warn: false
  alias LiveSlides.Repo

  alias LiveSlides.Presentations.{Deck, Presentation, PresentationServer, PresentationSupervisor}

  @doc """
  Returns the list of decks.

  ## Examples

      iex> list_decks()
      [%Deck{}, ...]

  """
  def list_decks(%{user_id: user_id}) do
    Deck
    |> where([d], d.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Gets a single deck.

  Raises `Ecto.NoResultsError` if the Deck does not exist.

  ## Examples

      iex> get_deck!(123)
      %Deck{}

      iex> get_deck!(456)
      ** (Ecto.NoResultsError)

  """
  def get_deck!(id), do: Repo.get!(Deck, id)

  @doc """
  Creates a deck.

  ## Examples

      iex> create_deck(%{field: value})
      {:ok, %Deck{}}

      iex> create_deck(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_deck(attrs \\ %{}) do
    %Deck{}
    |> Deck.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a deck.

  ## Examples

      iex> update_deck(deck, %{field: new_value})
      {:ok, %Deck{}}

      iex> update_deck(deck, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_deck(%Deck{} = deck, attrs) do
    deck
    |> Deck.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a deck.

  ## Examples

      iex> delete_deck(deck)
      {:ok, %Deck{}}

      iex> delete_deck(deck)
      {:error, %Ecto.Changeset{}}

  """
  def delete_deck(%Deck{} = deck) do
    Repo.delete(deck)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking deck changes.

  ## Examples

      iex> change_deck(deck)
      %Ecto.Changeset{data: %Deck{}}

  """
  def change_deck(%Deck{} = deck, attrs \\ %{}) do
    Deck.changeset(deck, attrs)
  end

  @doc """
  Starts a Presentation for a `Deck` or `Presentation`.
  """
  def present(%Deck{} = deck) do
    with {:ok, %Presentation{id: id}} <- create_presentation(deck),
         {:ok, _pid} <-
           DynamicSupervisor.start_child(supervisor(), {PresentationServer, {id, deck}}) do
      {:ok, id}
    end
  end

  def present(%Presentation{id: id} = presentation) do
    with {:ok, _pid} <-
           DynamicSupervisor.start_child(supervisor(), {PresentationServer, {id, presentation}}) do
      {:ok, id}
    else
      {:error, {:already_started, _pid}} -> {:error, :already_started}
    end
  end

  @doc """
  Gets a single presentation.

  Raises `Ecto.NoResultsError` if the Deck does not exist.
  """
  def get_presentation!(id), do: Repo.get!(Presentation, id)

  @doc """
  Create a Presentation from a `Deck`
  """
  def create_presentation(%Deck{} = deck) do
    params =
      deck
      |> Map.take([:slides, :title])
      |> Map.update!(:slides, fn slides ->
        Enum.map(slides, fn slide -> Map.from_struct(slide) end)
      end)

    %Presentation{}
    |> Presentation.changeset(params)
    |> Repo.insert()
  end

  @doc """
  List Presentations.
  """
  def list_presentations do
    Repo.all(Presentation)
  end

  @doc """
  Wrap presentations in a tuple indicating liveness.

  {:live, %Presentation} {:not_live, %Presentation{}}
  """
  def tag_live_presentations(presentations) do
    live_presentations =
      :global.registered_names()
      |> Enum.filter(fn
        {:presentation, _id} -> true
        _ -> false
      end)
      |> Enum.map(fn {:presentation, id} ->
        id
      end)
      |> MapSet.new()

    presentations
    |> Enum.map(fn presentation ->
      status =
        case MapSet.member?(live_presentations, presentation.id) do
          true -> :live
          false -> :not_live
        end

      {status, presentation}
    end)
  end

  @doc """
  Finishes a Presentation.
  """
  def finish(id) do
    with {:ok, pid} <- PresentationServer.whereis(id),
         :ok <- DynamicSupervisor.terminate_child(supervisor(), pid) do
      broadcast!(id, :finished)
    end
  end

  defp supervisor do
    Application.get_env(:live_slides, :supervisor, PresentationSupervisor)
  end

  @doc """
  Subscribes to a presentation.
  """
  def subscribe(id) do
    Phoenix.PubSub.subscribe(LiveSlides.PubSub, topic(id))
  end

  @doc """
  Broadcasts to a topic for presentation.
  """
  def broadcast!(id, msg) do
    Phoenix.PubSub.broadcast(LiveSlides.PubSub, topic(id), msg)
  end

  defp topic(id), do: "presentation-#{id}"
end
