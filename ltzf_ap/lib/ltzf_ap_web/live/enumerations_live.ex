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
    # TODO: Implement merge functionality
    {:noreply, socket}
  end

  def handle_event("delete_items", _params, socket) do
    # TODO: Implement delete functionality
    {:noreply, socket}
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
      enumeration_pagination: %{current_page: 1, per_page: 32, has_more: false, total_count: nil}
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

  defp find_item_by_id(values, item_id, enumeration_type) do
    Enum.find(values, fn value ->
      get_item_id(value, enumeration_type) == item_id
    end)
  end

  defp get_item_id(value, enumeration_type) do
    case enumeration_type do
      "autoren" ->
        # Create a unique ID for autoren based on person, organisation, and fachgebiet
        person = value["person"] || ""
        org = value["organisation"] || ""
        fach = value["fachgebiet"] || ""
        "#{person}|#{org}|#{fach}"

      "gremien" ->
        # Create a unique ID for gremien based on name, parlament, and wahlperiode
        name = value["name"] || ""
        parlament = value["parlament"] || ""
        wahlperiode = value["wahlperiode"] || ""
        "#{name}|#{parlament}|#{wahlperiode}"

      _ ->
        # For simple enumerations, the value itself is the ID
        value
    end
  end

  def get_item_id_for_display(value, enumeration_type) do
    get_item_id(value, enumeration_type)
  end
end
