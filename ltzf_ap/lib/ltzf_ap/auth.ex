defmodule LtzfAp.Auth do
  @moduledoc """
  Minimal authentication utilities for client-side validation.
  """

  @valid_scopes ["admin", "keyadder"]

  def valid_scope?(scope) when scope in @valid_scopes, do: true
  def valid_scope?(_), do: false

  def can_manage_keys?("admin"), do: true
  def can_manage_keys?("keyadder"), do: true
  def can_manage_keys?(_), do: false

  def can_access_admin_features?("admin"), do: true
  def can_access_admin_features?(_), do: false

  def scope_display_name("admin"), do: "Administrator"
  def scope_display_name("keyadder"), do: "Key Manager"
  def scope_display_name("collector"), do: "Data Collector"
  def scope_display_name(scope), do: scope
end
