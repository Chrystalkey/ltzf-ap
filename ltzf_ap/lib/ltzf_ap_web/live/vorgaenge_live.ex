defmodule LtzfApWeb.VorgaengeLive do
  use LtzfApWeb, :live_view
  import LtzfApWeb.SharedHeader

  def mount(_params, _session, socket) do
    # Set default date filter to 2 days ago with timezone
    default_since = DateTime.utc_now() |> DateTime.add(-2, :day) |> DateTime.to_iso8601()

    socket = assign(socket,
      vorgaenge: [],
      filters: %{
        "page" => "1",
        "per_page" => "32",
        "since" => default_since,
        "until" => "",
        "p" => "",
        "person" => "",
        "fach" => "",
        "org" => "",
        "vgtyp" => "",
        "wp" => ""
      },
      loading: false,
      error: nil,
      pagination: %{},
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

    # Load vorgaenge data
    send(self(), :load_vorgaenge)
    {:noreply, socket}
  end

  def handle_event("session_expired", %{"error" => error}, socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
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

  def handle_event("add_new_vorgang", _params, socket) do
    # Generate a new UUID for the vorgang
    new_uuid = generate_uuid()
    {:noreply, redirect(socket, to: ~p"/vorgaenge/#{new_uuid}")}
  end

  def handle_event("load_vorgaenge", _params, socket) do
    # Only load if we have a valid session
    if socket.assigns.session_id do
      {:noreply,
       socket
       |> assign(:loading, true)
       |> push_event("api_request", %{
         method: "getVorgaenge",
         params: socket.assigns.filters,
         request_id: "vorgaenge_load"
       })}
    else
      {:noreply, socket}
    end
  end

  def handle_event("api_response", %{"request_id" => "vorgaenge_load", "result" => result}, socket) do
    # Extract data and pagination info from API response
    vorgaenge = result["data"] || []
    pagination = %{
      total_count: result["count"],
      total_pages: result["totalPages"],
      current_page: result["currentPage"],
      per_page: result["perPage"]
    }

    {:noreply, assign(socket, vorgaenge: vorgaenge, pagination: pagination, loading: false, error: nil)}
  end

  def handle_event("api_response", %{"request_id" => "vorgaenge_load", "error" => error, "success" => false}, socket) do
    # Handle API error response
    {:noreply, assign(socket, vorgaenge: [], loading: false, error: error)}
  end

  def handle_event("api_error", %{"request_id" => "vorgaenge_load", "error" => error}, socket) do
    {:noreply, assign(socket, vorgaenge: [], loading: false, error: error)}
  end

  def handle_event("filter_change", params, socket) do
    # Convert form params to filters map, excluding non-filter fields
    filters = Map.take(params, ["since", "until", "p", "wp", "person", "fach", "org", "vgtyp", "page", "per_page"])

    # Convert datetime-local values to ISO 8601 format with timezone
    filters = filters
    |> convert_datetime_local_to_iso8601("since")
    |> convert_datetime_local_to_iso8601("until")

    socket = assign(socket, filters: filters)
    send(self(), :load_vorgaenge)
    {:noreply, socket}
  end

  def handle_event("page_change", %{"page" => page}, socket) do
    filters = Map.put(socket.assigns.filters, "page", page)
    socket = assign(socket, filters: filters)
    send(self(), :load_vorgaenge)
    {:noreply, socket}
  end

  def handle_info(:load_vorgaenge, socket) do
    # Only load if we have a valid session
    if socket.assigns.session_id do
      {:noreply,
       socket
       |> assign(:loading, true)
       |> push_event("api_request", %{
         method: "getVorgaenge",
         params: socket.assigns.filters,
         request_id: "vorgaenge_load"
       })}
    else
      {:noreply, socket}
    end
  end

  def handle_info(:retry_session_restore, socket) do
    {:noreply, push_event(socket, "restore_session", %{})}
  end

  # Helper functions for the template
  defp format_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> Calendar.strftime(date, "%d.%m.%Y")
      _ -> date_string
    end
  end

  defp format_date(_), do: "N/A"

  # Convert datetime-local input value to ISO 8601 format with timezone
  defp convert_datetime_local_to_iso8601(filters, field) when is_map(filters) do
    case Map.get(filters, field) do
      "" ->
        # Empty string means no filter
        Map.put(filters, field, "")
      value when is_binary(value) and value != "" ->
        # Convert "YYYY-MM-DDTHH:MM" to "YYYY-MM-DDTHH:MM:00.000Z"
        case NaiveDateTime.from_iso8601("#{value}:00") do
          {:ok, naive_datetime} ->
            case DateTime.from_naive(naive_datetime, "Etc/UTC") do
              {:ok, datetime} -> Map.put(filters, field, DateTime.to_iso8601(datetime))
              {:error, _} -> filters
            end
          {:error, _} -> filters
        end
      _ ->
        filters
    end
  end

  # Convert ISO 8601 datetime to datetime-local format for display
  defp convert_iso8601_to_datetime_local(iso8601_string) when is_binary(iso8601_string) do
    case DateTime.from_iso8601(iso8601_string) do
      {:ok, datetime, _} ->
        # Convert to datetime-local format: YYYY-MM-DDTHH:MM
        datetime
        |> DateTime.to_naive()
        |> NaiveDateTime.truncate(:second)
        |> NaiveDateTime.to_string()
        |> String.slice(0, 16)
      {:error, _} ->
        ""
    end
  end
  defp convert_iso8601_to_datetime_local(_), do: ""

  defp truncate_text(text, max_length \\ 100)
  defp truncate_text(text, max_length) when is_binary(text) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length) <> "..."
    else
      text
    end
  end

  defp truncate_text(_, _max_length), do: "N/A"

  defp get_vorgangstyp_label("antrag"), do: "Antrag"
  defp get_vorgangstyp_label("anfrage"), do: "Anfrage"
  defp get_vorgangstyp_label("bericht"), do: "Bericht"
  defp get_vorgangstyp_label("beschluss"), do: "Beschluss"
  defp get_vorgangstyp_label("entwurf"), do: "Entwurf"
  defp get_vorgangstyp_label("gesetz"), do: "Gesetz"
  defp get_vorgangstyp_label("mitteilung"), do: "Mitteilung"
  defp get_vorgangstyp_label("verordnung"), do: "Verordnung"
  defp get_vorgangstyp_label(typ) when is_binary(typ), do: String.capitalize(typ)
  defp get_vorgangstyp_label(_), do: "Unbekannt"

  defp get_parlament_label(parlament) when is_binary(parlament) do
    case parlament do
      "bundestag" -> "Bundestag"
      "bundesrat" -> "Bundesrat"
      "landtag" -> "Landtag"
      _ -> String.capitalize(parlament)
    end
  end
  defp get_parlament_label(_), do: "Unbekannt"

  defp get_last_station_info(vorgang) do
    case vorgang do
      %{"stationen" => stations} when is_list(stations) and length(stations) > 0 ->
        List.last(stations)
      _ ->
        nil
    end
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

  # Generate a UUID v7 string
  defp generate_uuid do
    # Get current timestamp in milliseconds since Unix epoch
    timestamp_ms = System.system_time(:millisecond)

    # Convert to 48-bit timestamp (first 6 bytes)
    timestamp_bytes = <<timestamp_ms::48>>

    # Generate 10 random bytes for the remaining part
    random_bytes = :crypto.strong_rand_bytes(10)

    # Combine timestamp and random bytes
    uuid_bytes = timestamp_bytes <> random_bytes

    # Encode as hex
    uuid_hex = Base.encode16(uuid_bytes, case: :lower)

    # Format as UUID v7: xxxxxxxx-xxxx-7xxx-yxxx-xxxxxxxxxxxx
    # where x is any hex digit, 7 is the version, and y is one of 8, 9, A, or B
    <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4), e::binary-size(12)>> = uuid_hex

    # Ensure version 7 UUID format (7 in the third group)
    c = "7" <> String.slice(c, 1, 3)

    # Ensure variant bits (8, 9, A, or B in the fourth group)
    d = "8" <> String.slice(d, 1, 3)

    "#{a}-#{b}-#{c}-#{d}-#{e}"
  end

end
