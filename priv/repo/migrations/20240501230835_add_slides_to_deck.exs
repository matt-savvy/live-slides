defmodule LiveSlides.Repo.Migrations.AddSlidesToDeck do
  use Ecto.Migration

  def change do
    alter table(:decks) do
      add :slides, {:array, :map}
    end
  end
end
