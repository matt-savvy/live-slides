defmodule LiveSlides.Presentations.PresentationState do
  @moduledoc """
  Functional core and transformation functions for PresentationServer.
  """

  defstruct [
    :id,
    title: "",
    slides: []
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
  def next_slide(%__MODULE__{slides: slides} = state) do
    case slides do
      [_head | rest] -> %{state | slides: rest}
      [] -> state
    end
  end
end
