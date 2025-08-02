defmodule LtzfAp.Schemas do
  @moduledoc """
  Data schemas and validation functions based on the OpenAPI specification.
  This module provides structured data types for all API objects.
  """

  # ============================================================================
  # ENUMERATIONS - Current known values from OpenAPI spec
  # These can change without spec updates, so we use String.t() in typespecs
  # ============================================================================

  # Current known parlament values from OpenAPI spec
  @known_parlamente [
    "BT", "BR", "BV", "EK", "BB", "BY", "BE", "HB", "HH", "HE",
    "MV", "NI", "NW", "RP", "SL", "SN", "TH", "SH", "BW", "ST"
  ]

  # Current known vorgangstyp values from OpenAPI spec
  @known_vorgangstypen [
    "gg-einspruch", "gg-zustimmung", "gg-land-parl", "gg-land-volk",
    "bw-einsatz", "sonstig"
  ]

  # Current known stationstyp values from OpenAPI spec
  @known_stationstypen [
    "preparl-regent", "preparl-eckpup", "preparl-regbsl", "preparl-vbegde",
    "parl-initiativ", "parl-ausschber", "parl-vollvlsgn", "parl-akzeptanz",
    "parl-ablehnung", "parl-zurueckgz", "parl-ggentwurf", "postparl-vesja",
    "postparl-vesne", "postparl-gsblt", "postparl-kraft", "sonstig"
  ]

  # Current known vg_ident_typ values from OpenAPI spec
  @known_vg_ident_typen ["initdrucks", "vorgnr", "api-id", "sonstig"]

  # Current known doktyp values from OpenAPI spec
  @known_doktypen [
    "preparl-entwurf", "entwurf", "antrag", "anfrage", "antwort",
    "mitteilung", "beschlussempf", "stellungnahme", "gutachten",
    "redeprotokoll", "tops", "tops-aend", "tops-ergz", "sonstig"
  ]

  # Current known enumeration_name values from OpenAPI spec
  @known_enumeration_names [
    "schlagworte", "stationstypen", "vorgangstypen", "parlamente",
    "vgidtypen", "dokumententypen"
  ]

  # ============================================================================
  # BASIC STRUCTS
  # ============================================================================

  defmodule TouchedBy do
    @moduledoc "Represents a scraper that has touched an object"
    defstruct [:scraper_id, :key]
    @type t() :: %__MODULE__{
      scraper_id: String.t() | nil,
      key: String.t() | nil
    }
  end

  defmodule VgIdent do
    @moduledoc "Unique identifier for a vorgang within a parliament+electoral period"
    defstruct [:id, :typ]
    @type t() :: %__MODULE__{
      id: String.t(),
      typ: String.t() # vg_ident_typ - flexible for future values
    }
  end

  defmodule Autor do
    @moduledoc "A person or organization that has taken on a specific function"
    defstruct [:person, :organisation, :fachgebiet, :lobbyregister]
    @type t() :: %__MODULE__{
      person: String.t() | nil,
      organisation: String.t(), # Required
      fachgebiet: String.t() | nil,
      lobbyregister: String.t() | nil
    }
  end

  defmodule Gremium do
    @moduledoc "A committee in which decisions can be made"
    defstruct [:parlament, :wahlperiode, :link, :name]
    @type t() :: %__MODULE__{
      parlament: String.t(), # parlament - flexible for future values
      wahlperiode: non_neg_integer(),
      link: String.t() | nil,
      name: String.t()
    }
  end

  defmodule Dokument do
    @moduledoc "A document involved in a vorgang"
    defstruct [
      :api_id, :touched_by, :drucksnr, :typ, :titel, :kurztitel, :vorwort,
      :volltext, :zusammenfassung, :zp_modifiziert, :zp_referenz, :zp_erstellt,
      :link, :hash, :meinung, :schlagworte, :autoren
    ]
    @type t() :: %__MODULE__{
      api_id: String.t() | nil,
      touched_by: [TouchedBy.t()] | nil,
      drucksnr: String.t() | nil,
      typ: String.t(), # doktyp - flexible for future values
      titel: String.t(),
      kurztitel: String.t() | nil,
      vorwort: String.t() | nil,
      volltext: String.t(),
      zusammenfassung: String.t() | nil,
      zp_modifiziert: String.t(), # date-time
      zp_referenz: String.t(), # date-time
      zp_erstellt: String.t() | nil, # date-time
      link: String.t(), # uri
      hash: String.t(),
      meinung: 1..5 | nil,
      schlagworte: [String.t()] | nil,
      autoren: [Autor.t()]
    }
  end

  defmodule Station do
    @moduledoc "A station in the legislative process"
    defstruct [
      :api_id, :touched_by, :titel, :zp_start, :zp_modifiziert, :gremium,
      :gremium_federf, :link, :parlament, :typ, :trojanergefahr, :schlagworte,
      :dokumente, :additional_links, :stellungnahmen
    ]
    @type t() :: %__MODULE__{
      api_id: String.t() | nil,
      touched_by: [TouchedBy.t()] | nil,
      titel: String.t() | nil,
      zp_start: String.t(), # date-time, required
      zp_modifiziert: String.t() | nil, # date-time
      gremium: Gremium.t() | nil,
      gremium_federf: boolean() | nil,
      link: String.t() | nil, # uri
      parlament: String.t(), # parlament - flexible for future values, required
      typ: String.t(), # stationstyp - flexible for future values, required
      trojanergefahr: 1..10 | nil,
      schlagworte: [String.t()] | nil,
      dokumente: [Dokument.t() | String.t()], # required, can be docs or UUIDs
      additional_links: [String.t()] | nil, # uris
      stellungnahmen: [Dokument.t()] | nil
    }
  end

  defmodule Lobbyregeintrag do
    @moduledoc "Entry in the Bundestag lobby register for a specific vorgang"
    defstruct [:organisation, :interne_id, :intention, :link, :betroffene_drucksachen]
    @type t() :: %__MODULE__{
      organisation: Autor.t(),
      interne_id: String.t(),
      intention: String.t(),
      link: String.t(), # uri
      betroffene_drucksachen: [String.t()]
    }
  end

  defmodule Vorgang do
    @moduledoc "Master object of the API - wrapper around stations"
    defstruct [
      :api_id, :touched_by, :titel, :kurztitel, :wahlperiode, :verfassungsaendernd,
      :typ, :ids, :links, :initiatoren, :stationen, :lobbyregister
    ]
    @type t() :: %__MODULE__{
      api_id: String.t(), # required
      touched_by: [TouchedBy.t()] | nil,
      titel: String.t(), # required
      kurztitel: String.t() | nil,
      wahlperiode: non_neg_integer(), # required
      verfassungsaendernd: boolean(), # required
      typ: String.t(), # vorgangstyp - flexible for future values, required
      ids: [VgIdent.t()] | nil,
      links: [String.t()] | nil, # uris
      initiatoren: [Autor.t()], # required
      stationen: [Station.t()], # required
      lobbyregister: [Lobbyregeintrag.t()] | nil
    }
  end

  # ============================================================================
  # VALIDATION FUNCTIONS
  # ============================================================================

  @doc """
  Validates if a string is a valid parlament value.
  Checks against current known values but allows for future additions.
  """
  @spec valid_parlament?(String.t()) :: boolean()
  def valid_parlament?(parlament) when is_binary(parlament) do
    parlament in @known_parlamente
  end
  def valid_parlament?(_), do: false

  @doc """
  Validates if a string is a valid vorgangstyp value.
  Checks against current known values but allows for future additions.
  """
  @spec valid_vorgangstyp?(String.t()) :: boolean()
  def valid_vorgangstyp?(typ) when is_binary(typ) do
    typ in @known_vorgangstypen
  end
  def valid_vorgangstyp?(_), do: false

  @doc """
  Validates if a string is a valid stationstyp value.
  Checks against current known values but allows for future additions.
  """
  @spec valid_stationstyp?(String.t()) :: boolean()
  def valid_stationstyp?(typ) when is_binary(typ) do
    typ in @known_stationstypen
  end
  def valid_stationstyp?(_), do: false

  @doc """
  Validates if a string is a valid vg_ident_typ value.
  Checks against current known values but allows for future additions.
  """
  @spec valid_vg_ident_typ?(String.t()) :: boolean()
  def valid_vg_ident_typ?(typ) when is_binary(typ) do
    typ in @known_vg_ident_typen
  end
  def valid_vg_ident_typ?(_), do: false

  @doc """
  Validates if a string is a valid doktyp value.
  Checks against current known values but allows for future additions.
  """
  @spec valid_doktyp?(String.t()) :: boolean()
  def valid_doktyp?(typ) when is_binary(typ) do
    typ in @known_doktypen
  end
  def valid_doktyp?(_), do: false

  @doc """
  Validates if a string is a valid enumeration_name value.
  Checks against current known values but allows for future additions.
  """
  @spec valid_enumeration_name?(String.t()) :: boolean()
  def valid_enumeration_name?(name) when is_binary(name) do
    name in @known_enumeration_names
  end
  def valid_enumeration_name?(_), do: false

  @doc """
  Validates if an integer is a valid trojanergefahr value (1-10).
  """
  @spec valid_trojanergefahr?(integer()) :: boolean()
  def valid_trojanergefahr?(value) when is_integer(value), do: value in 1..10
  def valid_trojanergefahr?(_), do: false

  @doc """
  Validates if an integer is a valid meinung value (1-5).
  """
  @spec valid_meinung?(integer()) :: boolean()
  def valid_meinung?(value) when is_integer(value), do: value in 1..5
  def valid_meinung?(_), do: false

  # ============================================================================
  # HELPER FUNCTIONS FOR KNOWN VALUES
  # ============================================================================

  @doc """
  Returns the current known parlament values from the OpenAPI spec.
  """
  @spec known_parlamente() :: [String.t()]
  def known_parlamente(), do: @known_parlamente

  @doc """
  Returns the current known vorgangstyp values from the OpenAPI spec.
  """
  @spec known_vorgangstypen() :: [String.t()]
  def known_vorgangstypen(), do: @known_vorgangstypen

  @doc """
  Returns the current known stationstyp values from the OpenAPI spec.
  """
  @spec known_stationstypen() :: [String.t()]
  def known_stationstypen(), do: @known_stationstypen

  @doc """
  Returns the current known vg_ident_typ values from the OpenAPI spec.
  """
  @spec known_vg_ident_typen() :: [String.t()]
  def known_vg_ident_typen(), do: @known_vg_ident_typen

  @doc """
  Returns the current known doktyp values from the OpenAPI spec.
  """
  @spec known_doktypen() :: [String.t()]
  def known_doktypen(), do: @known_doktypen

  @doc """
  Returns the current known enumeration_name values from the OpenAPI spec.
  """
  @spec known_enumeration_names() :: [String.t()]
  def known_enumeration_names(), do: @known_enumeration_names

  # ============================================================================
  # CONVERSION FUNCTIONS
  # ============================================================================

  @doc """
  Converts a map to a Vorgang struct, with validation.
  """
  @spec map_to_vorgang(map()) :: {:ok, Vorgang.t()} | {:error, String.t()}
  def map_to_vorgang(map) when is_map(map) do
    try do
      vorgang = %Vorgang{
        api_id: Map.get(map, "api_id"),
        touched_by: parse_touched_by(Map.get(map, "touched_by")),
        titel: Map.get(map, "titel"),
        kurztitel: Map.get(map, "kurztitel"),
        wahlperiode: Map.get(map, "wahlperiode"),
        verfassungsaendernd: Map.get(map, "verfassungsaendernd"),
        typ: Map.get(map, "typ"),
        ids: parse_vg_idents(Map.get(map, "ids")),
        links: Map.get(map, "links"),
        initiatoren: parse_autors(Map.get(map, "initiatoren")),
        stationen: parse_stations(Map.get(map, "stationen")),
        lobbyregister: parse_lobbyregister(Map.get(map, "lobbyregister"))
      }

      # Validate required fields
      case validate_vorgang(vorgang) do
        :ok -> {:ok, vorgang}
        {:error, reason} -> {:error, reason}
      end
    rescue
      e -> {:error, "Failed to parse vorgang: #{inspect(e)}"}
    end
  end

  @doc """
  Converts a Vorgang struct back to a map for API calls.
  """
  @spec vorgang_to_map(Vorgang.t()) :: map()
  def vorgang_to_map(%Vorgang{} = vorgang) do
    %{
      "api_id" => vorgang.api_id,
      "touched_by" => vorgang.touched_by,
      "titel" => vorgang.titel,
      "kurztitel" => vorgang.kurztitel,
      "wahlperiode" => vorgang.wahlperiode,
      "verfassungsaendernd" => vorgang.verfassungsaendernd,
      "typ" => vorgang.typ,
      "ids" => Enum.map(vorgang.ids || [], &vg_ident_to_map/1),
      "links" => vorgang.links,
      "initiatoren" => Enum.map(vorgang.initiatoren, &autor_to_map/1),
      "stationen" => Enum.map(vorgang.stationen, &station_to_map/1),
      "lobbyregister" => Enum.map(vorgang.lobbyregister || [], &lobbyregister_to_map/1)
    }
  end

  # ============================================================================
  # PRIVATE HELPER FUNCTIONS
  # ============================================================================

  defp parse_touched_by(nil), do: nil
  defp parse_touched_by(list) when is_list(list) do
    Enum.map(list, fn item ->
      %TouchedBy{
        scraper_id: Map.get(item, "scraper_id"),
        key: Map.get(item, "key")
      }
    end)
  end

  defp parse_vg_idents(nil), do: []
  defp parse_vg_idents(list) when is_list(list) do
    Enum.map(list, fn item ->
      %VgIdent{
        id: Map.get(item, "id"),
        typ: Map.get(item, "typ")
      }
    end)
  end

  defp parse_autors(nil), do: []
  defp parse_autors(list) when is_list(list) do
    Enum.map(list, fn item ->
      %Autor{
        person: Map.get(item, "person"),
        organisation: Map.get(item, "organisation"),
        fachgebiet: Map.get(item, "fachgebiet"),
        lobbyregister: Map.get(item, "lobbyregister")
      }
    end)
  end

  defp parse_stations(nil), do: []
  defp parse_stations(list) when is_list(list) do
    Enum.map(list, fn item ->
      %Station{
        api_id: Map.get(item, "api_id"),
        touched_by: parse_touched_by(Map.get(item, "touched_by")),
        titel: Map.get(item, "titel"),
        zp_start: Map.get(item, "zp_start"),
        zp_modifiziert: Map.get(item, "zp_modifiziert"),
        gremium: parse_gremium(Map.get(item, "gremium")),
        gremium_federf: Map.get(item, "gremium_federf"),
        link: Map.get(item, "link"),
        parlament: Map.get(item, "parlament"),
        typ: Map.get(item, "typ"),
        trojanergefahr: Map.get(item, "trojanergefahr"),
        schlagworte: Map.get(item, "schlagworte"),
        dokumente: Map.get(item, "dokumente"),
        additional_links: Map.get(item, "additional_links"),
        stellungnahmen: parse_dokuments(Map.get(item, "stellungnahmen"))
      }
    end)
  end

  defp parse_gremium(nil), do: nil
  defp parse_gremium(map) when is_map(map) do
    %Gremium{
      parlament: Map.get(map, "parlament"),
      wahlperiode: Map.get(map, "wahlperiode"),
      link: Map.get(map, "link"),
      name: Map.get(map, "name")
    }
  end

  defp parse_dokuments(nil), do: []
  defp parse_dokuments(list) when is_list(list) do
    Enum.map(list, fn item ->
      %Dokument{
        api_id: Map.get(item, "api_id"),
        touched_by: parse_touched_by(Map.get(item, "touched_by")),
        drucksnr: Map.get(item, "drucksnr"),
        typ: Map.get(item, "typ"),
        titel: Map.get(item, "titel"),
        kurztitel: Map.get(item, "kurztitel"),
        vorwort: Map.get(item, "vorwort"),
        volltext: Map.get(item, "volltext"),
        zusammenfassung: Map.get(item, "zusammenfassung"),
        zp_modifiziert: Map.get(item, "zp_modifiziert"),
        zp_referenz: Map.get(item, "zp_referenz"),
        zp_erstellt: Map.get(item, "zp_erstellt"),
        link: Map.get(item, "link"),
        hash: Map.get(item, "hash"),
        meinung: Map.get(item, "meinung"),
        schlagworte: Map.get(item, "schlagworte"),
        autoren: parse_autors(Map.get(item, "autoren"))
      }
    end)
  end

  defp parse_lobbyregister(nil), do: []
  defp parse_lobbyregister(list) when is_list(list) do
    Enum.map(list, fn item ->
      %Lobbyregeintrag{
        organisation: parse_autor(Map.get(item, "organisation")),
        interne_id: Map.get(item, "interne_id"),
        intention: Map.get(item, "intention"),
        link: Map.get(item, "link"),
        betroffene_drucksachen: Map.get(item, "betroffene_drucksachen")
      }
    end)
  end

  defp parse_autor(map) when is_map(map) do
    %Autor{
      person: Map.get(map, "person"),
      organisation: Map.get(map, "organisation"),
      fachgebiet: Map.get(map, "fachgebiet"),
      lobbyregister: Map.get(map, "lobbyregister")
    }
  end

  defp validate_vorgang(%Vorgang{} = vorgang) do
    cond do
      is_nil(vorgang.api_id) -> {:error, "api_id is required"}
      is_nil(vorgang.titel) -> {:error, "titel is required"}
      is_nil(vorgang.wahlperiode) -> {:error, "wahlperiode is required"}
      is_nil(vorgang.verfassungsaendernd) -> {:error, "verfassungsaendernd is required"}
      is_nil(vorgang.typ) -> {:error, "typ is required"}
      is_nil(vorgang.initiatoren) -> {:error, "initiatoren is required"}
      is_nil(vorgang.stationen) -> {:error, "stationen is required"}
      not valid_vorgangstyp?(vorgang.typ) -> {:error, "invalid vorgangstyp: #{vorgang.typ}"}
      true -> :ok
    end
  end

  defp vg_ident_to_map(%VgIdent{} = ident) do
    %{
      "id" => ident.id,
      "typ" => ident.typ
    }
  end

  @doc """
  Converts an Autor struct to a map with string keys.
  """
  @spec autor_to_map(Autor.t()) :: map()
  def autor_to_map(%Autor{} = autor) do
    %{
      "person" => autor.person,
      "organisation" => autor.organisation,
      "fachgebiet" => autor.fachgebiet,
      "lobbyregister" => autor.lobbyregister
    }
  end

  @doc """
  Converts a Station struct to a map with string keys.
  """
  @spec station_to_map(Station.t()) :: map()
  def station_to_map(%Station{} = station) do
    %{
      "api_id" => station.api_id,
      "touched_by" => station.touched_by,
      "titel" => station.titel,
      "zp_start" => station.zp_start,
      "zp_modifiziert" => station.zp_modifiziert,
      "gremium" => if(station.gremium, do: gremium_to_map(station.gremium)),
      "gremium_federf" => station.gremium_federf,
      "link" => station.link,
      "typ" => station.typ,
      "trojanergefahr" => station.trojanergefahr,
      "schlagworte" => station.schlagworte,
      "dokumente" => station.dokumente,
      "additional_links" => station.additional_links,
      "stellungnahmen" => station.stellungnahmen
    }
  end

  @doc """
  Converts a Gremium struct to a map with string keys.
  """
  @spec gremium_to_map(Gremium.t()) :: map()
  def gremium_to_map(%Gremium{} = gremium) do
    %{
      "parlament" => gremium.parlament,
      "wahlperiode" => gremium.wahlperiode,
      "link" => gremium.link,
      "name" => gremium.name
    }
  end

  @doc """
  Converts a Lobbyregeintrag struct to a map with string keys.
  """
  @spec lobbyregister_to_map(Lobbyregeintrag.t()) :: map()
  def lobbyregister_to_map(%Lobbyregeintrag{} = entry) do
    %{
      "organisation" => autor_to_map(entry.organisation),
      "interne_id" => entry.interne_id,
      "intention" => entry.intention,
      "link" => entry.link,
      "betroffene_drucksachen" => entry.betroffene_drucksachen
    }
  end
end
