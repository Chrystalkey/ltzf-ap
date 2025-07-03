defmodule LtzfApWeb.DataManagementHTML do
  use LtzfApWeb, :html

  import LtzfApWeb.DataManagementComponents
  import LtzfApWeb.DateHelpers

  embed_templates "data_management_html/*"

  def generic_list(assigns) do
    ~H"""
    <.generic_list_page
      entity_type={@entity_type}
      title={@title}
      description={@description}
      backend_url={@backend_url}
      api_key={@api_key}
      current_user={@current_user}
      flash={@flash}
      filters={@filters}
      render_config={@render_config}
    />
    """
  end

  def generic_vorgang_detail(assigns) do
    ~H"""
    <.vorgang_detail_page
      vorgang={@vorgang}
      current_user={@current_user}
      flash={@flash}
    />
    """
  end

  def generic_sitzung_detail(assigns) do
    fields = [
      %{key: "titel", label: "Title", type: :string},
      %{key: "nummer", label: "Number", type: :string},
      %{key: "termin", label: "Date & Time", type: :datetime},
      %{key: "public", label: "Public", type: :boolean},
      %{key: "api_id", label: "API ID", type: :mono}
    ]

    sections = [
      %{
        title: "Committee",
        items: [
          %{
            type: :custom,
            content: fn entity ->
              if entity["gremium"] do
                gremium = entity["gremium"]
                """
                <p class="text-sm font-medium text-gray-900">
                  #{Map.get(gremium, "name", "Unknown")} (#{Map.get(gremium, "parlament", "Unknown")} - Electoral Period #{Map.get(gremium, "wahlperiode", "Unknown")})
                </p>
                """
              else
                "<p class=\"text-sm text-gray-500\">N/A</p>"
              end
            end
          }
        ]
      },
      %{
        title: "Agenda Items (TOPs) (#{length(assigns.sitzung["tops"] || [])})",
        items: Enum.map(assigns.sitzung["tops"] || [], fn top ->
          %{
            type: :custom,
            content: fn _entity ->
              """
              <p class="text-sm font-medium text-gray-900">
                TOP #{Map.get(top, "nummer", "Unknown")}: #{Map.get(top, "titel", "Untitled")}
              </p>
              #{if top["vorgang_id"] && length(top["vorgang_id"]) > 0 do
                "<p class=\"text-sm text-gray-500\">Related Processes: #{length(top["vorgang_id"])}</p>"
              else
                ""
              end}
              """
            end
          }
        end)
      },
      %{
        title: "Documents (#{length(assigns.sitzung["dokumente"] || [])})",
        items: Enum.map(assigns.sitzung["dokumente"] || [], fn dokument ->
          %{
            type: :custom,
            content: fn _entity ->
              mod_date = safe_format_date(dokument["zp_modifiziert"]) || "N/A"

              """
              <p class="text-sm font-medium text-gray-900">
                #{Map.get(dokument, "titel", "Untitled")}
              </p>
              <p class="text-sm text-gray-500">
                Type: #{Map.get(dokument, "typ", "Unknown")} | Modified: #{mod_date}
              </p>
              """
            end
          }
        end)
      },
      %{
        title: "Experts (#{length(assigns.sitzung["experten"] || [])})",
        items: Enum.map(assigns.sitzung["experten"] || [], fn expert ->
          %{
            type: :person_org,
            person_key: Map.get(expert, "person"),
            org_key: Map.get(expert, "organisation"),
            fach_key: Map.get(expert, "fachgebiet")
          }
        end)
      }
    ]

    assigns = Map.put(assigns, :fields, fields)
    assigns = Map.put(assigns, :sections, sections)

    ~H"""
    <.generic_detail_page
      entity_type="sitzung"
      title="Parliamentary Session"
      entity={@sitzung}
      current_user={@current_user}
      flash={@flash}
      back_url="/data_management/sitzungen"
      back_text="Back to Sessions"
      fields={@fields}
      sections={@sections}
    />
    """
  end

  def vorgang_detail(assigns) do
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
    }

    function removeId(button) {
      button.parentElement.remove();
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
    }

    function removeLink(button) {
      button.parentElement.remove();
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
    }

    function removeInitiator(button) {
      button.parentElement.remove();
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
    </script>
    """
  end
end
