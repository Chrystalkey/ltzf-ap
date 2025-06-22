defmodule LtzfAdminWeb.DataManagementController do
  use LtzfAdminWeb, :controller

  def index(conn, _params) do
    # TODO: Fetch data from the API endpoints
    # - /api/v1/vorgang (legislative processes)
    # - /api/v1/sitzung (parliamentary sessions)
    # - /api/v1/dokument (documents)
    # - /api/v1/gremien (committees)
    # - /api/v1/autoren (authors)

    render(conn, :index,
      current_user: conn.assigns.current_user,
      vorgaenge: [], # TODO: Fetch from API
      sitzungen: [], # TODO: Fetch from API
      dokumente: [], # TODO: Fetch from API
      gremien: [], # TODO: Fetch from API
      autoren: [], # TODO: Fetch from API
      layout: false
    )
  end

  def vorgang(conn, %{"id" => id}) do
    # TODO: Fetch specific legislative process from /api/v1/vorgang/{vorgang_id}
    render(conn, :vorgang,
      current_user: conn.assigns.current_user,
      vorgang: nil, # TODO: Fetch from API
      layout: false
    )
  end

  def sitzung(conn, %{"id" => id}) do
    # TODO: Fetch specific session from /api/v1/sitzung/{sid}
    render(conn, :sitzung,
      current_user: conn.assigns.current_user,
      sitzung: nil, # TODO: Fetch from API
      layout: false
    )
  end

  def dokument(conn, %{"id" => id}) do
    # TODO: Fetch specific document from /api/v1/dokument/{api_id}
    render(conn, :dokument,
      current_user: conn.assigns.current_user,
      dokument: nil, # TODO: Fetch from API
      layout: false
    )
  end
end
