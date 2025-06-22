defmodule LtzfAdminWeb.Plugs.Authenticate do
  import Plug.Conn
  import Phoenix.Controller

  alias LtzfAdmin.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: "/")
        |> halt()
      user_id ->
        case Accounts.get_user!(user_id) do
          user when user.is_active ->
            assign(conn, :current_user, user)
          _ ->
            conn
            |> clear_session()
            |> put_flash(:error, "Your account has been deactivated. Please contact an administrator.")
            |> redirect(to: "/")
            |> halt()
        end
    end
  end
end
