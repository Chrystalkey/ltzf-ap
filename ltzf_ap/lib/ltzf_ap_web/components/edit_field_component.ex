defmodule LtzfApWeb.EditFieldComponent do
  @moduledoc """
  Reusable component for inline editing of fields.
  """

  use Phoenix.Component

  def edit_field(assigns) do
    ~H"""
    <div class="flex items-center space-x-2">
      <%= if @editing do %>
        <input
          type="text"
          value={@value}
          phx-blur={@save_event}
          phx-keyup={@save_event}
          phx-value-key="Enter"
          class="flex-1 px-3 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors duration-200"
          autofocus
        >
        <button
          phx-click={@save_event}
          class="text-green-600 hover:text-green-700 transition-colors duration-200 p-1.5 rounded-lg hover:bg-green-50"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
        </button>
        <button
          phx-click={@cancel_event}
          class="text-red-600 hover:text-red-700 transition-colors duration-200 p-1.5 rounded-lg hover:bg-red-50"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      <% else %>
        <span class="flex-1 px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-lg text-gray-900">
          <%= @display_value %>
        </span>
        <button
          phx-click={@edit_event}
          class="text-gray-400 hover:text-gray-600 transition-colors duration-200 p-1.5 rounded-lg hover:bg-gray-100"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
          </svg>
        </button>
      <% end %>
    </div>
    """
  end

  def edit_field_small(assigns) do
    ~H"""
    <div class="flex items-center space-x-2">
      <%= if @editing do %>
        <input
          type="text"
          value={@value}
          phx-blur={@save_event}
          phx-keyup={@save_event}
          phx-value-key="Enter"
          class="flex-1 px-2 py-1 border border-gray-300 rounded text-sm"
          autofocus
        >
        <button
          phx-click={@save_event}
          class="text-green-600 hover:text-green-700 transition-colors duration-200 p-1 rounded hover:bg-green-50"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
        </button>
        <button
          phx-click={@cancel_event}
          class="text-red-600 hover:text-red-700 transition-colors duration-200 p-1 rounded hover:bg-red-50"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      <% else %>
        <span class="text-sm text-gray-600"><%= @display_value %></span>
        <button
          phx-click={@edit_event}
          class="text-gray-400 hover:text-gray-600 transition-colors duration-200 p-1 rounded hover:bg-gray-100"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
          </svg>
        </button>
      <% end %>
    </div>
    """
  end
end
