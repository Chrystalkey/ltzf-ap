# Client-Side API Migration Plan

## Overview

This document outlines the plan to migrate the LTZF Administration Panel from server-side to client-side API requests. The primary goal is to ensure that API keys are **never transmitted to our server**, improving security and performance.

## Current Architecture Analysis

### Server-Side API Client (`LtzfAp.ApiClient`)
- Makes HTTP requests to the backend API from the Phoenix server
- Uses Finch HTTP client with connection pooling
- Handles authentication, rate limiting, and error responses
- All API communication goes through LiveView server processes

### Server-Side Session Management (`LtzfAp.Session`)
- Stores encrypted API keys in server-side sessions
- Uses GenServer for session lifecycle management
- Handles session expiration and cleanup
- API keys are temporarily stored on the server (security risk)

### Current Data Flow
1. User enters API key on login page
2. Server validates API key against backend
3. Server stores encrypted API key in session
4. All subsequent API calls go through server
5. Server decrypts API key for each request

## Target Architecture: Client-Side API Requests

### Client-Side API Client
- JavaScript-based API client running in the browser
- Direct communication between client and backend API
- No server involvement in API requests
- API keys stored securely in browser storage

### Client-Side Session Management
- Browser-based session storage (localStorage/sessionStorage)
- Client-side encryption for stored API keys
- Automatic session validation and cleanup
- No server-side session state

### Target Data Flow
1. User enters API key on login page
2. Client validates API key directly against backend
3. Client stores encrypted API key in browser storage
4. All subsequent API calls go directly from client to backend
5. Server only handles UI rendering and WebSocket communication

## Phase 1: Create Client-Side API Client

### 1.1 Create JavaScript API Client (`assets/js/api_client.js`)

```javascript
class ApiClient {
  constructor(baseUrl, apiKey) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
  }
  
  async request(endpoint, options = {}) {
    const url = `${this.baseUrl}${endpoint}`;
    const headers = {
      'X-API-Key': this.apiKey,
      'Content-Type': 'application/json',
      ...options.headers
    };
    
    try {
      const response = await fetch(url, {
        ...options,
        headers
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      
      return await response.json();
    } catch (error) {
      throw new Error(`API request failed: ${error.message}`);
    }
  }
  
  // Connectivity and Authentication
  async ping() {
    return this.request('/ping');
  }
  
  async authStatus() {
    return this.request('/api/v1/auth/status');
  }
  
  // Vorgaenge (Legislative Processes)
  async getVorgaenge(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = `/api/v1/vorgang${queryString ? `?${queryString}` : ''}`;
    return this.request(endpoint);
  }
  
  async getVorgangById(id) {
    return this.request(`/api/v1/vorgang/${id}`);
  }
  
  // Sitzungen (Sessions)
  async getSitzungen(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = `/api/v1/sitzung${queryString ? `?${queryString}` : ''}`;
    return this.request(endpoint);
  }
  
  // Enumerations
  async getEnumerations(enumName, params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = `/api/v1/enumeration/${enumName}${queryString ? `?${queryString}` : ''}`;
    return this.request(endpoint);
  }
  
  async updateEnumeration(enumName, values, replacing = []) {
    return this.request(`/api/v1/enumeration/${enumName}`, {
      method: 'PUT',
      body: JSON.stringify({ objects: values, replacing })
    });
  }
  
  async deleteEnumerationValue(enumName, value) {
    const encodedValue = encodeURIComponent(value);
    return this.request(`/api/v1/enumeration/${enumName}/${encodedValue}`, {
      method: 'DELETE'
    });
  }
  
  // Autoren and Gremien
  async getAutoren(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = `/api/v1/autoren${queryString ? `?${queryString}` : ''}`;
    return this.request(endpoint);
  }
  
  async updateAutoren(autorenData) {
    return this.request('/api/v1/autoren', {
      method: 'PUT',
      body: JSON.stringify({
        objects: autorenData.objects,
        replacing: autorenData.replacing || []
      })
    });
  }
  
  async getGremien(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = `/api/v1/gremien${queryString ? `?${queryString}` : ''}`;
    return this.request(endpoint);
  }
  
  async updateGremien(gremienData) {
    return this.request('/api/v1/gremien', {
      method: 'PUT',
      body: JSON.stringify({
        objects: gremienData.objects,
        replacing: gremienData.replacing || []
      })
    });
  }
  
  // Key Management
  async createApiKey(scope, expiresAt = null) {
    const body = { scope };
    if (expiresAt) body.expires_at = expiresAt;
    
    return this.request('/api/v1/auth', {
      method: 'POST',
      body: JSON.stringify(body)
    });
  }
  
  async deleteApiKey(keyToDelete) {
    return this.request('/api/v1/auth', {
      method: 'DELETE',
      headers: { 'api-key-delete': keyToDelete }
    });
  }
}
```

