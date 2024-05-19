defmodule LiveSlides.Presentations.PresentationServer do
  @moduledoc """
  Client/Server module to centralize state of a presentation.
  """

  use GenServer, restart: :transient

  alias LiveSlides.Presentations
  alias LiveSlides.Presentations.{Deck, Presentation, PresentationState}

  @timeout 60 * 60 * 1000

  @doc """
  Starts a PresentationServer process linked to the current process.
  """
  def start_link({id, deck_or_presentation}) do
    GenServer.start_link(__MODULE__, [id, deck_or_presentation], name: name(id))
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
  Looks up the pid for an id.
  """
  def whereis(id) do
    id
    |> global_id()
    |> :global.whereis_name()
    |> case do
      :undefined -> {:error, :not_found}
      pid when is_pid(pid) -> {:ok, pid}
    end
  end

  @doc """
  Returns the user_id.
  """
  def user_id(id) do
    id
    |> name()
    |> GenServer.call(:user_id)
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
  Rewinds the current slide if possible.
  """
  def prev_slide(id) do
    id
    |> name()
    |> GenServer.cast(:prev_slide)
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
  def init([id, %Deck{} = deck]) do
    {:ok, PresentationState.new(id, deck), timeout()}
  end

  def init([id, %Presentation{id: id} = presentation]) do
    {:ok, PresentationState.new(presentation), timeout()}
  end

  @impl true
  def handle_call(action, _from, state) when action in [:title, :user_id, :get_slide] do
    {:reply, apply(PresentationState, action, [state]), state, timeout()}
  end

  @impl true
  def handle_cast(action, state) when action in [:next_slide, :prev_slide] do
    next_state = apply(PresentationState, action, [state])

    if next_state == state do
      # no op
      {:noreply, next_state, timeout()}
    else
      slide = PresentationState.get_slide(next_state)
      Presentations.broadcast!(next_state.id, {:slide_changed, slide})

      {:noreply, next_state, timeout()}
    end
  end

  @impl true
  def handle_info(:timeout, state) do
    Presentations.broadcast!(state.id, :finished)
    {:stop, {:shutdown, :timeout}, state}
  end

  defp timeout do
    Application.get_env(:live_slides, :timeout, @timeout)
  end
end
