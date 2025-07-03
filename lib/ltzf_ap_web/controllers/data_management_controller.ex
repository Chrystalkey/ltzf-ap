defmodule LtzfApWeb.DataManagementController do
  use LtzfApWeb, :controller

  alias LtzfAp.ApiClient
  import LtzfApWeb.DataManagementComponents

  def index(conn, _params) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    render(conn, :index,
      current_user: conn.assigns.current_user,
      backend_url: backend_url,
      api_key: api_key,
      layout: false
    )
  end

  def vorgang(conn, %{"id" => id}) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    case ApiClient.get_vorgang(backend_url, api_key, id) do
      {:ok, vorgang} ->
        render(conn, :vorgang_detail,
          current_user: conn.assigns.current_user,
          vorgang: vorgang,
          layout: false
        )
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to fetch legislative process")
        |> redirect(to: "/data_management")
    end
  end



  def update_vorgang(conn, %{"id" => id, "vorgang" => vorgang_params}) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    # Convert form data to proper structure
    processed_params = process_vorgang_params(vorgang_params)

    case ApiClient.put_vorgang(backend_url, api_key, id, processed_params) do
      {:ok, _message} ->
        conn
        |> put_flash(:info, "Vorgang updated successfully")
        |> redirect(to: "/data_management/vorgang/#{id}")
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to update vorgang: #{reason}")
        |> redirect(to: "/data_management/vorgang/#{id}")
    end
  end

  def delete_vorgang(conn, %{"id" => id}) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    case ApiClient.delete_vorgang(backend_url, api_key, id) do
      {:ok, _message} ->
        conn
        |> put_flash(:info, "Vorgang deleted successfully")
        |> redirect(to: "/data_management/vorgaenge")
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to delete vorgang: #{reason}")
        |> redirect(to: "/data_management/vorgang/#{id}")
    end
  end

  def sitzung(conn, %{"id" => id}) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    case ApiClient.get_sitzung(backend_url, api_key, id) do
      {:ok, sitzung} ->
        render(conn, :generic_sitzung_detail,
          current_user: conn.assigns.current_user,
          sitzung: sitzung,
          layout: false
        )
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to fetch parliamentary session")
        |> redirect(to: "/data_management")
    end
  end

  def dokument(conn, %{"id" => id}) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    case ApiClient.get_dokument(backend_url, api_key, id) do
      {:ok, dokument} ->
        render(conn, :dokument,
          current_user: conn.assigns.current_user,
          dokument: dokument,
          layout: false
        )
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to fetch document")
        |> redirect(to: "/data_management")
    end
  end

  # Generic list page action that eliminates duplication
  defp generic_list_action(conn, entity_type, title, description, additional_filters \\ []) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    # Get filters for the entity type
    base_filters = Map.get(entity_filters(), entity_type, [])

    # Merge with additional filters
    filters = base_filters ++ additional_filters

    # Get render configuration for the entity type
    render_config = Map.get(render_configs(), entity_type)

    render(conn, :generic_list,
      current_user: conn.assigns.current_user,
      backend_url: backend_url,
      api_key: api_key,
      entity_type: entity_type,
      title: title,
      description: description,
      filters: filters,
      render_config: render_config,
      layout: false
    )
  end

  def vorgaenge(conn, _params) do
    generic_list_action(conn, "vorgang", "Gesetzgebungsverfahren", "Gesetzgebungsverfahren aus dem LTZF-Backend anzeigen und verwalten")
  end

  def sitzungen(conn, _params) do
    generic_list_action(conn, "sitzung", "Parlamentssitzungen", "Parlamentssitzungen aus dem LTZF-Backend anzeigen und verwalten")
  end

  def enumerations(conn, _params) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    render(conn, :enumerations,
      current_user: conn.assigns.current_user,
      backend_url: backend_url,
      api_key: api_key,
      layout: false
    )
  end

  # Proxy endpoints that fetch data from backend and return with proper headers
  def proxy_vorgang(conn, params) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    case ApiClient.get_vorgaenge(backend_url, api_key, params) do
      {:ok, data, headers} ->
        conn
        |> put_resp_header("x-total-count", get_header(headers, "x-total-count"))
        |> put_resp_header("x-total-pages", get_header(headers, "x-total-pages"))
        |> put_resp_header("x-page", get_header(headers, "x-page"))
        |> put_resp_header("x-per-page", get_header(headers, "x-per-page"))
        |> json(data)
      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{error: reason})
    end
  end

  def proxy_sitzung(conn, params) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    case ApiClient.get_sitzungen(backend_url, api_key, params) do
      {:ok, data, headers} ->
        conn
        |> put_resp_header("x-total-count", get_header(headers, "x-total-count"))
        |> put_resp_header("x-total-pages", get_header(headers, "x-total-pages"))
        |> put_resp_header("x-page", get_header(headers, "x-page"))
        |> put_resp_header("x-per-page", get_header(headers, "x-per-page"))
        |> json(data)
      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{error: reason})
    end
  end

  # Helper to get header value case-insensitively from headers list
  defp get_header(headers, key) do
    headers
    |> Enum.find(fn {k, _v} -> String.downcase(k) == String.downcase(key) end)
    |> case do
      {_, v} -> v
      nil -> ""
    end
  end

  # Process form parameters for vorgang update
  defp process_vorgang_params(params) do
    # Handle checkbox for verfassungsaendernd
    verfassungsaendernd = Map.get(params, "verfassungsaendernd") == "true"

    # Convert wahlperiode from string to integer
    wahlperiode = case Map.get(params, "wahlperiode") do
      nil -> nil
      value when is_binary(value) ->
        case Integer.parse(value) do
          {int, _} -> int
          :error -> nil
        end
      value when is_integer(value) -> value
      _ -> nil
    end

    # Process IDs array
    ids = case Map.get(params, "ids") do
      nil -> []
      ids_list when is_list(ids_list) ->
        ids_list
        |> Enum.filter(fn id -> id["id"] && String.trim(id["id"]) != "" end)
        |> Enum.map(fn id -> %{"id" => id["id"], "typ" => id["typ"]} end)
    end

    # Process links array
    links = case Map.get(params, "links") do
      nil -> []
      links_list when is_list(links_list) ->
        links_list
        |> Enum.filter(fn link -> link && String.trim(link) != "" end)
    end

    # Process initiators array
    initiators = case Map.get(params, "initiatoren") do
      nil -> []
      initiators_list when is_list(initiators_list) ->
        initiators_list
        |> Enum.filter(fn initiator -> initiator["organisation"] && String.trim(initiator["organisation"]) != "" end)
        |> Enum.map(fn initiator ->
          %{
            "person" => initiator["person"],
            "organisation" => initiator["organisation"],
            "fachgebiet" => initiator["fachgebiet"]
          }
          |> Enum.filter(fn {_k, v} -> v && String.trim(v) != "" end)
          |> Map.new()
        end)
    end

    # Build the final params structure
    params
    |> Map.put("verfassungsaendernd", verfassungsaendernd)
    |> Map.put("wahlperiode", wahlperiode)
    |> Map.put("ids", ids)
    |> Map.put("links", links)
    |> Map.put("initiatoren", initiators)
    |> Map.drop(["ids", "links", "initiatoren"]) # Remove the original form arrays
    |> Enum.filter(fn {_k, v} -> v != nil and v != "" end)
    |> Map.new()
  end
end
