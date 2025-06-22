defmodule LtzfAdminWeb.ApiKeyController do
  use LtzfAdminWeb, :controller

  alias LtzfAdmin.Accounts

  def index(conn, _params) do
    api_keys = Accounts.list_api_keys()
    render(conn, :index, api_keys: api_keys, layout: false)
  end

  def new(conn, _params) do
    changeset = Accounts.change_api_key(%Accounts.ApiKey{})
    render(conn, :new, changeset: changeset, layout: false)
  end

  def create(conn, %{"api_key" => api_key_params}) do
    user = Accounts.get_user!(conn.assigns.current_user_id)

    case Accounts.create_api_key(Map.put(api_key_params, "user_id", user.id)) do
      {:ok, api_key} ->
        conn
        |> put_flash(:info, "API key created successfully.")
        |> put_flash(:api_key, api_key.key)
        |> redirect(to: "/api_keys")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, layout: false)
    end
  end

  def show(conn, %{"id" => id}) do
    api_key = Accounts.get_api_key!(id)
    render(conn, :show, api_key: api_key, layout: false)
  end

  def edit(conn, %{"id" => id}) do
    api_key = Accounts.get_api_key!(id)
    changeset = Accounts.change_api_key(api_key)
    render(conn, :edit, api_key: api_key, changeset: changeset, layout: false)
  end

  def update(conn, %{"id" => id, "api_key" => api_key_params}) do
    api_key = Accounts.get_api_key!(id)

    case Accounts.update_api_key(api_key, api_key_params) do
      {:ok, api_key} ->
        conn
        |> put_flash(:info, "API key updated successfully.")
        |> redirect(to: "/api_keys/#{api_key}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, api_key: api_key, changeset: changeset, layout: false)
    end
  end

  def delete(conn, %{"id" => id}) do
    api_key = Accounts.get_api_key!(id)
    {:ok, _} = Accounts.delete_api_key(api_key)

    conn
    |> put_flash(:info, "API key deleted successfully.")
    |> redirect(to: "/api_keys")
  end

  def rotate(conn, %{"id" => id}) do
    api_key = Accounts.get_api_key!(id)

    case Accounts.rotate_api_key(api_key) do
      {:ok, new_api_key} ->
        conn
        |> put_flash(:info, "API key rotated successfully.")
        |> put_flash(:api_key, new_api_key.key)
        |> redirect(to: "/api_keys")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to rotate API key.")
        |> redirect(to: "/api_keys")
    end
  end
end
