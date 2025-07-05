defmodule LtzfApWeb.SitzungenLive do
  use LtzfApWeb, :live_view

  @unknown_scope "unknown"

      def mount(%{"s" => session_id} = _params, _session, socket) do
    mount_with_session(session_id, socket)
  end

  def mount(_params, _session, socket) do
    # Check if we have a session ID from localStorage
    {:ok, socket |> push_event("get_stored_session", %{})}
  end

  def handle_event("restore_session", %{"session_id" => session_id}, socket) do
    case mount_with_session(session_id, socket) do
      {:ok, updated_socket} -> {:noreply, updated_socket}
      {:ok, updated_socket, _opts} -> {:noreply, updated_socket}
    end
  end

  def handle_event("no_stored_session", _params, socket) do
    {:ok, redirect(socket, to: ~p"/login")}
  end

  defp mount_with_session(session_id, socket) do
    case LtzfAp.Session.get_session(session_id) do
      {:ok, session_data} ->
        # Get auth info from the session data
        auth_info = case LtzfAp.Auth.validate_api_key(session_data.backend_url, session_data.api_key) do
          {:ok, info} -> info
          {:error, _} -> %{scope: @unknown_scope}
        end

        socket =
          socket
          |> assign(:session_id, session_id)
          |> assign(:auth_info, auth_info)
          |> assign(:backend_url, session_data.backend_url)
          |> assign(:session_data, session_data)

        {:ok, socket}

      {:error, _} ->
        {:ok, redirect(socket, to: ~p"/login")}
    end
  end
end
