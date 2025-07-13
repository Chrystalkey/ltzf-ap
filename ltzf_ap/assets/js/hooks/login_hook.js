const LoginHook = {
  mounted() {
    this.connectivityCheckTimeout = null;
    
    // Get the backend URL input field
    this.backendUrlInput = this.el.querySelector('input[name="login[backend_url]"]');
    
    // Add event listener for backend URL changes
    if (this.backendUrlInput) {
      this.backendUrlInput.addEventListener('input', () => {
        this.checkConnectivity();
      });
    }
    
    // Handle authentication events
    this.handleEvent("authenticate", ({backend_url, api_key, remember_key}) => {
      this.authenticate(backend_url, api_key, remember_key);
    });
  },

  checkConnectivity() {
    const backendUrl = this.backendUrlInput.value.trim();
    
    // Clear previous timeout
    if (this.connectivityCheckTimeout) {
      clearTimeout(this.connectivityCheckTimeout);
    }
    
    // Update status to checking
    this.pushEvent("connectivity_status", {status: "checking"});
    
    if (!backendUrl) {
      this.pushEvent("connectivity_status", {status: "unknown"});
      return;
    }
    
    // Validate URL format
    try {
      new URL(backendUrl);
    } catch (e) {
      this.pushEvent("connectivity_status", {status: "invalid_url"});
      return;
    }
    
    // Debounce the connectivity check
    this.connectivityCheckTimeout = setTimeout(() => {
      this.performConnectivityCheck(backendUrl);
    }, 500);
  },

  async performConnectivityCheck(backendUrl) {
    try {
      // Check for mixed content issues first
      if (window.location.protocol === 'https:' && backendUrl.startsWith('http:')) {
        this.pushEvent("connectivity_status", {
          status: "mixed_content_warning",
          message: "HTTPS frontend detected with HTTP backend. This may cause issues. Consider using HTTPS for the backend URL or configuring your reverse proxy."
        });
        return;
      }
      
      // Create a temporary API client for connectivity check
      const tempClient = new ApiClient(backendUrl, "");
      
      // Try to ping the backend
      const result = await tempClient.ping();
      
      // If successful, update status to connected
      this.pushEvent("connectivity_status", {status: "connected"});
    } catch (error) {
      // Check if it's a mixed content error
      if (error.message.includes('Mixed content error')) {
        this.pushEvent("connectivity_status", {
          status: "mixed_content_error",
          message: "Mixed content blocked by browser. Please use HTTPS for the backend URL or configure your reverse proxy to handle API requests."
        });
        return;
      }
      
      // Fallback: try a HEAD request to the base URL
      try {
        const response = await fetch(backendUrl, {
          method: 'HEAD',
          mode: 'cors',
          credentials: 'omit'
        });
        
        if (response.ok) {
          this.pushEvent("connectivity_status", {status: "connected"});
        } else {
          throw new Error(`HTTP ${response.status}`);
        }
      } catch (fallbackError) {
        this.pushEvent("connectivity_status", {
          status: "disconnected",
          message: "Cannot connect to backend. Check the URL and ensure the server is running."
        });
      }
    }
  },

  async authenticate(backendUrl, apiKey, rememberKey) {
    try {
      // Update status to checking
      this.pushEvent("connectivity_status", {status: "checking"});
      
      // Use the auth manager to validate credentials
      const authManager = new AuthManager();
      const result = await authManager.validateCredentials(backendUrl, apiKey);
      
      if (result.success) {
        // Always store credentials (session storage for current session)
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + (rememberKey ? 7 : 1)); // 7 days if remember, 1 day if not
        authManager.storeCredentials(backendUrl, apiKey, result.scope, expiresAt);
        
        // Notify success
        this.pushEvent("auth_success", {credentials: {
          backend_url: backendUrl,
          scope: result.scope,
          expires_at: expiresAt.toISOString()
        }});
      } else {
        // Notify failure
        this.pushEvent("auth_failure", {error: result.error});
      }
    } catch (error) {
      this.pushEvent("auth_failure", {error: "Authentication failed: " + error.message});
    }
  }
};

export default LoginHook; 