### 1.2 Implement Authentication Flow

```javascript
// assets/js/auth_manager.js
class AuthManager {
  constructor() {
    this.storageKey = 'ltzf_auth';
  }
  
  async validateCredentials(backendUrl, apiKey) {
    const client = new ApiClient(backendUrl, apiKey);
    
    try {
      // Test connectivity
      await client.ping();
      
      // Validate API key
      const authStatus = await client.authStatus();
      
      if (authStatus.scope && ['admin', 'keyadder'].includes(authStatus.scope)) {
        return { success: true, scope: authStatus.scope };
      } else {
        return { success: false, error: 'Insufficient permissions' };
      }
    } catch (error) {
      return { success: false, error: error.message };
    }
  }
  
  storeCredentials(backendUrl, apiKey, scope, expiresAt) {
    const credentials = {
      backendUrl,
      apiKey: this.encryptApiKey(apiKey),
      scope,
      expiresAt: expiresAt.toISOString(),
      createdAt: new Date().toISOString()
    };
    
    sessionStorage.setItem(this.storageKey, JSON.stringify(credentials));
  }
  
  getCredentials() {
    const data = sessionStorage.getItem(this.storageKey);
    if (!data) return null;
    
    const credentials = JSON.parse(data);
    if (new Date(credentials.expiresAt) <= new Date()) {
      this.clearCredentials();
      return null;
    }
    
    return {
      ...credentials,
      apiKey: this.decryptApiKey(credentials.apiKey)
    };
  }
  
  clearCredentials() {
    sessionStorage.removeItem(this.storageKey);
  }
  
  // Simple encryption (in production, use proper encryption)
  encryptApiKey(apiKey) {
    return btoa(apiKey); // Base64 encoding
  }
  
  decryptApiKey(encryptedKey) {
    return atob(encryptedKey); // Base64 decoding
  }
}
```

### 1.3 Create API Method Mappings

| Server Method | Client Method | Purpose |
|---------------|---------------|---------|
| `ping()` | `ping()` | Connectivity check |
| `auth_status()` | `authStatus()` | Authentication validation |
| `get_vorgaenge()` | `getVorgaenge()` | Fetch legislative processes |
| `get_sitzungen()` | `getSitzungen()` | Fetch sessions |
| `get_enumerations()` | `getEnumerations()` | Fetch enumeration data |
| `create_api_key()` | `createApiKey()` | Create new API key |
| `delete_api_key()` | `deleteApiKey()` | Delete API key |
| `update_enumeration()` | `updateEnumeration()` | Update enumeration values |
| `delete_enumeration_value()` | `deleteEnumerationValue()` | Delete enumeration value |
| `update_autoren()` | `updateAutoren()` | Update authors |
| `update_gremien()` | `updateGremien()` | Update committees |

## Phase 2: Update LiveView Architecture

### 2.1 Modify LiveView Mounting

**Current Server-Side Mounting:**
```elixir
def mount(%{"s" => session_id}, _session, socket) do
  case LtzfAp.Session.get_session(session_id) do
    {:ok, session_data} ->
      # Server validates session and loads data
      {:ok, assign(socket, session_data: session_data)}
    {:error, _} ->
      {:ok, redirect(socket, to: ~p"/login")}
  end
end
```

