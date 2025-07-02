defmodule LtzfAp.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias LtzfAp.Repo
  alias LtzfAp.Accounts.{User, AuditLog}

  # User functions
  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def list_users do
    Repo.all(User)
    |> Repo.preload([:audit_logs])
  end

  def list_active_users do
    Repo.all(from u in User, where: u.is_active == true)
    |> Repo.preload([:audit_logs])
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
