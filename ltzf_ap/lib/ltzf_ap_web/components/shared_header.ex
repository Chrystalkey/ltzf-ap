defmodule LtzfApWeb.SharedHeader do
  @moduledoc """
  Shared header component for LiveView pages.
  """

  use Phoenix.Component
  import Phoenix.Component

  def app_header(assigns) do
    ~H"""
    <header class="bg-white/80 backdrop-blur-sm border-b border-slate-200/60 sticky top-0 z-10">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center py-4">
          <div class="flex items-center space-x-3">
            <div class="w-8 h-8 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-lg flex items-center justify-center">
              <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div>
              <h1 class="text-xl font-semibold text-slate-900">LTZF Admin Panel</h1>
              <p class="text-sm text-slate-500"><%= @subtitle %></p>
            </div>
          </div>

          <div class="flex items-center space-x-6">
            <div class="hidden sm:flex items-center space-x-4 text-sm">
              <div class="flex items-center space-x-2">
                <div class="w-2 h-2 bg-green-500 rounded-full"></div>
                <span class="text-slate-600 font-medium">
                  <%= if @session_id do %>
                    <%= LtzfAp.Auth.scope_display_name(@auth_info.scope) %>
                  <% else %>
                    Loading...
                  <% end %>
                </span>
              </div>
              <div class="text-slate-500">
                <span class="font-medium">Session:</span>
                <span class="ml-1">
                  <%= if @session_id do %>
                    <%= LtzfApWeb.SharedLiveHelpers.format_time_remaining(@session_data.expires_at) %>
                  <% else %>
                    Loading...
                  <% end %>
                </span>
              </div>
            </div>

            <div class="flex items-center space-x-3">
              <a href="/dashboard" class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-lg text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all duration-200 shadow-sm">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                </svg>
                Dashboard
              </a>

              <%= if @session_id do %>
                <button
                  phx-click="logout"
                  class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-lg text-white bg-gradient-to-r from-red-500 to-red-600 hover:from-red-600 hover:to-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 transition-all duration-200 shadow-sm"
                >
                  <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                  </svg>
                  Logout
                </button>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </header>
    """
  end

  def page_header(assigns) do
    ~H"""
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-slate-900"><%= @title %></h1>
      <div class="flex space-x-2">
        <button phx-click="clear_filters" class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
          Filter zurücksetzen
        </button>
      </div>
    </div>
    """
  end

  def loading_state(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg p-6 mb-6">
      <div class="flex items-center justify-center">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        <span class="ml-2 text-gray-600"><%= @message %></span>
      </div>
    </div>
    """
  end

  def error_state(assigns) do
    ~H"""
    <div class="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
      <div class="flex">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-red-800"><%= @title %></h3>
          <div class="mt-2 text-sm text-red-700">
            <p><%= @message %></p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def pagination_info(assigns) do
    ~H"""
    <%= if @pagination.total_count do %>
      <div class="bg-white shadow rounded-lg p-4 mb-4">
        <div class="flex justify-between items-center">
          <p class="text-sm text-gray-700">
            Zeige <%= (@pagination.current_page - 1) * @pagination.per_page + 1 %> bis <%= min(@pagination.current_page * @pagination.per_page, @pagination.total_count) %> von <%= @pagination.total_count %> <%= @item_name %>
          </p>
          <div class="flex space-x-2">
            <%= if @pagination.current_page > 1 do %>
              <button phx-click="page_change" phx-value-page={@pagination.current_page - 1} class="px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50">
                Zurück
              </button>
            <% end %>
            <%= if @pagination.current_page < @pagination.total_pages do %>
              <button phx-click="page_change" phx-value-page={@pagination.current_page + 1} class="px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50">
                Weiter
              </button>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end
