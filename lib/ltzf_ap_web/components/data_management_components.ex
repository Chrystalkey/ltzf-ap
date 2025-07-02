defmodule LtzfApWeb.DataManagementComponents do
  use Phoenix.Component
  import Phoenix.HTML
  import Phoenix.HTML.Form
  import LtzfApWeb.CoreComponents

  @doc """
  Renders a data management page with filters, results, and pagination.
  """
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :filters, :list, required: true
  attr :backend_url, :string, required: true
  attr :api_key, :string, required: true
  attr :current_user, :map, required: true
  attr :flash, :map, required: true
  attr :page_id, :string, required: true
  attr :api_endpoint, :string, required: true
  attr :loading_text, :string, required: true
  attr :empty_text, :string, required: true
  attr :render_item, :any, required: true

  def data_management_page(assigns) do
    ~H"""
    <div id={@page_id} class="min-h-screen bg-gray-100" data-backend-url={@backend_url} data-api-key={@api_key}>
      <.admin_nav current_page="data_management" current_user={@current_user} />

      <div class="py-10">
        <header>
          <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-3xl font-bold leading-tight text-gray-900"><%= @title %></h1>
                <p class="mt-2 text-sm text-gray-600">
                  <%= @description %>
                </p>
              </div>
              <a href="/data_management" class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
                </svg>
                Back to Data Management
              </a>
            </div>
          </div>
        </header>
        <main>
          <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="px-4 py-8 sm:px-0">
              <.flash_group flash={@flash} />

              <!-- Filters -->
              <.data_management_filters filters={@filters} />

              <!-- Loading State -->
              <div id="loading-state" class="bg-white shadow overflow-hidden sm:rounded-md">
                <div class="px-4 py-8 text-center">
                  <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600 mx-auto"></div>
                  <p class="mt-2 text-sm text-gray-600"><%= @loading_text %></p>
                </div>
              </div>

              <!-- Results -->
              <div id="results-container" class="bg-white shadow overflow-hidden sm:rounded-md" style="display: none;">
                <ul id="results-list" class="divide-y divide-gray-200">
                  <!-- Results will be populated by JavaScript -->
                </ul>
              </div>

              <!-- Empty State -->
              <div id="empty-state" class="text-center py-12" style="display: none;">
                <h3 class="mt-2 text-sm font-medium text-gray-900"><%= @empty_text %></h3>
              </div>

              <!-- Pagination -->
              <%= data_management_pagination(assigns) %>
            </div>
          </div>
        </main>
      </div>
    </div>
    """
  end

  @doc """
  Renders filter form fields for data management pages.
  """
  attr :filters, :list, required: true

  def data_management_filters(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg mb-6">
      <div class="px-4 py-5 sm:p-6">
        <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Filters</h3>
        <form id="filter-form" class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <%= for filter <- @filters do %>
            <div>
              <label for={filter.id} class="block text-sm font-medium text-gray-700"><%= filter.label %></label>
              <%= case filter.type do %>
                <% "select" -> %>
                  <select name={filter.name} id={filter.id} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
                    <%= for option <- filter.options do %>
                      <option value={option.value}><%= option.label %></option>
                    <% end %>
                  </select>
                <% "text" -> %>
                  <input type="text" name={filter.name} id={filter.id} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" placeholder={filter.placeholder}>
                <% "number" -> %>
                  <input type="number" name={filter.name} id={filter.id} min={filter.min} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" placeholder={filter.placeholder}>
                <% "datetime-local" -> %>
                  <input type="datetime-local" name={filter.name} id={filter.id} class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
              <% end %>
            </div>
          <% end %>
          <div class="flex items-end">
            <button type="submit" class="w-full inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
              </svg>
              Filter
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  @doc """
  Renders pagination controls for data management pages.
  """
  def data_management_pagination(assigns) do
    ~H"""
    <div id="pagination" class="mt-6 flex items-center justify-between" style="display: none;">
      <div class="flex-1 flex justify-between sm:hidden">
        <button id="prev-page-mobile" class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
          Previous
        </button>
        <button id="next-page-mobile" class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
          Next
        </button>
      </div>
      <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
        <div>
          <p class="text-sm text-gray-700">
            Showing <span id="page-info">page 1</span>
          </p>
        </div>
        <div>
          <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
            <button id="prev-page" class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
              <span class="sr-only">Previous</span>
              <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path fill-rule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
              </svg>
            </button>
            <button id="next-page" class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50">
              <span class="sr-only">Next</span>
              <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
              </svg>
            </button>
          </nav>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Returns the common parliament options used across all data management pages.
  """
  def parliament_options do
    [
      %{value: "", label: "All Parliaments"},
      %{value: "BT", label: "Bundestag (BT)"},
      %{value: "BR", label: "Bundesrat (BR)"},
      %{value: "BV", label: "Bundesversammlung (BV)"},
      %{value: "EK", label: "Europakammer (EK)"},
      %{value: "BB", label: "Brandenburg (BB)"},
      %{value: "BY", label: "Bayern (BY)"},
      %{value: "BE", label: "Berlin (BE)"},
      %{value: "HB", label: "Hansestadt Bremen (HB)"},
      %{value: "HH", label: "Hansestadt Hamburg (HH)"},
      %{value: "HE", label: "Hessen (HE)"},
      %{value: "MV", label: "Mecklenburg-Vorpommern (MV)"},
      %{value: "NI", label: "Niedersachsen (NI)"},
      %{value: "NW", label: "Nordrhein-Westfalen (NW)"},
      %{value: "RP", label: "Rheinland-Pfalz (RP)"},
      %{value: "SL", label: "Saarland (SL)"},
      %{value: "SN", label: "Sachsen (SN)"},
      %{value: "TH", label: "Thüringen (TH)"},
      %{value: "SH", label: "Schleswig-Holstein (SH)"},
      %{value: "BW", label: "Baden Württemberg (BW)"},
      %{value: "ST", label: "Sachsen Anhalt (ST)"}
    ]
  end

  @doc """
  Returns the common process type options used across data management pages.
  """
  def process_type_options do
    [
      %{value: "", label: "All Types"},
      %{value: "gg-einspruch", label: "Bundesgesetz Einspruch"},
      %{value: "gg-zustimmung", label: "Bundesgesetz Zustimmungspflicht"},
      %{value: "gg-land-parl", label: "Landesgesetz, normal"},
      %{value: "gg-land-volk", label: "Landesgesetz, Volksgesetzgebung"},
      %{value: "bw-einsatz", label: "Bundeswehreinsatz"},
      %{value: "sonstig", label: "Other"}
    ]
  end

  @doc """
  Returns common filter configurations for data management pages.
  """
  def common_filters do
    [
      %{
        id: "parlament",
        name: "p",
        label: "Parliament",
        type: "select",
        options: parliament_options()
      },
      %{
        id: "wahlperiode",
        name: "wp",
        label: "Electoral Period",
        type: "number",
        min: 0,
        placeholder: "e.g., 20"
      },
      %{
        id: "vgtyp",
        name: "vgtyp",
        label: "Process Type",
        type: "select",
        options: process_type_options()
      },
      %{
        id: "updated-since",
        name: "since",
        label: "Updated Since",
        type: "datetime-local"
      },
      %{
        id: "updated-until",
        name: "until",
        label: "Updated Until",
        type: "datetime-local"
      }
    ]
  end
end
