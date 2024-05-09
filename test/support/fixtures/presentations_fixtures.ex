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
      Map.get_lazy(attrs, :user, fn ->
        %{id: user_id} = user_fixture()

        user_id
      end)

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
end
