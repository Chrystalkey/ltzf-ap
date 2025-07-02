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
        render(conn, :vorgang,
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
        render(conn, :sitzung,
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

  def vorgaenge(conn, params) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    render(conn, :vorgaenge,
      current_user: conn.assigns.current_user,
      backend_url: backend_url,
      api_key: api_key,
      params: params,
      parliament_options: parliament_options(),
      process_type_options: process_type_options(),
      layout: false
    )
  end

  def sitzungen(conn, params) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    render(conn, :sitzungen,
      current_user: conn.assigns.current_user,
      backend_url: backend_url,
      api_key: api_key,
      params: params,
      parliament_options: parliament_options(),
      process_type_options: process_type_options(),
      layout: false
    )
  end

  def gremien(conn, params) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    render(conn, :gremien,
      current_user: conn.assigns.current_user,
      backend_url: backend_url,
      api_key: api_key,
      params: params,
      parliament_options: parliament_options(),
      layout: false
    )
  end

  def autoren(conn, params) do
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    render(conn, :autoren,
      current_user: conn.assigns.current_user,
      backend_url: backend_url,
      api_key: api_key,
      params: params,
      parliament_options: parliament_options(),
      layout: false
    )
  end
end
