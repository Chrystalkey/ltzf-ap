defmodule LtzfAdminWeb.PageController do
  use LtzfAdminWeb, :controller

  alias LtzfAdmin.Accounts

  def home(conn, _params) do
    # Check if user is logged in
    case get_session(conn, :user_id) do
      nil ->
        # User not logged in - show login/register page
        if not Accounts.has_users?() do
          # No users exist, redirect to registration for the first user (superuser)
          redirect(conn, to: ~p"/register")
        else
          # Users exist, show login page
          render(conn, :home, layout: {LtzfAdminWeb.Layouts, :clean})
        end
      _user_id ->
        # User is logged in - redirect to dashboard
        redirect(conn, to: ~p"/dashboard")
    end
  end
end
