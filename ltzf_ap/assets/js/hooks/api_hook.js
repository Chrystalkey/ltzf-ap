// API Hook for LiveView client-side API communication
// Handles API requests and communicates results back to LiveView

const ApiHook = {
  mounted() {
    console.log("ApiHook: mounted() called");
    console.log("ApiHook: this.el =", this.el);
    console.log("ApiHook: this.pushEvent =", typeof this.pushEvent);
    console.log("ApiHook: this.handleEvent =", typeof this.handleEvent);
    
    this.apiClient = null;
    this.authManager = new AuthManager();
    this.dataStore = new DataStore();
    this.requestId = 0;
    
    // Initialize API client if credentials are available
    this.initializeApiClient();
    
    // Test event handler to see if events are being received
    this.handleEvent("test", (data) => {
      console.log("ApiHook: received test event", data);
    });

    // Handle API requests from LiveView
    console.log("ApiHook: registering api_request handler");
    this.handleEvent("api_request", async (data) => {
      console.log("ApiHook: received api_request", data);
      try {
        if (!this.apiClient) {
          console.error("ApiHook: API client not initialized");
          throw new Error("API client not initialized");
        }
        
        console.log("ApiHook: executing API request", data.method, data.params);
        const result = await this.executeApiRequest(data);
        console.log("ApiHook: API request successful", data.request_id, result);
        this.pushEvent("api_response", { 
          request_id: data.request_id || data.id, 
          result,
          success: true 
        });
      } catch (error) {
        console.error("ApiHook: API request failed", data.request_id, error);
        this.pushEvent("api_response", { 
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

    // Handle scrolling to newly added stations
    this.handleEvent("scroll_to_station", (data) => {
      const { index } = data;
      const stationElement = document.getElementById(`station-${index}`);
      if (stationElement) {
        // Smooth scroll to the station
        stationElement.scrollIntoView({ 
          behavior: 'smooth', 
          block: 'center' 
        });
        
        // Add a subtle pulse animation
        stationElement.style.animation = 'pulse 2s ease-in-out';
        setTimeout(() => {
          stationElement.style.animation = '';
        }, 2000);
      }
    });
  },
  
  destroyed() {
    console.log("ApiHook: destroyed() called");
    // Cleanup any ongoing operations
    this.dataStore.clear();
  },
  
  // Execute API request based on method name
  async executeApiRequest(data) {
    const { method, params = {} } = data;
    
    console.log("ApiHook: executeApiRequest", method, params);
    console.log("ApiHook: apiClient methods", Object.getOwnPropertyNames(Object.getPrototypeOf(this.apiClient)));
    
    if (!this.apiClient || typeof this.apiClient[method] !== 'function') {
      throw new Error(`Unknown API method: ${method}`);
    }
    
    // Check cache first for GET requests
    if (method.startsWith('get') && Object.keys(params).length === 0) {
      const cacheKey = `${method}_${JSON.stringify(params)}`;
      const cached = this.dataStore.get(cacheKey);
      if (cached) {
        return cached;
      }
    }
    
    // Execute the API call
    let result;
    if (method === 'getVorgangById') {
      console.log("ApiHook: calling getVorgangById with id", params.id);
      result = await this.apiClient[method](params.id);
    } else if (method === 'putVorgangById') {
      console.log("ApiHook: calling putVorgangById with id", params.id);
      result = await this.apiClient[method](params.id, params.data);
    } else if (method === 'loadEnumerations') {
      console.log("ApiHook: calling loadEnumerations");
      result = await this.apiClient[method]();
    } else if (method === 'getEnumerations') {
      // Handle both array format [enumName, filters] and object format {enumName, ...}
      if (Array.isArray(params) && params.length >= 1) {
        const enumName = params[0];
        const filters = params[1] || {};
        result = await this.apiClient[method](enumName, filters);
      } else {
        result = await this.apiClient[method](params.enumName, params);
      }
    } else if (method === 'getAutoren' || method === 'getGremien') {
      // Handle array format [filters] for autoren and gremien
      if (Array.isArray(params) && params.length >= 1) {
        const filters = params[0] || {};
        result = await this.apiClient[method](filters);
      } else {
        result = await this.apiClient[method](params);
      }
    } else if (method === 'updateEnumeration') {
      // Handle array format [enumName, values, replacing] for updateEnumeration
      if (Array.isArray(params) && params.length >= 2) {
        const enumName = params[0];
        const values = params[1];
        const replacing = params[2] || [];
        result = await this.apiClient[method](enumName, values, replacing);
      } else {
        result = await this.apiClient[method](params.enumName, params.values, params.replacing);
      }
    } else if (method === 'deleteEnumerationValue') {
      // Handle array format [enumName, value] for deleteEnumerationValue
      if (Array.isArray(params) && params.length >= 2) {
        const enumName = params[0];
        const value = params[1];
        result = await this.apiClient[method](enumName, value);
      } else {
        result = await this.apiClient[method](params.enumName, params.value);
      }
    } else if (Array.isArray(params) && params.length === 0) {
      // No parameters, call method directly
      result = await this.apiClient[method]();
    } else if (Array.isArray(params)) {
      result = await this.apiClient[method](...params);
    } else {
      result = await this.apiClient[method](params);
    }
    
    // Cache GET requests
    if (method.startsWith('get') && Object.keys(params).length === 0) {
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