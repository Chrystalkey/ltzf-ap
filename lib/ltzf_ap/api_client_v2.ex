defmodule LtzfAp.ApiClientV2 do
  @moduledoc """
  API client for communicating with the LTZF backend API using the oapicode client.
  """

  alias SpecificationForTheLandtagszusammenfasserProject.Connection
  alias SpecificationForTheLandtagszusammenfasserProject.Api.Vorgang
  alias SpecificationForTheLandtagszusammenfasserProject.Api.Sitzung
  alias SpecificationForTheLandtagszusammenfasserProject.Api.DataAdministration
  alias SpecificationForTheLandtagszusammenfasserProject.Api.Unauthorisiert
  alias SpecificationForTheLandtagszusammenfasserProject.Api.Miscellaneous

  @doc """
  Creates a connection to the backend with the given URL and API key.
  """
  def create_connection(backend_url, api_key) do
    Connection.new(
      base_url: backend_url,
      middleware: [
        {Tesla.Middleware.Headers, [{"x-api-key", api_key}]},
        {Tesla.Middleware.JSON, engine: Jason}
      ]
    )
  end

    @doc """
  Fetches legislative processes (vorgänge) from the API.
  """
  def get_vorgaenge(backend_url, api_key, params \\ %{}) do
    if backend_url == "" or api_key == "" do
      {:error, "Backend URL or API key not configured"}
    else
      connection = create_connection(backend_url, api_key)

      # Build query string from params
      query_string = build_query_string(params)
      url = "/api/v1/vorgang#{query_string}"

      case Tesla.get(connection, url) do
        {:ok, %Tesla.Env{status: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, data} -> {:ok, data, []}
            {:error, _} -> {:error, "Invalid JSON response"}
          end
        {:ok, %Tesla.Env{status: 204}} ->
          {:ok, [], []}
        {:ok, %Tesla.Env{status: status, body: body}} ->
          {:error, "HTTP #{status}: #{body}"}
        {:error, error} ->
          {:error, "Network error: #{inspect(error)}"}
      end
    end
  end

    @doc """
  Fetches a specific legislative process by ID.
  """
  def get_vorgang(backend_url, api_key, id) do
    if backend_url == "" or api_key == "" do
      {:error, "Backend URL or API key not configured"}
    else
      connection = create_connection(backend_url, api_key)
      url = "/api/v1/vorgang/#{id}"

      case Tesla.get(connection, url) do
        {:ok, %Tesla.Env{status: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, data} -> {:ok, data}
            {:error, _} -> {:error, "Invalid JSON response"}
          end
        {:ok, %Tesla.Env{status: 404}} ->
          {:error, "Vorgang not found"}
        {:ok, %Tesla.Env{status: status, body: body}} ->
          {:error, "HTTP #{status}: #{body}"}
        {:error, error} ->
          {:error, "Network error: #{inspect(error)}"}
      end
    end
  end

  @doc """
  Updates a legislative process using PUT.
  """
  def put_vorgang(backend_url, api_key, id, data) do
    if backend_url == "" or api_key == "" do
      {:error, "Backend URL or API key not configured"}
    else
      connection = create_connection(backend_url, api_key)

      # Convert data to the proper model struct
      vorgang = convert_to_vorgang_model(data)

      case Vorgang.vorgang_id_put(connection, id, vorgang) do
        {:ok, _} ->
          {:ok, "Vorgang updated successfully"}
        {:error, error} ->
          case error do
            %Tesla.Env{status: 403} -> {:error, "Forbidden"}
            _ -> {:error, "API error: #{inspect(error)}"}
          end
      end
    end
  end

  @doc """
  Deletes a legislative process.
  """
  def delete_vorgang(backend_url, api_key, id) do
    if backend_url == "" or api_key == "" do
      {:error, "Backend URL or API key not configured"}
    else
      connection = create_connection(backend_url, api_key)

      case Vorgang.vorgang_delete(connection, id) do
        {:ok, _} ->
          {:ok, "Vorgang deleted successfully"}
        {:error, error} ->
          case error do
            %Tesla.Env{status: 403} -> {:error, "Forbidden"}
            %Tesla.Env{status: 404} -> {:error, "Vorgang not found"}
            _ -> {:error, "API error: #{inspect(error)}"}
          end
      end
    end
  end

    @doc """
  Fetches parliamentary sessions (sitzungen) from the API.
  """
  def get_sitzungen(backend_url, api_key, params \\ %{}) do
    if backend_url == "" or api_key == "" do
      {:error, "Backend URL or API key not configured"}
    else
      connection = create_connection(backend_url, api_key)

      # Build query string from params
      query_string = build_query_string(params)
      url = "/api/v1/sitzung#{query_string}"

      case Tesla.get(connection, url) do
        {:ok, %Tesla.Env{status: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, data} -> {:ok, data, []}
            {:error, _} -> {:error, "Invalid JSON response"}
          end
        {:ok, %Tesla.Env{status: 204}} ->
          {:ok, [], []}
        {:ok, %Tesla.Env{status: status, body: body}} ->
          {:error, "HTTP #{status}: #{body}"}
        {:error, error} ->
          {:error, "Network error: #{inspect(error)}"}
      end
    end
  end

    @doc """
  Fetches a specific parliamentary session by ID.
  """
  def get_sitzung(backend_url, api_key, id) do
    if backend_url == "" or api_key == "" do
      {:error, "Backend URL or API key not configured"}
    else
      connection = create_connection(backend_url, api_key)
      url = "/api/v1/sitzung/#{id}"

      case Tesla.get(connection, url) do
        {:ok, %Tesla.Env{status: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, data} -> {:ok, data}
            {:error, _} -> {:error, "Invalid JSON response"}
          end
        {:ok, %Tesla.Env{status: 404}} ->
          {:error, "Sitzung not found"}
        {:ok, %Tesla.Env{status: status, body: body}} ->
          {:error, "HTTP #{status}: #{body}"}
        {:error, error} ->
          {:error, "Network error: #{inspect(error)}"}
      end
    end
  end

  @doc """
  Fetches a specific document by ID.
  """
  def get_dokument(backend_url, api_key, id) do
    if backend_url == "" or api_key == "" do
      {:error, "Backend URL or API key not configured"}
    else
      connection = create_connection(backend_url, api_key)

      case Miscellaneous.dokument_get_by_id(connection, id) do
        {:ok, dokument} ->
          {:ok, struct_to_map_safe(dokument)}
        {:error, error} ->
          case error do
            %Tesla.Env{status: 404} -> {:error, "Document not found"}
            _ -> {:error, "API error: #{inspect(error)}"}
          end
      end
    end
  end

  @doc """
  Fetches committees (gremien) from the API.
  """
  def get_gremien(backend_url, api_key, params \\ %{}) do
    if backend_url == "" or api_key == "" do
      {:error, "Backend URL or API key not configured"}
    else
      connection = create_connection(backend_url, api_key)

      # Convert params to the format expected by the oapicode client
      opts = convert_params_to_opts(params)

      case Miscellaneous.gremien_get(connection, opts) do
        {:ok, gremien} when is_list(gremien) ->
          {:ok, Enum.map(gremien, &struct_to_map_safe/1)}
        {:ok, nil} ->
          {:ok, []}
        {:error, error} ->
          {:error, "API error: #{inspect(error)}"}
      end
    end
  end

  @doc """
  Fetches authors (autoren) from the API.
  """
  def get_autoren(backend_url, api_key, params \\ %{}) do
    if backend_url == "" or api_key == "" do
      {:error, "Backend URL or API key not configured"}
    else
      connection = create_connection(backend_url, api_key)

      # Convert params to the format expected by the oapicode client
      opts = convert_params_to_opts(params)

      case Miscellaneous.autoren_get(connection, opts) do
        {:ok, autoren} when is_list(autoren) ->
          {:ok, Enum.map(autoren, &struct_to_map_safe/1)}
        {:ok, nil} ->
          {:ok, []}
        {:error, error} ->
          {:error, "API error: #{inspect(error)}"}
      end
    end
  end

  # Private helper functions

  defp struct_to_map_safe(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn {k, v} -> {k, convert_value_safe(v)} end)
    |> Enum.into(%{})
  end
  defp struct_to_map_safe(value), do: value

  defp convert_value_safe(value) when is_list(value) do
    Enum.map(value, &convert_value_safe/1)
  end
  defp convert_value_safe(value) when is_struct(value) do
    # Handle empty structs by returning the original value
    case Map.keys(value) do
      [:__struct__] -> value
      _ -> struct_to_map_safe(value)
    end
  end
  defp convert_value_safe(value), do: value

  defp struct_to_map(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn {k, v} -> {k, convert_value(v)} end)
    |> Enum.into(%{})
  end
  defp struct_to_map(value), do: value

  defp convert_value(value) when is_list(value) do
    Enum.map(value, &convert_value/1)
  end
  defp convert_value(value) when is_struct(value) do
    struct_to_map(value)
  end
  defp convert_value(value), do: value

  defp build_query_string(params) do
    params
    |> Enum.filter(fn {_key, value} -> value != nil and value != "" end)
    |> Enum.map(fn {key, value} -> "#{key}=#{URI.encode_www_form(to_string(value))}" end)
    |> Enum.join("&")
    |> case do
      "" -> ""
      query -> "?#{query}"
    end
  end

  defp convert_params_to_opts(params) do
    params
    |> Enum.filter(fn {_key, value} -> value != nil and value != "" end)
    |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
    |> Enum.into([])
  end

  defp convert_to_vorgang_model(data) do
    # This is a simplified conversion - you may need to expand this based on your data structure
    %SpecificationForTheLandtagszusammenfasserProject.Model.Vorgang{
      api_id: Map.get(data, "api_id"),
      titel: Map.get(data, "titel"),
      kurztitel: Map.get(data, "kurztitel"),
      wahlperiode: Map.get(data, "wahlperiode"),
      verfassungsaendernd: Map.get(data, "verfassungsaendernd", false),
      typ: convert_vorgangstyp(Map.get(data, "typ")),
      ids: convert_vg_ident_list(Map.get(data, "ids", [])),
      links: convert_uri_list(Map.get(data, "links", [])),
      initiatoren: convert_autor_list(Map.get(data, "initiatoren", [])),
      stationen: convert_station_list(Map.get(data, "stationen", [])),
      lobbyregister: convert_lobbyregister_list(Map.get(data, "lobbyregister", []))
    }
  end

  defp convert_vorgangstyp(nil), do: nil
  defp convert_vorgangstyp(typ) when is_binary(typ) do
    %SpecificationForTheLandtagszusammenfasserProject.Model.Vorgangstyp{}
  end
  defp convert_vorgangstyp(typ) when is_map(typ) do
    %SpecificationForTheLandtagszusammenfasserProject.Model.Vorgangstyp{}
  end

  defp convert_vg_ident_list(ids) when is_list(ids) do
    Enum.map(ids, fn id ->
      %SpecificationForTheLandtagszusammenfasserProject.Model.VgIdent{
        id: Map.get(id, "id"),
        typ: convert_vg_ident_typ(Map.get(id, "typ"))
      }
    end)
  end
  defp convert_vg_ident_list(_), do: []

  defp convert_vg_ident_typ(nil), do: nil
  defp convert_vg_ident_typ(typ) when is_binary(typ) do
    %SpecificationForTheLandtagszusammenfasserProject.Model.VgIdentTyp{}
  end
  defp convert_vg_ident_typ(typ) when is_map(typ) do
    %SpecificationForTheLandtagszusammenfasserProject.Model.VgIdentTyp{}
  end

  defp convert_autor(nil), do: nil
  defp convert_autor(autor) when is_map(autor) do
    %SpecificationForTheLandtagszusammenfasserProject.Model.Autor{
      person: Map.get(autor, "person"),
      organisation: Map.get(autor, "organisation"),
      fachgebiet: Map.get(autor, "fachgebiet")
    }
  end

  defp convert_autor_list(autoren) when is_list(autoren) do
    Enum.map(autoren, fn autor ->
      %SpecificationForTheLandtagszusammenfasserProject.Model.Autor{
        person: Map.get(autor, "person"),
        organisation: Map.get(autor, "organisation"),
        fachgebiet: Map.get(autor, "fachgebiet")
      }
    end)
  end
  defp convert_autor_list(_), do: []

  defp convert_station_list(stationen) when is_list(stationen) do
    Enum.map(stationen, fn station ->
      %SpecificationForTheLandtagszusammenfasserProject.Model.Station{
        api_id: Map.get(station, "api_id"),
        titel: Map.get(station, "titel"),
        zp_start: Map.get(station, "zp_start"),
        zp_modifiziert: Map.get(station, "zp_modifiziert"),
        gremium: convert_gremium(Map.get(station, "gremium")),
        gremium_federf: Map.get(station, "gremium_federf"),
        link: convert_uri(Map.get(station, "link")),
        parlament: convert_parlament(Map.get(station, "parlament")),
        typ: convert_stationstyp(Map.get(station, "typ")),
        trojanergefahr: Map.get(station, "trojanergefahr"),
        schlagworte: Map.get(station, "schlagworte"),
        dokumente: convert_station_dokumente_list(Map.get(station, "dokumente", [])),
        additional_links: convert_uri_list(Map.get(station, "additional_links", [])),
        stellungnahmen: convert_dokument_list(Map.get(station, "stellungnahmen", []))
      }
    end)
  end
  defp convert_station_list(_), do: []

  defp convert_stationstyp(nil), do: nil
  defp convert_stationstyp(typ) when is_binary(typ) do
    %SpecificationForTheLandtagszusammenfasserProject.Model.Stationstyp{}
  end
  defp convert_stationstyp(typ) when is_map(typ) do
    %SpecificationForTheLandtagszusammenfasserProject.Model.Stationstyp{}
  end

  defp convert_parlament(nil), do: nil
  defp convert_parlament(parlament) when is_binary(parlament) do
    %SpecificationForTheLandtagszusammenfasserProject.Model.Parlament{}
  end
  defp convert_parlament(parlament) when is_map(parlament) do
    %SpecificationForTheLandtagszusammenfasserProject.Model.Parlament{}
  end

  defp convert_gremium(nil), do: nil
  defp convert_gremium(gremium) when is_map(gremium) do
    %SpecificationForTheLandtagszusammenfasserProject.Model.Gremium{
      name: Map.get(gremium, "name"),
      parlament: convert_parlament(Map.get(gremium, "parlament"))
    }
  end

  defp convert_uri(nil), do: nil
  defp convert_uri(uri) when is_binary(uri) do
    uri
  end
  defp convert_uri(uri) when is_map(uri) do
    Map.get(uri, "url") || uri
  end

  defp convert_uri_list(uris) when is_list(uris) do
    Enum.map(uris, &convert_uri/1)
  end
  defp convert_uri_list(_), do: []

  defp convert_dokument_list(dokumente) when is_list(dokumente) do
    Enum.map(dokumente, fn dokument ->
      %SpecificationForTheLandtagszusammenfasserProject.Model.Dokument{
        api_id: Map.get(dokument, "api_id"),
        titel: Map.get(dokument, "titel"),
        typ: convert_doktyp(Map.get(dokument, "typ")),
        link: convert_uri(Map.get(dokument, "link"))
      }
    end)
  end
  defp convert_dokument_list(_), do: []

  defp convert_station_dokumente_list(dokumente) when is_list(dokumente) do
    Enum.map(dokumente, fn dok ->
      %SpecificationForTheLandtagszusammenfasserProject.Model.StationDokumenteInner{
        api_id: Map.get(dok, "api_id"),
        typ: convert_doktyp(Map.get(dok, "typ")),
        titel: Map.get(dok, "titel"),
        link: convert_uri(Map.get(dok, "link"))
      }
    end)
  end
  defp convert_station_dokumente_list(_), do: []

  defp convert_doktyp(nil), do: nil
  defp convert_doktyp(typ) when is_binary(typ) do
    %SpecificationForTheLandtagszusammenfasserProject.Model.Doktyp{}
  end
  defp convert_doktyp(typ) when is_map(typ) do
    %SpecificationForTheLandtagszusammenfasserProject.Model.Doktyp{}
  end

  defp convert_lobbyregister_list(lobbyregister) when is_list(lobbyregister) do
    Enum.map(lobbyregister, fn entry ->
      %SpecificationForTheLandtagszusammenfasserProject.Model.Lobbyregeintrag{
        organisation: convert_autor(Map.get(entry, "organisation")),
        interne_id: Map.get(entry, "interne_id"),
        intention: Map.get(entry, "intention"),
        link: convert_uri(Map.get(entry, "link")),
        betroffene_drucksachen: Map.get(entry, "betroffene_drucksachen", [])
      }
    end)
  end
  defp convert_lobbyregister_list(_), do: []
end
