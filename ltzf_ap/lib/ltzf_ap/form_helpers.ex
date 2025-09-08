defmodule LtzfAp.FormHelpers do
  @moduledoc """
  Helper functions for working with form data and converting between
  form parameters and structured data objects.
  """

  alias LtzfAp.Schemas

  @doc """
  Converts form parameters for a vorgang to a structured Vorgang object.
  """
  @spec form_params_to_vorgang(map(), map() | nil) :: map()
  def form_params_to_vorgang(params, current_vorgang) do
    current_vorgang = current_vorgang || %{}

    current_vorgang
    |> Map.put("typ", params["typ"] || current_vorgang["typ"])
    |> Map.put("verfassungsaendernd", params["verfassungsaendernd"] == "true")
    |> Map.put("wahlperiode", parse_integer_or_default(params["wahlperiode"], current_vorgang["wahlperiode"] || 0))
    |> Map.put("titel", params["titel"] || current_vorgang["titel"] || "")
    |> Map.put("kurztitel", params["kurztitel"] || current_vorgang["kurztitel"])
  end

  @doc """
  Creates a new VgIdent from form parameters.
  """
  @spec form_params_to_vg_ident(map()) :: Schemas.VgIdent.t()
  def form_params_to_vg_ident(%{"typ" => typ, "id_value" => id}) do
    %Schemas.VgIdent{
      id: id,
      typ: typ
    }
  end

  @doc """
  Creates a new Autor from form parameters.
  """
  @spec form_params_to_autor(map()) :: Schemas.Autor.t()
  def form_params_to_autor(%{"person" => person, "organisation" => organisation, "fachgebiet" => fachgebiet, "lobbyregister" => lobbyregister}) do
    %Schemas.Autor{
      person: person,
      organisation: organisation,
      fachgebiet: fachgebiet,
      lobbyregister: lobbyregister
    }
  end

  def form_params_to_autor(%{"person" => person, "organisation" => organisation, "fachgebiet" => fachgebiet}) do
    %Schemas.Autor{
      person: person,
      organisation: organisation,
      fachgebiet: fachgebiet,
      lobbyregister: nil
    }
  end

  @doc """
  Creates a new Lobbyregeintrag from form parameters.
  """
  @spec form_params_to_lobbyregister(map()) :: Schemas.Lobbyregeintrag.t()
  def form_params_to_lobbyregister(params) do
    organisation = %Schemas.Autor{
      person: params["organisation_person"] || "",
      organisation: params["organisation_name"] || "",
      fachgebiet: params["organisation_fachgebiet"] || "",
      lobbyregister: params["organisation_lobbyregister"] || ""
    }

    betroffene_drucksachen = case params["betroffene_drucksachen"] do
      "" -> []
      drucksachen_str -> String.split(drucksachen_str, ",") |> Enum.map(&String.trim/1)
    end

    %Schemas.Lobbyregeintrag{
      organisation: organisation,
      interne_id: params["interne_id"] || "",
      intention: params["intention"] || "",
      link: params["link"] || "",
      betroffene_drucksachen: betroffene_drucksachen
    }
  end

  @doc """
  Creates a new Station from form parameters.
  """
  @spec form_params_to_station(map()) :: map()
  def form_params_to_station(params) do
    gremium = %{
      "name" => params["gremium_name"] || "",
      "wahlperiode" => parse_integer_or_default(params["gremium_wahlperiode"], 0),
      "parlament" => params["gremium_parlament"] || "",
      "link" => params["gremium_link"] || ""
    }

    station = %{
      "titel" => params["titel"] || "",
      "typ" => params["typ"] || "",
      "link" => params["link"] || "",
      "gremium" => gremium,
      "gremium_federf" => params["gremium_federf"] == "true",
      "trojanergefahr" => parse_integer_or_default(params["trojanergefahr"], 1),
      "schlagworte" => parse_schlagworte(params["schlagworte"]),
      "dokumente" => []
    }

    # Add zp_start if it has a valid value
    station = if params["zp_start"] && params["zp_start"] != "" do
      Map.put(station, "zp_start", parse_datetime_local(params["zp_start"]))
    else
      station
    end

    # Only add zp_modifiziert if it has a valid value
    if params["zp_modifiziert"] && params["zp_modifiziert"] != "" do
      Map.put(station, "zp_modifiziert", parse_datetime_local(params["zp_modifiziert"]))
    else
      station
    end
  end

  @doc """
  Updates station fields from form parameters.
  """
  @spec update_station_from_params(Schemas.Station.t(), map()) :: Schemas.Station.t()
  def update_station_from_params(station, params) do
    station
    |> update_station_field(params, "titel")
    |> update_station_field(params, "typ")
    |> update_station_field(params, "zp_start")
    |> update_station_field(params, "zp_modifiziert")
    |> update_station_field(params, "link")
    |> update_station_field(params, "gremium_federf", &parse_boolean/1)
    |> update_station_field(params, "trojanergefahr", &parse_integer_or_default(&1, 1))
    |> update_station_field(params, "schlagworte", &parse_schlagworte/1)
    |> update_gremium_field(params, "gremium_name", :name)
    |> update_gremium_field(params, "gremium_wahlperiode", :wahlperiode, &parse_integer_or_default(&1, 0))
    |> update_gremium_field(params, "gremium_parlament", :parlament)
    |> update_gremium_field(params, "gremium_link", :link)
  end

  @doc """
  Validates a Vorgang object and returns errors if any.
  """
  @spec validate_vorgang(map()) :: :ok | {:error, [String.t()]}
  def validate_vorgang(vorgang) when is_map(vorgang) do
    errors = []
    |> validate_required(vorgang["api_id"], "api_id")
    |> validate_required(vorgang["titel"], "titel")
    |> validate_required(vorgang["wahlperiode"], "wahlperiode")
    |> validate_required(vorgang["verfassungsaendernd"], "verfassungsaendernd")
    |> validate_required(vorgang["typ"], "typ")
    |> validate_required(vorgang["initiatoren"], "initiatoren")
    |> validate_required(vorgang["stationen"], "stationen")
    |> validate_enum(vorgang["typ"], &Schemas.valid_vorgangstyp?/1, "typ")
    |> validate_autors(vorgang["initiatoren"])
    |> validate_stations(vorgang["stationen"])

    case errors do
      [] -> :ok
      _ -> {:error, errors}
    end
  end

  @doc """
  Validates a Station object and returns errors if any.
  Only validates non-empty fields to allow for partial data during editing.
  """
  @spec validate_station(map()) :: :ok | {:error, [String.t()]}
  def validate_station(station) when is_map(station) do
    errors = []
    |> validate_required_if_present(station["typ"], "typ")
    |> validate_required_if_present(station["dokumente"], "dokumente")
    |> validate_required_if_present(station["zp_start"], "zp_start")
    |> validate_required_if_present(station["gremium"], "gremium")
    |> validate_enum_if_present(station["typ"], &Schemas.valid_stationstyp?/1, "typ")
    |> validate_gremium(station["gremium"])
    |> validate_trojanergefahr(station["trojanergefahr"])

    case errors do
      [] -> :ok
      _ -> {:error, errors}
    end
  end

  @doc """
  Validates an Autor object and returns errors if any.
  """
  @spec validate_autor(Schemas.Autor.t() | map()) :: :ok | {:error, [String.t()]}
  def validate_autor(%Schemas.Autor{} = autor) do
    errors = []
    |> validate_required(autor.organisation, "organisation")

    case errors do
      [] -> :ok
      _ -> {:error, errors}
    end
  end

  def validate_autor(autor) when is_map(autor) do
    errors = []
    |> validate_required(autor["organisation"], "organisation")

    case errors do
      [] -> :ok
      _ -> {:error, errors}
    end
  end

  @doc """
  Creates a new Document from form parameters.
  """
  @spec form_params_to_document(map()) :: map()
  def form_params_to_document(params) do
    document = %{
      "typ" => params["typ"] || "",
      "titel" => params["titel"] || "",
      "kurztitel" => params["kurztitel"] || "",
      "vorwort" => params["vorwort"] || "",
      "volltext" => params["volltext"] || "",
      "zusammenfassung" => params["zusammenfassung"] || "",
      "link" => params["link"] || "",
      "hash" => params["hash"] || "",
      "drucksnr" => params["drucksnr"] || "",
      "meinung" => parse_integer_or_default(params["meinung"], nil),
      "schlagworte" => parse_schlagworte(params["schlagworte"]),
      "autoren" => []
    }

    # Add datetime fields if they have valid values
    document = if params["zp_modifiziert"] && params["zp_modifiziert"] != "" do
      Map.put(document, "zp_modifiziert", parse_datetime_local(params["zp_modifiziert"]))
    else
      document
    end

    document = if params["zp_referenz"] && params["zp_referenz"] != "" do
      Map.put(document, "zp_referenz", parse_datetime_local(params["zp_referenz"]))
    else
      document
    end

    if params["zp_erstellt"] && params["zp_erstellt"] != "" do
      Map.put(document, "zp_erstellt", parse_datetime_local(params["zp_erstellt"]))
    else
      document
    end
  end

  @doc """
  Validates a Document object and returns errors if any.
  """
  @spec validate_document(map()) :: :ok | {:error, [String.t()]}
  def validate_document(document) when is_map(document) do
    errors = []
    |> validate_required_if_present(document["typ"], "typ")
    |> validate_required_if_present(document["titel"], "titel")
    |> validate_required_if_present(document["volltext"], "volltext")
    |> validate_required_if_present(document["link"], "link")
    |> validate_required_if_present(document["hash"], "hash")
    |> validate_required_if_present(document["zp_modifiziert"], "zp_modifiziert")
    |> validate_required_if_present(document["zp_referenz"], "zp_referenz")
    |> validate_enum_if_present(document["typ"], &Schemas.valid_doktyp?/1, "typ")
    |> validate_meinung_range(document["meinung"])

    case errors do
      [] -> :ok
      _ -> {:error, errors}
    end
  end

  # ============================================================================
  # PRIVATE HELPER FUNCTIONS
  # ============================================================================

  defp parse_integer_or_default(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  defp parse_integer_or_default(value, _default) when is_integer(value) do
    value
  end

  defp parse_integer_or_default(_value, default) do
    default
  end

  defp parse_boolean("true"), do: true
  defp parse_boolean(_), do: false

  defp parse_schlagworte(value) when is_binary(value) and value != "" do
    String.split(value, ",") |> Enum.map(&String.trim/1)
  end
  defp parse_schlagworte(_), do: []

  defp parse_datetime_local(value) when is_binary(value) and value != "" do
    # Convert datetime-local format (YYYY-MM-DDTHH:MM) to ISO 8601 with UTC timezone
    # datetime-local doesn't include seconds or timezone, so we add :00 and Z
    case String.split(value, "T") do
      [date, time] ->
        # Ensure time has seconds
        time_with_seconds = if String.length(time) == 5, do: time <> ":00", else: time
        "#{date}T#{time_with_seconds}Z"
      _ ->
        # If the format is unexpected, return as is
        value
    end
  end
  defp parse_datetime_local(_), do: nil



  defp update_station_field(station, params, field) do
    update_station_field(station, params, field, &(&1))
  end

  defp update_station_field(station, params, field, parser) do
    case Map.get(params, field) do
      nil -> station
      value -> Map.put(station, String.to_atom(field), parser.(value))
    end
  end

  defp update_gremium_field(station, params, field, gremium_field) do
    update_gremium_field(station, params, field, gremium_field, &(&1))
  end

  defp update_gremium_field(station, params, field, gremium_field, parser) do
    case Map.get(params, field) do
      nil -> station
      value ->
        gremium = station.gremium || %Schemas.Gremium{}
        updated_gremium = Map.put(gremium, gremium_field, parser.(value))
        Map.put(station, :gremium, updated_gremium)
    end
  end

  defp validate_required(errors, value, field) when is_nil(value) or value == "" do
    ["#{field} is required" | errors]
  end
  defp validate_required(errors, _value, _field), do: errors

  defp validate_required_if_present(errors, value, field) when is_nil(value) or value == "" do
    errors
  end
  defp validate_required_if_present(errors, value, field) do
    validate_required(errors, value, field)
  end

  defp validate_enum(errors, value, validator, field) when is_binary(value) do
    if validator.(value) do
      errors
    else
      ["#{field} has invalid value: #{value}" | errors]
    end
  end
  defp validate_enum(errors, _value, _validator, _field), do: errors

  defp validate_enum_if_present(errors, value, validator, field) when is_binary(value) and value != "" do
    validate_enum(errors, value, validator, field)
  end
  defp validate_enum_if_present(errors, _value, _validator, _field), do: errors

  defp validate_trojanergefahr(errors, value) when is_integer(value) do
    if Schemas.valid_trojanergefahr?(value) do
      errors
    else
      ["trojanergefahr must be between 1 and 10" | errors]
    end
  end
  defp validate_trojanergefahr(errors, _value), do: errors

  defp validate_autors(errors, autors) when is_list(autors) do
    Enum.reduce(autors, errors, fn autor, acc ->
      case validate_autor(autor) do
        :ok -> acc
        {:error, autor_errors} -> autor_errors ++ acc
      end
    end)
  end
  defp validate_autors(errors, _autors), do: errors

  defp validate_stations(errors, stations) when is_list(stations) do
    Enum.reduce(stations, errors, fn station, acc ->
      case validate_station(station) do
        :ok -> acc
        {:error, station_errors} -> station_errors ++ acc
      end
    end)
  end
  defp validate_stations(errors, _stations), do: errors

  defp validate_meinung_range(errors, value) when is_integer(value) do
    if value >= 1 and value <= 5 do
      errors
    else
      ["meinung must be between 1 and 5" | errors]
    end
  end
  defp validate_meinung_range(errors, _value), do: errors

  defp validate_gremium(errors, gremium) when is_map(gremium) do
    errors
    |> validate_required(gremium["parlament"], "gremium.parlament")
    |> validate_required(gremium["name"], "gremium.name")
    |> validate_required(gremium["wahlperiode"], "gremium.wahlperiode")
    |> validate_enum_if_present(gremium["parlament"], &Schemas.valid_parlament?/1, "gremium.parlament")
  end
  defp validate_gremium(errors, _gremium), do: errors
end
