defmodule Exli.Repo.Migrations.MakeGameIndexUnique do
  use Ecto.Migration

  def change do
    drop index(:games, [:name])
    create unique_index(:games, [:name])
  end
end
