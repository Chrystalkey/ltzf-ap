defmodule LtzfApWeb.LoginLive do
  use LtzfApWeb, :live_view

  @remember_session_duration 7 * 24 * 60 * 60 # 7 days in seconds
  @default_session_duration 1 * 24 * 60 * 60 # 1 day in seconds

  def mount(_params, _session, socket) do
    backend_url = get_connect_params(socket)["backend_url"] || ""

    socket =
      assign(socket,
        backend_url: backend_url,
        api_key: "",
        show_password: false,
        remember_key: false,
        loading: false,
        error: nil,
        connectivity_status: :unknown
      )

    {:ok, socket}
  end

  def handle_event("validate", %{"login" => params}, socket) do
    backend_url = params["backend_url"] || ""
    api_key = params["api_key"] || ""
    remember_key = params["remember_key"] == "true"

    # Update the socket with new values
    socket = assign(socket, backend_url: backend_url, api_key: api_key, remember_key: remember_key)

    {:noreply, socket}
  end

  def handle_event("connectivity_status", %{"status" => status}, socket) do
    status_atom = String.to_existing_atom(status)
    {:noreply, assign(socket, connectivity_status: status_atom)}
  end

  def handle_event("toggle_password", _params, socket) do
    {:noreply, assign(socket, show_password: !socket.assigns.show_password)}
  end

  def handle_event("login", %{"login" => params}, socket) do
    backend_url = params["backend_url"] || ""
    api_key = params["api_key"] || ""
    remember_key = params["remember_key"] == "true"

    if backend_url == "" or api_key == "" do
      {:noreply, assign(socket, error: "Please fill in all fields")}
    else
      socket = assign(socket, loading: true, error: nil)

      # Trigger client-side authentication
      {:noreply, push_event(socket, "authenticate", %{
        backend_url: backend_url,
        api_key: api_key,
        remember_key: remember_key
      })}
    end
  end

  def handle_event("auth_success", %{"credentials" => _credentials}, socket) do
    # Client has successfully authenticated
    {:noreply,
     socket
     |> assign(:loading, false)
     |> push_navigate(to: ~p"/dashboard", replace: true)}
  end

  def handle_event("auth_failure", %{"error" => error}, socket) do
    {:noreply, assign(socket, loading: false, error: error)}
  end

  defp valid_url?(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and not is_nil(host) ->
        true
      _ ->
        false
    end
  rescue
    _ -> false
  end

  defp connectivity_status_class(:connected), do: "text-green-500"
  defp connectivity_status_class(:connecting), do: "text-yellow-500"
  defp connectivity_status_class(:checking), do: "text-blue-500"
  defp connectivity_status_class(:disconnected), do: "text-red-500"
  defp connectivity_status_class(:invalid_url), do: "text-yellow-500"
  defp connectivity_status_class(_), do: "text-gray-500"

  defp connectivity_status_text(:connected), do: "Connected"
  defp connectivity_status_text(:connecting), do: "Connecting..."
  defp connectivity_status_text(:checking), do: "Checking..."
  defp connectivity_status_text(:disconnected), do: "Disconnected"
  defp connectivity_status_text(:invalid_url), do: "Invalid URL"
  defp connectivity_status_text(_), do: "Unknown"
end
