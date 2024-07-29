defmodule Exli.Repo.Migrations.AddSaveStoredAt do
  use Ecto.Migration

  def change do
    alter table(:saves) do
      add :stored_at, :naive_datetime
    end

    create index(:saves, [:stored_at])
  end
end
