defmodule LtzfApWeb.SharedLiveHelpers do
  @moduledoc """
  Shared helper functions for LiveView modules to reduce code duplication.
  """

  # Vorgangstyp label functions
  def get_vorgangstyp_label("gg-einspruch"), do: "Bundesgesetz Einspruch"
  def get_vorgangstyp_label("gg-zustimmung"), do: "Bundesgesetz Zustimmungspflichtig"
  def get_vorgangstyp_label("gg-land-parl"), do: "Landesgesetz (normal)"
  def get_vorgangstyp_label("gg-land-volk"), do: "Landesgesetz (Volksgesetzgebung)"
  def get_vorgangstyp_label("bw-einsatz"), do: "Bundeswehreinsatz"
  def get_vorgangstyp_label("sonstig"), do: "Sonstiges"
  def get_vorgangstyp_label("antrag"), do: "Antrag"
  def get_vorgangstyp_label("anfrage"), do: "Anfrage"
  def get_vorgangstyp_label("bericht"), do: "Bericht"
  def get_vorgangstyp_label("beschluss"), do: "Beschluss"
  def get_vorgangstyp_label("entwurf"), do: "Entwurf"
  def get_vorgangstyp_label("gesetz"), do: "Gesetz"
  def get_vorgangstyp_label("mitteilung"), do: "Mitteilung"
  def get_vorgangstyp_label("verordnung"), do: "Verordnung"
  def get_vorgangstyp_label(typ) when is_binary(typ), do: String.capitalize(typ)
  def get_vorgangstyp_label(_), do: "Unbekannt"

  # Stationstyp label functions
  def get_stationstyp_label("preparl-regent"), do: "Referentenentwurf / Regierungsentwurf"
  def get_stationstyp_label("preparl-eckpup"), do: "Eckpunktepapier / Parlamentsentwurf"
  def get_stationstyp_label("preparl-regbsl"), do: "Kabinettsbeschluss / Regierungsbeschluss"
  def get_stationstyp_label("preparl-vbegde"), do: "Volksbegehren / Diskussionsentwurf"
  def get_stationstyp_label("parl-initiativ"), do: "Gesetzesinitiative"
  def get_stationstyp_label("parl-ausschber"), do: "Beratung im Ausschuss"
  def get_stationstyp_label("parl-vollvlsgn"), do: "Vollversammlung / Lesung"
  def get_stationstyp_label("parl-akzeptanz"), do: "Schlussabstimmung & Akzeptanz"
  def get_stationstyp_label("parl-ablehnung"), do: "Schlussabstimmung & Ablehnung"
  def get_stationstyp_label("parl-zurueckgz"), do: "Plenarsitzung & Rückzug"
  def get_stationstyp_label("parl-ggentwurf"), do: "Gegenentwurf des Parlaments"
  def get_stationstyp_label("postparl-vesja"), do: "Volksentscheid nach Akzeptanz"
  def get_stationstyp_label("postparl-vesne"), do: "Volksentscheid nach Ablehnung"
  def get_stationstyp_label("postparl-gsblt"), do: "Veröffentlichung im Gesetzesblatt"
  def get_stationstyp_label("postparl-kraft"), do: "In Kraft getreten"
  def get_stationstyp_label("sonstig"), do: "Sonstiges"
  def get_stationstyp_label(typ) when is_binary(typ), do: String.capitalize(typ)
  def get_stationstyp_label(_), do: "Unbekannt"

  # Parliament label functions
  def get_parlament_label("BT"), do: "Bundestag"
  def get_parlament_label("BR"), do: "Bundesrat"
  def get_parlament_label("BV"), do: "Bundesversammlung"
  def get_parlament_label("EK"), do: "Europakammer des Bundesrats"
  def get_parlament_label("BB"), do: "Brandenburg"
  def get_parlament_label("BY"), do: "Bayern"
  def get_parlament_label("BE"), do: "Berlin"
  def get_parlament_label("HB"), do: "Hansestadt Bremen"
  def get_parlament_label("HH"), do: "Hansestadt Hamburg"
  def get_parlament_label("HE"), do: "Hessen"
  def get_parlament_label("MV"), do: "Mecklenburg-Vorpommern"
  def get_parlament_label("NI"), do: "Niedersachsen"
  def get_parlament_label("NW"), do: "Nordrhein-Westfalen"
  def get_parlament_label("RP"), do: "Rheinland-Pfalz"
  def get_parlament_label("SL"), do: "Saarland"
  def get_parlament_label("SN"), do: "Sachsen"
  def get_parlament_label("TH"), do: "Thüringen"
  def get_parlament_label("SH"), do: "Schleswig-Holstein"
  def get_parlament_label("BW"), do: "Baden-Württemberg"
  def get_parlament_label("ST"), do: "Sachsen-Anhalt"
  def get_parlament_label("bundestag"), do: "Bundestag"
  def get_parlament_label("bundesrat"), do: "Bundesrat"
  def get_parlament_label("landtag"), do: "Landtag"
  def get_parlament_label(parlament) when is_binary(parlament), do: String.capitalize(parlament)
  def get_parlament_label(_), do: "Unbekannt"

  # Date formatting functions
  def format_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> Calendar.strftime(date, "%d.%m.%Y")
      _ -> date_string
    end
  end
  def format_date(_), do: "N/A"

  def format_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _} -> Calendar.strftime(datetime, "%d.%m.%Y %H:%M")
      _ -> datetime_string
    end
  end
  def format_datetime(_), do: "N/A"

  # Text utility functions
  def truncate_text(text, max_length \\ 100)
  def truncate_text(text, max_length) when is_binary(text) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length) <> "..."
    else
      text
    end
  end
  def truncate_text(_, _max_length), do: "N/A"

  # Parliament color functions
  def get_parliament_color("bundestag"), do: "bg-blue-500"
  def get_parliament_color("bundesrat"), do: "bg-green-500"
  def get_parliament_color("landtag"), do: "bg-purple-500"
  def get_parliament_color(_), do: "bg-gray-500"

  # Enumeration display name functions
  def get_enumeration_display_name("schlagworte"), do: "Schlagworte"
  def get_enumeration_display_name("stationstypen"), do: "Stationstypen"
  def get_enumeration_display_name("vorgangstypen"), do: "Vorgangstypen"
  def get_enumeration_display_name("parlamente"), do: "Parlamente"
  def get_enumeration_display_name("vgidtypen"), do: "Vorgang ID Typen"
  def get_enumeration_display_name("dokumententypen"), do: "Dokumententypen"
  def get_enumeration_display_name("autoren"), do: "Autoren"
  def get_enumeration_display_name("gremien"), do: "Gremien"
  def get_enumeration_display_name(name), do: name

  # Enumeration item ID functions
  def get_item_id(item, _enumeration) when is_map(item), do: item["id"] || item["value"]
  def get_item_id(item, _enumeration) when is_binary(item), do: item
  def get_item_id(_, _), do: ""

  def get_item_id_for_display(item, "autoren") when is_map(item), do: item["id"] || item["value"] || "#{item["person"] || ""}-#{item["organisation"] || ""}"
  def get_item_id_for_display(item, "gremien") when is_map(item), do: item["id"] || item["value"] || "#{item["name"] || ""}-#{item["parlament"] || ""}-#{item["wahlperiode"] || ""}"
  def get_item_id_for_display(item, _enumeration) when is_map(item), do: item["id"] || item["value"]
  def get_item_id_for_display(item, _enumeration) when is_binary(item), do: item
  def get_item_id_for_display(_, _), do: ""

  # Vorgang utility functions
  def get_last_station_info(vorgang) do
    case vorgang do
      %{"stationen" => stations} when is_list(stations) and length(stations) > 0 ->
        List.last(stations)
      _ ->
        nil
    end
  end

  # Pagination utility functions
  def extract_pagination_from_headers(headers) do
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
