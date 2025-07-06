defmodule LtzfApWeb.SitzungenLive do
  use LtzfApWeb, :live_view

  alias LtzfApWeb.SharedLiveHelpers
  import LtzfApWeb.SharedHeader

  def mount(%{"s" => session_id} = _params, _session, socket) do
    additional_assigns = %{current_week_start: SharedLiveHelpers.get_current_week_start()}
    case SharedLiveHelpers.mount_with_session(session_id, socket, additional_assigns) do
      {:ok, socket} ->
        socket = load_sitzungen(socket)
        {:ok, socket}
      {:error, _reason} ->
        {:ok, redirect(socket, to: "/login")}
    end
  end

  def mount(_params, _session, socket) do
    # Set up initial assigns
    additional_assigns = %{current_week_start: SharedLiveHelpers.get_current_week_start()}
    assigns = SharedLiveHelpers.initial_assigns(additional_assigns)
    socket = assign(socket, assigns)

    # Check if we have a session ID from localStorage
    {:ok, socket |> push_event("get_stored_session", %{})}
  end

  def handle_event("restore_session", %{"session_id" => session_id}, socket) do
    try do
      additional_assigns = %{current_week_start: SharedLiveHelpers.get_current_week_start()}
      case SharedLiveHelpers.mount_with_session(session_id, socket, additional_assigns) do
        {:ok, updated_socket} ->
          updated_socket = load_sitzungen(updated_socket)
          {:noreply, updated_socket}
        {:error, _reason} ->
          additional_assigns = %{current_week_start: SharedLiveHelpers.get_current_week_start()}
          SharedLiveHelpers.handle_session_restoration_error(socket, "Invalid session", additional_assigns)
      end
    rescue
      _error ->
        additional_assigns = %{current_week_start: SharedLiveHelpers.get_current_week_start()}
        SharedLiveHelpers.handle_session_restoration_error(socket, "Session restoration error", additional_assigns)
    end
  end

  def handle_event("no_stored_session", _params, socket) do
    additional_assigns = %{current_week_start: SharedLiveHelpers.get_current_week_start()}
    assigns = SharedLiveHelpers.initial_assigns(additional_assigns)
    socket = assign(socket, assigns)
    {:ok, redirect(socket, to: ~p"/login")}
  end

  def handle_event("filter", params, socket) do
    filter_keys = ["since", "until", "p", "wp", "vgid", "vgtyp", "gr", "y", "m", "dom"]
    socket = SharedLiveHelpers.handle_filter(params, socket, filter_keys, :load_sitzungen)
    socket = load_sitzungen(socket)
    {:noreply, socket}
  end

  def handle_event("clear_filters", _params, socket) do
    socket = SharedLiveHelpers.handle_clear_filters(socket, "64", :load_sitzungen)
    socket = load_sitzungen(socket)
    {:noreply, socket}
  end

  def handle_event("page_change", %{"page" => page}, socket) do
    socket = SharedLiveHelpers.handle_page_change(socket, page, :load_sitzungen)
    socket = load_sitzungen(socket)
    {:noreply, socket}
  end

  def handle_event("week_navigation", %{"direction" => direction}, socket) do
    current_week_start = socket.assigns.current_week_start
    new_week_start = case direction do
      "prev" -> Date.add(current_week_start, -7)
      "next" -> Date.add(current_week_start, 7)
    end

    socket = assign(socket, :current_week_start, new_week_start)
    socket = load_sitzungen(socket)
    {:noreply, socket}
  end

  def handle_event("go_to_week", %{"date" => date_string}, socket) do
    case Date.from_iso8601(date_string) do
      {:ok, date} ->
        # Find the start of the week (Monday) for the given date
        day_of_week = SharedLiveHelpers.get_day_of_week(date)
        week_start = Date.add(date, -(day_of_week - 1))

        socket = assign(socket, :current_week_start, week_start)
        socket = load_sitzungen(socket)
        {:noreply, socket}
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("edit_session", %{"session-id" => session_id}, socket) do
    # For now, just log the session ID. You can implement the edit functionality later
    IO.puts("Edit session: #{session_id}")

    # You could redirect to an edit page or open a modal here
    # For example:
    # {:noreply, redirect(socket, to: ~p"/sitzungen/#{session_id}/edit")}

    # Or you could assign the session to edit and show a modal
    # socket = assign(socket, :editing_session, session_id)
    # {:noreply, socket}

    {:noreply, socket}
  end

  def handle_event("logout", _params, socket) do
    SharedLiveHelpers.handle_logout(socket)
  end

  defp load_sitzungen(socket) do
    try do
      # Don't load if we don't have session data
      if is_nil(socket.assigns.session_data) do
        socket
      else
        socket = assign(socket, :loading, true)

        # Convert filters to API parameters and add week range
        week_start = socket.assigns.current_week_start
        week_end = Date.add(week_start, 6)

        params = socket.assigns.filters
        |> Map.put("since", Date.to_string(week_start) <> "T00:00:00+00:00")
        |> Map.put("until", Date.to_string(week_end) <> "T23:59:59+00:00")
        |> Enum.filter(fn {_key, value} -> value != nil and value != "" end)
        |> Enum.map(fn {key, value} -> {key, value} end)

        case LtzfAp.ApiClient.get_sitzungen_with_headers(
          socket.assigns.backend_url,
          socket.assigns.session_data.api_key,
          params
        ) do
          {:ok, sitzungen, headers} ->
            pagination = SharedLiveHelpers.extract_pagination(headers)
            socket =
              socket
              |> assign(:sitzungen, sitzungen)
              |> assign(:pagination, pagination)
              |> assign(:loading, false)
              |> assign(:error, nil)

            socket

          {:error, _reason} ->
            socket =
              socket
              |> assign(:sitzungen, [])
              |> assign(:loading, false)
              |> assign(:error, nil) # Don't show error for empty weeks

            socket
        end
      end
    rescue
      _error ->
        socket =
          socket
          |> assign(:sitzungen, [])
          |> assign(:loading, false)
          |> assign(:error, nil) # Don't show error for empty weeks

        socket
    end
  end

  # Delegate to shared helpers
  defdelegate format_time_remaining(expires_at), to: SharedLiveHelpers
  defdelegate get_week_days(week_start), to: SharedLiveHelpers
  defdelegate get_week_number(date), to: SharedLiveHelpers
  defdelegate get_parliament_color(parlament), to: SharedLiveHelpers

  def group_sitzungen_by_day(sitzungen) do
    sitzungen
    |> Enum.group_by(fn sitzung ->
      case DateTime.from_iso8601(sitzung["termin"]) do
        {:ok, datetime, _offset} -> Date.new!(datetime.year, datetime.month, datetime.day)
        _ -> nil
      end
    end)
    |> Map.new(fn {date, sessions} -> {date, Enum.sort_by(sessions, & &1["termin"])} end)
  end

  def format_time(termin) do
    case DateTime.from_iso8601(termin) do
      {:ok, datetime, _offset} ->
        datetime
        |> DateTime.to_time()
        |> Time.to_string()
        |> String.slice(0, 5)
      _ -> "??:??"
    end
  end

  def get_gremium_display_name(gremium) do
    case gremium do
      %{"name" => name, "parlament" => parlament, "wahlperiode" => wahlperiode} ->
        "#{name} (#{parlament} #{wahlperiode})"
      %{"name" => name, "parlament" => parlament} ->
        "#{name} (#{parlament})"
      %{"name" => name} ->
        name
      _ -> "Unbekanntes Gremium"
    end
  end
end
