defmodule LtzfAdmin.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :role, :string, default: "user"
    field :is_active, :boolean, default: true

    has_many :api_keys, LtzfAdmin.Accounts.ApiKey
    has_many :audit_logs, LtzfAdmin.Accounts.AuditLog

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :password_confirmation, :role, :is_active])
    |> validate_required([:email, :password, :password_confirmation])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password)
    |> validate_inclusion(:role, ["superuser", "admin", "user"])
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :role, :is_active])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> validate_inclusion(:role, ["superuser", "admin", "user"])
    |> unique_constraint(:email)
  end

  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password)
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, %{password_hash: Pbkdf2.hash_pwd_salt(password)})
  end

  defp put_password_hash(changeset), do: changeset

  def verify_password(password, hash) do
    Pbkdf2.verify_pass(password, hash)
  end

  def superuser?(%__MODULE__{role: "superuser"}), do: true
  def superuser?(_), do: false

  def admin?(%__MODULE__{role: role}) when role in ["superuser", "admin"], do: true
  def admin?(_), do: false

  def active?(%__MODULE__{is_active: true}), do: true
  def active?(_), do: false
end
