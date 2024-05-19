defmodule LiveSlides.Presentations.Deck do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveSlides.Presentations.Deck.Slide

  schema "decks" do
    field :title, :string
    field :user_id, :id
    embeds_many :slides, Slide, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(deck, attrs) do
    deck
    |> cast(attrs, [:title, :user_id])
    |> validate_required([:title])
    |> cast_embed(:slides,
      sort_param: :slide_order,
      drop_param: :slide_delete
    )
  end
end
