defmodule LtzfApWeb.VorgangDetailLive do
  use LtzfApWeb, :live_view
  require Logger

  import LtzfApWeb.SharedHeader

  def mount(%{"id" => vorgang_id}, _session, socket) do
    IO.puts("VorgangDetailLive: mount called with vorgang_id: #{vorgang_id}")

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
      session_restored: false,
      vgidtypen: [],  # Add vgidtypen enumeration values
      vorgangstypen: [],  # Add vorgangstypen enumeration values
      stationstypen: [],  # Add stationstypen enumeration values
      parlamente: [],  # Add parlamente enumeration values
      adding_id: nil,
      adding_link: nil,
      adding_initiator: nil,
      adding_lobbyregister: nil,
      new_station_index: nil,  # Track newly added station
      collapsed_stations: MapSet.new(),  # Track which stations are collapsed
      saving: false,  # Track save operation state
      save_success: false  # Track save success state
    )

    # Trigger client-side session restoration only if not already restored
    IO.puts("VorgangDetailLive: pushing restore_session event")
    {:ok, push_event(socket, "restore_session", %{})}
  end

      def handle_event("session_restored", %{"credentials" => credentials}, socket) do
    IO.puts("VorgangDetailLive: session_restored received with credentials: #{inspect(credentials)}")

    socket = assign(socket,
      session_id: "restored",
      backend_url: credentials["backendUrl"] || credentials["backend_url"],
      auth_info: %{scope: credentials["scope"]},
      session_data: %{expires_at: credentials["expiresAt"] || credentials["expires_at"]},
      session_restored: true
    )

        # Load vorgang data
    IO.puts("VorgangDetailLive: loading vorgang data")
    socket = load_vorgang(socket)
    {:noreply, socket}
  end

    def handle_event("session_expired", %{"error" => error}, socket) do
    IO.puts("VorgangDetailLive: session_expired received with error: #{error}")

    socket = assign(socket,
      error: "Session expired: #{error}",
      loading: false
    )
    {:noreply, socket}
  end

  def handle_event("session_expired", _params, socket) do
    IO.puts("VorgangDetailLive: session_expired received without error")

    socket = assign(socket,
      error: "Session expired. Please log in again.",
      loading: false
    )
    {:noreply, socket}
  end

  def handle_event("api_response", %{"request_id" => "vorgang_load", "result" => result}, socket) do
    IO.puts("VorgangDetailLive: vorgang_load response received")

    vorgang = ensure_vorgang_fields(result)
    socket = assign(socket,
      vorgang: vorgang,
      original_vorgang: deep_copy(vorgang),
      loading: false,
      error: nil
    )
    {:noreply, socket}
  end

  def handle_event("api_response", %{"request_id" => "vorgang_update", "result" => _result}, socket) do
    # Update successful, update the original vorgang and clear saving state
    socket = assign(socket,
      original_vorgang: deep_copy(socket.assigns.vorgang),
      saving: false,
      save_success: true,
      error: nil
    )

    # Clear success message after 3 seconds
    Process.send_after(self(), :clear_save_success, 3000)

    {:noreply, socket}
  end

  def handle_event("api_response", %{"request_id" => "vorgang_update", "error" => error}, socket) do
    # Update failed, clear saving state and show error
    socket = assign(socket,
      saving: false,
      save_success: false,
      error: "Speichern fehlgeschlagen: #{error}"
    )
    {:noreply, socket}
  end

  def handle_event("api_response", %{"request_id" => "enumerations_load", "result" => result}, socket) do
    IO.puts("VorgangDetailLive: enumerations_load response received")

    socket = assign(socket,
      vgidtypen: result["vgidtypen"] || [],
      vorgangstypen: result["vorgangstypen"] || [],
      stationstypen: result["stationstypen"] || [],
      parlamente: result["parlamente"] || []
    )
    {:noreply, socket}
  end

  def handle_event("api_response", %{"request_id" => request_id, "error" => error}, socket) do
    IO.puts("VorgangDetailLive: API error for request #{request_id}: #{error}")

    socket = assign(socket,
      error: error,
      loading: false
    )
    {:noreply, socket}
  end

  # Simple form change handlers
  def handle_event("form_change", %{"vorgang" => vorgang_params}, socket) do
    # Convert form params to our vorgang structure
    new_vorgang = form_params_to_vorgang(vorgang_params, socket.assigns.vorgang)
    socket = assign(socket, vorgang: new_vorgang)
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    # Set saving state and send update to backend
    socket = assign(socket, saving: true)
    update_vorgang(socket)
    {:noreply, socket}
  end

  def handle_event("undo", _params, socket) do
    # Simple undo - just reset to original
    socket = assign(socket,
      vorgang: deep_copy(socket.assigns.original_vorgang)
    )
    {:noreply, socket}
  end

  def handle_event("reset", _params, socket) do
    socket = assign(socket,
      vorgang: deep_copy(socket.assigns.original_vorgang),
      error: nil
    )
    {:noreply, socket}
  end

  # Add new items
  def handle_event("add_id", _params, socket) do
    socket = assign(socket, adding_id: %{typ: "", id: ""})
    {:noreply, socket}
  end

  def handle_event("save_new_id", %{"typ" => typ, "id_value" => id}, socket) do
    if typ != "" and id != "" do
      new_vorgang = add_id(socket.assigns.vorgang, %{"typ" => typ, "id" => id})
      socket = assign(socket,
        vorgang: new_vorgang,
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

  def handle_event("add_link", _params, socket) do
    socket = assign(socket, adding_link: %{value: ""})
    {:noreply, socket}
  end

    def handle_event("save_new_link", %{"value" => value}, socket) do
    if value != "" do
      new_vorgang = add_link(socket.assigns.vorgang, value)
      socket = assign(socket,
        vorgang: new_vorgang,
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

  def handle_event("add_initiator", _params, socket) do
    socket = assign(socket, adding_initiator: %{person: "", organisation: "", fachgebiet: ""})
    {:noreply, socket}
  end

    def handle_event("save_new_initiator", %{"person" => person, "organisation" => organisation, "fachgebiet" => fachgebiet, "lobbyregister" => lobbyregister}, socket) do
    if person != "" or organisation != "" or fachgebiet != "" do
      new_vorgang = add_initiator(socket.assigns.vorgang, %{
        "person" => person,
        "organisation" => organisation,
        "fachgebiet" => fachgebiet,
        "lobbyregister" => lobbyregister
      })
      socket = assign(socket,
        vorgang: new_vorgang,
        adding_initiator: nil
      )
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("save_new_initiator", %{"person" => person, "organisation" => organisation, "fachgebiet" => fachgebiet}, socket) do
    if person != "" or organisation != "" or fachgebiet != "" do
      new_vorgang = add_initiator(socket.assigns.vorgang, %{
        "person" => person,
        "organisation" => organisation,
        "fachgebiet" => fachgebiet,
        "lobbyregister" => ""
      })
      socket = assign(socket,
        vorgang: new_vorgang,
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

  def handle_event("add_lobbyregister", _params, socket) do
    socket = assign(socket, adding_lobbyregister: %{value: ""})
    {:noreply, socket}
  end

  def handle_event("save_new_lobbyregister", params, socket) do
    # Create proper lobbyregister structure according to OpenAPI schema
    organisation = %{
      "person" => params["organisation_person"] || "",
      "organisation" => params["organisation_name"] || "",
      "fachgebiet" => params["organisation_fachgebiet"] || "",
      "lobbyregister" => params["organisation_lobbyregister"] || ""
    }

    betroffene_drucksachen = case params["betroffene_drucksachen"] do
      "" -> []
      drucksachen_str -> String.split(drucksachen_str, ",") |> Enum.map(&String.trim/1)
    end

    lobbyregister_entry = %{
      "organisation" => organisation,
      "interne_id" => params["interne_id"] || "",
      "intention" => params["intention"] || "",
      "link" => params["link"] || "",
      "betroffene_drucksachen" => betroffene_drucksachen
    }

    new_vorgang = add_lobbyregister(socket.assigns.vorgang, lobbyregister_entry)
    socket = assign(socket,
      vorgang: new_vorgang,
      adding_lobbyregister: nil
    )
    {:noreply, socket}
  end

  def handle_event("cancel_add_lobbyregister", _params, socket) do
    {:noreply, assign(socket, adding_lobbyregister: nil)}
  end

  # Stations handling
  def handle_event("add_station", _params, socket) do
    new_station = %{
      "titel" => "",
      "typ" => "",
      "parlament" => "",
      "zp_start" => "",
      "zp_modifiziert" => "",
      "link" => "",
      "gremium" => %{
        "name" => "",
        "wahlperiode" => "",
        "parlament" => "",
        "link" => ""
      },
      "gremium_federf" => false,
      "trojanergefahr" => "",
      "schlagworte" => [],
      "dokumente" => []
    }

    stationen = socket.assigns.vorgang["stationen"] || []
    new_index = length(stationen)
    new_vorgang = Map.put(socket.assigns.vorgang, "stationen", stationen ++ [new_station])

    # Ensure new station starts expanded
    new_collapsed_stations = MapSet.delete(socket.assigns.collapsed_stations, new_index)

    socket = assign(socket,
      vorgang: new_vorgang,
      new_station_index: new_index,
      collapsed_stations: new_collapsed_stations
    )

    # Clear the highlight after 3 seconds
    Process.send_after(self(), :clear_new_station_highlight, 3000)

    # Scroll to the new station after a brief delay to ensure DOM is updated
    Process.send_after(self(), {:scroll_to_station, new_index}, 100)

    {:noreply, socket}
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
      updated_stationen = List.delete_at(stationen, index)
      new_vorgang = Map.put(socket.assigns.vorgang, "stationen", updated_stationen)
      socket = assign(socket, vorgang: new_vorgang)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  # Handle info messages
  def handle_info(:clear_new_station_highlight, socket) do
    {:noreply, assign(socket, new_station_index: nil)}
  end

  def handle_info(:clear_save_success, socket) do
    {:noreply, assign(socket, save_success: false)}
  end

  def handle_info({:scroll_to_station, index}, socket) do
    {:noreply, push_event(socket, "scroll_to_station", %{index: index})}
  end

  # Handle station form changes
  def handle_event("form_change", %{"station" => station_params}, socket) do
    new_vorgang = update_stations_from_params(socket.assigns.vorgang, station_params)
    socket = assign(socket, vorgang: new_vorgang)
    {:noreply, socket}
  end

  # Handle mixed form changes (vorgang + station)
  def handle_event("form_change", params, socket) do
    new_vorgang = socket.assigns.vorgang

    # Handle vorgang params
    if Map.has_key?(params, "vorgang") do
      new_vorgang = form_params_to_vorgang(params["vorgang"], new_vorgang)
    end

    # Handle station params
    if Map.has_key?(params, "station") do
      new_vorgang = update_stations_from_params(new_vorgang, params["station"])
    end

    socket = assign(socket, vorgang: new_vorgang)
    {:noreply, socket}
  end

  # Remove items
  def handle_event("remove_id", %{"index" => index}, socket) do
    index = String.to_integer(index)
    new_vorgang = remove_id(socket.assigns.vorgang, index)
    socket = assign(socket, vorgang: new_vorgang)
    {:noreply, socket}
  end

  def handle_event("remove_link", %{"index" => index}, socket) do
    index = String.to_integer(index)
    new_vorgang = remove_link(socket.assigns.vorgang, index)
    socket = assign(socket, vorgang: new_vorgang)
      {:noreply, socket}
  end

  def handle_event("remove_initiator", %{"index" => index}, socket) do
    index = String.to_integer(index)
    new_vorgang = remove_initiator(socket.assigns.vorgang, index)
    socket = assign(socket, vorgang: new_vorgang)
    {:noreply, socket}
  end

  def handle_event("remove_lobbyregister", %{"index" => index}, socket) do
    index = String.to_integer(index)
    new_vorgang = remove_lobbyregister(socket.assigns.vorgang, index)
    socket = assign(socket, vorgang: new_vorgang)
    {:noreply, socket}
  end

  # Helper functions
      def has_changes(socket) do
    try do
      vorgang = Map.get(socket.assigns, :vorgang)
      original_vorgang = Map.get(socket.assigns, :original_vorgang)

      case {vorgang, original_vorgang} do
        {nil, _} ->
          # No vorgang data yet, so no changes
          false
        {_, nil} ->
          # No original data yet, so no changes
          false
        {v, o} ->
          # Simple JSON comparison
          case Jason.encode(v) do
            {:ok, v_json} ->
              case Jason.encode(o) do
                {:ok, o_json} -> v_json != o_json
                _ -> false
              end
            _ -> false
          end
      end
    rescue
      _ ->
        # Any error means no changes
        false
    end
  end

  def can_undo(socket) do
    # Can undo if there are changes
    has_changes(socket)
  end

  # Helper function for template
  def has_changes?(assigns) do
    try do
      vorgang = Map.get(assigns, :vorgang)
      original_vorgang = Map.get(assigns, :original_vorgang)

      case {vorgang, original_vorgang} do
        {nil, _} ->
          false
        {_, nil} ->
          false
        {v, o} ->
          # Simple JSON comparison
          case Jason.encode(v) do
            {:ok, v_json} ->
              case Jason.encode(o) do
                {:ok, o_json} ->
                  v_json != o_json
                _ ->
                  false
              end
            _ ->
              false
          end
      end
    rescue
      _ ->
        false
    end
  end

    defp load_vorgang(socket) do
    IO.puts("VorgangDetailLive: load_vorgang called")

    # Load enumerations first
    socket = load_enumerations(socket)

    # Then load vorgang data
    IO.puts("VorgangDetailLive: pushing getVorgangById request")
    push_event(socket, "api_request", %{
      method: "getVorgangById",
      params: %{id: socket.assigns.vorgang_id},
      request_id: "vorgang_load"
    })
  end

  defp load_enumerations(socket) do
    IO.puts("VorgangDetailLive: pushing loadEnumerations request")
    push_event(socket, "api_request", %{
      method: "loadEnumerations",
      params: %{},
      request_id: "enumerations_load"
    })
  end

  defp update_vorgang(socket) do
    IO.puts("VorgangDetailLive: update_vorgang called - pushing api_request event")

    # Test if the hook is working
    push_event(socket, "test", %{message: "Testing hook communication"})

    push_event(socket, "api_request", %{
      method: "putVorgangById",
      params: %{
        id: socket.assigns.vorgang_id,
        data: socket.assigns.vorgang
      },
      request_id: "vorgang_update"
    })
  end

  defp ensure_vorgang_fields(vorgang) do
    vorgang
    |> Map.put_new("typ", "")
    |> Map.put_new("verfassungsaendernd", false)
    |> Map.put_new("wahlperiode", "")
    |> Map.put_new("titel", "")
    |> Map.put_new("kurztitel", "")
    |> Map.put_new("ids", [])
    |> Map.put_new("links", [])
    |> Map.put_new("initiatoren", [])
    |> Map.put_new("lobbyregister", [])
    |> Map.put_new("stationen", [])
  end

  defp deep_copy(data) do
    case Jason.encode(data) do
      {:ok, json} -> Jason.decode!(json)
      _ -> data
    end
  end

  defp form_params_to_vorgang(params, current_vorgang) do
    current_vorgang
    |> Map.put("typ", params["typ"] || "")
    |> Map.put("verfassungsaendernd", params["verfassungsaendernd"] == "true")
    |> Map.put("wahlperiode", params["wahlperiode"] || "")
    |> Map.put("titel", params["titel"] || "")
    |> Map.put("kurztitel", params["kurztitel"] || "")
  end

  defp update_field(vorgang, field, value) do
    Map.put(vorgang, field, value)
  end

  defp update_id_field(vorgang, index, field, value) do
    ids = vorgang["ids"] || []
    if index < length(ids) do
      updated_ids = List.replace_at(ids, index, Map.put(Enum.at(ids, index), field, value))
      Map.put(vorgang, "ids", updated_ids)
    else
      vorgang
    end
  end

  defp add_id(vorgang, id_data) do
    ids = vorgang["ids"] || []
    Map.put(vorgang, "ids", ids ++ [id_data])
  end

  defp remove_id(vorgang, index) do
    ids = vorgang["ids"] || []
    if index < length(ids) do
      updated_ids = List.delete_at(ids, index)
      Map.put(vorgang, "ids", updated_ids)
    else
      vorgang
    end
  end

  defp add_link(vorgang, value) do
    links = vorgang["links"] || []
    Map.put(vorgang, "links", links ++ [value])
  end

  defp remove_link(vorgang, index) do
    links = vorgang["links"] || []
    if index < length(links) do
      updated_links = List.delete_at(links, index)
      Map.put(vorgang, "links", updated_links)
    else
      vorgang
    end
  end

  defp add_initiator(vorgang, initiator_data) do
    initiatoren = vorgang["initiatoren"] || []
    Map.put(vorgang, "initiatoren", initiatoren ++ [initiator_data])
  end

  defp remove_initiator(vorgang, index) do
    initiatoren = vorgang["initiatoren"] || []
    if index < length(initiatoren) do
      updated_initiatoren = List.delete_at(initiatoren, index)
      Map.put(vorgang, "initiatoren", updated_initiatoren)
    else
      vorgang
    end
  end

  defp add_lobbyregister(vorgang, lobbyregister_entry) do
    lobbyregister = vorgang["lobbyregister"] || []
    Map.put(vorgang, "lobbyregister", lobbyregister ++ [lobbyregister_entry])
  end

  defp remove_lobbyregister(vorgang, index) do
    lobbyregister = vorgang["lobbyregister"] || []
    if index < length(lobbyregister) do
      updated_lobbyregister = List.delete_at(lobbyregister, index)
      Map.put(vorgang, "lobbyregister", updated_lobbyregister)
    else
      vorgang
    end
  end

  defp update_stations_from_params(vorgang, params) do
    stationen = vorgang["stationen"] || []

    # Convert params to a map of station index -> station data
    station_updates = Enum.reduce(params, %{}, fn {key, value}, acc ->
      case parse_station_key(key) do
        {:ok, index, field_path, field_value} ->
          current = Map.get(acc, index, %{})
          updated = put_nested_value(current, field_path, field_value)
          Map.put(acc, index, updated)
        :error ->
          acc
      end
    end)

    # Apply updates to stations
    new_stationen = Enum.with_index(stationen)
    |> Enum.map(fn {station, index} ->
      case Map.get(station_updates, index) do
        nil -> station
        updates -> Map.merge(station, updates)
      end
    end)

    Map.put(vorgang, "stationen", new_stationen)
  end

  defp parse_station_key(key) do
    # Handle nested fields like "0[gremium][name]"
    case Regex.run(~r/^(\d+)\[([^\]]+)\](?:\[([^\]]+)\])?$/, key) do
      [_, index_str, field1, nil] ->
        index = String.to_integer(index_str)
        {:ok, index, [field1], nil}
      [_, index_str, field1, field2] ->
        index = String.to_integer(index_str)
        {:ok, index, [field1, field2], nil}
      nil ->
        :error
    end
  end

  defp put_nested_value(map, [key], value) do
    # Handle special cases
    case {key, value} do
      {"gremium_federf", "true"} -> Map.put(map, key, true)
      {"gremium_federf", _} -> Map.put(map, key, false)
      {"schlagworte", value} when is_binary(value) and value != "" ->
        schlagworte = String.split(value, ",") |> Enum.map(&String.trim/1)
        Map.put(map, key, schlagworte)
      {"schlagworte", _} -> Map.put(map, key, [])
      {"wahlperiode", value} when is_binary(value) and value != "" ->
        case Integer.parse(value) do
          {int, _} -> Map.put(map, key, int)
          :error -> Map.put(map, key, value)
        end
      {"trojanergefahr", value} when is_binary(value) and value != "" ->
        case Integer.parse(value) do
          {int, _} -> Map.put(map, key, int)
          :error -> Map.put(map, key, value)
        end
      _ -> Map.put(map, key, value)
    end
  end

  defp put_nested_value(map, [key | rest], value) do
    current = Map.get(map, key, %{})
    updated = put_nested_value(current, rest, value)
    Map.put(map, key, updated)
  end
end
