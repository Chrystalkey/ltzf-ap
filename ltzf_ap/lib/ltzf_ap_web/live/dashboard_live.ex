defmodule LtzfApWeb.DashboardLive do
  use LtzfApWeb, :live_view

  @timer_update_interval 60 * 1000 # 1 minute in milliseconds
  @error_message "Error"
  @unknown_scope "unknown"
  @seconds_per_day 86400
  @seconds_per_hour 3600
  @seconds_per_minute 60

  def mount(_params, _session, socket) do
    socket = socket
      |> assign(:auth_info, %{scope: @unknown_scope})
      |> assign(:session_data, %{expires_at: DateTime.utc_now()})
      |> assign(:stats, %{"vorgaenge" => "—", "sitzungen" => "—", "enumerations" => "—"})
      |> assign(:loading, true)
      |> assign(:session_id, nil)
      |> assign(:backend_url, nil)
    {:ok, push_event(socket, "restore_session", %{})}
  end

  def handle_event("session_restored", %{"credentials" => credentials}, socket) do
    socket = assign(socket,
      backend_url: credentials["backend_url"],
      auth_info: %{scope: credentials["scope"]},
      session_data: %{expires_at: credentials["expires_at"]},
      session_id: "restored",
      loading: false
    )
    send(self(), :load_stats)
    {:noreply, socket}
  end

  def handle_event("session_expired", _params, socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
  end

  def handle_event("logout", _params, socket) do
    {:noreply, socket |> push_event("logout", %{}) |> redirect(to: ~p"/login")}
  end

  def handle_event("logout_complete", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("api_response", %{"request_id" => "dashboard_stats", "result" => stats}, socket) do
    {:noreply, assign(socket, stats: stats, loading: false)}
  end

  def handle_event("api_error", %{"request_id" => "dashboard_stats", "error" => error}, socket) do
    {:noreply, assign(socket, loading: false, error: error)}
  end

  def handle_info(:load_stats, socket) do
    socket = socket
      |> assign(:loading, true)
      |> push_event("api_request", %{method: "loadDashboardStats", params: [], request_id: "dashboard_stats"})
    {:noreply, socket}
  end

  def handle_info(:update_timer, socket) do
    case socket.assigns.session_data do
      %{expires_at: expires_at} when not is_nil(expires_at) ->
        case DateTime.compare(DateTime.from_iso8601(expires_at), DateTime.utc_now()) do
          :gt -> {:noreply, socket}
          _ -> {:noreply, redirect(socket, to: ~p"/login")}
        end
      _ -> {:noreply, redirect(socket, to: ~p"/login")}
    end
  end

  defp start_session_timer(socket) do
    Process.send_after(self(), :update_timer, @timer_update_interval)
    socket
  end

  defp format_time_remaining(expires_at) do
    case DateTime.from_iso8601(expires_at) do
      {:ok, expires_datetime, _} ->
        now = DateTime.utc_now()
        diff_seconds = DateTime.diff(expires_datetime, now)

        if diff_seconds <= 0 do
          "Expired"
        else
          days = div(diff_seconds, @seconds_per_day)
          remaining_seconds = rem(diff_seconds, @seconds_per_day)
          hours = div(remaining_seconds, @seconds_per_hour)
          remaining_seconds = rem(remaining_seconds, @seconds_per_hour)
          minutes = div(remaining_seconds, @seconds_per_minute)

          cond do
            days > 0 -> "#{days}d #{hours}h #{minutes}m"
            hours > 0 -> "#{hours}h #{minutes}m"
            minutes > 0 -> "#{minutes}m"
            true -> "Less than 1m"
          end
        end
      _ ->
        "Unknown"
    end
  end

  defp scope_display_name("admin"), do: "Administrator"
  defp scope_display_name("keyadder"), do: "Key Manager"
  defp scope_display_name(_), do: "Unknown"

  defp calculate_total_items(stats) do
    Map.values(stats)
    |> Enum.map(fn
      value when is_integer(value) -> value
      value when is_binary(value) ->
        case Integer.parse(value) do
          {int, _} -> int
          :error -> 0
        end
      _ -> 0
    end)
    |> Enum.sum()
  end
end
