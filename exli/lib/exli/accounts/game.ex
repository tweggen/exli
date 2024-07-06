defmodule Exli.Accounts.Game do
  use Ecto.Schema
  import Ecto.Changeset
  alias Exli.Accounts.{Save}


  schema "games" do
    field :name, :string

    has_many :saved_games, Save, foreign_key: :game_id
  end


  @doc false
  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

end