**New Client-Side Mounting:**
```elixir
def mount(_params, _session, socket) do
  socket = assign(socket, 
    loading: true,
    error: nil,
    data: [],
    pagination: %{}
  )
  
  # Trigger client-side session restoration
  {:ok, push_event(socket, "restore_session", %{})}
end

def handle_event("session_restored", %{"credentials" => credentials}, socket) do
  # Client has restored session, initialize API client
  {:noreply, assign(socket, 
    backend_url: credentials.backend_url,
    scope: credentials.scope,
    loading: false
  )}
end

def handle_event("session_expired", _params, socket) do
  {:noreply, redirect(socket, to: ~p"/login")}
end
```

### 2.2 Update Event Handlers

**Replace Server-Side API Calls:**
```elixir
# OLD: Server-side API call
def handle_event("load_vorgaenge", _params, socket) do
  case LtzfAp.ApiClient.get_vorgaenge(
    socket.assigns.backend_url,
    socket.assigns.session_data.api_key,
    socket.assigns.filters
  ) do
    {:ok, data} -> {:noreply, assign(socket, vorgaenge: data)}
    {:error, reason} -> {:noreply, assign(socket, error: reason)}
  end
end

# NEW: Client-side API call
def handle_event("load_vorgaenge", _params, socket) do
  {:noreply, 
   socket
   |> assign(:loading, true)
   |> push_event("api_request", %{
     method: "getVorgaenge",
     params: socket.assigns.filters,
     request_id: generate_request_id()
   })}
end

def handle_event("api_response", %{"request_id" => id, "result" => data}, socket) do
  {:noreply, assign(socket, vorgaenge: data, loading: false)}
end

def handle_event("api_error", %{"request_id" => id, "error" => error}, socket) do
  {:noreply, assign(socket, error: error, loading: false)}
end
```

### 2.3 Update Authentication Flow

**New Login Process:**
```elixir
def handle_event("login", %{"login" => params}, socket) do
  backend_url = params["backend_url"]
  api_key = params["api_key"]
  remember_key = params["remember_key"] == "true"
  
  socket = assign(socket, loading: true, error: nil)
  
  # Trigger client-side authentication
  {:noreply, push_event(socket, "authenticate", %{
    backend_url: backend_url,
    api_key: api_key,
    remember_key: remember_key
  })}
end

def handle_event("auth_success", %{"credentials" => credentials}, socket) do
  # Client has successfully authenticated
  {:noreply, 
   socket
   |> assign(:loading, false)
   |> push_navigate(to: ~p"/dashboard", replace: true)}
end

def handle_event("auth_failure", %{"error" => error}, socket) do
  {:noreply, assign(socket, loading: false, error: error)}
end
```

## Phase 3: Implement Client-Side Data Management

### 3.1 Create Data Store

```javascript
// assets/js/data_store.js
class DataStore {
  constructor() {
    this.cache = new Map();
    this.subscribers = new Map();
  }
  
  set(key, data) {
    this.cache.set(key, {
      data,
      timestamp: Date.now()
    });
    
    // Notify subscribers
    if (this.subscribers.has(key)) {
      this.subscribers.get(key).forEach(callback => callback(data));
    }
  }
  
  get(key) {
    const cached = this.cache.get(key);
    if (!cached) return null;
    
    // Check if cache is still valid (5 minutes)
    if (Date.now() - cached.timestamp > 5 * 60 * 1000) {
      this.cache.delete(key);
      return null;
    }
    
    return cached.data;
  }
  
  subscribe(key, callback) {
    if (!this.subscribers.has(key)) {
      this.subscribers.set(key, []);
    }
    this.subscribers.get(key).push(callback);
  }
  
  unsubscribe(key, callback) {
    if (this.subscribers.has(key)) {
      const callbacks = this.subscribers.get(key);
      const index = callbacks.indexOf(callback);
      if (index > -1) {
        callbacks.splice(index, 1);
      }
    }
  }
}
```

### 3.2 Update Dashboard

