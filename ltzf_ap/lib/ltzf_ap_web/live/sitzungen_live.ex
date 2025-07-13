defmodule LtzfApWeb.SitzungenLive do
  use LtzfApWeb, :live_view
  import LtzfApWeb.SharedHeader

  def mount(_params, _session, socket) do
    # Calculate current week start (Monday)
    today = Date.utc_today()
    current_week_start = Date.add(today, -Date.day_of_week(today) + 1)

    socket = assign(socket,
      sitzungen: [],
      filters: %{"page" => "1", "per_page" => "32"},
      loading: false,
      error: nil,
      pagination: %{},
      session_id: nil,
      auth_info: %{scope: "unknown"},
      session_data: %{expires_at: DateTime.utc_now()},
      backend_url: nil,
      current_week_start: current_week_start
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

    # Load sitzungen data
    send(self(), :load_sitzungen)
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

  def handle_event("load_sitzungen", _params, socket) do
    {:noreply,
     socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "getSitzungen",
       params: socket.assigns.filters,
       request_id: "sitzungen_load"
     })}
  end

  def handle_event("api_response", %{"request_id" => "sitzungen_load", "result" => result}, socket) do
    # Extract data and pagination info from API response
    sitzungen = result["data"] || []
    pagination = %{
      total_count: result["count"],
      total_pages: result["totalPages"],
      current_page: result["currentPage"],
      per_page: result["perPage"]
    }

    {:noreply, assign(socket, sitzungen: sitzungen, pagination: pagination, loading: false, error: nil)}
  end

  def handle_event("api_error", %{"request_id" => "sitzungen_load", "error" => error}, socket) do
    {:noreply, assign(socket, sitzungen: [], loading: false, error: error)}
  end

  def handle_event("filter_change", params, socket) do
    # Convert form params to filters map, excluding non-filter fields
    filters = Map.take(params, ["since", "until", "p", "wp", "gr", "vgid", "vgtyp", "page", "per_page"])
    socket = assign(socket, filters: filters)
    send(self(), :load_sitzungen)
    {:noreply, socket}
  end

  def handle_event("page_change", %{"page" => page}, socket) do
    filters = Map.put(socket.assigns.filters, "page", page)
    socket = assign(socket, filters: filters)
    send(self(), :load_sitzungen)
    {:noreply, socket}
  end

  def handle_info(:load_sitzungen, socket) do
    {:noreply,
     socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "getSitzungen",
       params: socket.assigns.filters,
       request_id: "sitzungen_load"
     })}
  end

  def handle_event("week_navigation", %{"direction" => direction}, socket) do
    current_week_start = socket.assigns.current_week_start

    new_week_start = case direction do
      "prev" -> Date.add(current_week_start, -7)
      "next" -> Date.add(current_week_start, 7)
      _ -> current_week_start
    end

    {:noreply, assign(socket, current_week_start: new_week_start)}
  end

  def handle_event("go_to_week", %{"date" => date_string}, socket) do
    case Date.from_iso8601(date_string) do
      {:ok, date} ->
        # Calculate week start (Monday) for the given date
        week_start = Date.add(date, -Date.day_of_week(date) + 1)
        {:noreply, assign(socket, current_week_start: week_start)}
      _ ->
        {:noreply, socket}
    end
  end

  # Helper functions for the template
  defp format_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> Calendar.strftime(date, "%d.%m.%Y")
      _ -> date_string
    end
  end

  defp format_date(_), do: "N/A"

  defp truncate_text(text, max_length \\ 100)
  defp truncate_text(text, max_length) when is_binary(text) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length) <> "..."
    else
      text
    end
  end

  defp truncate_text(_, _max_length), do: "N/A"

  defp format_time(time_string) when is_binary(time_string) do
    case DateTime.from_iso8601(time_string) do
      {:ok, datetime, _offset} ->
        # Format as HH:MM in local timezone
        Calendar.strftime(datetime, "%H:%M")
      _ ->
        # Fallback: try to extract time from the string
        case String.split(time_string, "T") do
          [_date, time_part] ->
            case String.split(time_part, ":") do
              [hour, minute | _] -> "#{hour}:#{minute}"
              _ -> "N/A"
            end
          _ -> "N/A"
        end
    end
  end

  defp format_time(_), do: "N/A"

  defp get_parliament_color("bundestag"), do: "bg-blue-500"
  defp get_parliament_color("bundesrat"), do: "bg-green-500"
  defp get_parliament_color("landtag"), do: "bg-purple-500"
  defp get_parliament_color(_), do: "bg-gray-500"

  defp get_gremium_display_name(gremium) when is_map(gremium) do
    gremium["name"] || gremium["id"] || "Unbekannt"
  end
  defp get_gremium_display_name(gremium) when is_binary(gremium), do: gremium
  defp get_gremium_display_name(_), do: "Unbekannt"

  defp get_week_days(week_start) when is_struct(week_start, Date) do
    Enum.map(0..6, fn day_offset ->
      Date.add(week_start, day_offset)
    end)
  end

  defp get_week_days(week_start) when is_binary(week_start) do
    case Date.from_iso8601(week_start) do
      {:ok, date} ->
        Enum.map(0..6, fn day_offset ->
          Date.add(date, day_offset)
        end)
      _ ->
        []
    end
  end

  defp get_week_days(_), do: []

    defp get_week_number(date) when is_struct(date, Date) do
    # Calculate ISO week number manually
    {_year, week} = :calendar.iso_week_number(Date.to_erl(date))
    week
  end

  defp get_week_number(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} ->
        {_year, week} = :calendar.iso_week_number(Date.to_erl(date))
        week
      _ -> 1
    end
  end

  defp get_week_number(_), do: 1

  defp group_sitzungen_by_day(sitzungen) do
    Enum.group_by(sitzungen, fn sitzung ->
      case sitzung do
        %{"termin" => termin} when is_binary(termin) ->
          case DateTime.from_iso8601(termin) do
            {:ok, datetime, _offset} -> Date.to_string(datetime)
            _ -> "unknown"
          end
        _ -> "unknown"
      end
    end)
  end

  defp extract_pagination_from_headers(headers) do
    %{
      total_count: parse_integer_header(headers["x-total-count"]),
      total_pages: parse_integer_header(headers["x-total-pages"]),
      current_page: parse_integer_header(headers["x-page"]) || 1,
      per_page: parse_integer_header(headers["x-per-page"]) || 32
    }
  end

  defp parse_integer_header(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end
  defp parse_integer_header(_), do: nil

end
