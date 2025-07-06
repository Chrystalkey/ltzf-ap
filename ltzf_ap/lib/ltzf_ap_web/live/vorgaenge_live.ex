defmodule LtzfApWeb.VorgaengeLive do
  use LtzfApWeb, :live_view

  alias LtzfApWeb.SharedLiveHelpers
  import LtzfApWeb.SharedHeader

  @unknown_scope "unknown"

  def mount(%{"s" => session_id} = _params, _session, socket) do
    case SharedLiveHelpers.mount_with_session(session_id, socket) do
      {:ok, socket} ->
        socket = load_vorgaenge(socket)
        {:ok, socket}
      {:error, _reason} ->
        {:ok, redirect(socket, to: "/login")}
    end
  end

  def mount(_params, _session, socket) do
    # Set up initial assigns
    assigns = SharedLiveHelpers.initial_assigns()
    socket = assign(socket, assigns)

    # Check if we have a session ID from localStorage
    {:ok, socket |> push_event("get_stored_session", %{})}
  end

  def handle_event("restore_session", %{"session_id" => session_id}, socket) do
    case SharedLiveHelpers.mount_with_session(session_id, socket) do
      {:ok, updated_socket} ->
        updated_socket = load_vorgaenge(updated_socket)
        {:noreply, updated_socket}
      {:error, _reason} ->
        SharedLiveHelpers.handle_session_restoration_error(socket, "Invalid session")
    end
  rescue
    _error ->
      SharedLiveHelpers.handle_session_restoration_error(socket, "Session restoration error")
  end

  def handle_event("no_stored_session", _params, socket) do
    assigns = SharedLiveHelpers.initial_assigns()
    socket = assign(socket, assigns)
    {:ok, redirect(socket, to: ~p"/login")}
  end

  def handle_event("filter", params, socket) do
    filter_keys = ["since", "until", "p", "wp", "person", "fach", "org", "vgtyp"]
    socket = SharedLiveHelpers.handle_filter(params, socket, filter_keys, :load_vorgaenge)
    socket = load_vorgaenge(socket)
    {:noreply, socket}
  end

  def handle_event("clear_filters", _params, socket) do
    socket = SharedLiveHelpers.handle_clear_filters(socket, "32", :load_vorgaenge)
    socket = load_vorgaenge(socket)
    {:noreply, socket}
  end

  def handle_event("page_change", %{"page" => page}, socket) do
    socket = SharedLiveHelpers.handle_page_change(socket, page, :load_vorgaenge)
    socket = load_vorgaenge(socket)
    {:noreply, socket}
  end

  def handle_event("logout", _params, socket) do
    SharedLiveHelpers.handle_logout(socket)
  end

  defp load_vorgaenge(socket) do
    # Don't load if we don't have session data
    if is_nil(socket.assigns.session_data) do
      socket
    else
      socket = assign(socket, :loading, true)

      # Convert filters to API parameters
      params = socket.assigns.filters
      |> Enum.filter(fn {_key, value} -> value != nil and value != "" end)
      |> Enum.map(fn {key, value} -> {key, value} end)

      case LtzfAp.ApiClient.get_vorgaenge_with_headers(
        socket.assigns.backend_url,
        socket.assigns.session_data.api_key,
        params
      ) do
        {:ok, vorgaenge, headers} ->
          pagination = SharedLiveHelpers.extract_pagination(headers)
          socket =
            socket
            |> assign(:vorgaenge, vorgaenge)
            |> assign(:pagination, pagination)
            |> assign(:loading, false)
            |> assign(:error, nil)

          socket

        {:error, reason} ->
          socket =
            socket
            |> assign(:vorgaenge, [])
            |> assign(:loading, false)
            |> assign(:error, "Failed to load vorgaenge: #{inspect(reason)}")

          socket
      end
    end
  rescue
    error ->
      socket =
        socket
        |> assign(:vorgaenge, [])
        |> assign(:loading, false)
        |> assign(:error, "Exception loading vorgaenge: #{inspect(error)}")

      socket
  end

  # Helper functions for the template
  def get_last_station_info(vorgang) do
    case vorgang["stationen"] do
      stations when is_list(stations) and length(stations) > 0 ->
        # Sort by zp_start descending and get the most recent
        # Parse dates properly before sorting
        sorted_stations = stations
        |> Enum.filter(fn station -> station["zp_start"] != nil end)
        |> Enum.sort_by(fn station ->
          case DateTime.from_iso8601(station["zp_start"]) do
            {:ok, datetime, _} -> datetime
            _ -> DateTime.new!(~D[1900-01-01], ~T[00:00:00], "Etc/UTC")
          end
        end, {:desc, DateTime})

        last_station = List.first(sorted_stations)
        %{
          date: last_station["zp_start"],
          type: last_station["typ"]
        }
      _ ->
        %{date: nil, type: nil}
    end
  end

  # Delegate to shared helpers
  defdelegate format_date(date_string), to: SharedLiveHelpers
  defdelegate get_vorgangstyp_label(vorgangstyp), to: SharedLiveHelpers
  defdelegate get_parlament_label(parlament), to: SharedLiveHelpers
  defdelegate format_time_remaining(expires_at), to: SharedLiveHelpers
end
