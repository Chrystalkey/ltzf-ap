defmodule LtzfApWeb.DataManagementComponents do
  use Phoenix.Component
  import Phoenix.HTML
  import LtzfApWeb.CoreComponents
  import LtzfApWeb.DateHelpers

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
                <h1 class="text-3xl font-bold leading-tight text-gray-900 m-0"><%= @title %></h1>
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
  Generic data management list page that eliminates duplication across entity types.
  """
  attr :entity_type, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :backend_url, :string, required: true
  attr :api_key, :string, required: true
  attr :current_user, :map, required: true
  attr :flash, :map, required: true
  attr :filters, :list, required: true
  attr :render_config, :map, required: true

  def generic_list_page(assigns) do
    assigns = assign(assigns, :page_id, "#{assigns.entity_type}-page")
    assigns = assign(assigns, :api_endpoint, "/api/v1/#{assigns.entity_type}")
    assigns = assign(assigns, :loading_text, "Loading #{assigns.render_config.loading_text}...")
    assigns = assign(assigns, :empty_text, assigns.render_config.empty_text)
    assigns = assign(assigns, :render_item, assigns.render_config.render_item)

    ~H"""
    <.data_management_page
      title={@title}
      description={@description}
      filters={@filters}
      backend_url={@backend_url}
      api_key={@api_key}
      current_user={@current_user}
      flash={@flash}
      page_id={@page_id}
      api_endpoint={@api_endpoint}
      loading_text={@loading_text}
      empty_text={@empty_text}
      render_item={@render_item}
    />

    <script>
    document.addEventListener('DOMContentLoaded', function() {
      new DataManagementPage({
        pageId: '<%= @page_id %>',
        apiEndpoint: '<%= @api_endpoint %>',
        emptyText: '<%= @empty_text %>',
        renderItem: <%= raw(@render_config.render_item_js) %>
      });

      // Use shared edit function generator to eliminate duplication
      // Make sure createEditFunction is available before using it
      if (typeof createEditFunction === 'function') {
        window.edit<%= String.capitalize(@entity_type) %> = createEditFunction('<%= @entity_type %>');
      } else {
        console.error('createEditFunction is not available');
        // Fallback edit function
        window.edit<%= String.capitalize(@entity_type) %> = function(id, item) {
          console.log('Fallback edit function for <%= @entity_type %>:', id, item);
          alert('Edit functionality not yet implemented');
        };
      }
    });
    </script>
    """
  end

  @doc """
  Generic detail page component that eliminates duplication across entity detail pages.
  """
  attr :entity_type, :string, required: true
  attr :title, :string, required: true
  attr :entity, :map, required: true
  attr :current_user, :map, required: true
  attr :flash, :map, required: true
  attr :back_url, :string, required: true
  attr :back_text, :string, required: true
  attr :fields, :list, required: true
  attr :sections, :list, default: []

  def generic_detail_page(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <.admin_nav current_page="data_management" current_user={@current_user} />

      <div class="py-10">
        <header>
          <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-3xl font-bold leading-tight text-gray-900 m-0"><%= @title %></h1>
                <p class="mt-2 text-sm text-gray-600">
                  <%= Map.get(@entity, "titel") || Map.get(@entity, "name") || "Details" %>
                </p>
              </div>
              <a href={@back_url} class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
                </svg>
                <%= @back_text %>
              </a>
            </div>
          </div>
        </header>
        <main>
          <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="px-4 py-8 sm:px-0">
              <.flash_group flash={@flash} />

              <!-- Main Details -->
              <.detail_section title="#{String.capitalize(@entity_type)} Details" fields={@fields} entity={@entity} />

              <!-- Additional Sections -->
              <%= for section <- @sections do %>
                <.detail_section title={section.title} items={section.items} entity={@entity} />
              <% end %>
            </div>
          </div>
        </main>
      </div>
    </div>
    """
  end

  @doc """
  Renders a detail section with fields or items.
  """
  attr :title, :string, required: true
  attr :fields, :list, default: []
  attr :items, :list, default: []
  attr :entity, :map, required: true

  def detail_section(assigns) do
    ~H"""
    <div class="mt-6 bg-white shadow overflow-hidden sm:rounded-lg">
      <div class="px-4 py-5 sm:px-6">
        <h3 class="text-lg leading-6 font-medium text-gray-900"><%= @title %></h3>
      </div>
      <div class="border-t border-gray-200">
        <%= if @fields != [] do %>
          <dl>
            <%= for {field, index} <- Enum.with_index(@fields) do %>
              <div class={"#{if rem(index, 2) == 0, do: "bg-gray-50", else: "bg-white"} px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6"}>
                <dt class="text-sm font-medium text-gray-500"><%= field.label %></dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  <%= render_field_value(@entity, field) %>
                </dd>
              </div>
            <% end %>
          </dl>
        <% end %>
        <%= if @items != [] do %>
          <ul class="divide-y divide-gray-200">
            <%= for item <- @items do %>
              <li class="px-4 py-4">
                <div class="flex items-center justify-between">
                  <div>
                    <%= render_item_content(item, @entity) %>
                  </div>
                </div>
              </li>
            <% end %>
          </ul>
        <% end %>
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

  # Helper functions for rendering field values and item content
  defp render_field_value(entity, field) do
    # Convert atom key to string key for JSON data
    key = if is_atom(field.key), do: Atom.to_string(field.key), else: field.key
    value = Map.get(entity, key)

    case field.type do
      :boolean -> if value, do: "Yes", else: "No"
      :datetime ->
        safe_format_datetime_short(value) || "N/A"
      :date ->
        safe_format_date(value) || "N/A"
      :mono -> if value, do: raw("<span class=\"font-mono\">#{value}</span>"), else: "N/A"
      _ -> value || "N/A"
    end
  end

  defp render_item_content(item, entity) do
    case item.type do
      :person_org ->
        person = Map.get(item, :person_key)
        org = Map.get(item, :org_key)
        fach = Map.get(item, :fach_key)

        raw("""
        <p class="text-sm font-medium text-gray-900">
          #{if person, do: person, else: org}
        </p>
        <p class="text-sm text-gray-500">
          #{if org && person, do: org}
          #{if fach, do: " | #{fach}"}
        </p>
        """)

      :link ->
        link_text = Map.get(item, :link_text_key)
        link_url = Map.get(item, :link_url_key)

        if link_url do
          raw("<a href=\"#{link_url}\" class=\"text-indigo-600 hover:text-indigo-900\">#{link_text || "View"}</a>")
        else
          raw("")
        end

      :custom ->
        raw(item.content.(entity))
    end
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

  @doc """
  Returns render configurations for different entity types.
  """
  def render_configs do
    %{
      "vorgang" => %{
        loading_text: "legislative processes",
        empty_text: "No legislative processes found",
        render_item: "vorgang",
        render_item_js: """
        function(item) {
          return `
            <li class="px-6 py-4">
              <div class="flex items-center justify-between">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center justify-between">
                    <p class="text-sm font-medium text-indigo-600 truncate">
                      <a href="/data_management/vorgaenge/\${item.id}" class="hover:underline">
                        \${item.titel || 'Untitled Process'}
                      </a>
                    </p>
                    <div class="ml-2 flex-shrink-0 flex">
                      <p class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                        \${item.parlament || 'Unknown'}
                      </p>
                    </div>
                  </div>
                  <div class="mt-2 flex">
                    <div class="flex items-center text-sm text-gray-500">
                      <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd" />
                      </svg>
                      \${item.erstellt_am ? new Date(item.erstellt_am).toLocaleDateString('de-DE') : 'Unknown date'}
                    </div>
                  </div>
                  <div class="mt-2 flex">
                    <div class="flex items-center text-sm text-gray-500">
                      <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path fill-rule="evenodd" d="M4 4a2 2 0 00-2 2v4a2 2 0 002 2V6h10a2 2 0 00-2-2H4zm2 6a2 2 0 012-2h8a2 2 0 012 2v4a2 2 0 01-2 2H8a2 2 0 01-2-2v-4zm6 4a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd" />
                      </svg>
                      \${item.vgtyp || 'Unknown type'}
                    </div>
                  </div>
                </div>
                <div class="ml-4 flex-shrink-0 flex space-x-2">
                  <button onclick="editVorgang('\${item.id}', \${JSON.stringify(item).replace(/"/g, '\\"')})" class="inline-flex items-center px-3 py-1 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                    <svg class="mr-1.5 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                    </svg>
                    Edit
                  </button>
                </div>
              </div>
            </li>
          `;
        }
        """
      },
      "sitzung" => %{
        loading_text: "parliamentary sessions",
        empty_text: "No parliamentary sessions found",
        render_item: "sitzung",
        render_item_js: """
        function(item) {
          return `
            <li class="px-6 py-4">
              <div class="flex items-center justify-between">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center justify-between">
                    <p class="text-sm font-medium text-indigo-600 truncate">
                      <a href="/data_management/sitzungen/\${item.id}" class="hover:underline">
                        \${item.titel || 'Untitled Session'}
                      </a>
                    </p>
                    <div class="ml-2 flex-shrink-0 flex">
                      <p class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                        \${item.parlament || 'Unknown'}
                      </p>
                    </div>
                  </div>
                  <div class="mt-2 flex">
                    <div class="flex items-center text-sm text-gray-500">
                      <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd" />
                      </svg>
                      \${item.datum ? new Date(item.datum).toLocaleDateString('de-DE') : 'Unknown date'}
                    </div>
                  </div>
                  <div class="mt-2 flex">
                    <div class="flex items-center text-sm text-gray-500">
                      <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                        <path fill-rule="evenodd" d="M4 4a2 2 0 00-2 2v4a2 2 0 002 2V6h10a2 2 0 00-2-2H4zm2 6a2 2 0 012-2h8a2 2 0 012 2v4a2 2 0 01-2 2H8a2 2 0 01-2-2v-4zm6 4a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd" />
                      </svg>
                      \${item.vgtyp || 'Unknown type'}
                    </div>
                  </div>
                </div>
                <div class="ml-4 flex-shrink-0 flex space-x-2">
                  <button onclick="editSitzung('\${item.id}', \${JSON.stringify(item).replace(/"/g, '\\"')})" class="inline-flex items-center px-3 py-1 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                    <svg class="mr-1.5 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                    </svg>
                    Edit
                  </button>
                </div>
              </div>
            </li>
          `;
        }
        """
      },


    }
  end

  @doc """
  Returns entity-specific filter configurations to eliminate duplication.
  """
  def entity_filters do
    %{
      "vorgang" => [
        %{id: "parlament", name: "p", label: "Parliament", type: "select", options: parliament_options()},
        %{id: "wahlperiode", name: "wp", label: "Electoral Period", type: "number", min: 0, placeholder: "e.g., 20"},
        %{id: "vgtyp", name: "vgtyp", label: "Process Type", type: "select", options: process_type_options()},
        %{id: "updated-since", name: "since", label: "Updated Since", type: "datetime-local"},
        %{id: "updated-until", name: "until", label: "Updated Until", type: "datetime-local"},
        %{id: "person", name: "person", label: "Author Name Contains", type: "text", placeholder: "e.g., Schmidt"},
        %{id: "fach", name: "fach", label: "Author Professional Field", type: "text", placeholder: "e.g., Verfassungsrecht"},
        %{id: "org", name: "org", label: "Author Organization", type: "text", placeholder: "e.g., SPD"}
      ],
      "sitzung" => [
        %{id: "parlament", name: "p", label: "Parliament", type: "select", options: parliament_options()},
        %{id: "wahlperiode", name: "wp", label: "Electoral Period", type: "number", min: 0, placeholder: "e.g., 20"},
        %{id: "vgtyp", name: "vgtyp", label: "Process Type", type: "select", options: process_type_options()},
        %{id: "updated-since", name: "since", label: "Updated Since", type: "datetime-local"},
        %{id: "updated-until", name: "until", label: "Updated Until", type: "datetime-local"},
        %{id: "vgid", name: "vgid", label: "Associated Process ID", type: "text", placeholder: "UUID"}
      ],

    }
  end
end
