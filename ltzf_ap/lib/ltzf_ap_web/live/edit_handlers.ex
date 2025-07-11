defmodule LtzfApWeb.EditHandlers do
  @moduledoc """
  Macros and helpers for common edit event handler patterns.
  """

  defmacro edit_field_handlers(field_name, opts \\ []) do
    quote do
      def handle_event("edit_#{unquote(field_name)}", _params, socket) do
        current_value = Map.get(socket.assigns.vorgang, unquote(field_name), "")

        socket = assign(socket, :"editing_#{unquote(field_name)}", %{value: current_value})
        {:noreply, socket}
      end

      def handle_event("save_#{unquote(field_name)}", %{"value" => value}, socket) do
        editing = socket.assigns[:"editing_#{unquote(field_name)}"]

        if editing do
          new_vorgang = update_field(socket.assigns.vorgang, unquote(field_name), value)
          edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

          socket = assign(socket,
            vorgang: new_vorgang,
            edit_history: edit_history,
            current_edit_index: length(edit_history) - 1
          )
          socket = assign(socket, :"editing_#{unquote(field_name)}", nil)
          {:noreply, socket}
        else
          {:noreply, socket}
        end
      end

      def handle_event("cancel_#{unquote(field_name)}_edit", _params, socket) do
        {:noreply, assign(socket, :"editing_#{unquote(field_name)}", nil)}
      end
    end
  end

  defmacro edit_list_item_handlers(list_name, item_type, opts \\ []) do
    quote do
      def handle_event("edit_#{unquote(item_type)}_field", %{"index" => index, "field" => field}, socket) do
        index = String.to_integer(index)

        items = socket.assigns.vorgang[unquote(list_name)] || []
        current_value = if index < length(items) do
          Map.get(Enum.at(items, index), field, "")
        else
          ""
        end

        socket = assign(socket, :"editing_#{unquote(item_type)}", %{index: index, field: field, value: current_value})
        {:noreply, socket}
      end

      def handle_event("save_#{unquote(item_type)}_field", %{"value" => value}, socket) do
        editing = socket.assigns[:"editing_#{unquote(item_type)}"]

        if editing do
          new_vorgang = apply(__MODULE__, :"update_#{unquote(item_type)}_field", [socket.assigns.vorgang, editing.index, editing.field, value])
          edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

          socket = assign(socket,
            vorgang: new_vorgang,
            edit_history: edit_history,
            current_edit_index: length(edit_history) - 1
          )
          socket = assign(socket, :"editing_#{unquote(item_type)}", nil)
          {:noreply, socket}
        else
          {:noreply, socket}
        end
      end

      def handle_event("cancel_#{unquote(item_type)}_edit", _params, socket) do
        {:noreply, assign(socket, :"editing_#{unquote(item_type)}", nil)}
      end

      def handle_event("add_#{unquote(item_type)}", _params, socket) do
        default_fields = unquote(opts[:default_fields] || %{})
        socket = assign(socket, :"adding_#{unquote(item_type)}", default_fields)
        {:noreply, socket}
      end

      def handle_event("save_new_#{unquote(item_type)}", params, socket) do
        validation_fields = unquote(opts[:validation_fields] || [])

        if LtzfApWeb.EditHandlers.validate_required_fields(params, validation_fields) do
          new_item = LtzfApWeb.EditHandlers.build_item_item(params, unquote(opts[:transform_fields] || []))
          new_vorgang = apply(__MODULE__, :"add_#{unquote(item_type)}", [socket.assigns.vorgang, new_item])
          edit_history = socket.assigns.edit_history ++ [socket.assigns.vorgang]

          socket = assign(socket,
            vorgang: new_vorgang,
            edit_history: edit_history,
            current_edit_index: length(edit_history) - 1
          )
          socket = assign(socket, :"adding_#{unquote(item_type)}", nil)
          {:noreply, socket}
        else
          {:noreply, socket}
        end
      end

      def handle_event("cancel_add_#{unquote(item_type)}", _params, socket) do
        {:noreply, assign(socket, :"adding_#{unquote(item_type)}", nil)}
      end
    end
  end

  # Helper functions for the macros
  def validate_required_fields(params, required_fields) do
    Enum.all?(required_fields, fn field ->
      value = Map.get(params, field, "")
      is_binary(value) and String.trim(value) != ""
    end)
  end

  def build_item_item(params, transform_fields) do
    params
    |> Enum.map(fn {key, value} ->
      if key in transform_fields do
        {key, transform_field_value(key, value)}
      else
        {key, value}
      end
    end)
    |> Map.new()
  end

  defp transform_field_value("betroffene_drucksachen", value) when is_binary(value) and value != "" do
    String.split(value, ",")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))
  end
  defp transform_field_value(_, value), do: value
end
