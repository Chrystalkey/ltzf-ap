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
        render(conn, :generic_vorgang_detail,
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
    generic_list_action(conn, "vorgang", "Legislative Processes", "View and manage legislative processes from the LTZF backend")
  end

  def sitzungen(conn, _params) do
    generic_list_action(conn, "sitzung", "Parliamentary Sessions", "View and manage parliamentary sessions from the LTZF backend")
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
      {:ok, data} ->
        conn
        |> put_resp_header("x-total-count", get_total_count_from_response(data))
        |> put_resp_header("x-total-pages", get_total_pages_from_response(data))
        |> put_resp_header("x-page", get_page_from_response(data))
        |> put_resp_header("x-per-page", get_per_page_from_response(data))
        |> json(data)
      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{error: reason})
    end
  end

  # Helper functions to extract pagination info from response
  defp get_total_count_from_response(data) when is_list(data), do: to_string(length(data))
  defp get_total_count_from_response(_), do: "0"

  defp get_total_pages_from_response(_data), do: "1"  # Default to 1 page

  defp get_page_from_response(_data), do: "1"  # Default to page 1

  defp get_per_page_from_response(_data), do: "20"  # Default to 20 per page

  # Helper to get header value case-insensitively from headers list
  defp get_header(headers, key) do
    headers
    |> Enum.find(fn {k, _v} -> String.downcase(k) == String.downcase(key) end)
    |> case do
      {_, v} -> v
      nil -> ""
    end
  end
end
