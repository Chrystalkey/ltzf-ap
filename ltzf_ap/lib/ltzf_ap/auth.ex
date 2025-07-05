defmodule LtzfAp.Auth do
  @moduledoc """
  Authentication service for validating API keys and managing authorization levels.
  """

  @valid_scopes ["admin", "keyadder"]

  def validate_api_key(backend_url, api_key) do
    case LtzfAp.ApiClient.auth_status(backend_url, api_key) do
      {:ok, %{"scope" => scope}} when scope in @valid_scopes ->
        {:ok, %{scope: scope}}
      {:ok, %{"scope" => scope}} ->
        {:error, "Insufficient permissions. Required: admin or keyadder, got: #{scope}"}
      {:error, :forbidden} ->
        {:error, "Invalid API key"}
      {:error, reason} ->
        {:error, "Authentication failed: #{reason}"}
    end
  end

  def can_manage_keys?(%{scope: "admin"}), do: true
  def can_manage_keys?(%{scope: "keyadder"}), do: true
  def can_manage_keys?(_), do: false

  def can_access_admin_features?(%{scope: "admin"}), do: true
  def can_access_admin_features?(_), do: false

  def scope_display_name("admin"), do: "Administrator"
  def scope_display_name("keyadder"), do: "Key Manager"
  def scope_display_name("collector"), do: "Data Collector"
  def scope_display_name(scope), do: scope
end
