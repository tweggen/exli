defmodule Exli.Accounts.Game do
  use Ecto.Schema


  schema "games" do
    field :name, :string
  end
end