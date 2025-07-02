defmodule LtzfAp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :role, :string
    field :password_hash, :string
    field :email, :string
    field :username, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password_hash, :role])
    |> validate_required([:email, :username, :password_hash, :role])
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end
end
