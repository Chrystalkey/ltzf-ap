defmodule LtzfApWeb.SitzungenLive do
  use LtzfApWeb, :live_view

  @unknown_scope "unknown"

  def mount(%{"s" => session_id} = _params, _session, socket) do
    mount_with_session(session_id, socket)
  end

  def mount(_params, _session, socket) do
    # Set up initial assigns
    socket =
      socket
      |> assign(:filters, %{"page" => "1", "per_page" => "64"})
      |> assign(:sitzungen, [])
      |> assign(:loading, false)
      |> assign(:error, nil)
      |> assign(:pagination, %{})
      |> assign(:session_id, nil)
      |> assign(:auth_info, %{scope: @unknown_scope})
      |> assign(:backend_url, nil)
      |> assign(:session_data, nil)
      |> assign(:current_week_start, get_current_week_start())

    # Check if we have a session ID from localStorage
    {:ok, socket |> push_event("get_stored_session", %{})}
  end

  def handle_event("restore_session", %{"session_id" => session_id}, socket) do
    try do
      case mount_with_session(session_id, socket) do
        {:ok, updated_socket} ->
          {:noreply, updated_socket}
        {:error, _reason} ->
          socket =
            socket
            |> assign(:filters, %{"page" => "1", "per_page" => "64"})
            |> assign(:sitzungen, [])
            |> assign(:loading, false)
            |> assign(:error, "Invalid session")
            |> assign(:pagination, %{})

          {:noreply, redirect(socket, to: ~p"/login")}
      end
    rescue
      error ->
        socket =
          socket
          |> assign(:filters, %{"page" => "1", "per_page" => "64"})
          |> assign(:sitzungen, [])
          |> assign(:loading, false)
          |> assign(:error, "Session restoration error")
          |> assign(:pagination, %{})

        {:noreply, redirect(socket, to: ~p"/login")}
    end
  end

  def handle_event("no_stored_session", _params, socket) do
    # Set up assigns for the login redirect
    socket =
      socket
      |> assign(:filters, %{"page" => "1", "per_page" => "64"})
      |> assign(:sitzungen, [])
      |> assign(:loading, false)
      |> assign(:error, nil)
      |> assign(:pagination, %{})

    {:ok, redirect(socket, to: ~p"/login")}
  end

  def handle_event("filter", params, socket) do
    # Update filters and reload data
    filters = %{
      "since" => params["since"],
      "until" => params["until"],
      "p" => params["p"],
      "wp" => params["wp"],
      "vgid" => params["vgid"],
      "vgtyp" => params["vgtyp"],
      "gr" => params["gr"],
      "y" => params["y"],
      "m" => params["m"],
      "dom" => params["dom"],
      "page" => params["page"] || "1",
      "per_page" => params["per_page"] || "64"
    }

    socket = assign(socket, :filters, filters)
    socket = load_sitzungen(socket)
    {:noreply, socket}
  end

  def handle_event("clear_filters", _params, socket) do
    filters = %{
      "page" => "1",
      "per_page" => "64"
    }

    socket = assign(socket, :filters, filters)
    socket = load_sitzungen(socket)
    {:noreply, socket}
  end

  def handle_event("page_change", %{"page" => page}, socket) do
    filters = Map.put(socket.assigns.filters, "page", page)
    socket = assign(socket, :filters, filters)
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
        day_of_week = get_day_of_week(date)
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
    LtzfAp.Session.delete_session(socket.assigns.session_id)
    {:noreply,
     socket
     |> push_event("clear_session", %{})
     |> redirect(to: ~p"/login")}
  end

  defp mount_with_session(session_id, socket) do
    case LtzfAp.Session.get_session(session_id) do
      {:ok, session_data} ->
        # Get auth info from the session data
        auth_info = case LtzfAp.Auth.validate_api_key(session_data.backend_url, session_data.api_key) do
          {:ok, info} -> info
          {:error, _reason} -> %{scope: @unknown_scope}
        end

        socket =
          socket
          |> assign(:session_id, session_id)
          |> assign(:auth_info, auth_info)
          |> assign(:backend_url, session_data.backend_url)
          |> assign(:session_data, session_data)
          |> assign(:filters, %{"page" => "1", "per_page" => "64"})
          |> assign(:sitzungen, [])
          |> assign(:loading, false)
          |> assign(:error, nil)
          |> assign(:pagination, %{})
          |> assign(:current_week_start, get_current_week_start())

        # Load initial data
        socket = load_sitzungen(socket)
        {:ok, socket}

      {:error, _reason} ->
        {:error, :invalid_session}
    end
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
            pagination = extract_pagination(headers)
            socket =
              socket
              |> assign(:sitzungen, sitzungen)
              |> assign(:pagination, pagination)
              |> assign(:loading, false)
              |> assign(:error, nil)

            socket

                  {:error, reason} ->
          socket =
            socket
            |> assign(:sitzungen, [])
            |> assign(:loading, false)
            |> assign(:error, nil) # Don't show error for empty weeks

          socket
        end
      end
    rescue
      error ->
        socket =
          socket
          |> assign(:sitzungen, [])
          |> assign(:loading, false)
          |> assign(:error, nil) # Don't show error for empty weeks

        socket
    end
  end

  defp extract_pagination(headers) do
    headers_map = Map.new(headers, fn {k, v} -> {String.downcase(k), v} end)

    %{
      total_count: parse_integer(headers_map["x-total-count"]),
      total_pages: parse_integer(headers_map["x-total-pages"]),
      current_page: parse_integer(headers_map["x-page"]) || 1,
      per_page: parse_integer(headers_map["x-per-page"]) || 64
    }
  end

  defp parse_integer(nil), do: nil
  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end
  defp parse_integer(value) when is_integer(value), do: value

  defp get_current_week_start do
    today = Date.utc_today()
    day_of_week = Date.day_of_week(today)
    Date.add(today, -(day_of_week - 1))
  end

  def format_time_remaining(expires_at) do
    # Handle both string and DateTime inputs
    expires_datetime = case expires_at do
      %DateTime{} -> expires_at
      string when is_binary(string) ->
        case DateTime.from_iso8601(string) do
          {:ok, datetime, _offset} -> datetime
          _ -> nil
        end
      _ -> nil
    end

    if expires_datetime do
      now = DateTime.utc_now()
      diff = DateTime.diff(expires_datetime, now, :second)

      cond do
        diff < 0 -> "Expired"
        diff < 60 -> "#{diff}s"
        diff < 3600 -> "#{div(diff, 60)}m"
        diff < 86400 -> "#{div(diff, 3600)}h"
        true -> "#{div(diff, 86400)}d"
      end
    else
      "Unknown"
    end
  end

  def get_week_days(week_start) do
    for i <- 0..6 do
      Date.add(week_start, i)
    end
  end

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

        def get_week_number(date) do
    # Calculate a simple week number based on the month and day
    # This is a simplified calculation for display purposes
    month = date.month
    day = date.day

    # Simple calculation: (month - 1) * 4 + (day / 7)
    # This gives approximately 4 weeks per month
    week_number = div((month - 1) * 28 + day, 7)

    # Ensure week number is between 1 and 52
    cond do
      week_number < 1 -> 1
      week_number > 52 -> 52
      true -> week_number
    end
  end

    def get_day_of_week(date) do
    # Calculate day of week (1 = Monday, 7 = Sunday)
    # Using Zeller's congruence algorithm
    year = date.year
    month = date.month
    day = date.day

    # Adjust month and year for January and February
    {month, year} = if month < 3 do
      {month + 12, year - 1}
    else
      {month, year}
    end

    century = div(year, 100)
    year_of_century = rem(year, 100)

    # Zeller's congruence
    h = rem(day + div(13 * (month + 1), 5) + year_of_century + div(year_of_century, 4) + div(century, 4) - 2 * century, 7)

    # Convert to Monday = 1, Sunday = 7
    day_of_week = rem(h + 5, 7) + 1

    day_of_week
  end

  def get_parliament_color(parlament) do
    case parlament do
      "BT" -> "bg-blue-600"      # Bundestag - Blue
      "BR" -> "bg-green-600"     # Bundesrat - Green
      "BV" -> "bg-purple-600"    # Bundesversammlung - Purple
      "EK" -> "bg-indigo-600"    # Europakammer - Indigo
      "BB" -> "bg-red-600"       # Brandenburg - Red
      "BY" -> "bg-blue-700"      # Bayern - Dark Blue
      "BE" -> "bg-red-700"       # Berlin - Dark Red
      "HB" -> "bg-orange-600"    # Bremen - Orange
      "HH" -> "bg-red-500"       # Hamburg - Light Red
      "HE" -> "bg-green-700"     # Hessen - Dark Green
      "MV" -> "bg-blue-500"      # Mecklenburg-Vorpommern - Light Blue
      "NI" -> "bg-yellow-600"    # Niedersachsen - Yellow
      "NW" -> "bg-green-500"     # Nordrhein-Westfalen - Light Green
      "RP" -> "bg-yellow-700"    # Rheinland-Pfalz - Dark Yellow
      "SL" -> "bg-blue-800"      # Saarland - Very Dark Blue
      "SN" -> "bg-green-800"     # Sachsen - Very Dark Green
      "TH" -> "bg-red-800"       # Thüringen - Very Dark Red
      "SH" -> "bg-blue-400"      # Schleswig-Holstein - Very Light Blue
      "BW" -> "bg-black"         # Baden-Württemberg - Black
      "ST" -> "bg-gray-700"      # Sachsen-Anhalt - Gray
      _ -> "bg-gray-600"         # Default - Gray
    end
  end

end
