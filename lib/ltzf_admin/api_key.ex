defmodule LtzfAdmin.ApiKey do
  use Ecto.Schema
  import Ecto.Changeset

  schema "api_keys" do
    field :name, :string
    field :scope, :string
    field :key_hash, :string
    field :expires_at, :utc_datetime
    field :is_active, :boolean, default: false
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:key_hash, :name, :scope, :expires_at, :is_active])
    |> validate_required([:key_hash, :name, :scope, :expires_at, :is_active])
    |> unique_constraint(:key_hash)
  end
end
