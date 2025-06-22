defmodule LtzfAdmin.Accounts.ApiKey do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "api_keys" do
    field :key_hash, :string
    field :name, :string
    field :scope, :string
    field :expires_at, :utc_datetime
    field :is_active, :boolean, default: true
    field :key, :string, virtual: true
    
    belongs_to :user, LtzfAdmin.Accounts.User

    timestamps()
  end

  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:name, :scope, :expires_at, :is_active, :user_id])
    |> validate_required([:name, :scope, :user_id])
    |> validate_inclusion(:scope, ["admin", "collector", "keyadder"])
    |> validate_length(:name, min: 1, max: 100)
    |> unique_constraint(:key_hash)
    |> foreign_key_constraint(:user_id)
  end

  def create_changeset(api_key, attrs) do
    api_key
    |> changeset(attrs)
    |> put_key_hash()
  end

  defp put_key_hash(%Ecto.Changeset{valid?: true} = changeset) do
    key = generate_api_key()
    change(changeset, %{key_hash: Pbkdf2.hash_pwd_salt(key), key: key})
  end

  defp put_key_hash(changeset), do: changeset

  defp generate_api_key do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64()
    |> binary_part(0, 32)
  end

  def expired?(%__MODULE__{expires_at: nil}), do: false
  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :lt
  end

  def active?(api_key) do
    api_key.is_active and not expired?(api_key)
  end
end 