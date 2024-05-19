defmodule LiveSlides.PresentationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveSlides.Presentations` context.
  """

  import LiveSlides.AccountsFixtures

  @doc """
  Generate a deck.
  """
  def deck_fixture(attrs \\ %{}) do
    user_id =
      attrs
      |> Map.get_lazy(:user, &user_fixture/0)
      |> Map.get(:id)

    {:ok, deck} =
      attrs
      |> Enum.into(%{
        user_id: user_id,
        title: "some title",
        slides: [
          %{body: "this is the first slide"},
          %{body: "this is the second slide"},
          %{body: "this is the third slide"}
        ]
      })
      |> LiveSlides.Presentations.create_deck()

    deck
  end

  @doc """
  Generate a Presentation
  """
  def presentation_fixture(attrs \\ %{}) do
    {:ok, presentation} =
      attrs
      |> deck_fixture()
      |> LiveSlides.Presentations.create_presentation()

    presentation
  end
end
