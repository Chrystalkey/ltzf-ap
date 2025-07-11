defmodule LtzfApWeb.KeyManagementLive do
  use LtzfApWeb, :live_view
  import LtzfApWeb.SharedHeader

  def mount(_params, _session, socket) do
    socket = assign(socket,
      api_keys: [],
      loading: false,
      error: nil,
      show_create_form: false,
      session_id: nil,
      auth_info: %{scope: "unknown"},
      session_data: %{expires_at: DateTime.utc_now()},
      backend_url: nil
    )

    # Trigger client-side session restoration
    {:ok, push_event(socket, "restore_session", %{})}
  end

  def handle_event("session_restored", %{"credentials" => credentials}, socket) do
    # Client has restored session, initialize data
    socket = assign(socket,
      backend_url: credentials["backend_url"],
      auth_info: %{scope: credentials["scope"]},
      session_data: %{expires_at: credentials["expires_at"]},
      session_id: "restored" # Set a session ID to indicate we have a session
    )

    # Load API keys data
    send(self(), :load_api_keys)
    {:noreply, socket}
  end

  def handle_event("session_expired", _params, socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
  end

  def handle_event("logout", _params, socket) do
    {:noreply,
     socket
     |> push_event("logout", %{})
     |> redirect(to: ~p"/login")}
  end

  def handle_event("load_api_keys", _params, socket) do
    {:noreply,
     socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "loadApiKeys",
       params: [],
       request_id: "api_keys_load"
     })}
  end

  def handle_event("api_response", %{"request_id" => "api_keys_load", "result" => result}, socket) do
    # Extract data from API response
    api_keys = result["data"] || []

    {:noreply, assign(socket, api_keys: api_keys, loading: false, error: nil)}
  end

  def handle_event("api_error", %{"request_id" => "api_keys_load", "error" => error}, socket) do
    {:noreply, assign(socket, api_keys: [], loading: false, error: error)}
  end

  def handle_event("show_create_form", _params, socket) do
    {:noreply, assign(socket, show_create_form: true)}
  end

  def handle_event("hide_create_form", _params, socket) do
    {:noreply, assign(socket, show_create_form: false)}
  end

  def handle_event("create_api_key", %{"scope" => scope, "expires_at" => expires_at}, socket) do
    {:noreply,
     socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "createApiKey",
       params: [scope, expires_at],
       request_id: "api_key_create"
     })}
  end

  def handle_event("api_response", %{"request_id" => "api_key_create", "result" => _data}, socket) do
    # Reload API keys after creation
    send(self(), :load_api_keys)
    {:noreply, assign(socket, show_create_form: false, loading: false)}
  end

  def handle_event("api_error", %{"request_id" => "api_key_create", "error" => error}, socket) do
    {:noreply, assign(socket, error: error, loading: false)}
  end

  def handle_event("delete_api_key", %{"key" => key}, socket) do
    {:noreply,
     socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "deleteApiKey",
       params: [key],
       request_id: "api_key_delete"
     })}
  end

  def handle_event("api_response", %{"request_id" => "api_key_delete", "result" => _data}, socket) do
    # Reload API keys after deletion
    send(self(), :load_api_keys)
    {:noreply, assign(socket, loading: false)}
  end

  def handle_event("api_error", %{"request_id" => "api_key_delete", "error" => error}, socket) do
    {:noreply, assign(socket, error: error, loading: false)}
  end

  def handle_info(:load_api_keys, socket) do
    {:noreply,
     socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "loadApiKeys",
       params: [],
       request_id: "api_keys_load"
     })}
  end

  # Helper functions for the template
  defp format_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _} -> Calendar.strftime(datetime, "%d.%m.%Y %H:%M")
      _ -> date_string
    end
  end

  defp format_date(_), do: "N/A"

  defp scope_display_name("admin"), do: "Administrator"
  defp scope_display_name("keyadder"), do: "Key Manager"
  defp scope_display_name("collector"), do: "Data Collector"
  defp scope_display_name(scope), do: scope
end
