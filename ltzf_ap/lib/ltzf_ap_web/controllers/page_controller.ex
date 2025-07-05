defmodule LtzfApWeb.PageController do
  use LtzfApWeb, :controller

  def home(conn, _params) do
    # Redirect to dashboard (session restoration will handle login redirect if needed)
    redirect(conn, to: ~p"/dashboard")
  end
end