**Client-Side Statistics Loading:**
```javascript
// assets/js/dashboard_manager.js
class DashboardManager {
  constructor(apiClient, dataStore) {
    this.apiClient = apiClient;
    this.dataStore = dataStore;
  }
  
  async loadStats() {
    try {
      const [vorgaenge, sitzungen, enumerations] = await Promise.all([
        this.loadVorgaengeCount(),
        this.loadSitzungenCount(),
        this.loadEnumerationsCount()
      ]);
      
      const stats = {
        vorgaenge: vorgaenge,
        sitzungen: sitzungen,
        enumerations: enumerations
      };
      
      this.dataStore.set('dashboard_stats', stats);
      return stats;
    } catch (error) {
      console.error('Failed to load dashboard stats:', error);
      throw error;
    }
  }
  
  async loadVorgaengeCount() {
    try {
      const response = await this.apiClient.getVorgaenge({ per_page: 1 });
      // Extract total count from response headers or data
      return response.total_count || 0;
    } catch (error) {
      return 'Error';
    }
  }
  
  // Similar methods for sitzungen and enumerations...
}
```

### 3.3 Update All LiveView Pages

**Vorgaenge Page:**
```elixir
def mount(_params, _session, socket) do
  socket = assign(socket, 
    vorgaenge: [],
    filters: %{"page" => "1", "per_page" => "32"},
    loading: false,
    error: nil,
    pagination: %{}
  )
  
  {:ok, push_event(socket, "restore_session", %{})}
end

def handle_event("load_vorgaenge", _params, socket) do
  {:noreply, 
   socket
   |> assign(:loading, true)
   |> push_event("api_request", %{
     method: "getVorgaenge",
     params: socket.assigns.filters,
     request_id: "vorgaenge_load"
   })}
end

def handle_event("filter_change", %{"filters" => filters}, socket) do
  socket = assign(socket, filters: filters)
  send(self(), :load_vorgaenge)
  {:noreply, socket}
end
```

**Enumerations Page:**
```elixir
def handle_event("update_enumeration", %{"enum_name" => enum_name, "values" => values}, socket) do
  {:noreply, 
   socket
   |> assign(:loading, true)
   |> push_event("api_request", %{
     method: "updateEnumeration",
     params: [enum_name, values],
     request_id: "enum_update"
   })}
end

def handle_event("delete_enumeration_value", %{"enum_name" => enum_name, "value" => value}, socket) do
  {:noreply, 
   socket
   |> push_event("api_request", %{
     method: "deleteEnumerationValue",
     params: [enum_name, value],
     request_id: "enum_delete"
   })}
end
```

## Phase 4: Security and Performance Optimizations

### 4.1 Security Enhancements

**Enhanced API Key Storage:**
```javascript
// assets/js/security.js
class SecurityManager {
  constructor() {
    this.encryptionKey = this.generateEncryptionKey();
  }
  
  generateEncryptionKey() {
    // Generate a random encryption key
    const array = new Uint8Array(32);
    crypto.getRandomValues(array);
    return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
  }
  
  encryptApiKey(apiKey) {
    // Use Web Crypto API for proper encryption
    const encoder = new TextEncoder();
    const data = encoder.encode(apiKey);
    
    return crypto.subtle.encrypt(
      { name: 'AES-GCM', iv: this.generateIV() },
      this.encryptionKey,
      data
    ).then(encrypted => {
      return btoa(String.fromCharCode(...new Uint8Array(encrypted)));
    });
  }
  
  decryptApiKey(encryptedKey) {
    // Decrypt using Web Crypto API
    const encrypted = Uint8Array.from(atob(encryptedKey), c => c.charCodeAt(0));
    
    return crypto.subtle.decrypt(
      { name: 'AES-GCM', iv: this.generateIV() },
      this.encryptionKey,
      encrypted
    ).then(decrypted => {
      const decoder = new TextDecoder();
      return decoder.decode(decrypted);
    });
  }
  
  generateIV() {
    const array = new Uint8Array(12);
    crypto.getRandomValues(array);
    return array;
  }
}
```

