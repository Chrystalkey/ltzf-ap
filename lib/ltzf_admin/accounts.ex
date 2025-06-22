defmodule LtzfAdmin.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias LtzfAdmin.Repo
  alias LtzfAdmin.Accounts.{User, ApiKey, AuditLog}

  # User functions
  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def list_users do
    Repo.all(User)
    |> Repo.preload([:api_keys, :audit_logs])
  end

  def list_active_users do
    Repo.all(from u in User, where: u.is_active == true)
    |> Repo.preload([:api_keys, :audit_logs])
  end

  def create_user(attrs \\ %{}) do
    # Check if this is the first user (superuser)
    user_count = Repo.aggregate(User, :count, :id)

    attrs = if user_count == 0 do
      Map.put(attrs, "role", "superuser")
    else
      attrs
    end

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  def update_user_password(%User{} = user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  def deactivate_user(%User{} = user) do
    # Superuser cannot be deactivated
    if User.superuser?(user) do
      {:error, :cannot_deactivate_superuser}
    else
      user
      |> User.update_changeset(%{is_active: false})
      |> Repo.update()
    end
  end

  def activate_user(%User{} = user) do
    user
    |> User.update_changeset(%{is_active: true})
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    # Superuser cannot be deleted
    if User.superuser?(user) do
      {:error, :cannot_delete_superuser}
    else
      Repo.delete(user)
    end
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    case user do
      nil ->
        # Use a dummy verification to prevent timing attacks
        Pbkdf2.verify_pass("dummy", Pbkdf2.hash_pwd_salt("dummy"))
        {:error, :invalid_credentials}
      user ->
        if User.verify_password(password, user.password_hash) and User.active?(user) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  def has_users? do
    Repo.aggregate(User, :count, :id) > 0
  end

  def get_superuser do
    Repo.get_by(User, role: "superuser")
  end

  # API Key functions
  def get_api_key!(id), do: Repo.get!(ApiKey, id)

  def get_api_key_by_hash(key_hash) do
    Repo.get_by(ApiKey, key_hash: key_hash)
  end

  def list_api_keys do
    Repo.all(ApiKey)
    |> Repo.preload(:user)
  end

  def list_api_keys_by_user(user_id) do
    Repo.all(from k in ApiKey, where: k.user_id == ^user_id)
    |> Repo.preload(:user)
  end

  def create_api_key(attrs \\ %{}) do
    %ApiKey{}
    |> ApiKey.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_api_key(%ApiKey{} = api_key, attrs) do
    api_key
    |> ApiKey.changeset(attrs)
    |> Repo.update()
  end

  def delete_api_key(%ApiKey{} = api_key) do
    Repo.delete(api_key)
  end

  def change_api_key(%ApiKey{} = api_key, attrs \\ %{}) do
    ApiKey.changeset(api_key, attrs)
  end

  def rotate_api_key(%ApiKey{} = api_key) do
    %ApiKey{}
    |> ApiKey.create_changeset(%{
      name: api_key.name,
      scope: api_key.scope,
      user_id: api_key.user_id,
      expires_at: api_key.expires_at
    })
    |> Repo.insert()
  end

  # Audit Log functions
  def create_audit_log(attrs \\ %{}) do
    %AuditLog{}
    |> AuditLog.changeset(attrs)
    |> Repo.insert()
  end

  def list_audit_logs(limit \\ 100) do
    Repo.all(from a in AuditLog,
      order_by: [desc: a.inserted_at],
      limit: ^limit)
    |> Repo.preload(:user)
  end

  def list_audit_logs_by_user(user_id, limit \\ 50) do
    Repo.all(from a in AuditLog,
      where: a.user_id == ^user_id,
      order_by: [desc: a.inserted_at],
      limit: ^limit)
    |> Repo.preload(:user)
  end
end
