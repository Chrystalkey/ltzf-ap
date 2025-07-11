defmodule LtzfApWeb.VorgangDetailLive do
  use LtzfApWeb, :live_view
  import LtzfApWeb.SharedHeader
  import LtzfApWeb.SharedLiveHelpers
  import LtzfApWeb.EditFieldComponent
  import LtzfApWeb.TemplateHelpers

  def mount(%{"id" => vorgang_id}, _session, socket) do
    socket = assign(socket,
      vorgang_id: vorgang_id,
      vorgang: nil,
      original_vorgang: nil,
      loading: true,
      error: nil,
      session_id: nil,
      auth_info: %{scope: "unknown"},
      session_data: %{expires_at: DateTime.utc_now()},
      backend_url: nil,
      edit_history: [],
      current_edit_index: -1,
      session_restored: false,
      vgidtypen: [],  # Add vgidtypen enumeration values
      vorgangstypen: [],  # Add vorgangstypen enumeration values
      editing_initiator: nil,
      editing_link: nil,
      editing_field: nil,
      editing_id: nil,
      editing_page_title: nil,
      adding_id: nil,
      adding_link: nil,
      adding_initiator: nil,
      adding_lobbyregister: nil
    )

    # Trigger client-side session restoration only if not already restored
    {:ok, push_event(socket, "restore_session", %{})}
  end

  def handle_event("session_restored", %{"credentials" => credentials}, socket) do
    # Prevent multiple session restorations
    if socket.assigns.session_restored do
      {:noreply, socket}
    else
      # Client has restored session, initialize data
      socket = assign(socket,
        backend_url: credentials["backend_url"],
        auth_info: %{scope: credentials["scope"]},
        session_data: %{expires_at: credentials["expires_at"]},
        session_id: "restored",
        session_restored: true
      )

      # Load enumerations and vorgang data
      send(self(), :load_vgidtypen)
      send(self(), :load_vorgangstypen)
      send(self(), :load_vorgang)
      {:noreply, socket}
    end
  end

  def handle_event("session_expired", _params, socket) do
    {:noreply, redirect(socket, to: ~p"/login")}
  end

  def handle_event("logout", _params, socket) do
    {:noreply,
     socket
     |> push_event("logout", %{})
     |> redirect(to: ~p"/login")}
  end

  def handle_event("load_vorgang", _params, socket) do
    {:noreply,
     socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "getVorgangById",
       params: %{id: socket.assigns.vorgang_id},
       request_id: "vorgang_load"
     })}
  end

  def handle_event("api_response", %{"request_id" => "vorgang_load", "result" => result}, socket) do
    vorgang = ensure_vorgang_fields(result)
    socket = assign(socket,
      vorgang: vorgang,
      original_vorgang: deep_copy(vorgang),
      loading: false,
      error: nil,
      edit_history: [],
      current_edit_index: -1
    )
    {:noreply, socket}
  end

  def handle_event("api_error", %{"request_id" => "vorgang_load", "error" => error}, socket) do
    {:noreply, assign(socket, vorgang: nil, loading: false, error: error)}
  end

  def handle_event("api_response", %{"request_id" => "vorgang_update", "result" => result}, socket) do
    # Update successful, update the original vorgang
    socket = assign(socket,
      original_vorgang: deep_copy(socket.assigns.vorgang),
      edit_history: [],
      current_edit_index: -1
    )
    {:noreply, socket}
  end

  def handle_event("api_error", %{"request_id" => "vorgang_update", "error" => error}, socket) do
    {:noreply, assign(socket, error: error)}
  end

  def handle_event("field_change", %{"field" => field, "value" => value}, socket) do
    # Create a new edit state
    new_vorgang = update_field(socket.assigns.vorgang, field, value)
    edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

    socket = assign(socket,
      vorgang: new_vorgang,
      edit_history: edit_history,
      current_edit_index: length(edit_history) - 1
    )
    {:noreply, socket}
  end

    def handle_event("id_field_change", %{"index" => index, "field" => field, "value" => value}, socket) do
    # Parse index to integer
    index = String.to_integer(index)

    # Update the specific ID field
    new_vorgang = update_id_field(socket.assigns.vorgang, index, field, value)
    edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

    socket = assign(socket,
      vorgang: new_vorgang,
      edit_history: edit_history,
      current_edit_index: length(edit_history) - 1
    )
    {:noreply, socket}
  end

  def handle_event("edit_initiator_field", %{"index" => index, "field" => field}, socket) do
    # Parse index to integer
    index = String.to_integer(index)

    # Get current value
    initiators = socket.assigns.vorgang["initiatoren"] || []
    current_value = if index < length(initiators) do
      Map.get(Enum.at(initiators, index), field, "")
    else
      ""
    end

    # Set editing state
    socket = assign(socket,
      editing_initiator: %{index: index, field: field, value: current_value}
    )
    {:noreply, socket}
  end

  def handle_event("save_initiator_field", %{"value" => value}, socket) do
    editing = socket.assigns.editing_initiator

    if editing do
      # Update the specific initiator field
      new_vorgang = update_initiator_field(socket.assigns.vorgang, editing.index, editing.field, value)
      edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

      socket = assign(socket,
        vorgang: new_vorgang,
        edit_history: edit_history,
        current_edit_index: length(edit_history) - 1,
        editing_initiator: nil
      )
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_initiator_edit", _params, socket) do
    {:noreply, assign(socket, editing_initiator: nil)}
  end

  def handle_event("edit_link", %{"index" => index}, socket) do
    # Parse index to integer
    index = String.to_integer(index)

    # Get current value
    links = socket.assigns.vorgang["links"] || []
    current_value = if index < length(links) do
      Enum.at(links, index)
    else
      ""
    end

    # Set editing state
    socket = assign(socket,
      editing_link: %{index: index, value: current_value}
    )
    {:noreply, socket}
  end

  def handle_event("save_link", %{"value" => value}, socket) do
    editing = socket.assigns.editing_link

    if editing do
      # Update the specific link
      new_vorgang = update_link(socket.assigns.vorgang, editing.index, value)
      edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

      socket = assign(socket,
        vorgang: new_vorgang,
        edit_history: edit_history,
        current_edit_index: length(edit_history) - 1,
        editing_link: nil
      )
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_link_edit", _params, socket) do
    {:noreply, assign(socket, editing_link: nil)}
  end

  def handle_event("edit_field", %{"field" => field}, socket) do
    # Get current value
    current_value = Map.get(socket.assigns.vorgang, field, "")

    # Set editing state
    socket = assign(socket,
      editing_field: %{field: field, value: current_value}
    )
    {:noreply, socket}
  end

  def handle_event("save_field", %{"value" => value}, socket) do
    editing = socket.assigns.editing_field

    if editing do
      # Update the specific field
      new_vorgang = update_field(socket.assigns.vorgang, editing.field, value)
      edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

      socket = assign(socket,
        vorgang: new_vorgang,
        edit_history: edit_history,
        current_edit_index: length(edit_history) - 1,
        editing_field: nil
      )
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_field_edit", _params, socket) do
    {:noreply, assign(socket, editing_field: nil)}
  end

  def handle_event("edit_id_field", %{"index" => index}, socket) do
    # Parse index to integer
    index = String.to_integer(index)

    # Get current value
    ids = socket.assigns.vorgang["ids"] || []
    current_value = if index < length(ids) do
      Map.get(Enum.at(ids, index), "id", "")
    else
      ""
    end

    # Set editing state
    socket = assign(socket,
      editing_id: %{index: index, value: current_value}
    )
    {:noreply, socket}
  end

  def handle_event("save_id_field", %{"value" => value}, socket) do
    editing = socket.assigns.editing_id

    if editing do
      # Update the specific ID field
      new_vorgang = update_id_field(socket.assigns.vorgang, editing.index, "id", value)
      edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

      socket = assign(socket,
        vorgang: new_vorgang,
        edit_history: edit_history,
        current_edit_index: length(edit_history) - 1,
        editing_id: nil
      )
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_id_edit", _params, socket) do
    {:noreply, assign(socket, editing_id: nil)}
  end

  # Add new ID
  def handle_event("add_id", _params, socket) do
    socket = assign(socket, adding_id: %{typ: "", id: ""})
    {:noreply, socket}
  end

    def handle_event("save_new_id", %{"typ" => typ, "id" => id}, socket) do
    if typ != "" and id != "" do
      # Add new ID to the list
      new_vorgang = add_id(socket.assigns.vorgang, %{"typ" => typ, "id" => id})
      edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]
      socket = assign(socket,
        vorgang: new_vorgang,
        edit_history: edit_history,
        current_edit_index: length(edit_history) - 1,
        adding_id: nil
      )
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_add_id", _params, socket) do
    {:noreply, assign(socket, adding_id: nil)}
  end

  # Add new link
  def handle_event("add_link", _params, socket) do
    socket = assign(socket, adding_link: %{value: ""})
    {:noreply, socket}
  end

    def handle_event("save_new_link", %{"value" => value}, socket) do
    if value != "" do
      # Add new link to the list
      new_vorgang = add_link(socket.assigns.vorgang, value)
      edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

      socket = assign(socket,
        vorgang: new_vorgang,
        edit_history: edit_history,
        current_edit_index: length(edit_history) - 1,
        adding_link: nil
      )
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_add_link", _params, socket) do
    {:noreply, assign(socket, adding_link: nil)}
  end

  # Add new initiator
  def handle_event("add_initiator", _params, socket) do
    socket = assign(socket, adding_initiator: %{person: "", organisation: "", fachgebiet: ""})
    {:noreply, socket}
  end

    def handle_event("save_new_initiator", %{"person" => person, "organisation" => organisation, "fachgebiet" => fachgebiet}, socket) do
    if organisation != "" do
      # Add new initiator to the list
      new_vorgang = add_initiator(socket.assigns.vorgang, %{
        "person" => person,
        "organisation" => organisation,
        "fachgebiet" => fachgebiet
      })
      edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

      socket = assign(socket,
        vorgang: new_vorgang,
        edit_history: edit_history,
        current_edit_index: length(edit_history) - 1,
        adding_initiator: nil
      )
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_add_initiator", _params, socket) do
    {:noreply, assign(socket, adding_initiator: nil)}
  end

  # Add new lobbyregister entry
  def handle_event("add_lobbyregister", _params, socket) do
    socket = assign(socket, adding_lobbyregister: %{
      person: "",
      organisation: "",
      fachgebiet: "",
      interne_id: "",
      intention: "",
      link: "",
      betroffene_drucksachen: ""
    })
    {:noreply, socket}
  end

  def handle_event("save_new_lobbyregister", params, socket) do
    if params["organisation"] != "" and params["interne_id"] != "" and params["intention"] != "" and params["link"] != "" do
      # Parse betroffene_drucksachen from comma-separated string
      betroffene_drucksachen = if params["betroffene_drucksachen"] != "" do
        String.split(params["betroffene_drucksachen"], ",")
        |> Enum.map(&String.trim/1)
        |> Enum.filter(&(&1 != ""))
      else
        []
      end

      # Add new lobbyregister entry to the list
      new_vorgang = add_lobbyregister(socket.assigns.vorgang, %{
        "organisation" => %{
          "person" => params["person"],
          "organisation" => params["organisation"],
          "fachgebiet" => params["fachgebiet"]
        },
        "interne_id" => params["interne_id"],
        "intention" => params["intention"],
        "link" => params["link"],
        "betroffene_drucksachen" => betroffene_drucksachen
      })
      edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

      socket = assign(socket,
        vorgang: new_vorgang,
        edit_history: edit_history,
        current_edit_index: length(edit_history) - 1,
        adding_lobbyregister: nil
      )
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_add_lobbyregister", _params, socket) do
    {:noreply, assign(socket, adding_lobbyregister: nil)}
  end

  def handle_event("edit_page_title", _params, socket) do
    # Get current value
    current_value = Map.get(socket.assigns.vorgang, "titel", "")

    # Set editing state
    socket = assign(socket,
      editing_page_title: %{value: current_value}
    )
    {:noreply, socket}
  end

  def handle_event("save_page_title", %{"value" => value}, socket) do
    editing = socket.assigns.editing_page_title

    if editing do
      # Update the titel field
      new_vorgang = update_field(socket.assigns.vorgang, "titel", value)
      edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

      socket = assign(socket,
        vorgang: new_vorgang,
        edit_history: edit_history,
        current_edit_index: length(edit_history) - 1,
        editing_page_title: nil
      )
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_page_title_edit", _params, socket) do
    {:noreply, assign(socket, editing_page_title: nil)}
  end

  def handle_event("undo", _params, socket) do
    case socket.assigns.current_edit_index do
      -1 -> {:noreply, socket} # Nothing to undo
      index when index > 0 ->
        previous_state = Enum.at(socket.assigns.edit_history, index - 1)
        socket = assign(socket,
          vorgang: previous_state,
          current_edit_index: index - 1
        )
        {:noreply, socket}
      _ -> # index == 0, go back to original
        socket = assign(socket,
          vorgang: deep_copy(socket.assigns.original_vorgang),
          current_edit_index: -1
        )
        {:noreply, socket}
    end
  end

  def handle_event("reset", _params, socket) do
    socket = assign(socket,
      vorgang: deep_copy(socket.assigns.original_vorgang),
      edit_history: [],
      current_edit_index: -1,
      error: nil
    )
    {:noreply, socket}
  end

  def handle_event("submit", _params, socket) do
    {:noreply,
     socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "putVorgangById",
       params: %{
         id: socket.assigns.vorgang_id,
         data: socket.assigns.vorgang
       },
       request_id: "vorgang_update"
     })}
  end

  def handle_info(:load_vorgang, socket) do
    {:noreply,
     socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "getVorgangById",
       params: %{id: socket.assigns.vorgang_id},
       request_id: "vorgang_load"
     })}
  end

  def handle_info(:load_vgidtypen, socket) do
    {:noreply,
     socket
     |> push_event("api_request", %{
       method: "getEnumerations",
       params: %{enumName: "vgidtypen"},
       request_id: "vgidtypen_load"
     })}
  end

  def handle_info(:load_vorgangstypen, socket) do
    {:noreply,
     socket
     |> push_event("api_request", %{
       method: "getEnumerations",
       params: %{enumName: "vorgangstypen"},
       request_id: "vorgangstypen_load"
     })}
  end

  def handle_event("api_response", %{"request_id" => "vgidtypen_load", "result" => result}, socket) do
    vgidtypen = case result do
      data when is_list(data) -> data
      _ -> []
    end
    {:noreply, assign(socket, vgidtypen: vgidtypen)}
  end

  def handle_event("api_response", %{"request_id" => "vorgangstypen_load", "result" => result}, socket) do
    vorgangstypen = case result do
      data when is_list(data) -> data
      _ -> []
    end
    {:noreply, assign(socket, vorgangstypen: vorgangstypen)}
  end

  def handle_event("api_error", %{"request_id" => "vgidtypen_load", "error" => error}, socket) do
    # Log the error but don't fail the page - use fallback values from OpenAPI spec
    IO.puts("Failed to load vgidtypen: #{error}")
    fallback_vgidtypen = ["initdrucks", "vorgnr", "api-id", "sonstig"]
    {:noreply, assign(socket, vgidtypen: fallback_vgidtypen)}
  end

  def handle_event("api_error", %{"request_id" => "vorgangstypen_load", "error" => error}, socket) do
    # Log the error but don't fail the page - use fallback values from OpenAPI spec
    IO.puts("Failed to load vorgangstypen: #{error}")
    fallback_vorgangstypen = ["gg-einspruch", "gg-zustimmung", "gg-land-parl", "gg-land-volk", "bw-einsatz", "sonstig"]
    {:noreply, assign(socket, vorgangstypen: fallback_vorgangstypen)}
  end

  # Catch-all for any other API errors
  def handle_event("api_error", %{"request_id" => request_id, "error" => error}, socket) do
    IO.puts("Unhandled API error for request #{request_id}: #{error}")
    {:noreply, socket}
  end

  # Helper functions
  defp ensure_vorgang_fields(vorgang) when is_map(vorgang) do
    vorgang
    |> Map.put_new("ids", [])
    |> Map.put_new("initiatoren", [])
    |> Map.put_new("links", [])
    |> Map.put_new("lobbyregister", [])
    |> Map.put_new("stationen", [])
    |> Map.put_new("touched_by", [])
  end
  defp ensure_vorgang_fields(vorgang), do: vorgang

  defp deep_copy(data) when is_map(data) do
    Map.new(data, fn {k, v} -> {k, deep_copy(v)} end)
  end
  defp deep_copy(data) when is_list(data) do
    Enum.map(data, &deep_copy/1)
  end
  defp deep_copy(data), do: data

  defp update_field(vorgang, field, value) do
    case field do
      "titel" -> Map.put(vorgang, "titel", value)
      "kurztitel" -> Map.put(vorgang, "kurztitel", value)
      "wahlperiode" -> Map.put(vorgang, "wahlperiode", String.to_integer(value))
      "verfassungsaendernd" -> Map.put(vorgang, "verfassungsaendernd", value == "true")
      "typ" -> Map.put(vorgang, "typ", value)
      _ -> vorgang
    end
  end

    defp update_id_field(vorgang, index, field, value) do
    ids = vorgang["ids"] || []

    # Ensure the index is valid
    if index >= 0 and index < length(ids) do
      # Update the specific ID at the given index
      updated_ids = List.update_at(ids, index, fn id ->
        Map.put(id, field, value)
      end)

      Map.put(vorgang, "ids", updated_ids)
    else
      vorgang
    end
  end

  defp update_initiator_field(vorgang, index, field, value) do
    initiators = vorgang["initiatoren"] || []

    # Ensure the index is valid
    if index >= 0 and index < length(initiators) do
      # Update the specific initiator at the given index
      updated_initiators = List.update_at(initiators, index, fn initiator ->
        Map.put(initiator, field, value)
      end)

      Map.put(vorgang, "initiatoren", updated_initiators)
    else
      vorgang
    end
  end

  defp update_link(vorgang, index, value) do
    links = vorgang["links"] || []

    # Ensure the index is valid
    if index >= 0 and index < length(links) do
      # Update the specific link at the given index
      updated_links = List.update_at(links, index, fn _link -> value end)

      Map.put(vorgang, "links", updated_links)
    else
      vorgang
    end
  end

  # Add new entries
  defp add_id(vorgang, new_id) do
    ids = vorgang["ids"] || []
    Map.put(vorgang, "ids", ids ++ [new_id])
  end

  defp add_link(vorgang, new_link) do
    links = vorgang["links"] || []
    Map.put(vorgang, "links", links ++ [new_link])
  end

  defp add_initiator(vorgang, new_initiator) do
    initiators = vorgang["initiatoren"] || []
    Map.put(vorgang, "initiatoren", initiators ++ [new_initiator])
  end

  defp add_lobbyregister(vorgang, new_entry) do
    lobbyregister = vorgang["lobbyregister"] || []
    Map.put(vorgang, "lobbyregister", lobbyregister ++ [new_entry])
  end

  def has_changes(socket) do
    try do
      vorgang = Map.get(socket.assigns, :vorgang)
      original_vorgang = Map.get(socket.assigns, :original_vorgang)

      case {vorgang, original_vorgang} do
        {nil, _} -> false
        {_, nil} -> false
        {v, o} -> v != o
      end
    rescue
      _ -> false
    end
  end

  def can_undo(socket) do
    try do
      current_edit_index = Map.get(socket.assigns, :current_edit_index, -1)
      current_edit_index >= 0
    rescue
      _ -> false
    end
  end

  def format_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _} -> Calendar.strftime(datetime, "%d.%m.%Y %H:%M")
      _ -> date_string
    end
  end
  def format_date(_), do: "N/A"

  def get_vorgangstyp_label("gg-einspruch"), do: "Bundesgesetz Einspruch"
  def get_vorgangstyp_label("gg-zustimmung"), do: "Bundesgesetz Zustimmungspflichtig"
  def get_vorgangstyp_label("gg-land-parl"), do: "Landesgesetz (normal)"
  def get_vorgangstyp_label("gg-land-volk"), do: "Landesgesetz (Volksgesetzgebung)"
  def get_vorgangstyp_label("bw-einsatz"), do: "Bundeswehreinsatz"
  def get_vorgangstyp_label("sonstig"), do: "Sonstiges"
  def get_vorgangstyp_label(typ) when is_binary(typ), do: String.capitalize(typ)
  def get_vorgangstyp_label(_), do: "Unbekannt"

  def get_stationstyp_label("preparl-regent"), do: "Referentenentwurf / Regierungsentwurf"
  def get_stationstyp_label("preparl-eckpup"), do: "Eckpunktepapier / Parlamentsentwurf"
  def get_stationstyp_label("preparl-regbsl"), do: "Kabinettsbeschluss / Regierungsbeschluss"
  def get_stationstyp_label("preparl-vbegde"), do: "Volksbegehren / Diskussionsentwurf"
  def get_stationstyp_label("parl-initiativ"), do: "Gesetzesinitiative"
  def get_stationstyp_label("parl-ausschber"), do: "Beratung im Ausschuss"
  def get_stationstyp_label("parl-vollvlsgn"), do: "Vollversammlung / Lesung"
  def get_stationstyp_label("parl-akzeptanz"), do: "Schlussabstimmung & Akzeptanz"
  def get_stationstyp_label("parl-ablehnung"), do: "Schlussabstimmung & Ablehnung"
  def get_stationstyp_label("parl-zurueckgz"), do: "Plenarsitzung & Rückzug"
  def get_stationstyp_label("parl-ggentwurf"), do: "Gegenentwurf des Parlaments"
  def get_stationstyp_label("postparl-vesja"), do: "Volksentscheid nach Akzeptanz"
  def get_stationstyp_label("postparl-vesne"), do: "Volksentscheid nach Ablehnung"
  def get_stationstyp_label("postparl-gsblt"), do: "Veröffentlichung im Gesetzesblatt"
  def get_stationstyp_label("postparl-kraft"), do: "In Kraft getreten"
  def get_stationstyp_label("sonstig"), do: "Sonstiges"
  def get_stationstyp_label(typ) when is_binary(typ), do: String.capitalize(typ)
  def get_stationstyp_label(_), do: "Unbekannt"

  def get_parlament_label("BT"), do: "Bundestag"
  def get_parlament_label("BR"), do: "Bundesrat"
  def get_parlament_label("BV"), do: "Bundesversammlung"
  def get_parlament_label("EK"), do: "Europakammer des Bundesrats"
  def get_parlament_label("BB"), do: "Brandenburg"
  def get_parlament_label("BY"), do: "Bayern"
  def get_parlament_label("BE"), do: "Berlin"
  def get_parlament_label("HB"), do: "Hansestadt Bremen"
  def get_parlament_label("HH"), do: "Hansestadt Hamburg"
  def get_parlament_label("HE"), do: "Hessen"
  def get_parlament_label("MV"), do: "Mecklenburg-Vorpommern"
  def get_parlament_label("NI"), do: "Niedersachsen"
  def get_parlament_label("NW"), do: "Nordrhein-Westfalen"
  def get_parlament_label("RP"), do: "Rheinland-Pfalz"
  def get_parlament_label("SL"), do: "Saarland"
  def get_parlament_label("SN"), do: "Sachsen"
  def get_parlament_label("TH"), do: "Thüringen"
  def get_parlament_label("SH"), do: "Schleswig-Holstein"
  def get_parlament_label("BW"), do: "Baden-Württemberg"
  def get_parlament_label("ST"), do: "Sachsen-Anhalt"
  def get_parlament_label(parlament) when is_binary(parlament), do: parlament
  def get_parlament_label(_), do: "Unbekannt"
end
