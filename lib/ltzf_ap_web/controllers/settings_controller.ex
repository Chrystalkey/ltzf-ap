defmodule LtzfApWeb.SettingsController do
  use LtzfApWeb, :controller

  alias LtzfAp.Accounts

  def index(conn, _params) do
    current_user = conn.assigns.current_user
    # Get current settings from session or default values
    backend_url = get_session(conn, :backend_url) || ""
    api_key = get_session(conn, :api_key) || ""

    render(conn, :index,
      current_user: current_user,
      backend_url: backend_url,
      api_key: api_key,
      layout: false
    )
  end

  def update(conn, %{"settings" => settings_params}) do
    # Store settings in session for now (in a real app, you might want to store in database)
    conn
    |> put_session(:backend_url, settings_params["backend_url"])
    |> put_session(:api_key, settings_params["api_key"])
    |> put_flash(:info, "Settings updated successfully.")
    |> redirect(to: "/settings")
  end

  def update_password(conn, %{"password" => password_params}) do
    current_user = conn.assigns.current_user

    # Verify current password first
    case Accounts.authenticate_user(current_user.email, password_params["current_password"]) do
      {:ok, _user} ->
        # Update password
        case Accounts.update_user_password(current_user, %{
          "password" => password_params["new_password"],
          "password_confirmation" => password_params["password_confirmation"]
        }) do
          {:ok, _updated_user} ->
            conn
            |> put_flash(:info, "Password updated successfully! You can now use your new password to log in.")
            |> redirect(to: "/settings")

          {:error, changeset} ->
            conn
            |> put_flash(:error, "Failed to update password: #{format_password_errors(changeset)}")
            |> redirect(to: "/settings")
        end

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Current password is incorrect. Please enter your current password correctly.")
        |> redirect(to: "/settings")
    end
  end

  def update_password(conn, _params) do
    conn
    |> put_flash(:error, "Invalid password data. Please fill in all required fields.")
    |> redirect(to: "/settings")
  end

  def test_connection(conn, _params) do
    backend_url = get_session(conn, :backend_url)
    api_key = get_session(conn, :api_key)

    case test_backend_connection(backend_url, api_key) do
      {:ok, status} ->
        conn
        |> put_flash(:info, "Connection successful! Backend responded with status: #{status}")
        |> redirect(to: "/settings")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Connection failed: #{reason}")
        |> redirect(to: "/settings")
    end
  end

  defp test_backend_connection(backend_url, api_key) when is_binary(backend_url) and is_binary(api_key) and byte_size(backend_url) > 0 and byte_size(api_key) > 0 do
    try do
      # Test the auth/status endpoint which doesn't require special permissions
      url = String.trim(backend_url) <> "/api/v1/auth/status"

      headers = [
        {"X-API-Key", api_key},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.get(url, headers, timeout: 10000) do
        {:ok, %HTTPoison.Response{status_code: status_code}} when status_code in 200..299 ->
          {:ok, status_code}

        {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
          {:error, "HTTP #{status_code}: #{body}"}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "Network error: #{reason}"}
      end
    rescue
      e -> {:error, "Exception: #{inspect(e)}"}
    end
  end

  defp test_backend_connection(_, _) do
    {:error, "Backend URL and API key are required"}
  end

  defp format_password_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {message, _}} ->
      case {field, message} do
        {:password, "is too short"} ->
          "New password must be at least 6 characters long"
        {:password_confirmation, "does not match confirmation"} ->
          "Password confirmation does not match the new password"
        {:password, "can't be blank"} ->
          "New password is required"
        {:password_confirmation, "can't be blank"} ->
          "Password confirmation is required"
        {field, message} ->
          "#{String.replace(to_string(field), "_", " ")}: #{message}"
      end
    end)
    |> Enum.join(". ")
  end
end
