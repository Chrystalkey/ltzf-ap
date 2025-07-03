defmodule LtzfAp.ApiClient do
  @moduledoc """
  API client for communicating with the LTZF backend API.
  """

    @doc """
  Fetches legislative processes (vorgänge) from the API.
  """
  def get_vorgaenge(backend_url, api_key, params \\ %{}) do
    if backend_url == "" or api_key == "" do
      {:error, "Backend URL or API key not configured"}
    else
      url = "#{backend_url}/api/v1/vorgang"

      headers = [
        {"X-API-Key", api_key},
        {"Content-Type", "application/json"}
      ]

      query_params = build_query_params(params)

      case HTTPoison.get("#{url}?#{query_params}", headers, timeout: 5000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: response_headers}} ->
          case Jason.decode(body) do
            {:ok, data} -> {:ok, data, response_headers}
            {:error, _} -> {:error, "Invalid JSON response"}
          end
        {:ok, %HTTPoison.Response{status_code: 204, headers: response_headers}} ->
          {:ok, [], response_headers}
        {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
          {:error, "HTTP #{status_code}: #{body}"}
        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "Network error: #{reason}"}
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
      url = "#{backend_url}/api/v1/vorgang/#{id}"

      headers = [
        {"X-API-Key", api_key},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.get(url, headers, timeout: 5000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, data} -> {:ok, data}
            {:error, _} -> {:error, "Invalid JSON response"}
          end
        {:ok, %HTTPoison.Response{status_code: 404}} ->
          {:error, "Vorgang not found"}
        {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
          {:error, "HTTP #{status_code}: #{body}"}
        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "Network error: #{reason}"}
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
      url = "#{backend_url}/api/v1/sitzung"

      headers = [
        {"X-API-Key", api_key},
        {"Content-Type", "application/json"}
      ]

      query_params = build_query_params(params)

      case HTTPoison.get("#{url}?#{query_params}", headers, timeout: 5000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: response_headers}} ->
          case Jason.decode(body) do
            {:ok, data} -> {:ok, data, response_headers}
            {:error, _} -> {:error, "Invalid JSON response"}
          end
        {:ok, %HTTPoison.Response{status_code: 204, headers: response_headers}} ->
          {:ok, [], response_headers}
        {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
          {:error, "HTTP #{status_code}: #{body}"}
        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "Network error: #{reason}"}
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
      url = "#{backend_url}/api/v1/sitzung/#{id}"

      headers = [
        {"X-API-Key", api_key},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.get(url, headers, timeout: 5000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, data} -> {:ok, data}
            {:error, _} -> {:error, "Invalid JSON response"}
          end
        {:ok, %HTTPoison.Response{status_code: 404}} ->
          {:error, "Sitzung not found"}
        {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
          {:error, "HTTP #{status_code}: #{body}"}
        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "Network error: #{reason}"}
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
      url = "#{backend_url}/api/v1/dokument/#{id}"

      headers = [
        {"X-API-Key", api_key},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.get(url, headers, timeout: 5000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, data} -> {:ok, data}
            {:error, _} -> {:error, "Invalid JSON response"}
          end
        {:ok, %HTTPoison.Response{status_code: 404}} ->
          {:error, "Document not found"}
        {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
          {:error, "HTTP #{status_code}: #{body}"}
        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "Network error: #{reason}"}
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
      url = "#{backend_url}/api/v1/gremien"

      headers = [
        {"X-API-Key", api_key},
        {"Content-Type", "application/json"}
      ]

      query_params = build_query_params(params)

      case HTTPoison.get("#{url}?#{query_params}", headers, timeout: 5000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, data} -> {:ok, data}
            {:error, _} -> {:error, "Invalid JSON response"}
          end
        {:ok, %HTTPoison.Response{status_code: 204}} ->
          {:ok, []}
        {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
          {:error, "HTTP #{status_code}: #{body}"}
        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "Network error: #{reason}"}
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
      url = "#{backend_url}/api/v1/autoren"

      headers = [
        {"X-API-Key", api_key},
        {"Content-Type", "application/json"}
      ]

      query_params = build_query_params(params)

      case HTTPoison.get("#{url}?#{query_params}", headers, timeout: 5000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, data} -> {:ok, data}
            {:error, _} -> {:error, "Invalid JSON response"}
          end
        {:ok, %HTTPoison.Response{status_code: 204}} ->
          {:ok, []}
        {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
          {:error, "HTTP #{status_code}: #{body}"}
        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "Network error: #{reason}"}
      end
    end
  end

  # Private helper functions

  @doc """
  Updates a legislative process using PUT.
  """
  def put_vorgang(backend_url, api_key, id, data) do
    if backend_url == "" or api_key == "" do
      {:error, "Backend URL or API key not configured"}
    else
      url = "#{backend_url}/api/v1/vorgang/#{id}"

      headers = [
        {"X-API-Key", api_key},
        {"Content-Type", "application/json"}
      ]

      case Jason.encode(data) do
        {:ok, json_body} ->
          case HTTPoison.put(url, json_body, headers, timeout: 10000) do
            {:ok, %HTTPoison.Response{status_code: 201}} ->
              {:ok, "Vorgang updated successfully"}
            {:ok, %HTTPoison.Response{status_code: 403, body: body}} ->
              {:error, "Forbidden: #{body}"}
            {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
              {:error, "HTTP #{status_code}: #{body}"}
            {:error, %HTTPoison.Error{reason: reason}} ->
              {:error, "Network error: #{reason}"}
          end
        {:error, _} ->
          {:error, "Failed to encode data to JSON"}
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
      url = "#{backend_url}/api/v1/vorgang/#{id}"

      headers = [
        {"X-API-Key", api_key},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.delete(url, headers, timeout: 5000) do
        {:ok, %HTTPoison.Response{status_code: 204}} ->
          {:ok, "Vorgang deleted successfully"}
        {:ok, %HTTPoison.Response{status_code: 403, body: body}} ->
          {:error, "Forbidden: #{body}"}
        {:ok, %HTTPoison.Response{status_code: 404, body: body}} ->
          {:error, "Vorgang not found: #{body}"}
        {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
          {:error, "HTTP #{status_code}: #{body}"}
        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "Network error: #{reason}"}
      end
    end
  end

  defp build_query_params(params) do
    params
    |> Enum.filter(fn {_key, value} -> value != nil and value != "" end)
    |> Enum.map(fn {key, value} -> "#{key}=#{URI.encode_www_form(to_string(value))}" end)
    |> Enum.join("&")
  end
end
