defmodule LtzfApWeb.EnumerationsLive do
  use LtzfApWeb, :live_view
  import LtzfApWeb.SharedHeader

  def mount(_params, _session, socket) do
    socket = assign(socket,
      enumerations: %{},
      selected_enum: nil,
      loading: false,
      error: nil,
      editing: false,
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
    # Extract data from API response
    enumerations = result["data"] || %{}

    {:noreply, assign(socket, enumerations: enumerations, loading: false, error: nil)}
  end

  def handle_event("api_error", %{"request_id" => "enumerations_load", "error" => error}, socket) do
    {:noreply, assign(socket, enumerations: %{}, loading: false, error: error)}
  end

  def handle_event("select_enum", %{"enum" => enum_name}, socket) do
    {:noreply, assign(socket, selected_enum: enum_name)}
  end

  def handle_event("edit_enum", %{"enum" => enum_name}, socket) do
    {:noreply, assign(socket, editing: true, selected_enum: enum_name)}
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

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing: false)}
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

  # Helper functions for the template
  defp get_enum_values(enumerations, enum_name) do
    Map.get(enumerations, enum_name, [])
  end

  defp enum_names do
    [
      "vgtyp",
      "parlament",
      "wahlperiode",
      "autor_typ",
      "gremium_typ",
      "dokument_typ"
    ]
  end

  defp enum_display_name("vgtyp"), do: "Vorgangstyp"
  defp enum_display_name("parlament"), do: "Parlament"
  defp enum_display_name("wahlperiode"), do: "Wahlperiode"
  defp enum_display_name("autor_typ"), do: "Autor Typ"
  defp enum_display_name("gremium_typ"), do: "Gremium Typ"
  defp enum_display_name("dokument_typ"), do: "Dokument Typ"
  defp enum_display_name(name), do: name

  defp get_enumeration_display_name("vgtyp"), do: "Vorgangstyp"
  defp get_enumeration_display_name("parlament"), do: "Parlament"
  defp get_enumeration_display_name("wahlperiode"), do: "Wahlperiode"
  defp get_enumeration_display_name("autor_typ"), do: "Autor Typ"
  defp get_enumeration_display_name("gremium_typ"), do: "Gremium Typ"
  defp get_enumeration_display_name("dokument_typ"), do: "Dokument Typ"
  defp get_enumeration_display_name(name), do: name

  defp get_item_id(item, _enumeration) when is_map(item), do: item["id"] || item["value"]
  defp get_item_id(item, _enumeration) when is_binary(item), do: item
  defp get_item_id(_, _), do: ""

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
