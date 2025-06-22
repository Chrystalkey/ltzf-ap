defmodule LtzfAdminWeb.UserController do
  use LtzfAdminWeb, :controller

  alias LtzfAdmin.Accounts
  alias LtzfAdmin.Accounts.User

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users, layout: false)
  end

  def deactivate(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    current_user = conn.assigns.current_user

    case Accounts.deactivate_user(user) do
      {:ok, _user} ->
        # Log the action
        Accounts.create_audit_log(%{
          action: "update",
          resource_type: "user",
          resource_id: to_string(user.id),
          changes: %{is_active: false},
          user_id: current_user.id
        })

        conn
        |> put_flash(:info, "User deactivated successfully.")
        |> redirect(to: ~p"/users")

      {:error, :cannot_deactivate_superuser} ->
        conn
        |> put_flash(:error, "Cannot deactivate the superuser account.")
        |> redirect(to: ~p"/users")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to deactivate user.")
        |> redirect(to: ~p"/users")
    end
  end

  def activate(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    current_user = conn.assigns.current_user

    case Accounts.activate_user(user) do
      {:ok, _user} ->
        # Log the action
        Accounts.create_audit_log(%{
          action: "update",
          resource_type: "user",
          resource_id: to_string(user.id),
          changes: %{is_active: true},
          user_id: current_user.id
        })

        conn
        |> put_flash(:info, "User activated successfully.")
        |> redirect(to: ~p"/users")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to activate user.")
        |> redirect(to: ~p"/users")
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    current_user = conn.assigns.current_user

    case Accounts.delete_user(user) do
      {:ok, _user} ->
        # Log the action
        Accounts.create_audit_log(%{
          action: "delete",
          resource_type: "user",
          resource_id: to_string(user.id),
          changes: %{deleted_user_email: user.email},
          user_id: current_user.id
        })

        conn
        |> put_flash(:info, "User deleted successfully.")
        |> redirect(to: ~p"/users")

      {:error, :cannot_delete_superuser} ->
        conn
        |> put_flash(:error, "Cannot delete the superuser account.")
        |> redirect(to: ~p"/users")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to delete user.")
        |> redirect(to: ~p"/users")
    end
  end
end
