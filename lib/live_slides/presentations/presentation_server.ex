defmodule LiveSlides.Presentations.PresentationServer do
  @moduledoc """
  Client/Server module to centralize state of a presentation.
  """

  use GenServer

  alias LiveSlides.Presentations.{Deck, PresentationState}

  @doc """
  Starts a PresentationServer process linked to the current process.
  """
  def start_link({id, %Deck{} = deck}) do
    GenServer.start_link(__MODULE__, [id, deck], name: name(id))
  end

  @doc """
  Gets the PresentationServer name from an id. Can be used to send messages to
  the PresentationServer.
  """
  def name(id) do
    {:global, global_id(id)}
  end

  defp global_id(id) do
    {:presentation, id}
  end

  @doc """
  Returns the title.
  """
  def title(id) do
    id
    |> name()
    |> GenServer.call(:title)
  end

  @doc """
  Returns the current slide, if applicable.
  """
  def get_slide(id) do
    id
    |> name()
    |> GenServer.call(:get_slide)
  end

  @doc """
  Advances the current slide if possible.
  """
  def next_slide(id) do
    id
    |> name()
    |> GenServer.cast(:next_slide)
  end

  @doc """
  Returns true if a PresentationServer process exists for this id.
  """
  def exists?(id) do
    case :global.whereis_name(global_id(id)) do
      :undefined -> false
      pid when is_pid(pid) -> true
    end
  end

  @impl true
  def init([id, deck]) do
    {:ok, PresentationState.new(id, deck)}
  end

  @impl true
  def handle_call(:title, _from, state) do
    {:reply, PresentationState.title(state), state}
  end

  @impl true
  def handle_call(:get_slide, _from, state) do
    {:reply, PresentationState.get_slide(state), state}
  end

  @impl true
  def handle_cast(:next_slide, state) do
    {:noreply, PresentationState.next_slide(state)}
  end
end
