defmodule LtzfApWeb.DashboardLive do
  use LtzfApWeb, :live_view

    @timer_update_interval 60 * 1000 # 1 minute in milliseconds
  @error_message "Error"
  @unknown_scope "unknown"
  @seconds_per_day 86400
  @seconds_per_hour 3600
  @seconds_per_minute 60

      def mount(%{"s" => session_id} = _params, _session, socket) do
    mount_with_session(session_id, socket)
  end

  def mount(_params, _session, socket) do
    # Initialize with default values and check for stored session
    socket =
      socket
      |> assign(:auth_info, %{scope: @unknown_scope})
      |> assign(:session_data, %{expires_at: DateTime.utc_now()})
      |> assign(:stats, %{})
      |> assign(:loading, true)
      |> assign(:session_id, nil)
      |> assign(:backend_url, nil)

    {:ok, socket |> push_event("get_stored_session", %{})}
  end

  def handle_event("restore_session", %{"session_id" => session_id}, socket) do
    case mount_with_session(session_id, socket) do
      {:ok, updated_socket} -> {:noreply, updated_socket}
    end
  end

  def handle_event("no_stored_session", _params, socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
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
          |> assign(:stats, %{})
          |> assign(:loading, true)
          |> start_session_timer()

        # Load dashboard stats
        send(self(), :load_stats)
        {:ok, socket}

      {:error, _} ->
        {:ok, redirect(socket, to: ~p"/login")}
    end
  end

  def handle_info(:load_stats, socket) do
    stats = load_dashboard_stats(socket.assigns.backend_url, socket.assigns.session_data.api_key)
    {:noreply, assign(socket, stats: stats, loading: false)}
  end

  def handle_info(:update_timer, socket) do
    case LtzfAp.Session.get_session(socket.assigns.session_id) do
      {:ok, session_data} ->
        {:noreply, assign(socket, session_data: session_data)}
      {:error, _} ->
        {:noreply, redirect(socket, to: ~p"/login")}
    end
  end

  def handle_event("logout", _params, socket) do
    LtzfAp.Session.delete_session(socket.assigns.session_id)
    {:noreply,
     socket
     |> push_event("clear_session", %{})
     |> redirect(to: ~p"/login")}
  end



  defp load_dashboard_stats(backend_url, api_key) do
    vorgaenge_count = get_vorgaenge_count(backend_url, api_key)
    sitzungen_count = get_sitzungen_count(backend_url, api_key)
    enumerations_count = get_enumerations_count(backend_url, api_key)

    %{
      vorgaenge: vorgaenge_count,
      sitzungen: sitzungen_count,
      enumerations: enumerations_count
    }
  end

  defp get_vorgaenge_count(backend_url, api_key) do
    case LtzfAp.ApiClient.get_vorgaenge_with_headers(backend_url, api_key, [per_page: 1]) do
      {:ok, _data, headers} ->
        case get_total_count_from_headers(headers) do
          {:ok, count} -> count
          {:error, _} -> @error_message
        end
      {:error, _} -> @error_message
    end
  end

  defp get_sitzungen_count(backend_url, api_key) do
    case LtzfAp.ApiClient.get_sitzungen_with_headers(backend_url, api_key, [per_page: 1]) do
      {:ok, _data, headers} ->
        case get_total_count_from_headers(headers) do
          {:ok, count} -> count
          {:error, _} -> @error_message
        end
      {:error, _} -> @error_message
    end
  end

  defp get_total_count_from_headers(headers) do
    case Enum.find(headers, fn {name, _} -> String.downcase(name) == "x-total-count" end) do
      {_, count_str} ->
        case Integer.parse(count_str) do
          {count, _} -> {:ok, count}
          :error -> {:error, :invalid_count}
        end
      nil -> {:error, :no_count_header}
    end
  end

  defp get_enumerations_count(_backend_url, _api_key) do
    6
  end

  defp start_session_timer(socket) do
    if Process.whereis(:session_timer) do
      Process.cancel_timer(:session_timer)
    end

    Process.send_after(self(), :update_timer, @timer_update_interval)
    socket
  end

  defp format_time_remaining(expires_at) do
    now = DateTime.utc_now()
    diff = DateTime.diff(expires_at, now, :second)

    if diff > 0 do
      days = div(diff, @seconds_per_day)
      hours = div(rem(diff, @seconds_per_day), @seconds_per_hour)
      minutes = div(rem(diff, @seconds_per_hour), @seconds_per_minute)

      cond do
        days > 0 -> "#{days}d #{hours}h"
        hours > 0 -> "#{hours}h #{minutes}m"
        true -> "#{minutes}m"
      end
    else
      "Expired"
    end
  end

  defp calculate_total_items(stats) do
    vorgaenge = case stats.vorgaenge do
      count when is_integer(count) -> count
      _ -> 0
    end

    sitzungen = case stats.sitzungen do
      count when is_integer(count) -> count
      _ -> 0
    end

    enumerations = case stats.enumerations do
      count when is_integer(count) -> count
      _ -> 0
    end

    vorgaenge + sitzungen + enumerations
  end
end
