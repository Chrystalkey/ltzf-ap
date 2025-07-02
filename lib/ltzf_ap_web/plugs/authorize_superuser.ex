defmodule LtzfApWeb.Plugs.AuthorizeSuperuser do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = conn.assigns[:current_user]

    case current_user do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: "/login")
        |> halt()
      user ->
        if LtzfAp.Accounts.User.superuser?(user) do
          conn
        else
          conn
          |> put_flash(:error, "You don't have permission to access this page.")
          |> redirect(to: "/dashboard")
          |> halt()
        end
    end
  end
end
