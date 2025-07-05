defmodule LtzfApWeb.SessionPlug do
  @moduledoc """
  Plug for handling session management and authentication.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    session_id = get_session(conn, :session_id)

    if session_id do
      case LtzfAp.Session.get_session(session_id) do
        {:ok, session_data} ->
          conn
          |> put_session(:session_id, session_id)
          |> put_session(:auth_info, %{scope: "admin"}) # This should come from the session
          |> put_session(:backend_url, session_data.backend_url)

        {:error, _} ->
          conn
          |> delete_session(:session_id)
          |> delete_session(:auth_info)
          |> delete_session(:backend_url)
      end
    else
      conn
    end
  end
end
