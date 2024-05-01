defmodule LiveSlides.Presentations.Deck.Slide do
  use Ecto.Schema
  import Ecto.Changeset
  alias LiveSlides.Presentations.Deck.Slide

  embedded_schema do
    field :body, :string
  end

  @doc false
  def changeset(%Slide{} = slide, attrs) do
    slide
    |> cast(attrs, [:body])
    |> validate_required([:body])
  end
end
