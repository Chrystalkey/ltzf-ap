defmodule LtzfApWeb.ManualInputController do
  use LtzfApWeb, :controller

  def index(conn, _params) do
    render(conn, :index,
      current_user: conn.assigns.current_user,
      layout: false
    )
  end

  def new_vorgang(conn, _params) do
    render(conn, :new_vorgang,
      current_user: conn.assigns.current_user,
      vorgang: %{},
      layout: false
    )
  end

  def create_vorgang(conn, %{"vorgang" => _vorgang_params}) do
    # TODO: Create legislative process via /api/v1/vorgang PUT endpoint
    conn
    |> put_flash(:info, "Legislative process created successfully")
    |> redirect(to: ~p"/manual_input")
  end

  def new_sitzung(conn, _params) do
    render(conn, :new_sitzung,
      current_user: conn.assigns.current_user,
      sitzung: %{},
      layout: false
    )
  end

  def create_sitzung(conn, %{"sitzung" => _sitzung_params}) do
    # TODO: Create session via /api/v1/sitzung PUT endpoint
    conn
    |> put_flash(:info, "Session created successfully")
    |> redirect(to: ~p"/manual_input")
  end

  def new_dokument(conn, _params) do
    render(conn, :new_dokument,
      current_user: conn.assigns.current_user,
      dokument: %{},
      layout: false
    )
  end

  def create_dokument(conn, %{"dokument" => _dokument_params}) do
    # TODO: Create document via /api/v1/dokument/{api_id} PUT endpoint
    conn
    |> put_flash(:info, "Document created successfully")
    |> redirect(to: ~p"/manual_input")
  end

  def new_gremium(conn, _params) do
    render(conn, :new_gremium,
      current_user: conn.assigns.current_user,
      gremium: %{},
      layout: false
    )
  end

  def create_gremium(conn, %{"gremium" => _gremium_params}) do
    # TODO: Create committee via /api/v1/gremien PUT endpoint
    conn
    |> put_flash(:info, "Committee created successfully")
    |> redirect(to: ~p"/manual_input")
  end

  def new_autor(conn, _params) do
    render(conn, :new_autor,
      current_user: conn.assigns.current_user,
      autor: %{},
      layout: false
    )
  end

  def create_autor(conn, %{"autor" => _autor_params}) do
    # TODO: Create author via /api/v1/autoren PUT endpoint
    conn
    |> put_flash(:info, "Author created successfully")
    |> redirect(to: ~p"/manual_input")
  end
end
