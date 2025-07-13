defmodule LtzfAp.State do
  @moduledoc """
  State management module for LiveView applications.
  Provides structured state representation and helper functions.
  """

  alias LtzfAp.Schemas

  defmodule VorgangDetailState do
    @moduledoc "State for the VorgangDetailLive module"
    defstruct [
      # Core data
      vorgang_id: nil,
      vorgang: nil,
      original_vorgang: nil,

      # Loading and error states
      loading: true,
      error: nil,

      # Session management
      session_id: nil,
      auth_info: %{scope: "unknown"},
      session_data: %{expires_at: nil},
      backend_url: nil,
      session_restored: false,

      # Enumeration data
      vgidtypen: [],
      vorgangstypen: [],
      stationstypen: [],
      parlamente: [],
      dokumententypen: [],

      # Form states
      adding_id: nil,
      adding_link: nil,
      adding_initiator: nil,
      adding_lobbyregister: nil,
      adding_station: nil,
      adding_autor: nil,
      adding_additional_link: nil,

      # UI state
      new_station_index: nil,
      collapsed_stations: MapSet.new(),
      station_tabs: %{},
      saving: false,
      save_success: false,

      # Undo history
      history: []
    ]

    @type t() :: %__MODULE__{
      vorgang_id: String.t() | nil,
      vorgang: Schemas.Vorgang.t() | nil,
      original_vorgang: Schemas.Vorgang.t() | nil,
      loading: boolean(),
      error: String.t() | nil,
      session_id: String.t() | nil,
      auth_info: map(),
      session_data: map(),
      backend_url: String.t() | nil,
      session_restored: boolean(),
      vgidtypen: [String.t()],
      vorgangstypen: [String.t()],
      stationstypen: [String.t()],
      parlamente: [String.t()],
      dokumententypen: [String.t()],
      adding_id: map() | nil,
      adding_link: map() | nil,
      adding_initiator: map() | nil,
      adding_lobbyregister: map() | nil,
      adding_station: map() | nil,
      adding_autor: map() | nil,
      adding_additional_link: non_neg_integer() | nil,
      new_station_index: non_neg_integer() | nil,
      collapsed_stations: MapSet.t(),
      station_tabs: map(),
      saving: boolean(),
      save_success: boolean(),
      history: [map()]
    }
  end

  defmodule DashboardState do
    @moduledoc "State for the DashboardLive module"
    defstruct [
      # Session management
      session_id: nil,
      auth_info: %{scope: "unknown"},
      session_data: %{expires_at: nil},
      backend_url: nil,
      session_restored: false,

      # Dashboard data
      stats: %{
        vorgaenge: 0,
        sitzungen: 0,
        enumerations: 0
      },
      loading: true,
      error: nil
    ]

    @type t() :: %__MODULE__{
      session_id: String.t() | nil,
      auth_info: map(),
      session_data: map(),
      backend_url: String.t() | nil,
      session_restored: boolean(),
      stats: map(),
      loading: boolean(),
      error: String.t() | nil
    }
  end

  defmodule LoginState do
    @moduledoc "State for the LoginLive module"
    defstruct [
      backend_url: "",
      api_key: "",
      remember_key: false,
      loading: false,
      error: nil,
      connectivity_status: :unknown # :unknown, :checking, :connected, :failed
    ]

    @type t() :: %__MODULE__{
      backend_url: String.t(),
      api_key: String.t(),
      remember_key: boolean(),
      loading: boolean(),
      error: String.t() | nil,
      connectivity_status: :unknown | :checking | :connected | :failed
    }
  end

  # ============================================================================
  # STATE INITIALIZATION FUNCTIONS
  # ============================================================================

  @doc """
  Creates a new VorgangDetailState with default values.
  """
  @spec new_vorgang_detail_state(String.t()) :: VorgangDetailState.t()
  def new_vorgang_detail_state(vorgang_id) do
    %VorgangDetailState{
      vorgang_id: vorgang_id,
      vorgang: nil,
      original_vorgang: nil,
      loading: true,
      error: nil,
      session_id: nil,
      auth_info: %{scope: "unknown"},
      session_data: %{expires_at: nil},
      backend_url: nil,
      session_restored: false,
      vgidtypen: [],
      vorgangstypen: [],
      stationstypen: [],
      parlamente: [],
      dokumententypen: [],
      adding_id: nil,
      adding_link: nil,
      adding_initiator: nil,
      adding_lobbyregister: nil,
      adding_station: nil,
      adding_autor: nil,
      adding_additional_link: nil,
      new_station_index: nil,
      collapsed_stations: MapSet.new(),
      station_tabs: %{},
      saving: false,
      save_success: false,
      history: []
    }
  end

  @doc """
  Creates a new DashboardState with default values.
  """
  @spec new_dashboard_state() :: DashboardState.t()
  def new_dashboard_state() do
    %DashboardState{
      session_id: nil,
      auth_info: %{scope: "unknown"},
      session_data: %{expires_at: nil},
      backend_url: nil,
      session_restored: false,
      stats: %{
        vorgaenge: 0,
        sitzungen: 0,
        enumerations: 0
      },
      loading: true,
      error: nil
    }
  end

  @doc """
  Creates a new LoginState with default values.
  """
  @spec new_login_state() :: LoginState.t()
  def new_login_state() do
    %LoginState{
      backend_url: "",
      api_key: "",
      remember_key: false,
      loading: false,
      error: nil,
      connectivity_status: :unknown
    }
  end

  # ============================================================================
  # STATE UPDATE FUNCTIONS
  # ============================================================================

  @doc """
  Updates the session information in a state struct.
  """
  @spec update_session(VorgangDetailState.t() | DashboardState.t(), map()) :: VorgangDetailState.t() | DashboardState.t()
  def update_session(%VorgangDetailState{} = state, %{"credentials" => credentials}) do
    %{state |
      session_id: "restored",
      backend_url: credentials["backendUrl"] || credentials["backend_url"],
      auth_info: %{scope: credentials["scope"]},
      session_data: %{expires_at: credentials["expiresAt"] || credentials["expires_at"]},
      session_restored: true
    }
  end

  def update_session(%DashboardState{} = state, %{"credentials" => credentials}) do
    %{state |
      session_id: "restored",
      backend_url: credentials["backendUrl"] || credentials["backend_url"],
      auth_info: %{scope: credentials["scope"]},
      session_data: %{expires_at: credentials["expiresAt"] || credentials["expires_at"]},
      session_restored: true
    }
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def update_session(assigns, %{"credentials" => credentials}) when is_map(assigns) do
    # Try to determine the state type based on the assigns
    cond do
      Map.has_key?(assigns, :vorgang_id) ->
        # This is a VorgangDetailState
        filtered_assigns = assigns
        |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
        |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

        struct(VorgangDetailState, filtered_assigns)
        |> update_session(%{"credentials" => credentials})

      Map.has_key?(assigns, :stats) ->
        # This is a DashboardState
        filtered_assigns = Map.take(assigns, DashboardState.__struct__() |> Map.keys())
        struct(DashboardState, filtered_assigns)
        |> update_session(%{"credentials" => credentials})

      true ->
        # Default to VorgangDetailState if we can't determine
        filtered_assigns = assigns
        |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
        |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

        struct(VorgangDetailState, filtered_assigns)
        |> update_session(%{"credentials" => credentials})
    end
  end

  @doc """
  Updates the vorgang data in a VorgangDetailState.
  """
  @spec update_vorgang(VorgangDetailState.t(), map()) :: VorgangDetailState.t()
  def update_vorgang(%VorgangDetailState{} = state, vorgang) do
    # Create a MapSet with all station indices to make them collapsed by default
    stationen = vorgang["stationen"] || []
    collapsed_stations = stationen
    |> Enum.with_index()
    |> Enum.map(fn {_station, index} -> index end)
    |> MapSet.new()

    %{state |
      vorgang: vorgang,
      original_vorgang: deep_copy_vorgang(vorgang),
      loading: false,
      error: nil,
      collapsed_stations: collapsed_stations
    }
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def update_vorgang(assigns, vorgang) when is_map(assigns) do
    filtered_assigns = assigns
    |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
    |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

    struct(VorgangDetailState, filtered_assigns)
    |> update_vorgang(vorgang)
  end

  @doc """
  Updates the enumerations data in a VorgangDetailState.
  """
  @spec update_enumerations(VorgangDetailState.t(), map()) :: VorgangDetailState.t()
  def update_enumerations(%VorgangDetailState{} = state, enumerations) do
    %{state |
      vgidtypen: enumerations["vgidtypen"] || [],
      vorgangstypen: enumerations["vorgangstypen"] || [],
      stationstypen: enumerations["stationstypen"] || [],
      parlamente: enumerations["parlamente"] || [],
      dokumententypen: enumerations["dokumententypen"] || []
    }
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def update_enumerations(assigns, enumerations) when is_map(assigns) do
    filtered_assigns = assigns
    |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
    |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

    struct(VorgangDetailState, filtered_assigns)
    |> update_enumerations(enumerations)
  end

  @doc """
  Updates the dashboard stats in a DashboardState.
  """
  @spec update_dashboard_stats(DashboardState.t(), map()) :: DashboardState.t()
  def update_dashboard_stats(state, stats) do
    state
    |> Map.put(:stats, stats)
    |> Map.put(:loading, false)
    |> Map.put(:error, nil)
  end

  @doc """
  Sets an error state.
  """
  @spec set_error(VorgangDetailState.t() | DashboardState.t() | LoginState.t(), String.t()) :: VorgangDetailState.t() | DashboardState.t() | LoginState.t()
  def set_error(%VorgangDetailState{} = state, error) do
    %{state | error: error, loading: false}
  end

  def set_error(%DashboardState{} = state, error) do
    %{state | error: error, loading: false}
  end

  def set_error(%LoginState{} = state, error) do
    %{state | error: error}
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def set_error(assigns, error) when is_map(assigns) do
    # Try to determine the state type based on the assigns
    cond do
      Map.has_key?(assigns, :vorgang_id) ->
        # This is a VorgangDetailState
        # Filter out fields that aren't in the struct definition
        filtered_assigns = assigns
        |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
        |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

        struct(VorgangDetailState, filtered_assigns)
        |> set_error(error)

      Map.has_key?(assigns, :stats) ->
        # This is a DashboardState
        filtered_assigns = Map.take(assigns, DashboardState.__struct__() |> Map.keys())
        struct(DashboardState, filtered_assigns)
        |> set_error(error)

      Map.has_key?(assigns, :api_key) ->
        # This is a LoginState
        filtered_assigns = Map.take(assigns, LoginState.__struct__() |> Map.keys())
        struct(LoginState, filtered_assigns)
        |> set_error(error)

      true ->
        # Default to VorgangDetailState if we can't determine
        filtered_assigns = assigns
        |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
        |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

        struct(VorgangDetailState, filtered_assigns)
        |> set_error(error)
    end
  end

  @doc """
  Sets loading state.
  """
  @spec set_loading(VorgangDetailState.t() | DashboardState.t() | LoginState.t(), boolean()) :: VorgangDetailState.t() | DashboardState.t() | LoginState.t()
  def set_loading(state, loading) do
    Map.put(state, :loading, loading)
  end

  @doc """
  Sets saving state for vorgang detail.
  """
  @spec set_saving(VorgangDetailState.t(), boolean()) :: VorgangDetailState.t()
  def set_saving(%VorgangDetailState{} = state, saving) do
    %{state | saving: saving, save_success: false}
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def set_saving(assigns, saving) when is_map(assigns) do
    filtered_assigns = assigns
    |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
    |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

    struct(VorgangDetailState, filtered_assigns)
    |> set_saving(saving)
  end

  @doc """
  Sets save success state for vorgang detail.
  """
  @spec set_save_success(VorgangDetailState.t(), boolean()) :: VorgangDetailState.t()
  def set_save_success(%VorgangDetailState{} = state, success) do
    %{state | saving: false, save_success: success}
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def set_save_success(assigns, success) when is_map(assigns) do
    filtered_assigns = assigns
    |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
    |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

    struct(VorgangDetailState, filtered_assigns)
    |> set_save_success(success)
  end

  # ============================================================================
  # STATE QUERY FUNCTIONS
  # ============================================================================

  @doc """
  Checks if the current state has unsaved changes.
  """
  @spec has_changes?(VorgangDetailState.t()) :: boolean()
  def has_changes?(%VorgangDetailState{vorgang: vorgang, original_vorgang: original_vorgang}) do
    case {vorgang, original_vorgang} do
      {nil, _} -> false
      {_, nil} -> false
      {v, o} ->
        case Jason.encode(v) do
          {:ok, v_json} ->
            case Jason.encode(o) do
              {:ok, o_json} -> v_json != o_json
              _ -> false
            end
          _ -> false
        end
    end
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def has_changes?(assigns) when is_map(assigns) do
    filtered_assigns = assigns
    |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
    |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

    struct(VorgangDetailState, filtered_assigns)
    |> has_changes?()
  end

  @doc """
  Checks if the current state can be undone.
  """
  @spec can_undo?(VorgangDetailState.t()) :: boolean()
  def can_undo?(state), do: has_changes?(state)

  @doc """
  Checks if the session is valid.
  """
  @spec session_valid?(VorgangDetailState.t() | DashboardState.t()) :: boolean()
  def session_valid?(state) do
    state.session_restored &&
    state.session_id != nil &&
    state.backend_url != nil
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def session_valid?(assigns) when is_map(assigns) do
    # Try to determine the state type based on the assigns
    cond do
      Map.has_key?(assigns, :vorgang_id) ->
        # This is a VorgangDetailState
        filtered_assigns = assigns
        |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
        |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

        struct(VorgangDetailState, filtered_assigns)
        |> session_valid?()

      Map.has_key?(assigns, :stats) ->
        # This is a DashboardState
        filtered_assigns = Map.take(assigns, DashboardState.__struct__() |> Map.keys())
        struct(DashboardState, filtered_assigns)
        |> session_valid?()

      true ->
        # Default to VorgangDetailState if we can't determine
        filtered_assigns = assigns
        |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
        |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

        struct(VorgangDetailState, filtered_assigns)
        |> session_valid?()
    end
  end

  @doc """
  Checks if the user has admin scope.
  """
  @spec has_admin_scope?(VorgangDetailState.t() | DashboardState.t()) :: boolean()
  def has_admin_scope?(state) do
    state.auth_info[:scope] == "admin"
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def has_admin_scope?(assigns) when is_map(assigns) do
    # Try to determine the state type based on the assigns
    cond do
      Map.has_key?(assigns, :vorgang_id) ->
        # This is a VorgangDetailState
        filtered_assigns = assigns
        |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
        |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

        struct(VorgangDetailState, filtered_assigns)
        |> has_admin_scope?()

      Map.has_key?(assigns, :stats) ->
        # This is a DashboardState
        filtered_assigns = Map.take(assigns, DashboardState.__struct__() |> Map.keys())
        struct(DashboardState, filtered_assigns)
        |> has_admin_scope?()

      true ->
        # Default to VorgangDetailState if we can't determine
        filtered_assigns = assigns
        |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
        |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

        struct(VorgangDetailState, filtered_assigns)
        |> has_admin_scope?()
    end
  end

  @doc """
  Checks if the user has keyadder scope.
  """
  @spec has_keyadder_scope?(VorgangDetailState.t() | DashboardState.t()) :: boolean()
  def has_keyadder_scope?(state) do
    scope = state.auth_info[:scope]
    scope == "admin" or scope == "keyadder"
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def has_keyadder_scope?(assigns) when is_map(assigns) do
    # Try to determine the state type based on the assigns
    cond do
      Map.has_key?(assigns, :vorgang_id) ->
        # This is a VorgangDetailState
        filtered_assigns = assigns
        |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
        |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

        struct(VorgangDetailState, filtered_assigns)
        |> has_keyadder_scope?()

      Map.has_key?(assigns, :stats) ->
        # This is a DashboardState
        filtered_assigns = Map.take(assigns, DashboardState.__struct__() |> Map.keys())
        struct(DashboardState, filtered_assigns)
        |> has_keyadder_scope?()

      true ->
        # Default to VorgangDetailState if we can't determine
        filtered_assigns = assigns
        |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
        |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

        struct(VorgangDetailState, filtered_assigns)
        |> has_keyadder_scope?()
    end
  end

  # ============================================================================
  # UNDO HISTORY FUNCTIONS
  # ============================================================================

  @doc """
  Adds a vorgang state to the undo history.
  """
  @spec add_to_history(VorgangDetailState.t(), map()) :: VorgangDetailState.t()
  def add_to_history(%VorgangDetailState{} = state, vorgang) do
    # Limit history to 20 entries to prevent memory issues
    history = [deep_copy_vorgang(vorgang) | state.history] |> Enum.take(20)
    %{state | history: history}
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def add_to_history(assigns, vorgang) when is_map(assigns) do
    filtered_assigns = assigns
    |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
    |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

    struct(VorgangDetailState, filtered_assigns)
    |> add_to_history(vorgang)
  end

  @doc """
  Pops the last vorgang state from the undo history.
  """
  @spec pop_from_history(VorgangDetailState.t()) :: {VorgangDetailState.t(), map() | nil}
  def pop_from_history(%VorgangDetailState{} = state) do
    case state.history do
      [last_state | rest_history] ->
        new_state = %{state | history: rest_history}
        {new_state, last_state}
      [] ->
        {state, nil}
    end
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def pop_from_history(assigns) when is_map(assigns) do
    filtered_assigns = assigns
    |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
    |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

    struct(VorgangDetailState, filtered_assigns)
    |> pop_from_history()
  end

  @doc """
  Checks if undo is available (history has entries).
  """
  @spec can_undo?(VorgangDetailState.t()) :: boolean()
  def can_undo?(%VorgangDetailState{} = state) do
    length(state.history) > 0
  end

  # Handle maps (from socket.assigns) by converting to struct first
  def can_undo?(assigns) when is_map(assigns) do
    filtered_assigns = assigns
    |> Map.take(VorgangDetailState.__struct__() |> Map.keys())
    |> Map.put(:collapsed_stations, assigns[:collapsed_stations] || MapSet.new())

    struct(VorgangDetailState, filtered_assigns)
    |> can_undo?()
  end

  # ============================================================================
  # PRIVATE HELPER FUNCTIONS
  # ============================================================================

  defp deep_copy_vorgang(vorgang) do
    case Jason.encode(vorgang) do
      {:ok, json} -> Jason.decode!(json)
      _ -> vorgang
    end
  end
end
