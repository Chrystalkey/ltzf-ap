defmodule LtzfApWeb.LoginLive do
  use LtzfApWeb, :live_view

  @connectivity_check_interval 1000 # 1 second
  @connectivity_check_cooldown 2 # 2 seconds minimum between checks
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
        connectivity_status: :unknown,
        last_connectivity_check: nil,
        consecutive_failures: 0,
        consecutive_successes: 0
      )

    {:ok, start_periodic_check(socket)}
  end

          def handle_event("validate", %{"login" => params}, socket) do
    backend_url = params["backend_url"] || ""
    api_key = params["api_key"] || ""
    remember_key = params["remember_key"] == "true"

    # Update the socket with new values
    socket = assign(socket, backend_url: backend_url, api_key: api_key, remember_key: remember_key)

    # Don't trigger immediate check - let the periodic check handle it
    # This prevents race conditions between immediate and periodic checks

    {:noreply, socket}
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

      # Determine session duration based on remember_key checkbox
      session_duration = if remember_key, do: @remember_session_duration, else: @default_session_duration

      case authenticate(backend_url, api_key) do
        {:ok, _auth_info} ->
          case LtzfAp.Session.create_session(api_key, backend_url, session_duration) do
            {:ok, session_id, expires_at} ->
              # Store session in localStorage and navigate to dashboard
              {:noreply,
               socket
               |> push_event("store_session", %{
                 session_id: session_id,
                 backend_url: backend_url,
                 expires_at: DateTime.to_iso8601(expires_at)
               })
               |> push_navigate(to: ~p"/dashboard", replace: true)}

            {:error, reason} ->
              {:noreply, assign(socket, loading: false, error: "Failed to create session: #{reason}")}
          end

        {:error, message} ->
          {:noreply, assign(socket, loading: false, error: message)}
      end
    end
  end

  defp authenticate(backend_url, api_key) do
    case LtzfAp.Auth.validate_api_key(backend_url, api_key) do
      {:ok, auth_info} -> {:ok, auth_info}
      {:error, message} -> {:error, message}
    end
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

  defp connectivity_status_class(:connected), do: "text-green-600"
  defp connectivity_status_class(:disconnected), do: "text-red-600"
  defp connectivity_status_class(:invalid_url), do: "text-yellow-600"
  defp connectivity_status_class(:checking), do: "text-blue-600"
  defp connectivity_status_class(:unknown), do: "text-gray-400"

  defp connectivity_status_text(:connected), do: "Connected"
  defp connectivity_status_text(:disconnected), do: "Disconnected"
  defp connectivity_status_text(:invalid_url), do: "Invalid URL format"
  defp connectivity_status_text(:checking), do: "Checking connectivity..."
    defp connectivity_status_text(:unknown), do: "Enter backend URL to check connectivity"

  defp start_periodic_check(socket) do
    Process.send_after(self(), :periodic_connectivity_check, @connectivity_check_interval)
    socket
  end

  def handle_info(:periodic_connectivity_check, socket) do
    # Schedule the next check
    Process.send_after(self(), :periodic_connectivity_check, @connectivity_check_interval)

    backend_url = socket.assigns.backend_url
    now = System.system_time(:second)

    # Don't check too frequently
    if socket.assigns.last_connectivity_check &&
       (now - socket.assigns.last_connectivity_check) < @connectivity_check_cooldown do
      {:noreply, socket}
    else
      socket = assign(socket, last_connectivity_check: now)

      {new_status, new_failures, new_successes} = cond do
        backend_url == "" ->
          {:unknown, 0, 0}
        valid_url?(backend_url) ->
          case LtzfAp.ApiClient.ping(backend_url) do
            {:ok, :pong} ->
              failures = 0
              successes = socket.assigns.consecutive_successes + 1
              # Require 2 consecutive successes to show as connected
              if successes >= 2, do: {:connected, failures, successes}, else: {:disconnected, failures, successes}
            {:error, _} ->
              successes = 0
              failures = socket.assigns.consecutive_failures + 1
              # Require 2 consecutive failures to show as disconnected
              if failures >= 2, do: {:disconnected, failures, successes}, else: {:connected, failures, successes}
          end
        true ->
          {:invalid_url, 0, 0}
      end

      # Only update if status actually changed
      if socket.assigns.connectivity_status != new_status do
        {:noreply, assign(socket,
          connectivity_status: new_status,
          consecutive_failures: new_failures,
          consecutive_successes: new_successes
        )}
      else
        {:noreply, assign(socket,
          consecutive_failures: new_failures,
          consecutive_successes: new_successes
        )}
      end
    end
  end
end
