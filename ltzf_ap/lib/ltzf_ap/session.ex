defmodule LtzfAp.Session do
  @moduledoc """
  Session management for the LTZF Administration Panel.
  Handles encrypted API key storage and session validation.
  """

  use GenServer

  @max_session_duration 7 * 24 * 60 * 60 # 7 days in seconds
  @default_session_duration 1 * 24 * 60 * 60 # 1 day in seconds
  @cleanup_interval 60 * 60 * 1000 # 1 hour in milliseconds

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

    def init(_) do
    # Create the priv directory if it doesn't exist
    File.mkdir_p("priv")

    # Use a simpler approach with file-based storage for now
    # We'll implement proper SQLite later
    schedule_cleanup()
    {:ok, %{sessions: %{}}}
  end

  def create_session(api_key, backend_url, expires_in \\ @default_session_duration) do
    GenServer.call(__MODULE__, {:create_session, api_key, backend_url, expires_in})
  end

  def get_session(session_id) do
    GenServer.call(__MODULE__, {:get_session, session_id})
  end

  def delete_session(session_id) do
    GenServer.call(__MODULE__, {:delete_session, session_id})
  end

  def cleanup_expired_sessions do
    GenServer.call(__MODULE__, :cleanup_expired_sessions)
  end

  # GenServer callbacks

    def handle_call({:create_session, api_key, backend_url, expires_in}, _from, %{sessions: sessions} = state) do
    session_id = UUID.uuid4()
    expires_at = DateTime.utc_now() |> DateTime.add(expires_in, :second)

    encrypted_key = encrypt_api_key(api_key)

    new_session = %{
      encrypted_api_key: encrypted_key,
      backend_url: backend_url,
      expires_at: expires_at,
      created_at: DateTime.utc_now()
    }

    new_sessions = Map.put(sessions, session_id, new_session)
    {:reply, {:ok, session_id, expires_at}, %{state | sessions: new_sessions}}
  end

    def handle_call({:get_session, session_id}, _from, %{sessions: sessions} = state) do
    case Map.get(sessions, session_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      session ->
        if DateTime.compare(session.expires_at, DateTime.utc_now()) == :gt do
          api_key = decrypt_api_key(session.encrypted_api_key)
          {:reply, {:ok, %{api_key: api_key, backend_url: session.backend_url, expires_at: session.expires_at}}, state}
        else
          # Session expired, remove it
          new_sessions = Map.delete(sessions, session_id)
          {:reply, {:error, :expired}, %{state | sessions: new_sessions}}
        end
    end
  end

  def handle_call({:delete_session, session_id}, _from, %{sessions: sessions} = state) do
    new_sessions = Map.delete(sessions, session_id)
    {:reply, :ok, %{state | sessions: new_sessions}}
  end

  def handle_call(:cleanup_expired_sessions, _from, %{sessions: sessions} = state) do
    now = DateTime.utc_now()
    new_sessions = Map.filter(sessions, fn {_id, session} ->
      DateTime.compare(session.expires_at, now) == :gt
    end)
    {:reply, :ok, %{state | sessions: new_sessions}}
  end

  def handle_info(:cleanup, state) do
    cleanup_expired_sessions()
    schedule_cleanup()
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  # Private functions

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end

  defp encrypt_api_key(api_key) do
    # In production, use proper encryption with Cloak
    # For now, using a simple base64 encoding
    Base.encode64(api_key)
  end

  defp decrypt_api_key(encrypted_key) do
    # In production, use proper decryption with Cloak
    # For now, using simple base64 decoding
    Base.decode64!(encrypted_key)
  end
end