**Request Signing (if required by backend):**
```javascript
async signRequest(method, url, body = null) {
  const timestamp = Date.now();
  const nonce = this.generateNonce();
  
  const signature = await this.createSignature(method, url, body, timestamp, nonce);
  
  return {
    'X-Timestamp': timestamp,
    'X-Nonce': nonce,
    'X-Signature': signature
  };
}
```

### 4.2 Performance Optimizations

**Request Deduplication:**
```javascript
class RequestManager {
  constructor() {
    this.pendingRequests = new Map();
  }
  
  async makeRequest(key, requestFn) {
    if (this.pendingRequests.has(key)) {
      return this.pendingRequests.get(key);
    }
    
    const promise = requestFn();
    this.pendingRequests.set(key, promise);
    
    try {
      const result = await promise;
      this.pendingRequests.delete(key);
      return result;
    } catch (error) {
      this.pendingRequests.delete(key);
      throw error;
    }
  }
}
```

**Progressive Loading:**
```javascript
class ProgressiveLoader {
  constructor(apiClient) {
    this.apiClient = apiClient;
    this.loadingQueue = [];
  }
  
  async loadProgressive(endpoint, params, pageSize = 10) {
    const results = [];
    let page = 1;
    let hasMore = true;
    
    while (hasMore) {
      const data = await this.apiClient.request(`${endpoint}?page=${page}&per_page=${pageSize}`, params);
      results.push(...data);
      
      hasMore = data.length === pageSize;
      page++;
      
      // Yield control to allow UI updates
      await new Promise(resolve => setTimeout(resolve, 0));
    }
    
    return results;
  }
}
```

### 4.3 Error Handling

**Comprehensive Error Handling:**
```javascript
class ErrorHandler {
  constructor() {
    this.retryDelays = [1000, 2000, 5000, 10000]; // Exponential backoff
  }
  
  async withRetry(requestFn, maxRetries = 3) {
    let lastError;
    
    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await requestFn();
      } catch (error) {
        lastError = error;
        
        if (attempt === maxRetries) {
          throw error;
        }
        
        if (this.isRetryableError(error)) {
          await this.delay(this.retryDelays[attempt] || this.retryDelays[this.retryDelays.length - 1]);
          continue;
        }
        
        throw error;
      }
    }
  }
  
  isRetryableError(error) {
    // Network errors, 5xx server errors, rate limiting
    return error.message.includes('Network') || 
           error.message.includes('HTTP 5') ||
           error.message.includes('HTTP 429');
  }
  
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## Phase 5: Remove Server-Side Components

### 5.1 Clean Up Server Code

**Remove API Client Module:**
```elixir
# Remove entire file: lib/ltzf_ap/api_client.ex
# Remove from application supervision tree
```

**Update Session Module:**
```elixir
# lib/ltzf_ap/session.ex - Simplified for minimal server state only
defmodule LtzfAp.Session do
  use GenServer
  
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  def init(_) do
    {:ok, %{}}
  end
  
  # Only keep minimal server-side state if needed
  # Most session management moves to client-side
end
```

**Update Auth Module:**
```elixir
# lib/ltzf_ap/auth.ex - Simplified for client-side validation
defmodule LtzfAp.Auth do
  @moduledoc """
  Minimal authentication utilities for client-side validation.
  """
  
  @valid_scopes ["admin", "keyadder"]
  
  def valid_scope?(scope) when scope in @valid_scopes, do: true
  def valid_scope?(_), do: false
  
  def can_manage_keys?("admin"), do: true
  def can_manage_keys?("keyadder"), do: true
  def can_manage_keys?(_), do: false
  
  def scope_display_name("admin"), do: "Administrator"
  def scope_display_name("keyadder"), do: "Key Manager"
  def scope_display_name(scope), do: scope
