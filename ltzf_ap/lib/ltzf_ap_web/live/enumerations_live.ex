defmodule LtzfApWeb.EnumerationsLive do
  use LtzfApWeb, :live_view
  import LtzfApWeb.SharedHeader

  alias LtzfApWeb.SharedLiveHelpers

  @unknown_scope "unknown"

  # Simple enumerations from the API
  @simple_enumerations [
    "schlagworte",
    "stationstypen",
    "vorgangstypen",
    "parlamente",
    "vgidtypen",
    "dokumententypen"
  ]

  # Complex enumerations that need special handling
  @complex_enumerations [
    "autoren",
    "gremien"
  ]

      def mount(%{"s" => session_id} = _params, _session, socket) do
    case SharedLiveHelpers.mount_with_session(session_id, socket, enumeration_assigns()) do
      {:ok, socket} ->
        {:ok, socket}
      {:error, _reason} ->
        {:ok, redirect(socket, to: "/login")}
    end
  end

  def mount(_params, _session, socket) do
    # Set up initial assigns
    assigns = SharedLiveHelpers.initial_assigns(enumeration_assigns())
    socket = assign(socket, assigns)

    # Check if we have a session ID from localStorage
    {:ok, socket |> push_event("get_stored_session", %{})}
  end

  def handle_event("restore_session", %{"session_id" => session_id}, socket) do
    case SharedLiveHelpers.mount_with_session(session_id, socket, enumeration_assigns()) do
      {:ok, updated_socket} ->
        {:noreply, updated_socket}
      {:error, _reason} ->
        SharedLiveHelpers.handle_session_restoration_error(socket, "Invalid session", enumeration_assigns())
    end
  rescue
    _error ->
      SharedLiveHelpers.handle_session_restoration_error(socket, "Session restoration error", enumeration_assigns())
  end

  def handle_event("no_stored_session", _params, socket) do
    assigns = SharedLiveHelpers.initial_assigns(enumeration_assigns())
    socket = assign(socket, assigns)
    {:ok, redirect(socket, to: ~p"/login")}
  end

  def handle_event("logout", _params, socket) do
    SharedLiveHelpers.handle_logout(socket)
  end

  def handle_event("select_enumeration", %{"enumeration" => enum_name}, socket) do
    socket =
      socket
      |> assign(:selected_enumeration, enum_name)
      |> assign(:selected_items, [])
      |> assign(:loading_values, true)
      |> assign(:values, [])
      |> assign(:error, nil)
      |> assign(:enumeration_pagination, %{current_page: 1, per_page: 32, has_more: false})

    # Load the enumeration values
        case load_enumeration_values(socket.assigns.backend_url, socket.assigns.session_data.api_key, enum_name, %{page: 1, per_page: 32}) do
      {:ok, values, headers} ->
        pagination = extract_enumeration_pagination(headers)
        {:noreply,
          socket
          |> assign(:values, values)
          |> assign(:loading_values, false)
          |> assign(:enumeration_pagination, pagination)
        }
      {:error, error} ->
        {:noreply,
          socket
          |> assign(:error, "Fehler beim Laden der Werte: #{error}")
          |> assign(:loading_values, false)
        }
    end
  end

  def handle_event("load_more", _params, socket) do
    if socket.assigns.enumeration_pagination.has_more do
      socket = assign(socket, :loading_more, true)

      next_page = socket.assigns.enumeration_pagination.current_page + 1
      params = build_pagination_params(socket.assigns.current_filters, next_page, socket.assigns.enumeration_pagination.per_page, socket.assigns.selected_enumeration)

          case load_enumeration_values(socket.assigns.backend_url, socket.assigns.session_data.api_key, socket.assigns.selected_enumeration, params) do
      {:ok, new_values, headers} ->
        pagination = extract_enumeration_pagination(headers)
        updated_values = socket.assigns.values ++ new_values

        {:noreply,
          socket
          |> assign(:values, updated_values)
          |> assign(:loading_more, false)
          |> assign(:enumeration_pagination, pagination)
        }
      {:error, error} ->
        {:noreply,
          socket
          |> assign(:error, "Fehler beim Laden weiterer Werte: #{error}")
          |> assign(:loading_more, false)
        }
    end
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_item", %{"item" => item_id}, socket) do
    selected_items = socket.assigns.selected_items

    # Find the actual item by its ID
    actual_item = find_item_by_id(socket.assigns.values, item_id, socket.assigns.selected_enumeration)

    if actual_item do
      new_selected_items =
        if actual_item in selected_items do
          List.delete(selected_items, actual_item)
        else
          [actual_item | selected_items]
        end

      {:noreply, assign(socket, :selected_items, new_selected_items)}
    else
      {:noreply, socket}
    end
  end

    def handle_event("filter_values", %{"filter" => filter_params}, socket) do
    socket = assign(socket, :loading_values, true)

    # Build filter parameters based on enumeration type
    params = build_filter_params(socket.assigns.selected_enumeration, filter_params)
    # Add pagination parameters
    params = params ++ [page: 1, per_page: 32]

        case load_enumeration_values(socket.assigns.backend_url, socket.assigns.session_data.api_key, socket.assigns.selected_enumeration, params) do
      {:ok, values, headers} ->
        pagination = extract_enumeration_pagination(headers)
        {:noreply,
          socket
          |> assign(:values, values)
          |> assign(:loading_values, false)
          |> assign(:current_filters, filter_params)
          |> assign(:enumeration_pagination, pagination)
        }
      {:error, error} ->
        {:noreply,
          socket
          |> assign(:error, "Fehler beim Filtern: #{error}")
          |> assign(:loading_values, false)
        }
    end
  end

  def handle_event("merge_items", _params, socket) do
    if length(socket.assigns.selected_items) >= 2 do
      # Enter merge mode to get the replacement value from user
      {:noreply,
        socket
        |> assign(:merge_mode, true)
        |> assign(:merge_replacement_value, "")
      }
    else
      {:noreply, socket}
    end
  end

  def handle_event("confirm_merge", _params, socket) do
    if socket.assigns.merge_replacement_value != "" do
      items_to_merge = socket.assigns.selected_items

      case socket.assigns.selected_enumeration do
        enum_name when enum_name in @simple_enumerations ->
          # For simple enumerations, use the replacing field to properly merge
          current_values = socket.assigns.values

          # Remove the selected items from the current values
          updated_values = Enum.reject(current_values, fn value -> value in items_to_merge end)

          # Add the replacement value to the beginning of the objects array
          # (so it gets index 0)
          final_values = [socket.assigns.merge_replacement_value | updated_values]

          # Create the replacing array to tell the backend which old values
          # should be replaced by the new value (at index 0)
          replacing = [
            %{
              values: items_to_merge,
              replaced_by: 0
            }
          ]

          case LtzfAp.ApiClient.update_enumeration_with_replacing(
            socket.assigns.backend_url,
            socket.assigns.session_data.api_key,
            enum_name,
            final_values,
            replacing
          ) do
            {:ok, :updated} ->
              {:noreply,
                socket
                |> assign(:values, final_values)
                |> assign(:selected_items, [])
                |> assign(:merge_mode, false)
                |> assign(:merge_replacement_value, "")
                |> put_flash(:info, "Items successfully merged into '#{socket.assigns.merge_replacement_value}'")
              }
            {:error, error} ->
              {:noreply,
                socket
                |> put_flash(:error, "Failed to merge items: #{error}")
              }
          end

        "autoren" ->
          handle_merge_autoren_with_replacement(socket, items_to_merge, socket.assigns.merge_replacement_value)

        "gremien" ->
          handle_merge_gremien_with_replacement(socket, items_to_merge, socket.assigns.merge_replacement_value)

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply,
        socket
        |> put_flash(:error, "Please enter a replacement value")
      }
    end
  end

  def handle_event("cancel_merge", _params, socket) do
    {:noreply,
      socket
      |> assign(:merge_mode, false)
      |> assign(:merge_replacement_value, "")
    }
  end

  def handle_event("update_merge_value", %{"value" => value}, socket) do
    {:noreply, assign(socket, :merge_replacement_value, value)}
  end

  def handle_event("update_merge_value", params, socket) do
    # Handle the case where the value comes from the input field
    value = params["value"] || ""
    {:noreply, assign(socket, :merge_replacement_value, value)}
  end

  def handle_event("delete_items", _params, socket) do
    if length(socket.assigns.selected_items) > 0 do
      case socket.assigns.selected_enumeration do
        enum_name when enum_name in @simple_enumerations ->
          # For simple enumerations, use the DELETE endpoint for each selected item
          selected_items = socket.assigns.selected_items

          # Delete each selected item individually using the DELETE endpoint
          results = Enum.map(selected_items, fn item ->
            LtzfAp.ApiClient.delete_enumeration_value(
              socket.assigns.backend_url,
              socket.assigns.session_data.api_key,
              enum_name,
              item
            )
          end)

          # Check if all deletions were successful
          case Enum.find(results, fn result ->
            case result do
              {:ok, :deleted} -> false
              _ -> true
            end
          end) do
            nil ->
              # All deletions successful
              updated_values = Enum.reject(socket.assigns.values, fn value ->
                value in selected_items
              end)

              {:noreply,
                socket
                |> assign(:values, updated_values)
                |> assign(:selected_items, [])
                |> put_flash(:info, "Items successfully deleted")
              }

            {:error, error} ->
              {:noreply,
                socket
                |> put_flash(:error, "Failed to delete some items: #{error}")
              }
          end

        "autoren" ->
          handle_delete_autoren(socket)

        "gremien" ->
          handle_delete_gremien(socket)

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("edit_item", %{"item" => item_id}, socket) do
    # Find the actual item by its ID
    actual_item = find_item_by_id(socket.assigns.values, item_id, socket.assigns.selected_enumeration)

    if actual_item do
      # For now, we'll just show a flash message
      # In a real implementation, you might want to open a modal or navigate to an edit page
      {:noreply,
        socket
        |> put_flash(:info, "Edit functionality for #{socket.assigns.selected_enumeration} would open here")
      }
    else
      {:noreply, socket}
    end
  end

  def handle_event("save_changes", _params, socket) do
    # TODO: Implement save functionality
    {:noreply, socket}
  end

  defp enumeration_assigns do
    %{
      selected_enumeration: nil,
      selected_items: [],
      values: [],
      loading_values: false,
      loading_more: false,
      current_filters: %{},
      enumeration_pagination: %{current_page: 1, per_page: 32, has_more: false, total_count: nil},
      merge_mode: false,
      merge_replacement_value: ""
    }
  end

  defp load_enumeration_values(backend_url, api_key, enum_name, params) do
    cond do
      enum_name in @simple_enumerations ->
        LtzfAp.ApiClient.get_enumerations_with_headers(backend_url, api_key, enum_name, params)
      enum_name == "autoren" ->
        LtzfAp.ApiClient.get_autoren_with_headers(backend_url, api_key, params)
      enum_name == "gremien" ->
        LtzfAp.ApiClient.get_gremien_with_headers(backend_url, api_key, params)
      true ->
        {:error, "Unbekannte Enumeration: #{enum_name}"}
    end
  end

  defp build_filter_params(enum_name, filter_params) do
    case enum_name do
      "autoren" ->
        [
          person: filter_params["person"],
          fach: filter_params["fach"],
          org: filter_params["org"]
        ]
        |> Enum.filter(fn {_k, v} -> v && v != "" end)

      "gremien" ->
        [
          gr: filter_params["gr"],
          p: filter_params["p"],
          wp: filter_params["wp"]
        ]
        |> Enum.filter(fn {_k, v} -> v && v != "" end)

      _ ->
        # For simple enumerations, just use the contains filter
        if filter_params["contains"] && filter_params["contains"] != "" do
          [contains: filter_params["contains"]]
        else
          []
        end
    end
  end

  defp build_pagination_params(filter_params, page, per_page, selected_enumeration) do
    base_params = build_filter_params(selected_enumeration, filter_params)
    base_params ++ [page: page, per_page: per_page]
  end

  defp extract_enumeration_pagination(headers) do
    headers_map = Map.new(headers, fn {k, v} -> {String.downcase(k), v} end)

    total_count = parse_integer(headers_map["x-total-count"])
    current_page = parse_integer(headers_map["x-page"]) || 1
    per_page = parse_integer(headers_map["x-per-page"]) || 32

    has_more = if total_count do
      current_page * per_page < total_count
    else
      false
    end

    %{
      current_page: current_page,
      per_page: per_page,
      total_count: total_count,
      has_more: has_more
    }
  end

  defp parse_integer(nil), do: nil
  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end
  defp parse_integer(value) when is_integer(value), do: value

  def get_enumeration_display_name(enum_name) do
    case enum_name do
      "schlagworte" -> "Schlagworte"
      "stationstypen" -> "Stationstypen"
      "vorgangstypen" -> "Vorgangstypen"
      "parlamente" -> "Parlamente"
      "vgidtypen" -> "Vorgang ID Typen"
      "dokumententypen" -> "Dokumententypen"
      "autoren" -> "Autoren"
      "gremien" -> "Gremien"
      _ -> enum_name
    end
  end

  def is_complex_enumeration?(enum_name) do
    enum_name in @complex_enumerations
  end

  def format_autor(autor) do
    parts = []
    parts = if autor["person"], do: [autor["person"] | parts], else: parts
    parts = if autor["organisation"], do: [autor["organisation"] | parts], else: parts
    parts = if autor["fachgebiet"], do: ["(#{autor["fachgebiet"]})" | parts], else: parts

    Enum.join(Enum.reverse(parts), " ")
  end

  def format_gremium(gremium) do
    "#{gremium["name"]} (#{gremium["parlament"]}, WP #{gremium["wahlperiode"]})"
  end

  defp get_item_id(value, enumeration_type) do
    case enumeration_type do
      "autoren" ->
        # For autoren, create a unique ID based on person and organization
        person = Map.get(value, "person", "")
        org = Map.get(value, "organisation", "")
        "#{person}_#{org}"

      "gremien" ->
        # For gremien, create a unique ID based on parlament, wahlperiode, and name
        parlament = Map.get(value, "parlament", "")
        wahlperiode = Map.get(value, "wahlperiode", "")
        name = Map.get(value, "name", "")
        "#{parlament}_#{wahlperiode}_#{name}"

      _ ->
        # For simple enumerations, use the value itself
        value
    end
  end

  defp find_item_by_id(values, item_id, enumeration_type) do
    Enum.find(values, fn value ->
      get_item_id(value, enumeration_type) == item_id
    end)
  end

  def get_item_id_for_display(value, enumeration_type) do
    get_item_id(value, enumeration_type)
  end

  defp handle_delete_autoren(socket) do
    # For autoren, we need to build parameters to match the selected items
    # This is a simplified approach - in practice you might want more sophisticated matching
    selected_items = socket.assigns.selected_items

    # For now, we'll delete by organization if available, otherwise by person
    delete_params = case List.first(selected_items) do
      %{"organisation" => org} when org != nil and org != "" ->
        [org: org]
      %{"person" => person} when person != nil and person != "" ->
        [person: person]
      _ ->
        []
    end

    if delete_params != [] do
      case LtzfAp.ApiClient.delete_autoren_by_params(
        socket.assigns.backend_url,
        socket.assigns.session_data.api_key,
        delete_params
      ) do
        {:ok, :deleted} ->
          # Reload the values
          reload_enumeration_values(socket, "autoren")
        {:ok, :not_modified} ->
          # Items already deleted or don't exist, reload to refresh the view
          reload_enumeration_values(socket, "autoren")
        {:error, error} ->
          {:noreply,
            socket
            |> put_flash(:error, "Failed to delete autoren: #{error}")
          }
      end
    else
      {:noreply,
        socket
        |> put_flash(:error, "Cannot determine deletion criteria for selected autoren")
      }
    end
  end

  defp handle_delete_gremien(socket) do
    # For gremien, we need to build parameters to match the selected items
    selected_items = socket.assigns.selected_items

    # For now, we'll delete by name if available
    delete_params = case List.first(selected_items) do
      %{"name" => name} when name != nil and name != "" ->
        [gr: name]
      _ ->
        []
    end

    if delete_params != [] do
      case LtzfAp.ApiClient.delete_gremien_by_params(
        socket.assigns.backend_url,
        socket.assigns.session_data.api_key,
        delete_params
      ) do
        {:ok, :deleted} ->
          # Reload the values
          reload_enumeration_values(socket, "gremien")
        {:ok, :not_modified} ->
          # Items already deleted or don't exist, reload to refresh the view
          reload_enumeration_values(socket, "gremien")
        {:error, error} ->
          {:noreply,
            socket
            |> put_flash(:error, "Failed to delete gremien: #{error}")
          }
      end
    else
      {:noreply,
        socket
        |> put_flash(:error, "Cannot determine deletion criteria for selected gremien")
      }
    end
  end

  defp reload_enumeration_values(socket, enum_name) do
    socket = assign(socket, :loading_values, true)
    case load_enumeration_values(socket.assigns.backend_url, socket.assigns.session_data.api_key, enum_name, %{page: 1, per_page: 32}) do
      {:ok, values, headers} ->
        pagination = extract_enumeration_pagination(headers)
        {:noreply,
          socket
          |> assign(:values, values)
          |> assign(:loading_values, false)
          |> assign(:selected_items, [])
          |> assign(:enumeration_pagination, pagination)
          |> put_flash(:info, "Items successfully deleted")
        }
      {:error, error} ->
        {:noreply,
          socket
          |> assign(:loading_values, false)
          |> put_flash(:error, "Failed to reload values: #{error}")
        }
    end
  end

  defp handle_merge_autoren_with_replacement(socket, items_to_merge, replacement_value) do
    # For autoren, we need to create a new autor object with the replacement value
    # and use the replacing field to tell the backend which old values should be replaced
    current_values = socket.assigns.values
    updated_values = Enum.reject(current_values, fn value -> value in items_to_merge end)

    # Create a new autor object with the replacement value as organization
    new_autor = %{
      "organisation" => replacement_value,
      "person" => "",
      "fachgebiet" => ""
    }

    # Add the new autor to the beginning of the objects array (so it gets index 0)
    final_values = [new_autor | updated_values]

    # Create the replacing array to tell the backend which old values
    # should be replaced by the new value (at index 0)
    replacing = [
      %{
        values: items_to_merge,
        replaced_by: 0
      }
    ]

    autoren_data = %{
      objects: final_values,
      replacing: replacing
    }

    case LtzfAp.ApiClient.update_autoren(
      socket.assigns.backend_url,
      socket.assigns.session_data.api_key,
      autoren_data
    ) do
      {:ok, :updated} ->
        {:noreply,
          socket
          |> assign(:values, final_values)
          |> assign(:selected_items, [])
          |> assign(:merge_mode, false)
          |> assign(:merge_replacement_value, "")
          |> put_flash(:info, "Autoren successfully merged into '#{replacement_value}'")
        }
      {:error, error} ->
        {:noreply,
          socket
          |> put_flash(:error, "Failed to merge autoren: #{error}")
        }
    end
  end

  defp handle_merge_gremien_with_replacement(socket, items_to_merge, replacement_value) do
    # For gremien, we need to create a new gremium object with the replacement value
    # and use the replacing field to tell the backend which old values should be replaced
    current_values = socket.assigns.values
    updated_values = Enum.reject(current_values, fn value -> value in items_to_merge end)

    # Create a new gremium object with the replacement value as name
    # We'll use the first item's parlament and wahlperiode as defaults
    first_item = List.first(items_to_merge)
    new_gremium = %{
      "name" => replacement_value,
      "parlament" => Map.get(first_item, "parlament", "BT"),
      "wahlperiode" => Map.get(first_item, "wahlperiode", 20)
    }

    # Add the new gremium to the beginning of the objects array (so it gets index 0)
    final_values = [new_gremium | updated_values]

    # Create the replacing array to tell the backend which old values
    # should be replaced by the new value (at index 0)
    replacing = [
      %{
        values: items_to_merge,
        replaced_by: 0
      }
    ]

    gremien_data = %{
      objects: final_values,
      replacing: replacing
    }

    case LtzfAp.ApiClient.update_gremien(
      socket.assigns.backend_url,
      socket.assigns.session_data.api_key,
      gremien_data
    ) do
      {:ok, :updated} ->
        {:noreply,
          socket
          |> assign(:values, final_values)
          |> assign(:selected_items, [])
          |> assign(:merge_mode, false)
          |> assign(:merge_replacement_value, "")
          |> put_flash(:info, "Gremien successfully merged into '#{replacement_value}'")
        }
      {:error, error} ->
        {:noreply,
          socket
          |> put_flash(:error, "Failed to merge gremien: #{error}")
        }
    end
  end

  defp format_selected_items_for_display(selected_items, enumeration_type) do
    selected_items
    |> Enum.take(3)
    |> Enum.map(fn item ->
      case enumeration_type do
        "autoren" ->
          person = Map.get(item, "person", "")
          org = Map.get(item, "organisation", "")
          if person != "", do: person, else: org
        "gremien" ->
          name = Map.get(item, "name", "")
          parlament = Map.get(item, "parlament", "")
          "#{name} (#{parlament})"
        _ ->
          item
      end
    end)
    |> Enum.join(", ")
  end
end
