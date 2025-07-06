defmodule LtzfApWeb.VorgaengeLive do
  use LtzfApWeb, :live_view

  @unknown_scope "unknown"

      def mount(%{"s" => session_id} = _params, _session, socket) do
    mount_with_session(session_id, socket)
  end

  def mount(_params, _session, socket) do
    # Set up initial assigns
    socket =
      socket
      |> assign(:filters, %{"page" => "1", "per_page" => "32"})
      |> assign(:vorgaenge, [])
      |> assign(:loading, false)
      |> assign(:error, nil)
      |> assign(:pagination, %{})
      |> assign(:session_id, nil)
      |> assign(:auth_info, %{scope: @unknown_scope})
      |> assign(:backend_url, nil)
      |> assign(:session_data, nil)

    # Check if we have a session ID from localStorage
    {:ok, socket |> push_event("get_stored_session", %{})}
  end

  def handle_event("restore_session", %{"session_id" => session_id}, socket) do

    case mount_with_session(session_id, socket) do
      {:ok, updated_socket} ->
        {:noreply, updated_socket}
      {:error, reason} ->
        socket =
          socket
          |> assign(:filters, %{"page" => "1", "per_page" => "32"})
          |> assign(:vorgaenge, [])
          |> assign(:loading, false)
          |> assign(:error, "Invalid session")
          |> assign(:pagination, %{})

        {:noreply, redirect(socket, to: ~p"/login")}
    end
  rescue
    error ->
      socket =
        socket
        |> assign(:filters, %{"page" => "1", "per_page" => "32"})
        |> assign(:vorgaenge, [])
        |> assign(:loading, false)
        |> assign(:error, "Session restoration error")
        |> assign(:pagination, %{})

      {:noreply, redirect(socket, to: ~p"/login")}
  end

  def handle_event("no_stored_session", _params, socket) do
    # Set up assigns for the login redirect
    socket =
      socket
      |> assign(:filters, %{"page" => "1", "per_page" => "32"})
      |> assign(:vorgaenge, [])
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
      "person" => params["person"],
      "fach" => params["fach"],
      "org" => params["org"],
      "vgtyp" => params["vgtyp"],
      "page" => params["page"] || "1",
      "per_page" => params["per_page"] || "32"
    }

    socket = assign(socket, :filters, filters)
    socket = load_vorgaenge(socket)
    {:noreply, socket}
  end

  def handle_event("clear_filters", _params, socket) do
    filters = %{
      "page" => "1",
      "per_page" => "32"
    }

    socket = assign(socket, :filters, filters)
    socket = load_vorgaenge(socket)
    {:noreply, socket}
  end

  def handle_event("page_change", %{"page" => page}, socket) do
    filters = Map.put(socket.assigns.filters, "page", page)
    socket = assign(socket, :filters, filters)
    socket = load_vorgaenge(socket)
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
          {:ok, info} ->
            info
          {:error, reason} ->
            %{scope: @unknown_scope}
        end

        socket =
          socket
          |> assign(:session_id, session_id)
          |> assign(:auth_info, auth_info)
          |> assign(:backend_url, session_data.backend_url)
          |> assign(:session_data, session_data)
          |> assign(:filters, %{"page" => "1", "per_page" => "32"})
          |> assign(:vorgaenge, [])
          |> assign(:loading, false)
          |> assign(:error, nil)
          |> assign(:pagination, %{})

        # Load initial data
        socket = load_vorgaenge(socket)
        {:ok, socket}

      {:error, reason} ->
        {:error, :invalid_session}
    end
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

          pagination = extract_pagination(headers)
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

  defp extract_pagination(headers) do
    headers_map = Map.new(headers, fn {k, v} -> {String.downcase(k), v} end)

    %{
      total_count: parse_int(headers_map["x-total-count"]),
      total_pages: parse_int(headers_map["x-total-pages"]),
      current_page: parse_int(headers_map["x-page"]) || 1,
      per_page: parse_int(headers_map["x-per-page"]) || 32,
      link: headers_map["link"]
    }
  end

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end
  defp parse_int(_), do: nil

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

  def format_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _} -> Calendar.strftime(datetime, "%d.%m.%Y %H:%M")
      _ -> date_string
    end
  end
  def format_date(_), do: "N/A"

  def get_vorgangstyp_label(vorgangstyp) do
    case vorgangstyp do
      "gg-einspruch" -> "Bundesgesetz Einspruch"
      "gg-zustimmung" -> "Bundesgesetz Zustimmungspflichtig"
      "gg-land-parl" -> "Landesgesetz (normal)"
      "gg-land-volk" -> "Landesgesetz (Volksgesetzgebung)"
      "bw-einsatz" -> "Bundeswehreinsatz"
      "sonstig" -> "Sonstiges"
      _ -> vorgangstyp
    end
  end

  def get_parlament_label(parlament) do
    case parlament do
      "BT" -> "Bundestag"
      "BR" -> "Bundesrat"
      "BV" -> "Bundesversammlung"
      "EK" -> "Europakammer des Bundesrats"
      "BB" -> "Brandenburg"
      "BY" -> "Bayern"
      "BE" -> "Berlin"
      "HB" -> "Hansestadt Bremen"
      "HH" -> "Hansestadt Hamburg"
      "HE" -> "Hessen"
      "MV" -> "Mecklenburg-Vorpommern"
      "NI" -> "Niedersachsen"
      "NW" -> "Nordrhein-Westfalen"
      "RP" -> "Rheinland-Pfalz"
      "SL" -> "Saarland"
      "SN" -> "Sachsen"
      "TH" -> "Thüringen"
      "SH" -> "Schleswig-Holstein"
      "BW" -> "Baden-Württemberg"
      "ST" -> "Sachsen-Anhalt"
      _ -> parlament
    end
  end

  # Time formatting helper
  defp format_time_remaining(expires_at) do
    now = DateTime.utc_now()
    diff = DateTime.diff(expires_at, now, :second)

    if diff > 0 do
      days = div(diff, 86400)
      hours = div(rem(diff, 86400), 3600)
      minutes = div(rem(diff, 3600), 60)

      cond do
        days > 0 -> "#{days}d #{hours}h"
        hours > 0 -> "#{hours}h #{minutes}m"
        true -> "#{minutes}m"
      end
    else
      "Expired"
    end
  end
end
