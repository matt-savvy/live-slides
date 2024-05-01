defmodule LiveSlides.PresentationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveSlides.Presentations` context.
  """

  @doc """
  Generate a deck.
  """
  def deck_fixture(attrs \\ %{}) do
    {:ok, deck} =
      attrs
      |> Enum.into(%{
        title: "some title"
      })
      |> LiveSlides.Presentations.create_deck()

    deck
  end
end
