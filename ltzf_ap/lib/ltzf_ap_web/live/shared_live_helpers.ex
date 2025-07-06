defmodule LtzfApWeb.SharedLiveHelpers do
  @moduledoc """
  Shared functionality for LiveView modules that handle API data with session management.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  @unknown_scope "unknown"

  @doc """
  Common mount function for LiveView modules that need session management.
  """
  def mount_with_session(session_id, socket, additional_assigns \\ %{}) do
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
          |> assign(:loading, false)
          |> assign(:error, nil)
          |> assign(:pagination, %{})
          |> assign(additional_assigns)

        {:ok, socket}

      {:error, _reason} ->
        {:error, :invalid_session}
    end
  end

  @doc """
  Common initial assigns for LiveView modules.
  """
  def initial_assigns(additional_assigns \\ %{}) do
    %{
      filters: %{"page" => "1", "per_page" => "32"},
      loading: false,
      error: nil,
      pagination: %{},
      session_id: nil,
      auth_info: %{scope: @unknown_scope},
      backend_url: nil,
      session_data: nil,
      vorgaenge: [],
      sitzungen: []
    }
    |> Map.merge(additional_assigns)
  end

  @doc """
  Common session restoration error handling.
  """
  def handle_session_restoration_error(socket, error_message, additional_assigns \\ %{}) do
    socket =
      socket
      |> assign(:filters, %{"page" => "1", "per_page" => "32"})
      |> assign(:loading, false)
      |> assign(:error, error_message)
      |> assign(:pagination, %{})
      |> assign(additional_assigns)

    {:noreply, redirect(socket, to: "/login")}
  end

  @doc """
  Common logout handler.
  """
  def handle_logout(socket) do
    LtzfAp.Session.delete_session(socket.assigns.session_id)
    {:noreply,
     socket
     |> push_event("clear_session", %{})
     |> redirect(to: "/login")}
  end

  @doc """
  Common filter event handler.
  """
  def handle_filter(params, socket, filter_keys, _load_function) do
    filters = Map.take(params, filter_keys)
    |> Map.put("page", params["page"] || "1")
    |> Map.put("per_page", params["per_page"] || "32")

    assign(socket, :filters, filters)
  end

  @doc """
  Common clear filters handler.
  """
  def handle_clear_filters(socket, per_page \\ "32", _load_function) do
    filters = %{
      "page" => "1",
      "per_page" => per_page
    }

    assign(socket, :filters, filters)
  end

  @doc """
  Common page change handler.
  """
  def handle_page_change(socket, page, _load_function) do
    filters = Map.put(socket.assigns.filters, "page", page)
    assign(socket, :filters, filters)
  end

  @doc """
  Extract pagination information from API response headers.
  """
  def extract_pagination(headers) do
    headers_map = Map.new(headers, fn {k, v} -> {String.downcase(k), v} end)

    %{
      total_count: parse_integer(headers_map["x-total-count"]),
      total_pages: parse_integer(headers_map["x-total-pages"]),
      current_page: parse_integer(headers_map["x-page"]) || 1,
      per_page: parse_integer(headers_map["x-per-page"]) || 32,
      link: headers_map["link"]
    }
  end

  @doc """
  Parse integer from string or return nil.
  """
  def parse_integer(nil), do: nil
  def parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end
  def parse_integer(value) when is_integer(value), do: value

  @doc """
  Format time remaining until expiration.
  """
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

  @doc """
  Get parliament display label.
  """
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

  @doc """
  Get vorgangstyp display label.
  """
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

  @doc """
  Format date string to German format.
  """
  def format_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _} -> Calendar.strftime(datetime, "%d.%m.%Y %H:%M")
      _ -> date_string
    end
  end
  def format_date(_), do: "N/A"

  @doc """
  Get parliament color for styling.
  """
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

  @doc """
  Calculate day of week using Zeller's congruence (1 = Monday, 7 = Sunday).
  """
  def get_day_of_week(date) do
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

  @doc """
  Get current week start (Monday).
  """
  def get_current_week_start do
    today = Date.utc_today()
    day_of_week = Date.day_of_week(today)
    Date.add(today, -(day_of_week - 1))
  end

  @doc """
  Get week days from week start.
  """
  def get_week_days(week_start) do
    for i <- 0..6 do
      Date.add(week_start, i)
    end
  end

  @doc """
  Calculate week number for display.
  """
  def get_week_number(date) do
    month = date.month
    day = date.day

    # Simple calculation: (month - 1) * 4 + (day / 7)
    week_number = div((month - 1) * 28 + day, 7)

    # Ensure week number is between 1 and 52
    cond do
      week_number < 1 -> 1
      week_number > 52 -> 52
      true -> week_number
    end
  end
end
