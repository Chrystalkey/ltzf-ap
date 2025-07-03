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
    assigns = assign(assigns, :api_endpoint, "/api/proxy/#{assigns.entity_type}")
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
                  <%= render_field_value(field, @entity) %>
                </dd>
              </div>
            <% end %>
          </dl>
        <% end %>
        <%= if @items != [] do %>
          <ul class="divide-y divide-gray-200">
            <%= for item <- @items do %>
              <li class="px-4 py-4">
                <%= render_item_content(item, @entity) %>
              </li>
            <% end %>
          </ul>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders the vorgang detail page with editing capabilities.
  """
  attr :vorgang, :map, required: true
  attr :current_user, :map, required: true
  attr :flash, :map, required: true

  def vorgang_detail_page(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100">
      <.admin_nav current_page="data_management" current_user={@current_user} />

      <div class="py-10">
        <header>
          <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-3xl font-bold leading-tight text-gray-900 m-0">Vorgang Details</h1>
                <p class="mt-2 text-sm text-gray-600">
                  <%= @vorgang["titel"] %>
                </p>
              </div>
              <div class="flex space-x-3">
                <button type="submit" form="vorgang-form" class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                  <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  Save Changes
                </button>
                <button type="button" onclick="undoChanges()" id="undo-btn" disabled class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed">
                  <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6"></path>
                  </svg>
                  Undo
                </button>
                <button type="button" onclick="resetToBackend()" class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                  <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
                  </svg>
                  Reset
                </button>
                <a href="/data_management/vorgaenge" class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                  Cancel
                </a>
                <button onclick="confirmDelete()" class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500">
                  <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                  </svg>
                  Delete
                </button>
              </div>
            </div>
          </div>
        </header>

        <main>
          <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="px-4 py-8 sm:px-0">
              <.flash_group flash={@flash} />

              <form id="vorgang-form" phx-submit="update_vorgang" method="post" action={"/data_management/vorgang/#{@vorgang["api_id"]}"}>
                <input type="hidden" name="_method" value="put" />

                <!-- Two Column Layout -->
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">

                  <!-- Left Column - Core Information -->
                  <div class="space-y-6">
                    <!-- Basic Details -->
                    <div class="bg-white shadow overflow-hidden sm:rounded-lg">
                      <div class="px-4 py-5 sm:px-6">
                        <h3 class="text-lg leading-6 font-medium text-gray-900">Basic Details</h3>
                      </div>
                      <div class="border-t border-gray-200">
                        <dl class="divide-y divide-gray-200">
                          <div class="px-4 py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                            <dt class="text-sm font-medium text-gray-500">API ID</dt>
                            <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2 font-mono"><%= @vorgang["api_id"] %></dd>
                          </div>
                          <div class="px-4 py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                            <dt class="text-sm font-medium text-gray-500">Titel *</dt>
                            <dd class="mt-1 sm:mt-0 sm:col-span-2">
                              <input type="text" name="vorgang[titel]" value={@vorgang["titel"]} required class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
                            </dd>
                          </div>
                          <div class="px-4 py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                            <dt class="text-sm font-medium text-gray-500">Kurztitel</dt>
                            <dd class="mt-1 sm:mt-0 sm:col-span-2">
                              <input type="text" name="vorgang[kurztitel]" value={@vorgang["kurztitel"]} class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
                            </dd>
                          </div>
                          <div class="px-4 py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                            <dt class="text-sm font-medium text-gray-500">Typ *</dt>
                            <dd class="mt-1 sm:mt-0 sm:col-span-2">
                              <select name="vorgang[typ]" required class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md">
                                <option value="gg-einspruch" selected={@vorgang["typ"] == "gg-einspruch"}>Bundesgesetz Einspruch</option>
                                <option value="gg-zustimmung" selected={@vorgang["typ"] == "gg-zustimmung"}>Bundesgesetz Zustimmungspflicht</option>
                                <option value="gg-land-parl" selected={@vorgang["typ"] == "gg-land-parl"}>Landesgesetz, normal</option>
                                <option value="gg-land-volk" selected={@vorgang["typ"] == "gg-land-volk"}>Landesgesetz, Volksgesetzgebung</option>
                                <option value="bw-einsatz" selected={@vorgang["typ"] == "bw-einsatz"}>Bundeswehreinsatz</option>
                                <option value="sonstig" selected={@vorgang["typ"] == "sonstig"}>Sonstig</option>
                              </select>
                            </dd>
                          </div>
                          <div class="px-4 py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                            <dt class="text-sm font-medium text-gray-500">Wahlperiode *</dt>
                            <dd class="mt-1 sm:mt-0 sm:col-span-2">
                              <input type="number" name="vorgang[wahlperiode]" value={@vorgang["wahlperiode"]} min="0" required class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
                            </dd>
                          </div>
                          <div class="px-4 py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                            <dt class="text-sm font-medium text-gray-500">Verfassungsändernd</dt>
                            <dd class="mt-1 sm:mt-0 sm:col-span-2">
                              <input type="checkbox" name="vorgang[verfassungsaendernd]" value="true" checked={@vorgang["verfassungsaendernd"]} class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded" />
                            </dd>
                          </div>
                        </dl>
                      </div>
                    </div>

                    <!-- Identifiers -->
                    <div class="bg-white shadow overflow-hidden sm:rounded-lg">
                      <div class="px-4 py-5 sm:px-6">
                        <h3 class="text-lg leading-6 font-medium text-gray-900">Identifiers</h3>
                      </div>
                      <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
                        <div id="ids-container">
                          <%= for {id, index} <- Enum.with_index(@vorgang["ids"] || []) do %>
                            <div class="flex space-x-2 mb-2">
                              <input type="text" name="vorgang[ids][][id]" value={id["id"]} placeholder="ID" class="flex-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block sm:text-sm border-gray-300 rounded-md" />
                              <select name="vorgang[ids][][typ]" class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block sm:text-sm border-gray-300 rounded-md">
                                <option value="initdrucks" selected={id["typ"] == "initdrucks"}>Initiativdrucksache</option>
                                <option value="vorgnr" selected={id["typ"] == "vorgnr"}>Vorgangsnummer</option>
                                <option value="api-id" selected={id["typ"] == "api-id"}>API ID</option>
                                <option value="sonstig" selected={id["typ"] == "sonstig"}>Sonstig</option>
                              </select>
                              <button type="button" onclick="removeId(this)" class="inline-flex items-center p-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500">
                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                                </svg>
                              </button>
                            </div>
                          <% end %>
                        </div>
                        <button type="button" onclick="addId()" class="mt-2 inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                          <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                          </svg>
                          Add Identifier
                        </button>
                      </div>
                    </div>

                    <!-- Links -->
                    <div class="bg-white shadow overflow-hidden sm:rounded-lg">
                      <div class="px-4 py-5 sm:px-6">
                        <h3 class="text-lg leading-6 font-medium text-gray-900">Links</h3>
                      </div>
                      <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
                        <div id="links-container">
                          <%= for link <- @vorgang["links"] || [] do %>
                            <div class="flex space-x-2 mb-2">
                              <input type="url" name="vorgang[links][]" value={link} placeholder="URL" class="flex-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block sm:text-sm border-gray-300 rounded-md" />
                              <button type="button" onclick="removeLink(this)" class="inline-flex items-center p-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500">
                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                                </svg>
                              </button>
                            </div>
                          <% end %>
                        </div>
                        <button type="button" onclick="addLink()" class="mt-2 inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                          <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                          </svg>
                          Add Link
                        </button>
                      </div>
                    </div>
                  </div>

                  <!-- Right Column - Participants & Metadata -->
                  <div class="space-y-6">
                    <!-- Initiators -->
                    <div class="bg-white shadow overflow-hidden sm:rounded-lg">
                      <div class="px-4 py-5 sm:px-6">
                        <h3 class="text-lg leading-6 font-medium text-gray-900">Initiators</h3>
                      </div>
                      <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
                        <div id="initiators-container">
                          <%= for {initiator, index} <- Enum.with_index(@vorgang["initiatoren"] || []) do %>
                            <div class="border rounded-lg p-4 mb-4">
                              <div class="grid grid-cols-1 gap-4">
                                <div>
                                  <label class="block text-sm font-medium text-gray-700">Person</label>
                                  <input type="text" name="vorgang[initiatoren][][person]" value={initiator["person"]} class="mt-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
                                </div>
                                <div>
                                  <label class="block text-sm font-medium text-gray-700">Organisation *</label>
                                  <input type="text" name="vorgang[initiatoren][][organisation]" value={initiator["organisation"]} required class="mt-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
                                </div>
                                <div>
                                  <label class="block text-sm font-medium text-gray-700">Fachgebiet</label>
                                  <input type="text" name="vorgang[initiatoren][][fachgebiet]" value={initiator["fachgebiet"]} class="mt-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
                                </div>
                              </div>
                              <button type="button" onclick="removeInitiator(this)" class="mt-2 inline-flex items-center px-3 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500">
                                Remove
                              </button>
                            </div>
                          <% end %>
                        </div>
                        <button type="button" onclick="addInitiator()" class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                          <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                          </svg>
                          Add Initiator
                        </button>
                      </div>
                    </div>

                    <!-- System Information -->
                    <%= if @vorgang["touched_by"] do %>
                      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
                        <div class="px-4 py-5 sm:px-6">
                          <h3 class="text-lg leading-6 font-medium text-gray-900">System Information</h3>
                        </div>
                        <div class="border-t border-gray-200">
                          <dl class="divide-y divide-gray-200">
                            <div class="px-4 py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                              <dt class="text-sm font-medium text-gray-500">Touched By</dt>
                              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                                <%= for touch <- @vorgang["touched_by"] do %>
                                  <div class="mb-1">
                                    <span class="font-mono text-xs"><%= touch["scraper_id"] %></span>
                                    <span class="text-gray-500">(<%= touch["key"] %>)</span>
                                  </div>
                                <% end %>
                              </dd>
                            </div>
                          </dl>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>

                <!-- Stations Section -->
                <div class="bg-white shadow overflow-hidden sm:rounded-lg mb-8">
                  <div class="px-4 py-5 sm:px-6">
                    <div class="flex items-center justify-between">
                      <h3 class="text-lg leading-6 font-medium text-gray-900">Stations (<%= length(@vorgang["stationen"] || []) %>)</h3>
                      <button type="button" onclick="toggleAllStations()" class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                        Expand All
                      </button>
                    </div>
                  </div>
                  <div class="border-t border-gray-200">
                    <div id="stations-container">
                      <%= for {station, index} <- Enum.with_index(@vorgang["stationen"] || []) do %>
                        <div class="station-item border-b border-gray-200">
                          <!-- Collapsed Station Header -->
                          <div class="px-4 py-4 cursor-pointer" onclick="toggleStation(this)">
                            <div class="flex items-center justify-between">
                              <div class="flex items-center space-x-3">
                                <svg class="station-toggle h-5 w-5 text-gray-400 transform transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                                </svg>
                                <div>
                                  <p class="text-sm font-medium text-gray-900">
                                    <%= station["titel"] || station["typ"] %>
                                  </p>
                                  <p class="text-sm text-gray-500">
                                    <%= if station["zp_start"] do %>
                                      <%= safe_format_date(station["zp_start"]) %>
                                    <% end %>
                                    | <%= station["typ"] %> | <%= station["parlament"] %>
                                  </p>
                                </div>
                              </div>
                            </div>
                          </div>

                          <!-- Expanded Station Content -->
                          <div class="station-content hidden px-4 py-4 bg-gray-50">
                            <!-- Station form fields would go here -->
                            <p class="text-sm text-gray-500">Station editing interface will be implemented here</p>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              </form>
            </div>
          </div>
        </main>
      </div>
    </div>

    <script>
    function confirmDelete() {
      if (confirm('Are you sure you want to delete this vorgang? This action cannot be undone.')) {
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = '/data_management/vorgang/<%= @vorgang["api_id"] %>';

        const methodInput = document.createElement('input');
        methodInput.type = 'hidden';
        methodInput.name = '_method';
        methodInput.value = 'delete';

        form.appendChild(methodInput);
        document.body.appendChild(form);
        form.submit();
      }
    }

    function addId() {
      const container = document.getElementById('ids-container');
      const div = document.createElement('div');
      div.className = 'flex space-x-2 mb-2';
      div.innerHTML = `
        <input type="text" name="vorgang[ids][][id]" placeholder="ID" class="flex-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block sm:text-sm border-gray-300 rounded-md" />
        <select name="vorgang[ids][][typ]" class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block sm:text-sm border-gray-300 rounded-md">
          <option value="initdrucks">Initiativdrucksache</option>
          <option value="vorgnr">Vorgangsnummer</option>
          <option value="api-id">API ID</option>
          <option value="sonstig">Sonstig</option>
        </select>
        <button type="button" onclick="removeId(this)" class="inline-flex items-center p-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      `;
      container.appendChild(div);

      // Track the add action
      const action = {
        id: ++actionId,
        type: 'add_item',
        itemType: 'identifier',
        element: div,
        container: container
      };
      addToUndoStack(action);
    }

    function removeId(button) {
      const element = button.parentElement;
      const container = element.parentElement;

      // Track the remove action before removing
      const action = {
        id: ++actionId,
        type: 'remove_item',
        itemType: 'identifier',
        element: element,
        container: container
      };
      addToUndoStack(action);

      element.remove();
    }

    function addLink() {
      const container = document.getElementById('links-container');
      const div = document.createElement('div');
      div.className = 'flex space-x-2 mb-2';
      div.innerHTML = `
        <input type="url" name="vorgang[links][]" placeholder="URL" class="flex-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block sm:text-sm border-gray-300 rounded-md" />
        <button type="button" onclick="removeLink(this)" class="inline-flex items-center p-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      `;
      container.appendChild(div);

      // Track the add action
      const action = {
        id: ++actionId,
        type: 'add_item',
        itemType: 'link',
        element: div,
        container: container
      };
      addToUndoStack(action);
    }

    function removeLink(button) {
      const element = button.parentElement;
      const container = element.parentElement;

      // Track the remove action before removing
      const action = {
        id: ++actionId,
        type: 'remove_item',
        itemType: 'link',
        element: element,
        container: container
      };
      addToUndoStack(action);

      element.remove();
    }

    function addInitiator() {
      const container = document.getElementById('initiators-container');
      const div = document.createElement('div');
      div.className = 'border rounded-lg p-4 mb-4';
      div.innerHTML = `
        <div class="grid grid-cols-1 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">Person</label>
            <input type="text" name="vorgang[initiatoren][][person]" class="mt-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Organisation *</label>
            <input type="text" name="vorgang[initiatoren][][organisation]" required class="mt-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Fachgebiet</label>
            <input type="text" name="vorgang[initiatoren][][fachgebiet]" class="mt-1 shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
          </div>
        </div>
        <button type="button" onclick="removeInitiator(this)" class="mt-2 inline-flex items-center px-3 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500">
          Remove
        </button>
      `;
      container.appendChild(div);

      // Track the add action
      const action = {
        id: ++actionId,
        type: 'add_item',
        itemType: 'initiator',
        element: div,
        container: container
      };
      addToUndoStack(action);
    }

    function removeInitiator(button) {
      const element = button.parentElement;
      const container = element.parentElement;

      // Track the remove action before removing
      const action = {
        id: ++actionId,
        type: 'remove_item',
        itemType: 'initiator',
        element: element,
        container: container
      };
      addToUndoStack(action);

      element.remove();
    }

    function toggleStation(header) {
      const content = header.nextElementSibling;
      const toggle = header.querySelector('.station-toggle');

      if (content.classList.contains('hidden')) {
        content.classList.remove('hidden');
        toggle.classList.add('rotate-90');
      } else {
        content.classList.add('hidden');
        toggle.classList.remove('rotate-90');
      }
    }

    function toggleAllStations() {
      const button = event.target;
      const stations = document.querySelectorAll('.station-content');
      const toggles = document.querySelectorAll('.station-toggle');

      if (button.textContent.includes('Expand')) {
        stations.forEach(station => station.classList.remove('hidden'));
        toggles.forEach(toggle => toggle.classList.add('rotate-90'));
        button.textContent = 'Collapse All';
      } else {
        stations.forEach(station => station.classList.add('hidden'));
        toggles.forEach(toggle => toggle.classList.remove('rotate-90'));
        button.textContent = 'Expand All';
      }
    }

        // Undo and Reset functionality
    let undoStack = [];
    let actionId = 0;

        // Initialize form tracking
    document.addEventListener('DOMContentLoaded', function() {
      // Initialize existing form inputs with their current values
      const formInputs = document.querySelectorAll('input, select, textarea');
      formInputs.forEach(input => {
        // Store the initial value in dataset
        if (input.type === 'checkbox') {
          input.dataset.lastValue = input.checked.toString();
        } else {
          input.dataset.lastValue = input.value;
        }

        input.addEventListener('change', handleFieldChange);
        input.addEventListener('input', handleFieldInput);
      });

      // Add event listeners for dynamic content
      setupDynamicContentListeners();
    });

    function setupDynamicContentListeners() {
      // Monitor for new elements being added (for dynamic arrays)
      const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
          mutation.addedNodes.forEach(function(node) {
            if (node.nodeType === 1) { // Element node
              const inputs = node.querySelectorAll ? node.querySelectorAll('input, select, textarea') : [];
              inputs.forEach(input => {
                input.addEventListener('change', handleFieldChange);
                input.addEventListener('input', handleFieldInput);
              });
            }
          });
        });
      });

      observer.observe(document.getElementById('vorgang-form'), {
        childList: true,
        subtree: true
      });
    }

    function handleFieldChange(event) {
      const action = createFieldEditAction(event.target);
      if (action) {
        addToUndoStack(action);
      }
    }

    function handleFieldInput(event) {
      // Debounce input events to avoid too many actions
      clearTimeout(event.target.inputTimeout);
      event.target.inputTimeout = setTimeout(() => {
        const action = createFieldEditAction(event.target);
        if (action) {
          addToUndoStack(action);
        }
      }, 500);
    }

    function createFieldEditAction(element) {
      const name = element.name;
      const oldValue = element.dataset.lastValue || '';
      const newValue = element.type === 'checkbox' ? element.checked.toString() : element.value;

      // Skip if no actual change
      if (oldValue === newValue) {
        return null;
      }

      // Store current value for next comparison
      element.dataset.lastValue = newValue;

      return {
        id: ++actionId,
        type: 'field_edit',
        field: name,
        oldValue: oldValue,
        newValue: newValue,
        element: element
      };
    }

    function addToUndoStack(action) {
      undoStack.push(action);

      // Limit stack to last 20 actions
      if (undoStack.length > 20) {
        undoStack.shift();
      }

      updateUndoButton();
    }

    function updateUndoButton() {
      const undoBtn = document.getElementById('undo-btn');
      if (undoStack.length > 0) {
        undoBtn.disabled = false;
        undoBtn.classList.remove('opacity-50', 'cursor-not-allowed');
        undoBtn.title = `Undo last action (${undoStack.length} actions available)`;
      } else {
        undoBtn.disabled = true;
        undoBtn.classList.add('opacity-50', 'cursor-not-allowed');
        undoBtn.title = 'No actions to undo';
      }
    }

    function undoChanges() {
      if (undoStack.length === 0) {
        alert('No actions to undo');
        return;
      }

      const lastAction = undoStack.pop();
      undoAction(lastAction);
      updateUndoButton();

      // Show feedback
      showNotification(`Undid: ${getActionDescription(lastAction)}`, 'success');
    }

    function undoAction(action) {
      switch (action.type) {
        case 'field_edit':
          undoFieldEdit(action);
          break;
        case 'add_item':
          undoAddItem(action);
          break;
        case 'remove_item':
          undoRemoveItem(action);
          break;
        default:
          console.warn('Unknown action type:', action.type);
      }
    }

    function undoFieldEdit(action) {
      const element = action.element;
      if (element && element.parentNode) {
        if (element.type === 'checkbox') {
          element.checked = action.oldValue === 'true';
        } else {
          element.value = action.oldValue;
        }
        element.dataset.lastValue = action.oldValue;
      }
    }

    function undoAddItem(action) {
      if (action.element && action.element.parentNode) {
        action.element.remove();
      }
    }

    function undoRemoveItem(action) {
      if (action.container && action.element) {
        action.container.appendChild(action.element);
      }
    }

    function getActionDescription(action) {
      switch (action.type) {
        case 'field_edit':
          return `Edited ${action.field}`;
        case 'add_item':
          return `Added ${action.itemType}`;
        case 'remove_item':
          return `Removed ${action.itemType}`;
        default:
          return 'Action';
      }
    }

        function resetToBackend() {
      if (confirm('Are you sure you want to reset all changes? This will discard all unsaved changes.')) {
        // Simply reload the page to get fresh data from the backend
        window.location.reload();
      }
    }

    function restoreFormData(data) {
      const form = document.getElementById('vorgang-form');

      // Clear existing form data
      const inputs = form.querySelectorAll('input, select, textarea');
      inputs.forEach(input => {
        if (input.type === 'checkbox') {
          input.checked = false;
        } else {
          input.value = '';
        }
      });

      // Restore data
      Object.keys(data).forEach(key => {
        const value = data[key];
        const elements = form.querySelectorAll(`[name="${key}"]`);

        if (Array.isArray(value)) {
          // Handle array values (like ids, links, initiators)
          value.forEach((item, index) => {
            if (typeof item === 'object') {
              // Handle object arrays (like ids with id and typ)
              Object.keys(item).forEach(subKey => {
                const subElements = form.querySelectorAll(`[name="${key}[${index}][${subKey}]"]`);
                if (subElements[index]) {
                  subElements[index].value = item[subKey];
                }
              });
            } else {
              // Handle simple arrays (like links)
              const elements = form.querySelectorAll(`[name="${key}[]"]`);
              if (elements[index]) {
                elements[index].value = item;
              }
            }
          });
        } else {
          // Handle single values
          elements.forEach(element => {
            if (element.type === 'checkbox') {
              element.checked = value === 'true';
            } else {
              element.value = value;
            }
          });
        }
      });
    }

    function showNotification(message, type = 'info') {
      // Create notification element
      const notification = document.createElement('div');
      notification.className = `fixed top-4 right-4 z-50 px-4 py-2 rounded-md shadow-lg ${
        type === 'success' ? 'bg-green-500 text-white' :
        type === 'error' ? 'bg-red-500 text-white' :
        'bg-blue-500 text-white'
      }`;
      notification.textContent = message;

      document.body.appendChild(notification);

      // Remove after 3 seconds
      setTimeout(() => {
        notification.remove();
      }, 3000);
    }
    </script>
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
  defp render_field_value(field, entity) do
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
      %{value: "", label: "Alle Typen"},
      %{value: "gg-einspruch", label: "Bundesgesetz Einspruch"},
      %{value: "gg-zustimmung", label: "Bundesgesetz Zustimmungspflicht"},
      %{value: "gg-land-parl", label: "Landesgesetz, normal"},
      %{value: "gg-land-volk", label: "Landesgesetz, Volksgesetzgebung"},
      %{value: "bw-einsatz", label: "Bundeswehreinsatz"},
      %{value: "sonstig", label: "Sonstige"}
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
        label: "Parlament",
        type: "select",
        options: parliament_options()
      },
      %{
        id: "wahlperiode",
        name: "wp",
        label: "Wahlperiode",
        type: "number",
        min: 0,
        placeholder: "z.B. 20"
      },
      %{
        id: "vgtyp",
        name: "vgtyp",
        label: "Vorgangstyp",
        type: "select",
        options: process_type_options()
      },
      %{
        id: "updated-since",
        name: "since",
        label: "Aktualisiert seit",
        type: "datetime-local"
      },
      %{
        id: "updated-until",
        name: "until",
        label: "Aktualisiert bis",
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
        loading_text: "Gesetzgebungsverfahren",
        empty_text: "Keine Gesetzgebungsverfahren gefunden",
        render_item: "vorgang",
        api_endpoint: "/api/proxy/vorgang"
      },
      "sitzung" => %{
        loading_text: "Parlamentssitzungen",
        empty_text: "Keine Sitzungen gefunden",
        render_item: "sitzung",
        api_endpoint: "/api/proxy/sitzung"
      },
      "dokument" => %{
        loading_text: "Dokumente",
        empty_text: "Keine Dokumente gefunden",
        render_item: "dokument",
        api_endpoint: "/api/proxy/dokument"
      }
    }
  end

  @doc """
  Returns entity-specific filter configurations to eliminate duplication.
  """
  def entity_filters do
    %{
      "vorgang" => [
        %{id: "parlament", name: "p", label: "Parlament", type: "select", options: parliament_options()},
        %{id: "wahlperiode", name: "wp", label: "Wahlperiode", type: "number", min: 0, placeholder: "z.B. 20"},
        %{id: "vgtyp", name: "vgtyp", label: "Vorgangstyp", type: "select", options: process_type_options()},
        %{id: "updated-since", name: "since", label: "Aktualisiert seit", type: "datetime-local"},
        %{id: "updated-until", name: "until", label: "Aktualisiert bis", type: "datetime-local"},
        %{id: "person", name: "person", label: "Initiator:innen-Name enthält", type: "text", placeholder: "z.B. Schmidt"},
        %{id: "fach", name: "fach", label: "Initiator:innen-Fachgebiet", type: "text", placeholder: "z.B. Verfassungsrecht"},
        %{id: "org", name: "org", label: "Initiator:innen-Organisation", type: "text", placeholder: "z.B. SPD"}
      ],
      "sitzung" => [
        %{id: "parlament", name: "p", label: "Parlament", type: "select", options: parliament_options()},
        %{id: "wahlperiode", name: "wp", label: "Wahlperiode", type: "number", min: 0, placeholder: "z.B. 20"},
        %{id: "vgtyp", name: "vgtyp", label: "Vorgangstyp", type: "select", options: process_type_options()},
        %{id: "updated-since", name: "since", label: "Aktualisiert seit", type: "datetime-local"},
        %{id: "updated-until", name: "until", label: "Aktualisiert bis", type: "datetime-local"},
        %{id: "vgid", name: "vgid", label: "Zugehörige Vorgangs-ID", type: "text", placeholder: "UUID"}
      ],

    }
  end
end
