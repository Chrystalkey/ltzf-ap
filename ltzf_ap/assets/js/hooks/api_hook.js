// API Hook for LiveView client-side API communication
// Handles API requests and communicates results back to LiveView

const ApiHook = {
  mounted() {
    this.apiClient = null;
    this.authManager = new AuthManager();
    this.dataStore = new DataStore();
    this.requestId = 0;
    
    // Initialize API client if credentials are available
    this.initializeApiClient();
    
    // Handle API requests from LiveView
    this.handleEvent("api_request", async (data) => {
      try {
        if (!this.apiClient) {
          throw new Error("API client not initialized");
        }
        
        const result = await this.executeApiRequest(data);
        this.pushEvent("api_response", { 
          request_id: data.request_id || data.id, 
          result,
          success: true 
        });
      } catch (error) {
        this.pushEvent("api_error", { 
          request_id: data.request_id || data.id, 
          error: error.message,
          success: false 
        });
      }
    });
    
    // Handle authentication requests
    this.handleEvent("authenticate", async (data) => {
      try {
        const result = await this.authManager.validateCredentials(
          data.backend_url, 
          data.api_key
        );
        
        if (result.success) {
          // Store credentials
          const expiresAt = new Date();
          expiresAt.setDate(expiresAt.getDate() + (data.remember_key ? 7 : 1));
          
          this.authManager.storeCredentials(
            data.backend_url,
            data.api_key,
            result.scope,
            expiresAt
          );
          
          // Initialize API client
          this.apiClient = this.authManager.getApiClient();
          
          this.pushEvent("auth_success", {
            credentials: {
              backend_url: data.backend_url,
              scope: result.scope,
              expires_at: expiresAt.toISOString()
            }
          });
        } else {
          this.pushEvent("auth_failure", { error: result.error });
        }
      } catch (error) {
        this.pushEvent("auth_failure", { error: error.message });
      }
    });
    
    // Handle session restoration
    this.handleEvent("restore_session", async () => {
      try {
        const validation = await this.authManager.validateStoredCredentials();
        
        if (validation.valid) {
          this.apiClient = this.authManager.getApiClient();
          this.pushEvent("session_restored", {
            credentials: {
              backend_url: validation.credentials.backendUrl,
              scope: validation.credentials.scope,
              expires_at: validation.credentials.expiresAt
            }
          });
        } else {
          this.pushEvent("session_expired", { error: validation.error });
        }
      } catch (error) {
        this.pushEvent("session_expired", { error: error.message });
      }
    });
    
    // Handle logout
    this.handleEvent("logout", () => {
      this.authManager.clearCredentials();
      this.dataStore.clear();
      this.apiClient = null;
      this.pushEvent("logout_complete", {});
    });
  },
  
  destroyed() {
    // Cleanup any ongoing operations
    this.dataStore.clear();
  },
  
  // Execute API request based on method name
  async executeApiRequest(data) {
    const { method, params = [] } = data;
    
    if (!this.apiClient || typeof this.apiClient[method] !== 'function') {
      throw new Error(`Unknown API method: ${method}`);
    }
    
    // Check cache first for GET requests
    if (method.startsWith('get') && params.length === 0) {
      const cacheKey = `${method}_${JSON.stringify(params)}`;
      const cached = this.dataStore.get(cacheKey);
      if (cached) {
        return cached;
      }
    }
    
    // Execute the API call
    let result;
    if (Array.isArray(params) && params.length === 0) {
      // No parameters, call method directly
      result = await this.apiClient[method]();
    } else if (Array.isArray(params)) {
      result = await this.apiClient[method](...params);
    } else {
      result = await this.apiClient[method](params);
    }
    
    // Cache GET requests
    if (method.startsWith('get') && params.length === 0) {
      const cacheKey = `${method}_${JSON.stringify(params)}`;
      this.dataStore.set(cacheKey, result);
    }
    
    return result;
  },
  
  // Initialize API client from stored credentials
  initializeApiClient() {
    try {
      if (this.authManager.hasValidCredentials()) {
        this.apiClient = this.authManager.getApiClient();
      }
    } catch (error) {
      console.warn('Failed to initialize API client:', error);
    }
  },
  
  // Generate unique request ID
  generateRequestId() {
    return `req_${++this.requestId}_${Date.now()}`;
  }
};

export default ApiHook; 