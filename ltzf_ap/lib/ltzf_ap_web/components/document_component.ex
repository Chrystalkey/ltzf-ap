defmodule LtzfApWeb.DocumentComponent do
  @moduledoc """
  Reusable component for displaying and editing documents (dokumente and stellungnahmen).
  """

  use Phoenix.Component
  import Phoenix.HTML.Form

  defp format_datetime_for_input(datetime_string) when is_binary(datetime_string) and datetime_string != "" do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} ->
        # Convert to local datetime format for datetime-local input
        datetime
        |> DateTime.to_naive()
        |> NaiveDateTime.to_string()
        |> String.slice(0, 16)  # Remove seconds and timezone
      _ ->
        ""
    end
  end
  defp format_datetime_for_input(_), do: ""

  def document_list(assigns) do
    ~H"""
    <div class="space-y-4 overflow-visible">
      <div class="flex justify-between items-center">
        <h3 class="text-lg font-medium text-gray-900"><%= @title %></h3>
        <button
          phx-click="add_document"
          phx-value-station-index={@station_index}
          phx-value-document-type={@document_type}
          class="inline-flex items-center px-3 py-2 text-sm font-medium text-white bg-indigo-600 border border-transparent rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
          </svg>
          <%= @add_button_text %>
        </button>
      </div>

      <%= if (@documents || []) == [] do %>
        <div class="text-center py-8">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">Keine <%= @empty_state_text %></h3>
          <p class="mt-1 text-sm text-gray-500">Fügen Sie <%= @empty_state_text %> zu dieser Station hinzu.</p>
        </div>
      <% else %>
        <div class="space-y-4">
          <%= for {document, document_index} <- Enum.with_index(@documents) do %>
            <div class="border border-gray-200 rounded-lg p-4 overflow-visible">
              <div class="flex justify-between items-start mb-4">
                <div class="flex-1">
                  <h4 class="text-sm font-medium text-gray-900">
                    <%= if document["titel"] && document["titel"] != "", do: document["titel"], else: "Dokument #{document_index + 1}" %>
                  </h4>
                  <div class="flex items-center space-x-4 mt-1 text-sm text-gray-500">
                    <%= if document["typ"] && document["typ"] != "" do %>
                      <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800">
                        <%= document["typ"] %>
                      </span>
                    <% end %>
                    <%= if document["link"] && document["link"] != "" do %>
                      <a href={document["link"]} target="_blank" class="text-indigo-600 hover:text-indigo-500">
                        <svg class="w-4 h-4 inline mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path>
                        </svg>
                        Link
                      </a>
                    <% end %>
                  </div>
                </div>
                <button
                  phx-click="remove_document"
                  phx-value-station-index={@station_index}
                  phx-value-document-index={document_index}
                  phx-value-document-type={@document_type}
                  class="inline-flex items-center px-2 py-1 text-xs font-medium text-red-700 bg-red-100 border border-transparent rounded-md hover:bg-red-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500">
                  <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                  </svg>
                </button>
              </div>

              <!-- Document Form -->
              <form phx-change="update_document" phx-value-station-index={@station_index} phx-value-document-index={document_index} phx-value-document-type={@document_type}>
                                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Titel *</label>
                    <input
                      type="text"
                      name="document[titel]"
                      value={document["titel"] || ""}
                      required
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                      placeholder="Dokumenttitel">
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Typ *</label>
                    <select
                      name="document[typ]"
                      value={document["typ"] || ""}
                      required
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm">
                      <option value="">Bitte wählen</option>
                      <%= for doktyp <- @dokumententypen do %>
                        <option value={doktyp} selected={document["typ"] == doktyp}><%= doktyp %></option>
                      <% end %>
                    </select>
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Link *</label>
                    <input
                      type="url"
                      name="document[link]"
                      value={document["link"] || ""}
                      required
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                      placeholder="https://...">
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Hash *</label>
                    <input
                      type="text"
                      name="document[hash]"
                      value={document["hash"] || ""}
                      required
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                      placeholder="Dokument-Hash">
                  </div>
                </div>

                                <div class="mt-4">
                  <label class="block text-sm font-medium text-gray-700 mb-1">Volltext *</label>
                  <textarea
                    name="document[volltext]"
                    rows="4"
                    required
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                    placeholder="Volltext des Dokuments..."><%= document["volltext"] || "" %></textarea>
                </div>

                                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Kurztitel</label>
                    <input
                      type="text"
                      name="document[kurztitel]"
                      value={document["kurztitel"] || ""}
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                      placeholder="Kurzer, griffiger Titel">
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Drucksachennummer</label>
                    <input
                      type="text"
                      name="document[drucksnr]"
                      value={document["drucksnr"] || ""}
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                      placeholder="z.B. BT-Drs. 20/12345">
                  </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Modifiziert *</label>
                    <input
                      type="datetime-local"
                      name="document[zp_modifiziert]"
                      value={format_datetime_for_input(document["zp_modifiziert"])}
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm">
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Referenz *</label>
                    <input
                      type="datetime-local"
                      name="document[zp_referenz]"
                      value={format_datetime_for_input(document["zp_referenz"])}
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm">
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Erstellt</label>
                    <input
                      type="datetime-local"
                      name="document[zp_erstellt]"
                      value={format_datetime_for_input(document["zp_erstellt"])}
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm">
                  </div>
                </div>

                <div class="mt-4">
                  <label class="block text-sm font-medium text-gray-700 mb-1">Zusammenfassung</label>
                  <textarea
                    name="document[zusammenfassung]"
                    rows="2"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                    placeholder="Kurze Zusammenfassung..."><%= document["zusammenfassung"] || "" %></textarea>
                </div>

                <div class="mt-4">
                  <label class="block text-sm font-medium text-gray-700 mb-1">Vorwort</label>
                  <textarea
                    name="document[vorwort]"
                    rows="3"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                    placeholder="Präambel oder Vorwort..."><%= document["vorwort"] || "" %></textarea>
                </div>

                                                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Meinung (1-5)</label>
                    <select
                      name="document[meinung]"
                      value={document["meinung"] || ""}
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm">
                      <option value="">Keine Bewertung</option>
                      <%= for value <- 1..5 do %>
                        <option value={value} selected={document["meinung"] == value}><%= value %></option>
                      <% end %>
                    </select>
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Schlagworte</label>
                    <input
                      type="text"
                      name="document[schlagworte]"
                      value={if document["schlagworte"], do: Enum.join(document["schlagworte"], ", "), else: ""}
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm"
                      placeholder="kommagetrennt, lowercase">
                  </div>
                </div>

              </form>

              <!-- Autoren Section (standalone form) -->
              <div class="mt-4">
                <div class="flex justify-between items-center mb-3">
                  <label class="block text-sm font-medium text-gray-700">Autoren</label>
                  <button
                    type="button"
                    phx-click="add_autor"
                    phx-value-station-index={@station_index}
                    phx-value-document-index={document_index}
                    phx-value-document-type={@document_type}
                    class="inline-flex items-center px-2 py-1 text-xs font-medium text-white bg-green-600 border border-transparent rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-all duration-200 shadow-sm">
                    <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                    </svg>
                    Hinzufügen
                  </button>
                </div>

                <%= if Map.get(@adding_autor || %{}, "#{@station_index}-#{document_index}") do %>
                  <form phx-submit="save_new_autor"
                        phx-value-station-index={@station_index}
                        phx-value-document-index={document_index}
                        phx-value-document-type={@document_type}
                        class="space-y-3 bg-gray-50 p-3 rounded-lg border border-gray-200 mb-3">
                    <div class="grid grid-cols-1 gap-2">
                      <input type="text" name="person" placeholder="Person" class="px-2 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm">
                      <input type="text" name="organisation" placeholder="Organisation *" required class="px-2 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm">
                      <input type="text" name="fachgebiet" placeholder="Fachgebiet" class="px-2 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm">
                      <input type="url" name="lobbyregister" placeholder="Lobbyregister Link" class="px-2 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 text-sm">
                    </div>
                    <div class="flex gap-2">
                      <button type="submit" class="inline-flex items-center px-2 py-1 text-xs font-medium text-white bg-indigo-600 border border-transparent rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all duration-200 shadow-sm">
                        <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                        </svg>
                        OK
                      </button>
                      <button type="button" phx-click="cancel_add_autor" phx-value-station-index={@station_index} phx-value-document-index={document_index} phx-value-document-type={@document_type} class="inline-flex items-center px-2 py-1 text-xs font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all duration-200 shadow-sm">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                      </button>
                    </div>
                  </form>
                <% end %>

                <div class="space-y-2">
                  <%= for {autor, autor_index} <- Enum.with_index(document["autoren"] || []) do %>
                    <div class="p-3 bg-gray-50 rounded-md border border-gray-200">
                      <div class="flex justify-between items-start">
                        <div class="space-y-1">
                          <%= if autor["person"] && autor["person"] != "" do %>
                            <div class="flex items-center space-x-2">
                              <span class="text-xs font-medium text-gray-700">Person:</span>
                              <span class="text-xs text-gray-900"><%= autor["person"] %></span>
                            </div>
                          <% end %>
                          <%= if autor["organisation"] && autor["organisation"] != "" do %>
                            <div class="flex items-center space-x-2">
                              <span class="text-xs font-medium text-gray-700">Organisation:</span>
                              <span class="text-xs text-gray-900"><%= autor["organisation"] %></span>
                            </div>
                          <% end %>
                          <%= if autor["fachgebiet"] && autor["fachgebiet"] != "" do %>
                            <div class="flex items-center space-x-2">
                              <span class="text-xs font-medium text-gray-700">Fachgebiet:</span>
                              <span class="text-xs text-gray-900"><%= autor["fachgebiet"] %></span>
                            </div>
                          <% end %>
                          <%= if autor["lobbyregister"] && autor["lobbyregister"] != "" do %>
                            <div class="flex items-center space-x-2">
                              <span class="text-xs font-medium text-gray-700">Lobbyregister:</span>
                              <a href={autor["lobbyregister"]} target="_blank" class="text-xs text-indigo-600 hover:text-indigo-900 hover:underline"><%= autor["lobbyregister"] %></a>
                            </div>
                          <% end %>
                        </div>
                        <button
                          phx-click="remove_autor"
                          phx-value-station-index={@station_index}
                          phx-value-document-index={document_index}
                          phx-value-document-type={@document_type}
                          phx-value-autor-index={autor_index}
                          class="inline-flex items-center px-1 py-1 text-xs font-medium text-red-700 bg-red-100 border border-transparent rounded-md hover:bg-red-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 transition-all duration-200">
                          <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                          </svg>
                        </button>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
