defmodule LiveSlides.Presentations.PresentationState do
  @moduledoc """
  Functional core and transformation functions for PresentationServer.
  """

  defstruct title: "", slides: []

  alias LiveSlides.Presentations.Deck

  @doc """
  Creates new PresentationState
  """
  def new(%Deck{title: title}) do
    %__MODULE__{title: title}
  end
end
