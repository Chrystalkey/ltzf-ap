// API Hook for LiveView client-side API communication
// Handles API requests and communicates results back to LiveView

const ApiHook = {
  mounted() {
    this.apiClient = null;
    this.authManager = new AuthManager();
    this.dataStore = new DataStore();
    this.requestId = 0;
    this.sessionRestoreAttempts = 0;
    this.maxSessionRestoreAttempts = 2;
    
    // Initialize API client if credentials are available
    this.initializeApiClient();
    
    // Test event handler to see if events are being received
    this.handleEvent("test", (data) => {
      // Test event handler
    });

    this.handleEvent("api_request", async (data) => {
      try {
        if (!this.apiClient) throw new Error("API client not initialized");
        const result = await this.executeApiRequest(data);
        this.pushEvent("api_response", { request_id: data.request_id || data.id, result, success: true });
      } catch (error) {
        this.pushEvent("api_response", { request_id: data.request_id || data.id, error: error.message, success: false });
      }
    });
    
    this.handleEvent("authenticate", async (data) => {
      try {
        const result = await this.authManager.validateCredentials(data.backend_url, data.api_key);
        if (result.success) {
          const expiresAt = new Date();
          expiresAt.setDate(expiresAt.getDate() + (data.remember_key ? 7 : 1));
          const stored = this.authManager.storeCredentials(data.backend_url, data.api_key, result.scope, expiresAt);
          if (stored) {
            this.apiClient = this.authManager.getApiClient();
            this.pushEvent("auth_success", { credentials: { backend_url: data.backend_url, scope: result.scope, expires_at: expiresAt.toISOString() } });
          } else {
            this.pushEvent("auth_failure", { error: "Failed to store credentials" });
          }
        } else {
          this.pushEvent("auth_failure", { error: result.error });
        }
      } catch (error) {
        this.pushEvent("auth_failure", { error: error.message });
      }
    });
    
    this.handleEvent("restore_session", async () => {
      // Prevent infinite restore attempts
      if (this.sessionRestoreAttempts >= this.maxSessionRestoreAttempts) {
        console.error('Too many session restore attempts, clearing credentials');
        this.authManager.clearCredentials();
        this.sessionRestoreAttempts = 0;
        this.pushEvent("session_expired", { error: "Session restoration failed, please login again" });
        return;
      }
      
      this.sessionRestoreAttempts++;
      
      try {
        const validation = await this.authManager.validateStoredCredentials();
        if (validation.valid) {
          this.apiClient = this.authManager.getApiClient();
          this.sessionRestoreAttempts = 0; // Reset on success
          this.pushEvent("session_restored", { credentials: { backend_url: validation.credentials.backendUrl, scope: validation.credentials.scope, expires_at: validation.credentials.expiresAt } });
        } else {
          // If validation failed but we haven't exceeded retries, don't clear credentials yet
          if (validation.error.includes('will retry')) {
            // Wait a bit before retrying
            setTimeout(() => {
              this.handleEvent("restore_session", {});
            }, 1000);
          } else {
            this.authManager.clearCredentials();
            this.sessionRestoreAttempts = 0;
            this.pushEvent("session_expired", { error: validation.error });
          }
        }
      } catch (error) {
        console.error('Session restoration error:', error);
        this.authManager.clearCredentials();
        this.sessionRestoreAttempts = 0;
        this.pushEvent("session_expired", { error: error.message });
      }
    });
    
    this.handleEvent("logout", () => {
      this.authManager.clearCredentials();
      this.dataStore.clear();
      this.apiClient = null;
      this.sessionRestoreAttempts = 0;
      this.pushEvent("logout_complete", {});
    });

    this.handleEvent("scroll_to_station", (data) => {
      const stationElement = document.getElementById(`station-${data.index}`);
      if (stationElement) {
        stationElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
        stationElement.style.animation = 'pulse 2s ease-in-out';
        setTimeout(() => stationElement.style.animation = '', 2000);
      }
    });
  },
  
  destroyed() {
    // Cleanup any ongoing operations
    this.dataStore.clear();
  },
  
  async executeApiRequest(data) {
    const { method, params = {} } = data;
    if (!this.apiClient || typeof this.apiClient[method] !== 'function') throw new Error(`Unknown API method: ${method}`);
    
    if (method.startsWith('get') && Object.keys(params).length === 0) {
      const cacheKey = `${method}_${JSON.stringify(params)}`;
      const cached = this.dataStore.get(cacheKey);
      if (cached) return cached;
    }
    
    let result;
    if (method === 'getVorgangById') result = await this.apiClient[method](params.id);
    else if (method === 'putVorgangById') result = await this.apiClient[method](params.id, params.data);
    else if (method === 'getDocumentById') result = await this.apiClient[method](params.apiId);
    else if (method === 'loadEnumerations') result = await this.apiClient[method]();
    else if (method === 'getEnumerations') {
      if (Array.isArray(params) && params.length >= 1) result = await this.apiClient[method](params[0], params[1] || {});
      else result = await this.apiClient[method](params.enumName, params);
    } else if (method === 'getAutoren' || method === 'getGremien') {
      if (Array.isArray(params) && params.length >= 1) result = await this.apiClient[method](params[0] || {});
      else result = await this.apiClient[method](params);
    } else if (method === 'updateEnumeration') {
      if (Array.isArray(params) && params.length >= 2) result = await this.apiClient[method](params[0], params[1], params[2] || []);
      else result = await this.apiClient[method](params.enumName, params.values, params.replacing);
    } else if (method === 'deleteEnumerationValue') {
      if (Array.isArray(params) && params.length >= 2) result = await this.apiClient[method](params[0], params[1]);
      else result = await this.apiClient[method](params.enumName, params.value);
    } else if (Array.isArray(params) && params.length === 0) result = await this.apiClient[method]();
    else if (Array.isArray(params)) result = await this.apiClient[method](...params);
    else result = await this.apiClient[method](params);
    
    if (method.startsWith('get') && Object.keys(params).length === 0) {
      this.dataStore.set(`${method}_${JSON.stringify(params)}`, result);
    }
    return result;
  },
  
  initializeApiClient() {
    try { 
      if (this.authManager.hasValidCredentials()) {
        this.apiClient = this.authManager.getApiClient();
      }
    }
    catch (error) { 
      console.error('Failed to initialize API client:', error);
    }
  },
  generateRequestId() { return `req_${++this.requestId}_${Date.now()}`; }
};

export default ApiHook; 