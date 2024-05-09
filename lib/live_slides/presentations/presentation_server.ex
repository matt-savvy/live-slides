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
    GenServer.start_link(__MODULE__, deck, name: name(id))
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
  Returns true if a PresentationServer process exists for this id.
  """
  def exists?(id) do
    case :global.whereis_name(global_id(id)) do
      :undefined -> false
      pid when is_pid(pid) -> true
    end
  end

  @impl true
  def init(deck) do
    {:ok, PresentationState.new(deck)}
  end

  @impl true
  def handle_call(:title, _from, state) do
    {:reply, PresentationState.title(state), state}
  end
end
