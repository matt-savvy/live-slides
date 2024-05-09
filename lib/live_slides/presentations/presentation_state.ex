defmodule LiveSlides.Presentations.PresentationState do
  @moduledoc """
  Functional core and transformation functions for PresentationServer.
  """

  defstruct [
    :id,
    title: "",
    slides: [],
    prev_slides: []
  ]

  alias LiveSlides.Presentations.Deck

  @doc """
  Creates new PresentationState
  """
  def new(id, %Deck{title: title, slides: slides}) do
    %__MODULE__{id: id, title: title, slides: slides}
  end

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
end