end
```

### 5.2 Update Configuration

**Remove Dependencies:**
```elixir
# mix.exs - Remove server-side dependencies
defp deps do
  [
    {:phoenix, "~> 1.7.21"},
    {:phoenix_html, "~> 4.1"},
    {:phoenix_live_reload, "~> 1.2", only: :dev},
    {:phoenix_live_view, "~> 1.0"},
    {:floki, ">= 0.30.0", only: :test},
    {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
    {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
    {:heroicons, github: "tailwindlabs/heroicons", tag: "v2.1.1"},
    {:telemetry_metrics, "~> 1.0"},
    {:telemetry_poller, "~> 1.0"},
    {:gettext, "~> 0.26"},
    {:jason, "~> 1.2"},
    {:dns_cluster, "~> 0.1.1"},
    {:bandit, "~> 1.5"},
    # Removed: {:finch, "~> 0.18"},
    # Removed: {:ecto_sqlite3, "~> 0.12"},
    # Removed: {:cloak, "~> 1.1"},
    # Removed: {:uuid, "~> 1.1"}
  ]
end
```

**Update Application Supervision:**
```elixir
# lib/ltzf_ap/application.ex
def start(_type, _args) do
  children = [
    LtzfApWeb.Telemetry,
    {DNSCluster, query: Application.get_env(:ltzf_ap, :dns_cluster_query) || :ignore},
    {Phoenix.PubSub, name: LtzfAp.PubSub},
    # Removed: LtzfAp.ApiClient,
    # Removed: LtzfAp.Session,
    LtzfApWeb.Endpoint
  ]

  opts = [strategy: :one_for_one, name: LtzfAp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Implementation Timeline

### Week 1: Foundation
- [ ] Create client-side API client
- [ ] Implement authentication manager
- [ ] Create data store and caching
- [ ] Set up security utilities

### Week 2: Core Migration
- [ ] Update login flow
- [ ] Migrate dashboard to client-side
- [ ] Update session management
- [ ] Implement error handling

### Week 3: Feature Migration
- [ ] Migrate Vorgaenge page
- [ ] Migrate Sitzungen page
- [ ] Migrate Enumerations page
- [ ] Migrate Key Management page

### Week 4: Testing & Optimization
- [ ] Comprehensive testing
- [ ] Performance optimization
- [ ] Security audit
- [ ] Remove server-side components

### Week 5: Deployment
- [ ] Production deployment
- [ ] Monitoring setup
- [ ] Documentation updates
- [ ] User training

## Benefits of Client-Side Architecture

### Security Benefits
- **API keys never leave the client browser**
- **No server-side storage of sensitive credentials**
- **Reduced attack surface on server**
- **Better privacy for users**

### Performance Benefits
- **Direct client-to-backend communication**
- **Reduced server load and bandwidth usage**
- **Faster response times**
- **Better scalability**

### Development Benefits
- **Simplified server architecture**
- **Easier to implement real-time features**
- **Better separation of concerns**
- **Reduced server maintenance**

### User Experience Benefits
- **Faster page loads**
- **Better offline support potential**
- **More responsive UI**
- **Reduced server dependency**

## Risk Mitigation

### Security Risks
- **Browser storage security**: Use sessionStorage for sensitive data, implement proper encryption
- **XSS attacks**: Implement proper CSP headers, sanitize all user inputs
- **CSRF attacks**: Maintain CSRF protection for LiveView communication

### Technical Risks
- **Browser compatibility**: Test across major browsers, implement polyfills if needed
- **Network failures**: Implement comprehensive error handling and retry logic
- **API changes**: Maintain versioning strategy for client-side API client

### Migration Risks
- **Data loss**: Implement parallel systems during transition
- **User disruption**: Gradual rollout with fallback support
- **Testing coverage**: Comprehensive testing of all migrated features

## Conclusion

This migration plan provides a clear path to move from server-side to client-side API requests while maintaining security and improving performance. The phased approach ensures a smooth transition with minimal disruption to users.

The client-side architecture eliminates the security risk of API key transmission to our server while providing a better user experience through direct API communication. The implementation timeline allows for thorough testing and validation at each stage.

Key success factors:
1. **Comprehensive testing** at each phase
2. **Gradual rollout** with fallback support
3. **Security audit** before production deployment
4. **User training** on new authentication flow
5. **Monitoring** of performance and error rates

This migration will result in a more secure, performant, and maintainable application architecture. 