defmodule LiveSlides.Presentations.Deck do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveSlides.Presentations.Deck.Slide

  schema "decks" do
    field :title, :string
    field :user_id, :id
    embeds_many :slides, Slide

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(deck, attrs) do
    deck
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
