defmodule LiveSlides.Presentations.PresentationState do
  @moduledoc """
  Functional core and transformation functions for PresentationServer.
  """

  defstruct [
    :id,
    :user_id,
    title: "",
    slides: [],
    prev_slides: []
  ]

  alias LiveSlides.Presentations.{Deck, Presentation}

  @doc """
  Creates new PresentationState
  """
  def new(%Presentation{id: id, user_id: user_id, title: title, slides: slides}) do
    %__MODULE__{id: id, user_id: user_id, title: title, slides: slides}
  end

  def new(id, %Deck{user_id: user_id, title: title, slides: slides}) do
    %__MODULE__{id: id, user_id: user_id, title: title, slides: slides}
  end

  @doc """
  Returns the user_id.
  """
  def user_id(%__MODULE__{user_id: user_id}), do: user_id

  @doc """
  Returns the title.
  """
  def title(%__MODULE__{title: title}), do: title

  @doc """
  Returns the current slide, if possible.
  """
  def get_slide(%__MODULE__{slides: slides}) do
    case slides do
      [slide | _rest] -> slide
      _ -> nil
    end
  end

  @doc """
  Advances the current slide.
  """
  def next_slide(%__MODULE__{slides: slides, prev_slides: prev_slides} = state) do
    case slides do
      [_head] -> state
      [head | rest] -> %{state | slides: rest, prev_slides: [head | prev_slides]}
      [] -> state
    end
  end

  @doc """
  Rewinds to the previous slide.
  """
  def prev_slide(%__MODULE__{slides: slides, prev_slides: prev_slides} = state) do
    case prev_slides do
      [head | rest] -> %{state | slides: [head | slides], prev_slides: rest}
      [] -> state
    end
  end

  @doc """
  Returns tuple to indicate slide number x out of y.
  """
  def progress(%__MODULE__{slides: slides, prev_slides: prev_slides}) do
    prev_count = Enum.count(prev_slides)
    total_count = prev_count + Enum.count(slides)
    {prev_count + 1, total_count}
  end
end
