defmodule LtzfApWeb.DashboardController do
  use LtzfApWeb, :controller

  alias LtzfAp.Accounts
  alias LtzfAp.Accounts.User

  def index(conn, _params) do
    current_user = conn.assigns.current_user
    recent_logs = Accounts.list_audit_logs(10)

    # Add user management data for superusers
    users = if User.superuser?(current_user) do
      Accounts.list_users()
    else
      []
    end

    render(conn, :index,
      current_user: current_user,
      recent_logs: recent_logs,
      users: users,
      layout: false
    )
  end
end
