defmodule LiveSlides.Repo.Migrations.CreatePresentations do
  use Ecto.Migration

  def change do
    create table(:presentations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
      add :slides, {:array, :map}

      timestamps(type: :utc_datetime)
    end
  end
end
