defmodule LtzfApWeb.VorgangDetailLive do
  @moduledoc """
  LiveView for editing legislative processes (Vorgänge) with structured types
  and better state management based on the OpenAPI specification.
  """

  use LtzfApWeb, :live_view
  require Logger

  import LtzfApWeb.SharedHeader
  import LtzfApWeb.DocumentComponent

  alias LtzfAp.{Schemas, FormHelpers, State}

  @doc """
  Mounts the LiveView with structured state initialization.
  """
  def mount(%{"id" => vorgang_id}, _session, socket) do
    state = State.new_vorgang_detail_state(vorgang_id)

    socket = assign(socket, Map.from_struct(state))

    # Trigger client-side session restoration
    {:ok, push_event(socket, "restore_session", %{})}
  end

  # ============================================================================
  # SESSION MANAGEMENT EVENTS
  # ============================================================================

  def handle_event("session_restored", credentials, socket) do
    state = State.update_session(socket.assigns, credentials)
    socket = assign(socket, Map.from_struct(state))

    # Load vorgang data
    socket = load_vorgang(socket)
    {:noreply, socket}
  end

  def handle_event("session_expired", %{"error" => error}, socket) do
    # Redirect to login page instead of showing error
    {:noreply, push_redirect(socket, to: ~p"/login")}
  end

  def handle_event("session_expired", _params, socket) do
    # Redirect to login page instead of showing error
    {:noreply, push_redirect(socket, to: ~p"/login")}
  end

  # ============================================================================
  # API RESPONSE HANDLERS
  # ============================================================================

  def handle_event("api_response", %{"request_id" => "vorgang_load", "result" => result}, socket) do
    # API result is already a map with string keys, use it directly
    state = State.update_vorgang(socket.assigns, result)
    socket = assign(socket, Map.from_struct(state))

    # Extract document IDs and fetch documents
    socket = load_documents_from_vorgang(socket)
    {:noreply, socket}
  end

  def handle_event("api_response", %{"request_id" => "vorgang_update", "result" => _result}, socket) do
    # Update successful, update the original vorgang and clear saving state
    state = socket.assigns
    |> State.set_save_success(true)
    |> Map.put(:original_vorgang, deep_copy_vorgang(socket.assigns.vorgang))

    socket = assign(socket, Map.from_struct(state))

    # Clear success message after 3 seconds
    Process.send_after(self(), :clear_save_success, 3000)
    {:noreply, socket}
  end

  def handle_event("api_response", %{"request_id" => "vorgang_update", "error" => error}, socket) do
    state = State.set_save_success(socket.assigns, false)
    |> State.set_error("Speichern fehlgeschlagen: #{error}")

    socket = assign(socket, Map.from_struct(state))
    {:noreply, socket}
  end

  def handle_event("api_response", %{"request_id" => "enumerations_load", "result" => result}, socket) do
    state = State.update_enumerations(socket.assigns, result)
    socket = assign(socket, Map.from_struct(state))
    {:noreply, socket}
  end

  def handle_event("api_response", %{"request_id" => request_id, "result" => result}, socket) do
    # Handle document loading responses
    if String.starts_with?(request_id, "document_load_") do
      document_id = String.replace(request_id, "document_load_", "")
      socket = handle_document_loaded(socket, document_id, result)
      {:noreply, socket}
    else
      # Handle other API responses
      state = State.set_error(socket.assigns, "Unknown request_id: #{request_id}")
      socket = assign(socket, Map.from_struct(state))
      {:noreply, socket}
    end
  end

  def handle_event("api_response", %{"request_id" => _request_id, "error" => error}, socket) do
    state = State.set_error(socket.assigns, error)
    socket = assign(socket, Map.from_struct(state))
    {:noreply, socket}
  end

  # ============================================================================
  # FORM CHANGE HANDLERS
  # ============================================================================

  def handle_event("form_change", %{"vorgang" => vorgang_params}, socket) do
    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

    # Convert form params to structured vorgang object
    new_vorgang = FormHelpers.form_params_to_vorgang(vorgang_params, socket.assigns.vorgang)

    # Validate the vorgang before updating
    case FormHelpers.validate_vorgang(new_vorgang) do
      :ok ->
        socket = assign_vorgang(socket, new_vorgang)
        {:noreply, socket}

      {:error, _errors} ->
        # In a real application, you might want to show validation errors
        # For now, we'll just update the vorgang and let the backend handle validation
        socket = assign_vorgang(socket, new_vorgang)
        {:noreply, socket}
    end
  end



  def handle_event("form_change", params, socket) do
    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

    new_vorgang = socket.assigns.vorgang

    # Handle vorgang params
    if Map.has_key?(params, "vorgang") do
      new_vorgang = FormHelpers.form_params_to_vorgang(params["vorgang"], new_vorgang)
    end

    # Handle station params
    if Map.has_key?(params, "station") do
      new_vorgang = update_stations_from_params(new_vorgang, params["station"])
    end

    socket = assign_vorgang(socket, new_vorgang)
    {:noreply, socket}
  end

  # ============================================================================
  # ACTION HANDLERS
  # ============================================================================

  def handle_event("save", _params, socket) do
    case FormHelpers.validate_vorgang(socket.assigns.vorgang) do
      :ok ->
        socket |> assign(Map.from_struct(State.set_saving(socket.assigns, true))) |> update_vorgang() |> then(&{:noreply, &1})
      {:error, errors} ->
        socket |> assign(Map.from_struct(State.set_error(socket.assigns, "Validation failed: #{Enum.join(errors, ", ")}"))) |> then(&{:noreply, &1})
    end
  end

  def handle_event("undo", _params, socket) do
    case State.pop_from_history(socket.assigns) do
      {new_state, nil} ->
        # No history available, do nothing
        {:noreply, socket}
      {new_state, previous_vorgang} ->
        # Restore the previous state
        socket = assign(socket, Map.from_struct(new_state))
        socket = assign_vorgang(socket, previous_vorgang)
        {:noreply, socket}
    end
  end

  def handle_event("reset", _params, socket) do
    # Redirect to the same page to trigger a page reload
    {:noreply, push_redirect(socket, to: ~p"/vorgaenge/#{socket.assigns.vorgang_id}")}
  end

  # ============================================================================
  # ADD ITEM HANDLERS
  # ============================================================================

  def handle_event("add_id", _params, socket) do
    socket = assign(socket, adding_id: %{typ: "", id: ""})
    {:noreply, socket}
  end

  def handle_event("add_link", _params, socket) do
    socket = assign(socket, adding_link: %{value: ""})
    {:noreply, socket}
  end

  def handle_event("save_new_link", %{"value" => value}, socket) do
    if value != "" do
      # Save current state to history before making changes
      socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

      new_vorgang = add_link(socket.assigns.vorgang, value)
      socket = assign_vorgang(socket, new_vorgang)
      socket = assign(socket, adding_link: nil)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("save_new_id", %{"typ" => typ, "id_value" => id}, socket) do
    if typ != "" and id != "" do
      # Validate the vg_ident_typ
      if Schemas.valid_vg_ident_typ?(typ) do
        # Save current state to history before making changes
        socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

        new_vg_ident = FormHelpers.form_params_to_vg_ident(%{"typ" => typ, "id_value" => id})
        new_vorgang = add_id(socket.assigns.vorgang, new_vg_ident)
        socket = assign_vorgang(socket, new_vorgang)
        socket = assign(socket, adding_id: nil)
        {:noreply, socket}
      else
        state = State.set_error(socket.assigns, "Invalid identifier type: #{typ}")
        socket = assign(socket, Map.from_struct(state))
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("add_initiator", _params, socket) do
    socket = assign(socket, adding_initiator: %{person: "", organisation: "", fachgebiet: ""})
    {:noreply, socket}
  end

  def handle_event("save_new_initiator", params, socket) do
    if params["organisation"] != "" do
      new_autor = FormHelpers.form_params_to_autor(params)

      # Validate the autor
      case FormHelpers.validate_autor(new_autor) do
        :ok ->
          # Save current state to history before making changes
          socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

          new_vorgang = add_initiator(socket.assigns.vorgang, new_autor)
          socket = assign_vorgang(socket, new_vorgang)
          socket = assign(socket, adding_initiator: nil)
          {:noreply, socket}

        {:error, errors} ->
          error_msg = "Invalid initiator: #{Enum.join(errors, ", ")}"
          state = State.set_error(socket.assigns, error_msg)
          socket = assign(socket, Map.from_struct(state))
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("add_lobbyregister", _params, socket) do
    socket = assign(socket, adding_lobbyregister: %{value: ""})
    {:noreply, socket}
  end

  def handle_event("save_new_lobbyregister", params, socket) do
    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

    new_lobbyregister = FormHelpers.form_params_to_lobbyregister(params) |> Schemas.lobbyregister_to_map()
    new_vorgang = add_lobbyregister(socket.assigns.vorgang, new_lobbyregister)
    socket = assign_vorgang(socket, new_vorgang)
    socket = assign(socket, adding_lobbyregister: nil)
    {:noreply, socket}
  end

  # ============================================================================
  # STATION HANDLERS
  # ============================================================================

  def handle_event("add_station", _params, socket) do
    socket = assign(socket, adding_station: %{
      "titel" => "",
      "typ" => "",
      "zp_start" => "",
      "link" => "",
      "gremium_name" => "",
      "gremium_wahlperiode" => "",
      "gremium_parlament" => "",
      "gremium_link" => "",
      "gremium_federf" => false,
      "trojanergefahr" => 1,
      "schlagworte" => ""
    })
    {:noreply, socket}
  end

  def handle_event("save_new_station", params, socket) do
    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

    new_station = FormHelpers.form_params_to_station(params)

    # Validate the station
    case FormHelpers.validate_station(new_station) do
      :ok ->
        stationen = socket.assigns.vorgang["stationen"] || []
        new_index = length(stationen)
        new_vorgang = Map.put(socket.assigns.vorgang, "stationen", stationen ++ [new_station])

        # Ensure new station starts expanded
        new_collapsed_stations = MapSet.delete(socket.assigns.collapsed_stations, new_index)

        socket = assign_vorgang(socket, new_vorgang)
        socket = assign(socket,
          adding_station: nil,
          new_station_index: new_index,
          collapsed_stations: new_collapsed_stations
        )

        # Clear the highlight after 3 seconds
        Process.send_after(self(), :clear_new_station_highlight, 3000)
        Process.send_after(self(), {:scroll_to_station, new_index}, 100)

        {:noreply, socket}

      {:error, errors} ->
        error_msg = "Invalid station: #{Enum.join(errors, ", ")}"
        state = State.set_error(socket.assigns, error_msg)
        socket = assign(socket, Map.from_struct(state))
        {:noreply, socket}
    end
  end

  def handle_event("toggle_station", %{"index" => index}, socket) do
    index = String.to_integer(index)
    collapsed_stations = socket.assigns.collapsed_stations

    new_collapsed_stations = if MapSet.member?(collapsed_stations, index) do
      MapSet.delete(collapsed_stations, index)
    else
      MapSet.put(collapsed_stations, index)
    end

    socket = assign(socket, collapsed_stations: new_collapsed_stations)
    {:noreply, socket}
  end

  def handle_event("remove_station", %{"index" => index}, socket) do
    index = String.to_integer(index)
    stationen = socket.assigns.vorgang["stationen"] || []
    if index < length(stationen) do
      # Save current state to history before making changes
      socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

      updated_stationen = List.delete_at(stationen, index)
      new_vorgang = Map.put(socket.assigns.vorgang, "stationen", updated_stationen)
      socket = assign_vorgang(socket, new_vorgang)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  # ============================================================================
  # REMOVE ITEM HANDLERS
  # ============================================================================

  def handle_event("remove_id", %{"index" => index}, socket) do
    index = String.to_integer(index)
    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

    new_vorgang = remove_id(socket.assigns.vorgang, index)
    socket = assign_vorgang(socket, new_vorgang)
    {:noreply, socket}
  end

  def handle_event("remove_link", %{"index" => index}, socket) do
    index = String.to_integer(index)
    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

    new_vorgang = remove_link(socket.assigns.vorgang, index)
    socket = assign_vorgang(socket, new_vorgang)
    {:noreply, socket}
  end

  def handle_event("remove_initiator", %{"index" => index}, socket) do
    index = String.to_integer(index)
    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

    new_vorgang = remove_initiator(socket.assigns.vorgang, index)
    socket = assign_vorgang(socket, new_vorgang)
    {:noreply, socket}
  end

  def handle_event("remove_lobbyregister", %{"index" => index}, socket) do
    index = String.to_integer(index)
    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

    new_vorgang = remove_lobbyregister(socket.assigns.vorgang, index)
    socket = assign_vorgang(socket, new_vorgang)
    {:noreply, socket}
  end

  # ============================================================================
  # CANCEL HANDLERS
  # ============================================================================

  def handle_event("cancel_add_id", _params, socket) do
    {:noreply, assign(socket, adding_id: nil)}
  end

  def handle_event("cancel_add_link", _params, socket) do
    {:noreply, assign(socket, adding_link: nil)}
  end

  def handle_event("cancel_add_initiator", _params, socket) do
    {:noreply, assign(socket, adding_initiator: nil)}
  end

  def handle_event("cancel_add_lobbyregister", _params, socket) do
    {:noreply, assign(socket, adding_lobbyregister: nil)}
  end

  def handle_event("cancel_add_station", _params, socket) do
    {:noreply, assign(socket, adding_station: nil)}
  end

  def handle_event("add_additional_link", %{"station-index" => station_index}, socket) do
    station_index = String.to_integer(station_index)
    socket = assign(socket, adding_additional_link: station_index)
    {:noreply, socket}
  end

  def handle_event("save_new_additional_link", %{"station-index" => station_index, "link" => link}, socket) do
    station_index = String.to_integer(station_index)

    if link != "" do
      # Save current state to history before making changes
      socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

      stationen = socket.assigns.vorgang["stationen"] || []
      station = Enum.at(stationen, station_index)
      additional_links = station["additional_links"] || []

      updated_station = Map.put(station, "additional_links", additional_links ++ [link])
      updated_stationen = List.replace_at(stationen, station_index, updated_station)
      new_vorgang = Map.put(socket.assigns.vorgang, "stationen", updated_stationen)

      socket = assign_vorgang(socket, new_vorgang)
      socket = assign(socket, adding_additional_link: nil)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_additional_link", %{"station-index" => station_index, "link-index" => link_index}, socket) do
    station_index = String.to_integer(station_index)
    link_index = String.to_integer(link_index)

    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

    stationen = socket.assigns.vorgang["stationen"] || []
    station = Enum.at(stationen, station_index)
    additional_links = station["additional_links"] || []

    updated_additional_links = List.delete_at(additional_links, link_index)
    updated_station = Map.put(station, "additional_links", updated_additional_links)
    updated_stationen = List.replace_at(stationen, station_index, updated_station)
    new_vorgang = Map.put(socket.assigns.vorgang, "stationen", updated_stationen)

    socket = assign_vorgang(socket, new_vorgang)
    {:noreply, socket}
  end

  def handle_event("cancel_add_additional_link", _params, socket) do
    {:noreply, assign(socket, adding_additional_link: nil)}
  end

  def handle_event("switch_station_tab", %{"station-index" => station_index, "tab" => tab}, socket) do
    station_index = String.to_integer(station_index)
    station_tabs = socket.assigns.station_tabs || %{}
    updated_tabs = Map.put(station_tabs, station_index, tab)
    {:noreply, assign(socket, station_tabs: updated_tabs)}
  end

  # ============================================================================
  # DOCUMENT MANAGEMENT HANDLERS
  # ============================================================================

    def handle_event("add_document", %{"station-index" => station_index, "document-type" => document_type}, socket) do
    station_index = String.to_integer(station_index)

    # Create new document with all required fields according to the OpenAPI spec
    new_document = %{
      "titel" => "",
      "typ" => "",
      "volltext" => "",
      "hash" => "",
      "link" => "",
      "zp_modifiziert" => "",
      "zp_referenz" => "",
      "autoren" => []
    }

    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

    # Add document to the appropriate list in the station
    stationen = socket.assigns.vorgang["stationen"] || []
    station = Enum.at(stationen, station_index)

    updated_station = case document_type do
      "dokumente" ->
        dokumente = station["dokumente"] || []
        Map.put(station, "dokumente", dokumente ++ [new_document])
      "stellungnahmen" ->
        stellungnahmen = station["stellungnahmen"] || []
        Map.put(station, "stellungnahmen", stellungnahmen ++ [new_document])
    end

    updated_stationen = List.replace_at(stationen, station_index, updated_station)
    new_vorgang = Map.put(socket.assigns.vorgang, "stationen", updated_stationen)

    socket = assign_vorgang(socket, new_vorgang)
    {:noreply, socket}
  end

      def handle_event("update_document", %{"station-index" => station_index, "document-index" => document_index, "document-type" => document_type, "document" => document_params}, socket) do
    station_index = String.to_integer(station_index)
    document_index = String.to_integer(document_index)

    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

          # Get the existing document to preserve unchanged fields
      stationen = socket.assigns.vorgang["stationen"] || []
      station = Enum.at(stationen, station_index)

      existing_document = get_document_safely(station, document_type, document_index)

            # Process document params according to OpenAPI spec
    processed_params = FormHelpers.form_params_to_document(document_params)

    # Merge with existing document to preserve unchanged fields
    updated_document = Map.merge(existing_document, processed_params)

    updated_station = case document_type do
      "dokumente" ->
        dokumente = station["dokumente"] || []
        updated_dokumente = List.replace_at(dokumente, document_index, updated_document)
        Map.put(station, "dokumente", updated_dokumente)
      "stellungnahmen" ->
        stellungnahmen = station["stellungnahmen"] || []
        updated_stellungnahmen = List.replace_at(stellungnahmen, document_index, updated_document)
        Map.put(station, "stellungnahmen", updated_stellungnahmen)
    end

    updated_stationen = List.replace_at(stationen, station_index, updated_station)
    new_vorgang = Map.put(socket.assigns.vorgang, "stationen", updated_stationen)

    socket = assign_vorgang(socket, new_vorgang)
    {:noreply, socket}
  end

  def handle_event("remove_document", %{"station-index" => station_index, "document-index" => document_index, "document-type" => document_type}, socket) do
    station_index = String.to_integer(station_index)
    document_index = String.to_integer(document_index)

    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

    # Remove document from the appropriate list
    stationen = socket.assigns.vorgang["stationen"] || []
    station = Enum.at(stationen, station_index)

    updated_station = case document_type do
      "dokumente" ->
        dokumente = station["dokumente"] || []
        updated_dokumente = List.delete_at(dokumente, document_index)
        Map.put(station, "dokumente", updated_dokumente)
      "stellungnahmen" ->
        stellungnahmen = station["stellungnahmen"] || []
        updated_stellungnahmen = List.delete_at(stellungnahmen, document_index)
        Map.put(station, "stellungnahmen", updated_stellungnahmen)
    end

    updated_stationen = List.replace_at(stationen, station_index, updated_station)
    new_vorgang = Map.put(socket.assigns.vorgang, "stationen", updated_stationen)

    socket = assign_vorgang(socket, new_vorgang)
    {:noreply, socket}
  end

  # ============================================================================
  # AUTOREN MANAGEMENT HANDLERS
  # ============================================================================

  def handle_event("add_autor", %{"station-index" => station_index, "document-index" => document_index, "document-type" => document_type}, socket) do
    station_index = String.to_integer(station_index)
    document_index = String.to_integer(document_index)

    # Create a unique key for this station-document combination
    key = "#{station_index}-#{document_index}"

    # Initialize adding_autor state if it doesn't exist
    adding_autor = socket.assigns.adding_autor || %{}
    updated_adding_autor = Map.put(adding_autor, key, true)

    socket = assign(socket, adding_autor: updated_adding_autor)
    {:noreply, socket}
  end

  def handle_event("save_new_autor", %{"station-index" => station_index, "document-index" => document_index, "document-type" => document_type} = params, socket) do
    station_index = String.to_integer(station_index)
    document_index = String.to_integer(document_index)

    # Debug: Log the incoming params
    IO.inspect(params, label: "save_new_autor params")

    if params["organisation"] != "" do
      new_autor_struct = FormHelpers.form_params_to_autor(params)

      # Convert struct to map with string keys
      new_autor = %{
        "person" => new_autor_struct.person,
        "organisation" => new_autor_struct.organisation,
        "fachgebiet" => new_autor_struct.fachgebiet,
        "lobbyregister" => new_autor_struct.lobbyregister
      }

      # Validate the autor
      case FormHelpers.validate_autor(new_autor) do
        :ok ->
          # Save current state to history before making changes
          socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

          # Add autor to the document
          stationen = socket.assigns.vorgang["stationen"] || []
          station = Enum.at(stationen, station_index)

          document = get_document_safely(station, document_type, document_index)

          autoren = document["autoren"] || []
          IO.inspect(autoren, label: "existing autoren")
          updated_autoren = autoren ++ [new_autor]
          IO.inspect(updated_autoren, label: "updated autoren")
          updated_document = Map.put(document, "autoren", updated_autoren)

          updated_station = case document_type do
            "dokumente" ->
              dokumente = station["dokumente"] || []
              updated_dokumente = List.replace_at(dokumente, document_index, updated_document)
              Map.put(station, "dokumente", updated_dokumente)
            "stellungnahmen" ->
              stellungnahmen = station["stellungnahmen"] || []
              updated_stellungnahmen = List.replace_at(stellungnahmen, document_index, updated_document)
              Map.put(station, "stellungnahmen", updated_stellungnahmen)
          end

          updated_stationen = List.replace_at(stationen, station_index, updated_station)
          new_vorgang = Map.put(socket.assigns.vorgang, "stationen", updated_stationen)

          # Clear adding_autor state
          key = "#{station_index}-#{document_index}"
          adding_autor = socket.assigns.adding_autor || %{}
          updated_adding_autor = Map.delete(adding_autor, key)

          socket = assign_vorgang(socket, new_vorgang)
          socket = assign(socket, adding_autor: updated_adding_autor)
          IO.inspect("Autor added successfully", label: "SUCCESS")
          {:noreply, socket}

        {:error, errors} ->
          error_msg = "Invalid autor: #{Enum.join(errors, ", ")}"
          state = State.set_error(socket.assigns, error_msg)
          socket = assign(socket, Map.from_struct(state))
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_autor", %{"station-index" => station_index, "document-index" => document_index, "document-type" => document_type, "autor-index" => autor_index}, socket) do
    station_index = String.to_integer(station_index)
    document_index = String.to_integer(document_index)
    autor_index = String.to_integer(autor_index)

    # Save current state to history before making changes
    socket = assign(socket, Map.from_struct(State.add_to_history(socket.assigns, socket.assigns.vorgang)))

    # Remove autor from the document
    stationen = socket.assigns.vorgang["stationen"] || []
    station = Enum.at(stationen, station_index)

    document = get_document_safely(station, document_type, document_index)

    autoren = document["autoren"] || []
    updated_autoren = List.delete_at(autoren, autor_index)
    updated_document = Map.put(document, "autoren", updated_autoren)

    updated_station = case document_type do
      "dokumente" ->
        dokumente = station["dokumente"] || []
        updated_dokumente = List.replace_at(dokumente, document_index, updated_document)
        Map.put(station, "dokumente", updated_dokumente)
      "stellungnahmen" ->
        stellungnahmen = station["stellungnahmen"] || []
        updated_stellungnahmen = List.replace_at(stellungnahmen, document_index, updated_document)
        Map.put(station, "stellungnahmen", updated_stellungnahmen)
    end

    updated_stationen = List.replace_at(stationen, station_index, updated_station)
    new_vorgang = Map.put(socket.assigns.vorgang, "stationen", updated_stationen)

    socket = assign_vorgang(socket, new_vorgang)
    {:noreply, socket}
  end

  def handle_event("cancel_add_autor", %{"station-index" => station_index, "document-index" => document_index, "document-type" => document_type}, socket) do
    station_index = String.to_integer(station_index)
    document_index = String.to_integer(document_index)

    # Clear adding_autor state
    key = "#{station_index}-#{document_index}"
    adding_autor = socket.assigns.adding_autor || %{}
    updated_adding_autor = Map.delete(adding_autor, key)

    socket = assign(socket, adding_autor: updated_adding_autor)
    {:noreply, socket}
  end

  # ============================================================================
  # INFO HANDLERS
  # ============================================================================

  def handle_info(:clear_new_station_highlight, socket) do
    {:noreply, assign(socket, new_station_index: nil)}
  end

  def handle_info(:clear_save_success, socket) do
    {:noreply, assign(socket, save_success: false)}
  end

  def handle_info({:scroll_to_station, index}, socket) do
    {:noreply, push_event(socket, "scroll_to_station", %{index: index})}
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  # Helper function to assign vorgang (now always a map)
  defp assign_vorgang(socket, vorgang) do
    assign(socket, vorgang: vorgang)
  end

  defp load_vorgang(socket) do
    socket |> load_enumerations() |> push_event("api_request", %{
      method: "getVorgangById",
      params: %{id: socket.assigns.vorgang_id},
      request_id: "vorgang_load"
    })
  end

  defp load_enumerations(socket) do
    push_event(socket, "api_request", %{
      method: "loadEnumerations",
      params: %{},
      request_id: "enumerations_load"
    })
  end

  # ============================================================================
  # DOCUMENT LOADING FUNCTIONS
  # ============================================================================

    defp load_documents_from_vorgang(socket) do
    # Extract all document IDs from stations
    document_ids = extract_document_ids_from_vorgang(socket.assigns.vorgang)

    # Store document IDs for later reference
    socket = assign(socket, document_ids: document_ids)

    # Fetch each unique document
    Enum.reduce(document_ids, socket, fn {id, _type}, acc_socket ->
      push_event(acc_socket, "api_request", %{
        method: "getDocumentById",
        params: %{apiId: id},
        request_id: "document_load_#{id}"
      })
    end)
  end

    defp extract_document_ids_from_vorgang(vorgang) do
    stationen = vorgang["stationen"] || []

    result = Enum.flat_map(stationen, fn station ->
      dokumente = station["dokumente"] || []
      stellungnahmen = station["stellungnahmen"] || []

            # Extract string IDs (UUIDs) from documents
      dokumente_ids = dokumente |> Enum.filter(&is_binary/1) |> Enum.map(fn id -> {id, "dokumente"} end)
      stellungnahmen_ids = stellungnahmen |> Enum.filter(&is_binary/1) |> Enum.map(fn id -> {id, "stellungnahmen"} end)

      dokumente_ids ++ stellungnahmen_ids
    end)
    |> Enum.uniq_by(fn {id, _type} -> id end)

    result
  end

    defp handle_document_loaded(socket, document_id, document_data) do
    # Update the document in the appropriate station
    stationen = socket.assigns.vorgang["stationen"] || []

    updated_stationen = Enum.map(stationen, fn station ->
      # Check dokumente
      if station["dokumente"] do
        # Find and replace the document with matching ID
        updated_dokumente = Enum.map(station["dokumente"], fn doc ->
          if is_binary(doc) and doc == document_id do
            document_data
          else
            doc
          end
        end)

        Map.put(station, "dokumente", updated_dokumente)
      else
        station
      end
    end)

    new_vorgang = Map.put(socket.assigns.vorgang, "stationen", updated_stationen)

    # Force a more explicit state update to ensure LiveView detects the change
    socket = assign_vorgang(socket, new_vorgang)
    socket = assign(socket, :document_updated, true)
    socket
  end

  # Helper function to get a document safely (handles both ID strings and full objects)
  defp get_document_safely(station, document_type, document_index) do
    documents = case document_type do
      "dokumente" -> station["dokumente"] || []
      "stellungnahmen" -> station["stellungnahmen"] || []
    end

    document = Enum.at(documents, document_index)

    # If document is a string (ID), return empty map for now
    # The document will be loaded asynchronously
    if is_binary(document) do
      %{}
    else
      document || %{}
    end
  end

  defp update_vorgang(socket) do
    push_event(socket, "api_request", %{
      method: "putVorgangById",
      params: %{id: socket.assigns.vorgang_id, data: socket.assigns.vorgang},
      request_id: "vorgang_update"
    })
  end

  defp deep_copy_vorgang(vorgang) do
    case Jason.encode(vorgang) do
      {:ok, json} -> Jason.decode!(json)
      _ -> vorgang
    end
  end

  # ============================================================================
  # DATA MANIPULATION FUNCTIONS
  # ============================================================================

  defp add_id(vorgang, id_data), do: Map.put(vorgang, "ids", (vorgang["ids"] || []) ++ [id_data])
  defp remove_id(vorgang, index) do
    ids = vorgang["ids"] || []
    if index < length(ids), do: Map.put(vorgang, "ids", List.delete_at(ids, index)), else: vorgang
  end
  defp add_link(vorgang, value), do: Map.put(vorgang, "links", (vorgang["links"] || []) ++ [value])
  defp remove_link(vorgang, index) do
    links = vorgang["links"] || []
    if index < length(links), do: Map.put(vorgang, "links", List.delete_at(links, index)), else: vorgang
  end
  defp add_initiator(vorgang, initiator_data), do: Map.put(vorgang, "initiatoren", (vorgang["initiatoren"] || []) ++ [initiator_data])
  defp remove_initiator(vorgang, index) do
    initiatoren = vorgang["initiatoren"] || []
    if index < length(initiatoren), do: Map.put(vorgang, "initiatoren", List.delete_at(initiatoren, index)), else: vorgang
  end
  defp add_lobbyregister(vorgang, lobbyregister_entry), do: Map.put(vorgang, "lobbyregister", (vorgang["lobbyregister"] || []) ++ [lobbyregister_entry])
  defp remove_lobbyregister(vorgang, index) do
    lobbyregister = vorgang["lobbyregister"] || []
    if index < length(lobbyregister), do: Map.put(vorgang, "lobbyregister", List.delete_at(lobbyregister, index)), else: vorgang
  end

  defp update_stations_from_params(vorgang, station_params) do
    stationen = vorgang["stationen"] || []

    updated_stationen = station_params
    |> Enum.map(fn {index_str, station_param} ->
      index = String.to_integer(index_str)
      if index < length(stationen) do
        station = Enum.at(stationen, index)
        update_station_from_params(station, station_param)
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)

    Map.put(vorgang, "stationen", updated_stationen)
  end

  defp update_station_from_params(station, params) do
    station
    |> update_station_field(params, "titel")
    |> update_station_field(params, "typ")
    |> update_station_field(params, "zp_start")
    |> update_station_field(params, "zp_modifiziert")
    |> update_station_field(params, "link")
    |> update_station_field(params, "gremium_federf", &parse_boolean/1)
    |> update_station_field(params, "trojanergefahr", &parse_integer_or_default(&1, 1))
    |> update_station_field(params, "schlagworte", &parse_schlagworte/1)
    |> update_gremium_from_params(params)
  end

  defp update_gremium_from_params(station, params) do
    if Map.has_key?(params, "gremium") do
      gremium = station["gremium"] || %{}
      updated_gremium = gremium
      |> update_gremium_field(params["gremium"], "name")
      |> update_gremium_field(params["gremium"], "wahlperiode", &parse_integer_or_default(&1, 0))
      |> update_gremium_field(params["gremium"], "parlament")
      |> update_gremium_field(params["gremium"], "link")

      Map.put(station, "gremium", updated_gremium)
    else
      station
    end
  end

  defp update_station_field(station, params, field) do
    update_station_field(station, params, field, &(&1))
  end

  defp update_station_field(station, params, field, parser) do
    case Map.get(params, field) do
      nil -> station
      value -> Map.put(station, field, parser.(value))
    end
  end

  defp update_gremium_field(gremium, params, field) do
    update_gremium_field(gremium, params, field, &(&1))
  end

  defp update_gremium_field(gremium, params, field, parser) do
    case Map.get(params, field) do
      nil -> gremium
      value -> Map.put(gremium, field, parser.(value))
    end
  end

  defp parse_boolean("true"), do: true
  defp parse_boolean("false"), do: false
  defp parse_boolean(true), do: true
  defp parse_boolean(false), do: false
  defp parse_boolean(_), do: false

  defp parse_schlagworte(value) when is_binary(value) and value != "" do
    value
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
  defp parse_schlagworte(_), do: []



  defp parse_integer_or_default(value, default) when is_binary(value), do: Integer.parse(value) |> then(fn {int, _} -> int; :error -> default end)
  defp parse_integer_or_default(value, _default) when is_integer(value), do: value
  defp parse_integer_or_default(_value, default), do: default





  # ============================================================================
  # TEMPLATE HELPER FUNCTIONS
  # ============================================================================

  def has_changes?(assigns), do: State.has_changes?(assigns)
  def can_undo?(assigns), do: State.can_undo?(assigns)
  def session_valid?(assigns), do: State.session_valid?(assigns)
  def has_admin_scope?(assigns), do: State.has_admin_scope?(assigns)
  def has_keyadder_scope?(assigns), do: State.has_keyadder_scope?(assigns)
end
