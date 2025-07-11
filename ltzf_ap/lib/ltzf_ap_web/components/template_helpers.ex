defmodule LtzfApWeb.TemplateHelpers do
  @moduledoc """
  Common helper functions for templates to reduce code duplication.
  """

  use Phoenix.Component

  # Safe list iteration with fallback
  def safe_list(list, fallback \\ [])
  def safe_list(list, _fallback) when is_list(list), do: list
  def safe_list(_, fallback), do: fallback

  # Safe map access with fallback
  def safe_get(map, key, fallback \\ "")
  def safe_get(map, key, fallback) when is_map(map), do: Map.get(map, key, fallback)
  def safe_get(_, _, fallback), do: fallback

  # Conditional rendering helper
  def render_if(condition, content) do
    if condition, do: content, else: ""
  end

  # Form field classes
  def input_classes do
    "w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors duration-200"
  end

  def select_classes do
    "w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors duration-200"
  end

  def button_classes(variant \\ :primary) do
    case variant do
      :primary -> "px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors duration-200"
      :secondary -> "px-4 py-2 bg-gray-200 text-gray-900 rounded-lg hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition-colors duration-200"
      :danger -> "px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors duration-200"
      :success -> "px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 transition-colors duration-200"
    end
  end

  # Icon components
  def icon_edit(assigns) do
    ~H"""
    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
    </svg>
    """
  end

  def icon_save(assigns) do
    ~H"""
    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
    </svg>
    """
  end

  def icon_cancel(assigns) do
    ~H"""
    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
    </svg>
    """
  end

  def icon_add(assigns) do
    ~H"""
    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
    </svg>
    """
  end

  def icon_delete(assigns) do
    ~H"""
    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
    </svg>
    """
  end

  # Status badge component
  def status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex px-3 py-1 text-sm font-semibold rounded-full",
      case @status do
        :success -> "bg-green-100 text-green-800"
        :warning -> "bg-yellow-100 text-yellow-800"
        :error -> "bg-red-100 text-red-800"
        :info -> "bg-blue-100 text-blue-800"
        _ -> "bg-gray-100 text-gray-800"
      end
    ]}>
      <%= @text %>
    </span>
    """
  end

  # Loading spinner component
  def loading_spinner(assigns) do
    ~H"""
    <div class="flex justify-center items-center">
      <svg class="animate-spin h-5 w-5 text-blue-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <%= if @text do %>
        <span class="ml-2 text-sm text-gray-600"><%= @text %></span>
      <% end %>
    </div>
    """
  end

  # Empty state component
  def empty_state(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <div class="text-center">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900"><%= @title %></h3>
        <p class="mt-1 text-sm text-gray-500"><%= @message %></p>
      </div>
    </div>
    """
  end
end
