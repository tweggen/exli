defmodule Exli.Repo.Migrations.CreateSavegames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :name, :string
    end

    create index(:games, [:name])

    create table(:saves) do
      add :game_id, references(:games, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :gamedata, :string

      timestamps(type: :utc_datetime)
    end

    create index(:games, [:game_id])
    create index(:games, [:user_id])

  end
end
