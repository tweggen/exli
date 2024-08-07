defmodule Exli.Accounts.Save do  
  use Ecto.Schema
  alias Exli.Accounts.Game
  alias Exli.Accounts.User

  schema "saves" do
    field :gamedata, :string
    field :stored_at, :naive_datetime
    
    belongs_to :game, Game, foreign_key: :game_id
    belongs_to :user, User, foreign_key: :user_id

    timestamps(type: :utc_datetime)
  end
end