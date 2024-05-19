defmodule LiveSlides.Presentations.Presentation do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveSlides.Presentations.Deck.Slide

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "presentations" do
    field :title, :string
    field :user_id, :id
    embeds_many :slides, Slide, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(presentation, attrs) do
    presentation
    |> cast(attrs, [:title, :user_id])
    |> validate_required([:title, :user_id])
    |> cast_embed(:slides)
  end
end
