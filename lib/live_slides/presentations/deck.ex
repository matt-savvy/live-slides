defmodule LiveSlides.Presentations.Deck do
  use Ecto.Schema
  import Ecto.Changeset

  schema "decks" do
    field :title, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(deck, attrs) do
    deck
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
