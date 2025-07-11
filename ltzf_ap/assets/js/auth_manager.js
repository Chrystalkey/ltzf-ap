// Authentication manager for client-side authentication
// Handles credential validation, storage, and session management

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
        return { success: false, error: 'Insufficient permissions. Required: admin or keyadder, got: ' + (authStatus.scope || 'none') };
      }
    } catch (error) {
      if (error.message.includes('HTTP 403')) {
        return { success: false, error: 'Invalid API key' };
      } else if (error.message.includes('HTTP 401')) {
        return { success: false, error: 'Unauthorized' };
      } else {
        return { success: false, error: 'Authentication failed: ' + error.message };
      }
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
    
    try {
      const credentials = JSON.parse(data);
      if (new Date(credentials.expiresAt) <= new Date()) {
        this.clearCredentials();
        return null;
      }
      
      return {
        ...credentials,
        apiKey: this.decryptApiKey(credentials.apiKey)
      };
    } catch (error) {
      console.error('Error parsing stored credentials:', error);
      this.clearCredentials();
      return null;
    }
  }
  
  clearCredentials() {
    sessionStorage.removeItem(this.storageKey);
  }
  
  hasValidCredentials() {
    return this.getCredentials() !== null;
  }
  
  // Simple encryption (in production, use proper encryption)
  encryptApiKey(apiKey) {
    return btoa(apiKey); // Base64 encoding
  }
  
  decryptApiKey(encryptedKey) {
    return atob(encryptedKey); // Base64 decoding
  }
  
  // Get API client instance for authenticated requests
  getApiClient() {
    const credentials = this.getCredentials();
    if (!credentials) {
      throw new Error('No valid credentials found');
    }
    
    return new ApiClient(credentials.backendUrl, credentials.apiKey);
  }
  
  // Validate stored credentials against backend
  async validateStoredCredentials() {
    const credentials = this.getCredentials();
    if (!credentials) {
      return { valid: false, error: 'No stored credentials' };
    }
    
    try {
      const client = new ApiClient(credentials.backendUrl, credentials.apiKey);
      await client.authStatus();
      return { valid: true, credentials };
    } catch (error) {
      this.clearCredentials();
      return { valid: false, error: 'Stored credentials are invalid' };
    }
  }
}

// Export for use in other modules
window.AuthManager = AuthManager; 