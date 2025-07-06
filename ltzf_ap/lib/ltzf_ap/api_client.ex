defmodule LtzfAp.ApiClient do
  @moduledoc """
  HTTP client for communicating with the LTZF API backend.
  Handles authentication, rate limiting, and error responses.
  """

  use GenServer
  @finch_name LtzfAp.Finch
  @ping_timeout 100 # milliseconds

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    Finch.start_link(name: @finch_name, pool_size: 10)
    {:ok, %{}}
  end

      def ping(backend_url) do
    url = "#{backend_url}/ping"

    case Finch.build(:get, url, []) |> Finch.request(@finch_name, receive_timeout: @ping_timeout) do
      {:ok, %{status: 200}} -> {:ok, :pong}
      {:ok, %{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  def auth_status(backend_url, api_key) do
    url = "#{backend_url}/api/v1/auth/status"
    headers = [{"X-API-Key", api_key}]

    case Finch.build(:get, url, headers) |> Finch.request(@finch_name) do
      {:ok, %{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, reason}
        end

      {:ok, %{status: 403}} -> {:error, :forbidden}
      {:ok, %{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_vorgaenge(backend_url, api_key, params \\ []) do
    case get_vorgaenge_with_headers(backend_url, api_key, params) do
      {:ok, data, _headers} -> {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_vorgaenge_with_headers(backend_url, api_key, params \\ []) do
    url = "#{backend_url}/api/v1/vorgang"
    headers = [{"X-API-Key", api_key}]

    query_string = build_query_string(params)
    full_url = if query_string == "", do: url, else: "#{url}?#{query_string}"


    case Finch.build(:get, full_url, headers) |> Finch.request(@finch_name) do
      {:ok, %{status: 200, body: body, headers: response_headers}} ->
        case Jason.decode(body) do
          {:ok, data} ->
            {:ok, data, response_headers}
          {:error, reason} ->
            {:error, reason}
        end

      {:ok, %{status: 204, headers: response_headers}} ->
        {:ok, [], response_headers}
      {:ok, %{status: 403}} ->
        {:error, :forbidden}
      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_sitzungen(backend_url, api_key, params \\ []) do
    case get_sitzungen_with_headers(backend_url, api_key, params) do
      {:ok, data, _headers} -> {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_sitzungen_with_headers(backend_url, api_key, params \\ []) do
    url = "#{backend_url}/api/v1/sitzung"
    headers = [{"X-API-Key", api_key}]

    query_string = build_query_string(params)
    full_url = if query_string == "", do: url, else: "#{url}?#{query_string}"

    case Finch.build(:get, full_url, headers) |> Finch.request(@finch_name) do
      {:ok, %{status: 200, body: body, headers: response_headers}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data, response_headers}
          {:error, reason} -> {:error, reason}
        end

      {:ok, %{status: 204, headers: response_headers}} -> {:ok, [], response_headers}
      {:ok, %{status: 403}} -> {:error, :forbidden}
      {:ok, %{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_enumerations(backend_url, api_key, enum_name, params \\ []) do
    url = "#{backend_url}/api/v1/enumeration/#{enum_name}"
    headers = [{"X-API-Key", api_key}]

    query_string = build_query_string(params)
    full_url = if query_string == "", do: url, else: "#{url}?#{query_string}"

    case Finch.build(:get, full_url, headers) |> Finch.request(@finch_name) do
      {:ok, %{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, reason}
        end

      {:ok, %{status: 204}} -> {:ok, []}
      {:ok, %{status: 403}} -> {:error, :forbidden}
      {:ok, %{status: 404}} -> {:error, :not_found}
      {:ok, %{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  def create_api_key(backend_url, api_key, scope, expires_at \\ nil) do
    url = "#{backend_url}/api/v1/auth"
    headers = [{"X-API-Key", api_key}, {"Content-Type", "application/json"}]

    body = %{
      scope: scope
    }

    body = if expires_at, do: Map.put(body, :expires_at, expires_at), else: body

    case Finch.build(:post, url, headers, Jason.encode!(body)) |> Finch.request(@finch_name) do
      {:ok, %{status: 201, body: body}} -> {:ok, body}
      {:ok, %{status: 403}} -> {:error, :forbidden}
      {:ok, %{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  def delete_api_key(backend_url, api_key, key_to_delete) do
    url = "#{backend_url}/api/v1/auth"
    headers = [{"X-API-Key", api_key}, {"api-key-delete", key_to_delete}]

    case Finch.build(:delete, url, headers) |> Finch.request(@finch_name) do
      {:ok, %{status: 204}} -> {:ok, :deleted}
      {:ok, %{status: 403}} -> {:error, :forbidden}
      {:ok, %{status: 404}} -> {:error, :not_found}
      {:ok, %{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_query_string(params) do
    params
    |> Enum.filter(fn {_key, value} -> value != nil and value != "" end)
    |> Enum.map(fn {key, value} -> "#{key}=#{URI.encode_www_form(to_string(value))}" end)
    |> Enum.join("&")
  end
end
