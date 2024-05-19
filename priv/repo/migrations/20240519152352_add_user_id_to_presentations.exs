defmodule LiveSlides.Repo.Migrations.AddUserIdToPresentations do
  use Ecto.Migration

  def change do
    alter table(:presentations) do
      add :user_id, references(:users, on_delete: :nothing)
    end

    create index(:presentations, [:user_id])
  end
end
