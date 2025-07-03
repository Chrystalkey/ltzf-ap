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
    fields = [
      %{key: "titel", label: "Title", type: :string},
      %{key: "kurztitel", label: "Short Title", type: :string},
      %{key: "typ", label: "Type", type: :string},
      %{key: "wahlperiode", label: "Electoral Period", type: :string},
      %{key: "verfassungsaendernd", label: "Constitutional Amendment", type: :boolean},
      %{key: "api_id", label: "API ID", type: :mono}
    ]

    sections = [
      %{
        title: "Initiators",
        items: Enum.map(assigns.vorgang["initiatoren"] || [], fn initiator ->
          %{
            type: :person_org,
            person_key: Map.get(initiator, "person"),
            org_key: Map.get(initiator, "organisation"),
            fach_key: Map.get(initiator, "fachgebiet")
          }
        end)
      },
      %{
        title: "Stations (#{length(assigns.vorgang["stationen"] || [])})",
        items: Enum.map(assigns.vorgang["stationen"] || [], fn station ->
          %{
            type: :custom,
            content: fn _entity ->
              gremium_info = if station["gremium"] do
                gremium = station["gremium"]
                "#{Map.get(gremium, "name", "Unknown")} (#{Map.get(gremium, "parlament", "Unknown")})"
              else
                ""
              end

              start_date = safe_format_date(station["zp_start"])

              mod_date = safe_format_date(station["zp_modifiziert"])

              """
              <p class="text-sm font-medium text-gray-900">
                #{Map.get(station, "titel") || Map.get(station, "typ") || "Unknown"}
              </p>
              <p class="text-sm text-gray-500">
                #{Map.get(station, "typ")} | #{gremium_info}
              </p>
              <p class="text-sm text-gray-500">
                #{if start_date, do: "Started: #{start_date}"}
                #{if mod_date, do: " | Modified: #{mod_date}"}
              </p>
              """
            end
          }
        end)
      }
    ]

    assigns = assign(assigns, :fields, fields)
    assigns = assign(assigns, :sections, sections)

    ~H"""
    <.generic_detail_page
      entity_type="vorgang"
      title="Legislative Process"
      entity={@vorgang}
      current_user={@current_user}
      flash={@flash}
      back_url="/data_management/vorgaenge"
      back_text="Back to Processes"
      fields={@fields}
      sections={@sections}
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

    assigns = assign(assigns, :fields, fields)
    assigns = assign(assigns, :sections, sections)

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
end
