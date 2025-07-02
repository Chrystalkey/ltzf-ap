defmodule LtzfApWeb.SessionController do
  use LtzfApWeb, :controller

  alias LtzfAp.Accounts
  alias LtzfAp.Accounts.User

  def new(conn, _params) do
    render(conn, :new, layout: {LtzfApWeb.Layouts, :clean})
  end

  def create(conn, %{"session" => session_params}) do
    case Accounts.authenticate_user(session_params["email"], session_params["password"]) do
      {:ok, user} ->
        # Log the login
        Accounts.create_audit_log(%{
          action: "login",
          resource_type: "session",
          resource_id: to_string(user.id),
          changes: %{},
          user_id: user.id
        })

        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: ~p"/dashboard")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render(:new, layout: {LtzfApWeb.Layouts, :clean})
    end
  end

  def delete(conn, _params) do
    current_user = conn.assigns[:current_user]

    # Log the logout if user is logged in
    if current_user do
      Accounts.create_audit_log(%{
        action: "logout",
        resource_type: "session",
        resource_id: to_string(current_user.id),
        changes: %{},
        user_id: current_user.id
      })
    end

    conn
    |> clear_session()
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: ~p"/")
  end

  def register(conn, _params) do
    changeset = Accounts.change_user(%User{})
    is_first_user = not Accounts.has_users?()

    render(conn, :register, changeset: changeset, is_first_user: is_first_user, layout: {LtzfApWeb.Layouts, :clean})
  end

  def create_user(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        # Log the registration
        Accounts.create_audit_log(%{
          action: "create",
          resource_type: "user",
          resource_id: to_string(user.id),
          changes: %{email: user.email, role: user.role},
          user_id: user.id
        })

        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, if(User.superuser?(user), do: "Administrator account created successfully!", else: "Account created successfully!"))
        |> redirect(to: ~p"/dashboard")

      {:error, %Ecto.Changeset{} = changeset} ->
        is_first_user = not Accounts.has_users?()
        render(conn, :register, changeset: changeset, is_first_user: is_first_user, layout: {LtzfApWeb.Layouts, :clean})
    end
  end
end
