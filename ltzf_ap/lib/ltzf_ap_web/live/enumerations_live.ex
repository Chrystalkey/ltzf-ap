defmodule LtzfApWeb.EnumerationsLive do
  use LtzfApWeb, :live_view
  import LtzfApWeb.SharedHeader

  def mount(_params, _session, socket) do
    socket = assign(socket,
      enumerations: %{},
      selected_enumeration: nil,  # Changed from selected_enum
      values: [],  # Added missing assign
      selected_items: [],  # Added missing assign
      loading_values: false,  # Added missing assign
      loading_more: false,  # Added missing assign
      merge_mode: false,  # Added missing assign
      merge_replacement_value: "",  # Added missing assign
      current_filters: %{},  # Added missing assign
      enumeration_pagination: %{has_more: false, total_count: nil},  # Added missing assign
      loading: false,
      error: nil,
      editing: false,
      editing_item_id: nil,  # Added for edit functionality
      editing_value: "",  # Added for edit functionality
      session_id: nil,
      auth_info: %{scope: "unknown"},
      session_data: %{expires_at: DateTime.utc_now()},
      backend_url: nil
    )

    # Trigger client-side session restoration
    {:ok, push_event(socket, "restore_session", %{})}
  end

  def handle_event("session_restored", %{"credentials" => credentials}, socket) do
    # Client has restored session, initialize data
    socket = assign(socket,
      backend_url: credentials["backend_url"],
      auth_info: %{scope: credentials["scope"]},
      session_data: %{expires_at: credentials["expires_at"]},
      session_id: "restored" # Set a session ID to indicate we have a session
    )

    # Load enumerations data
    send(self(), :load_enumerations)
    {:noreply, socket}
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

  def handle_event("load_enumerations", _params, socket) do
        {:noreply,
          socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "loadEnumerations",
       params: [],
       request_id: "enumerations_load"
     })}
  end

  def handle_event("api_response", %{"request_id" => "enumerations_load", "result" => result}, socket) do
    # Handle different response formats for loadEnumerations
    enumerations = case result do
      %{"data" => data} when is_map(data) -> data
      data when is_map(data) -> data
      _ -> %{}
    end

    {:noreply, assign(socket, enumerations: enumerations, loading: false, error: nil)}
  end

  def handle_event("api_error", %{"request_id" => "enumerations_load", "error" => error}, socket) do
    {:noreply, assign(socket, enumerations: %{}, loading: false, error: error)}
  end

  # Updated event handler to match template
  def handle_event("select_enumeration", %{"enumeration" => enum_name}, socket) do
    # Load values for the selected enumeration
    socket = assign(socket,
      selected_enumeration: enum_name,
      loading_values: true,
      values: [],
      selected_items: [],
      current_filters: %{},
      error: nil
    )

    # Load values for this enumeration
    send(self(), {:load_enumeration_values, enum_name})
    {:noreply, socket}
  end

    # Added handler for loading enumeration values
  def handle_info({:load_enumeration_values, enum_name}, socket) do
    # Load without filters
    handle_info({:load_enumeration_values_with_filters, enum_name, %{}}, socket)
  end

  # Added handler for loading enumeration values with filters
  def handle_info({:load_enumeration_values_with_filters, enum_name, filters}, socket) do
    # Determine the correct API method based on the enumeration type
    {method, params} = case enum_name do
      "autoren" -> {"getAutoren", [filters]}
      "gremien" -> {"getGremien", [filters]}
      _ -> {"getEnumerations", [enum_name, filters]}
    end

    {:noreply,
      socket
     |> assign(:loading_values, true)
     |> push_event("api_request", %{
       method: method,
       params: params,
       request_id: "enumeration_values_load"
     })}
  end

  # Added handler for enumeration values response
  def handle_event("api_response", %{"request_id" => "enumeration_values_load", "result" => result}, socket) do
    # Handle different response formats
    {values, pagination} = case result do
      %{"data" => data, "pagination" => pag} ->
        {data || [], pag || %{has_more: false, total_count: nil}}
      %{"data" => data} ->
        {data || [], %{has_more: false, total_count: nil}}
      data when is_list(data) ->
        {data, %{has_more: false, total_count: nil}}
      _ ->
        {[], %{has_more: false, total_count: nil}}
    end

    {:noreply, assign(socket,
      values: values,
      loading_values: false,
      enumeration_pagination: pagination,
      error: nil
    )}
  end

  # Added handler for enumeration values error
  def handle_event("api_error", %{"request_id" => "enumeration_values_load", "error" => error}, socket) do
    {:noreply, assign(socket,
      values: [],
      loading_values: false,
      error: error
    )}
  end

  # Added handler for toggling items
  def handle_event("toggle_item", %{"item" => item_id}, socket) do
    selected_items = socket.assigns.selected_items

    new_selected_items = if item_id in selected_items do
      List.delete(selected_items, item_id)
    else
      [item_id | selected_items]
    end

    {:noreply, assign(socket, selected_items: new_selected_items)}
  end

  # Added handler for merge mode
  def handle_event("merge_items", _params, socket) do
    {:noreply, assign(socket, merge_mode: true, merge_replacement_value: "")}
  end

  # Added handler for canceling merge
  def handle_event("cancel_merge", _params, socket) do
    {:noreply, assign(socket, merge_mode: false, merge_replacement_value: "")}
  end

  # Added handler for updating merge value
  def handle_event("update_merge_value", %{"value" => value}, socket) do
    {:noreply, assign(socket, merge_replacement_value: value)}
  end

    # Added handler for confirming merge
  def handle_event("confirm_merge", _params, socket) do
    selected_enumeration = socket.assigns.selected_enumeration
    selected_items = socket.assigns.selected_items
    replacement_value = socket.assigns.merge_replacement_value

    if selected_enumeration && length(selected_items) > 1 && replacement_value != "" do
      # Only send the new replacement value, not the entire list
      new_values = [replacement_value]

      # Create replacing array for the API - the selected items will be replaced by the new value
      replacing = [%{
        "values" => selected_items,
        "replaced_by" => 0  # Index 0 since we're only sending the new value
      }]

      {:noreply,
        socket
       |> assign(:loading, true)
       |> push_event("api_request", %{
         method: "updateEnumeration",
         params: [selected_enumeration, new_values, replacing],
         request_id: "enum_merge"
       })}
    else
      {:noreply, assign(socket, merge_mode: false, merge_replacement_value: "", selected_items: [])}
    end
  end

  # Added handler for deleting items
  def handle_event("delete_items", _params, socket) do
    selected_enumeration = socket.assigns.selected_enumeration
    selected_items = socket.assigns.selected_items

    if selected_enumeration && length(selected_items) > 0 do
      # Delete each selected item
      Enum.each(selected_items, fn item_id ->
        send(self(), {:delete_enumeration_value, selected_enumeration, item_id})
      end)

      {:noreply, assign(socket, selected_items: [])}
    else
      {:noreply, socket}
    end
  end

    # Added handler for filtering values
  def handle_event("filter_values", %{"filter" => filters}, socket) do
    selected_enumeration = socket.assigns.selected_enumeration

    if selected_enumeration do
      # Update filters and reload data with new filters
      socket = assign(socket, current_filters: filters)

      # Reload the current enumeration values with the new filters
      send(self(), {:load_enumeration_values_with_filters, selected_enumeration, filters})

      {:noreply, socket}
    else
      {:noreply, assign(socket, current_filters: filters)}
    end
  end

  # Added handler for clearing filters
  def handle_event("clear_filters", _params, socket) do
    selected_enumeration = socket.assigns.selected_enumeration

    if selected_enumeration do
      # Clear filters and reload data without filters
      socket = assign(socket, current_filters: %{})

      # Reload the current enumeration values without filters
      send(self(), {:load_enumeration_values_with_filters, selected_enumeration, %{}})

      {:noreply, socket}
    else
      {:noreply, assign(socket, current_filters: %{})}
    end
  end

        # Added handler for adding new values to simple enumerations
  def handle_event("add_value", %{"filter" => filters}, socket) do
    value = Map.get(filters, "contains", "")
    selected_enumeration = socket.assigns.selected_enumeration

    # Only allow adding to simple enumerations
    simple_enumerations = ["schlagworte", "stationstypen", "vorgangstypen", "parlamente", "vgidtypen", "dokumententypen"]

    if selected_enumeration && selected_enumeration in simple_enumerations && String.trim(value) != "" do
      # Get current values and add the new value
      current_values = socket.assigns.values
      new_value = String.trim(value)

      # Check if value already exists
      if new_value in current_values do
        {:noreply, assign(socket, error: "Value '#{new_value}' already exists in the enumeration")}
      else
        # Add the new value to the existing list
        updated_values = [new_value | current_values]

        # Update the enumeration with the complete list
        {:noreply,
          socket
         |> assign(:loading, true)
         |> push_event("api_request", %{
           method: "updateEnumeration",
           params: [selected_enumeration, updated_values, []],
           request_id: "enum_add_value"
         })}
      end
    else
      {:noreply, socket}
    end
  end

  # Added handler for loading more
  def handle_event("load_more", _params, socket) do
    {:noreply, assign(socket, loading_more: true)}
  end

  # Added handler for editing items
  def handle_event("edit_item", %{"item" => item_id}, socket) do
    selected_enumeration = socket.assigns.selected_enumeration
    values = socket.assigns.values

    # Find the item to edit
    item_to_edit = Enum.find(values, fn value ->
      get_item_id_for_display(value, selected_enumeration) == item_id
    end)

    if item_to_edit do
      # Set up edit mode with the current value
      edit_value = case item_to_edit do
        value when is_binary(value) -> value
        %{"name" => name} -> name
        %{"value" => value} -> value
        _ -> ""
      end

      {:noreply, assign(socket,
        editing: true,
        editing_item_id: item_id,
        editing_value: edit_value
      )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("edit_enum", %{"enum" => enum_name}, socket) do
    {:noreply, assign(socket, editing: true, selected_enumeration: enum_name)}
  end

  def handle_event("save_enum", %{"enum_name" => enum_name, "values" => values}, socket) do
    # Parse values from form
    parsed_values = values
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))

    {:noreply,
      socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "updateEnumeration",
       params: [enum_name, parsed_values],
       request_id: "enum_update"
     })}
  end

  def handle_event("api_response", %{"request_id" => "enum_update", "result" => _data}, socket) do
    # Reload enumerations after update
    send(self(), :load_enumerations)
    {:noreply, assign(socket, editing: false, loading: false)}
  end

  def handle_event("api_error", %{"request_id" => "enum_update", "error" => error}, socket) do
    {:noreply, assign(socket, error: error, loading: false)}
  end

  def handle_event("delete_value", %{"enum_name" => enum_name, "value" => value}, socket) do
              {:noreply,
                socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "deleteEnumerationValue",
       params: [enum_name, value],
       request_id: "enum_delete"
     })}
  end

  def handle_event("api_response", %{"request_id" => "enum_delete", "result" => _data}, socket) do
    # Reload enumerations after delete
    send(self(), :load_enumerations)
    {:noreply, assign(socket, loading: false)}
  end

  def handle_event("api_error", %{"request_id" => "enum_delete", "error" => error}, socket) do
    {:noreply, assign(socket, error: error, loading: false)}
  end

  # Response handlers for merge operation
  def handle_event("api_response", %{"request_id" => "enum_merge", "result" => _data}, socket) do
    # Reload the current enumeration values after merge
    selected_enumeration = socket.assigns.selected_enumeration
    if selected_enumeration do
      send(self(), {:load_enumeration_values, selected_enumeration})
    end
    {:noreply, assign(socket, merge_mode: false, merge_replacement_value: "", selected_items: [], loading: false)}
  end

  def handle_event("api_error", %{"request_id" => "enum_merge", "error" => error}, socket) do
    {:noreply, assign(socket, error: error, loading: false)}
  end

  # Response handlers for individual value deletion
  def handle_event("api_response", %{"request_id" => "enum_delete_value", "result" => _data}, socket) do
    # Reload the current enumeration values after deletion
    selected_enumeration = socket.assigns.selected_enumeration
    if selected_enumeration do
      send(self(), {:load_enumeration_values, selected_enumeration})
    end
    {:noreply, socket}
  end

  def handle_event("api_error", %{"request_id" => "enum_delete_value", "error" => error}, socket) do
    {:noreply, assign(socket, error: error)}
  end

  # Response handlers for edit operation
  def handle_event("api_response", %{"request_id" => "enum_edit", "result" => _data}, socket) do
    # Reload the current enumeration values after edit
    selected_enumeration = socket.assigns.selected_enumeration
    if selected_enumeration do
      send(self(), {:load_enumeration_values, selected_enumeration})
    end
    {:noreply, assign(socket, editing: false, editing_item_id: nil, editing_value: "", loading: false)}
  end

  def handle_event("api_error", %{"request_id" => "enum_edit", "error" => error}, socket) do
    {:noreply, assign(socket, error: error, loading: false)}
  end

  # Response handlers for add value operation
  def handle_event("api_response", %{"request_id" => "enum_add_value", "result" => _data}, socket) do
    # Reload the current enumeration values after adding
    selected_enumeration = socket.assigns.selected_enumeration
    if selected_enumeration do
      send(self(), {:load_enumeration_values, selected_enumeration})
    end
    {:noreply, assign(socket, loading: false, error: nil)}
  end

  def handle_event("api_error", %{"request_id" => "enum_add_value", "error" => error}, socket) do
    {:noreply, assign(socket, error: error, loading: false)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing: false, editing_item_id: nil, editing_value: "")}
  end

  def handle_event("update_editing_value", %{"value" => value}, socket) do
    {:noreply, assign(socket, editing_value: value)}
  end

    def handle_event("save_edit", %{"value" => new_value}, socket) do
    selected_enumeration = socket.assigns.selected_enumeration
    editing_item_id = socket.assigns.editing_item_id

    if selected_enumeration && editing_item_id && new_value != "" do
      # Only send the new value, not the entire list
      new_values = [new_value]

      # Create replacing array for the API - the old value will be replaced by the new value
      replacing = [%{
        "values" => [editing_item_id],
        "replaced_by" => 0  # Index 0 since we're only sending the new value
      }]

      {:noreply,
        socket
       |> assign(:loading, true)
       |> push_event("api_request", %{
         method: "updateEnumeration",
         params: [selected_enumeration, new_values, replacing],
         request_id: "enum_edit"
       })}
    else
      {:noreply, assign(socket, editing: false, editing_item_id: nil, editing_value: "")}
    end
  end

  def handle_info(:load_enumerations, socket) do
          {:noreply,
            socket
     |> assign(:loading, true)
     |> push_event("api_request", %{
       method: "loadEnumerations",
       params: [],
       request_id: "enumerations_load"
     })}
  end

  # Handler for deleting individual enumeration values
  def handle_info({:delete_enumeration_value, enum_name, value}, socket) do
    {:noreply,
      socket
     |> push_event("api_request", %{
       method: "deleteEnumerationValue",
       params: [enum_name, value],
       request_id: "enum_delete_value"
     })}
  end

  # Helper functions for the template
  defp get_enum_values(enumerations, enum_name) do
    Map.get(enumerations, enum_name, [])
  end

  defp enum_names do
    [
      "schlagworte",
      "stationstypen",
      "vorgangstypen",
      "parlamente",
      "vgidtypen",
      "dokumententypen"
    ]
  end

  defp enum_display_name("schlagworte"), do: "Schlagworte"
  defp enum_display_name("stationstypen"), do: "Stationstypen"
  defp enum_display_name("vorgangstypen"), do: "Vorgangstypen"
  defp enum_display_name("parlamente"), do: "Parlamente"
  defp enum_display_name("vgidtypen"), do: "Vorgang ID Typen"
  defp enum_display_name("dokumententypen"), do: "Dokumententypen"
  defp enum_display_name(name), do: name

  defp get_enumeration_display_name("schlagworte"), do: "Schlagworte"
  defp get_enumeration_display_name("stationstypen"), do: "Stationstypen"
  defp get_enumeration_display_name("vorgangstypen"), do: "Vorgangstypen"
  defp get_enumeration_display_name("parlamente"), do: "Parlamente"
  defp get_enumeration_display_name("vgidtypen"), do: "Vorgang ID Typen"
  defp get_enumeration_display_name("dokumententypen"), do: "Dokumententypen"
  defp get_enumeration_display_name("autoren"), do: "Autoren"
  defp get_enumeration_display_name("gremien"), do: "Gremien"
  defp get_enumeration_display_name(name), do: name

  defp get_item_id(item, _enumeration) when is_map(item), do: item["id"] || item["value"]
  defp get_item_id(item, _enumeration) when is_binary(item), do: item
  defp get_item_id(_, _), do: ""

  defp get_item_id_for_display(item, "autoren") when is_map(item), do: item["id"] || item["value"] || "#{item["person"] || ""}-#{item["organisation"] || ""}"
  defp get_item_id_for_display(item, "gremien") when is_map(item), do: item["id"] || item["value"] || "#{item["name"] || ""}-#{item["parlament"] || ""}-#{item["wahlperiode"] || ""}"
  defp get_item_id_for_display(item, _enumeration) when is_map(item), do: item["id"] || item["value"]
  defp get_item_id_for_display(item, _enumeration) when is_binary(item), do: item
  defp get_item_id_for_display(_, _), do: ""

  defp format_selected_items_for_display(items, _enumeration) when is_list(items) do
    items
    |> Enum.take(3)
    |> Enum.map(fn item ->
      case item do
        %{"name" => name} -> name
        %{"value" => value} -> value
        value when is_binary(value) -> value
        _ -> "Unknown"
      end
    end)
    |> Enum.join(", ")
  end
  defp format_selected_items_for_display(_, _), do: ""


end
