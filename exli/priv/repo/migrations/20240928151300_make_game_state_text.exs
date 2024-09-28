defmodule Exli.Repo.Migrations.MakeGameStateText do
  use Ecto.Migration

  def change do
    alter table(:saves) do
      modify :gamedata, :text
    end
  end

end

