// Client-side API client for LTZF Administration Panel
// Handles all API communication directly from browser to backend

class ApiClient {
  constructor(baseUrl, apiKey) {
    this.baseUrl = this.normalizeBackendUrl(baseUrl);
    this.apiKey = apiKey;
  }
  
  // Normalize backend URL to use HTTPS if frontend is HTTPS
  normalizeBackendUrl(url) {
    try {
      const urlObj = new URL(url);
      
      // If the frontend is served over HTTPS, force the backend to also use HTTPS
      if (window.location.protocol === 'https:' && urlObj.protocol === 'http:') {
        urlObj.protocol = 'https:';
        console.warn('Mixed content detected: Converting backend URL from HTTP to HTTPS');
        return urlObj.toString();
      }
      
      return url;
    } catch (error) {
      console.error('Invalid backend URL:', error);
      return url;
    }
  }
  
  async request(endpoint, options = {}) {
    let url = `${this.baseUrl}${endpoint}`;
    
    // Handle query parameters
    if (options.params) {
      const queryString = new URLSearchParams(options.params).toString();
      if (queryString) {
        url += `?${queryString}`;
      }
    }
    
    const headers = {
      'X-API-Key': this.apiKey,
      'Content-Type': 'application/json',
      ...options.headers
    };
    
    try {
      const response = await fetch(url, {
        method: options.method || 'GET',
        headers,
        body: options.body,
        mode: 'cors', // Ensure CORS is enabled
        credentials: 'omit' // Don't send cookies to avoid mixed content issues
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      
      // Handle empty responses (204 No Content and 201 Created)
      if (response.status === 204 || response.status === 201) {
        return { data: null, headers: this.extractHeaders(response.headers) };
      }
      
      const data = await response.json();
      return { 
        data: data, 
        headers: this.extractHeaders(response.headers)
      };
    } catch (error) {
      // Handle specific HTTPS/mixed content errors
      if (error.name === 'TypeError' && error.message.includes('Failed to fetch')) {
        // Check if this is a mixed content error
        if (window.location.protocol === 'https:' && this.baseUrl.startsWith('http:')) {
          throw new Error('Mixed content error: HTTPS page trying to access HTTP API. Please use HTTPS for the backend URL or configure your reverse proxy to handle API requests.');
        }
        throw new Error('Network error - check CORS or server availability');
      }
      throw new Error(`API request failed: ${error.message}`);
    }
  }
  
  extractHeaders(headers) {
    const result = {};
    headers.forEach((value, key) => {
      result[key.toLowerCase()] = value;
    });
    return result;
  }
  
  // Connectivity and Authentication
  async ping() {
    const url = `${this.baseUrl}/ping`;
    
    try {
      const response = await fetch(url, {
        method: 'GET',
        mode: 'cors',
        credentials: 'omit', // Don't send cookies to avoid mixed content issues
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'Content-Type': 'application/json'
        }
      });
      
      // For ping, we only care if the request was successful
      // Don't try to parse JSON response
      if (response.ok) {
        return { status: 'ok' };
      } else {
        throw new Error(`HTTP ${response.status}`);
      }
    } catch (error) {
      // Handle CORS and network errors
      if (error.name === 'TypeError' && error.message.includes('Failed to fetch')) {
        // Check if this is a mixed content error
        if (window.location.protocol === 'https:' && this.baseUrl.startsWith('http:')) {
          throw new Error('Mixed content error: HTTPS page trying to access HTTP API. Please use HTTPS for the backend URL or configure your reverse proxy to handle API requests.');
        }
        throw new Error('Network error - check CORS or server availability');
      }
      throw new Error(`Ping failed: ${error.message}`);
    }
  }
  
  async authStatus() {
    const response = await this.request('/api/v1/auth/status');
    return response.data;
  }
  
  // Dashboard Statistics
  async loadDashboardStats() {
    try {
      const [vorgaenge, sitzungen] = await Promise.all([
        this.getVorgaenge({ per_page: 5 }),
        this.getSitzungen({ per_page: 5 })
      ]);
      
      const result = {
        vorgaenge: vorgaenge.count,
        sitzungen: sitzungen.count,
        enumerations: 6 // Fixed count for now
      };
      return result;
    } catch (error) {
      console.error('Error loading dashboard stats:', error);
      return {
        vorgaenge: 'Error',
        sitzungen: 'Error',
        enumerations: 'Error'
      };
    }
  }
  
  async getVorgaengeCount() {
    try {
      const response = await this.getVorgaenge({ per_page: 1 });
      return response.count || 0;
    } catch (error) {
      console.error('Error getting vorgaenge count:', error);
      return 'Error';
    }
  }
  
  async getSitzungenCount() {
    try {
      const response = await this.getSitzungen({ per_page: 1 });
      return response.count || 0;
    } catch (error) {
      console.error('Error getting sitzungen count:', error);
      return 'Error';
    }
  }
  
  // Enumerations
  async loadEnumerations() {
    try {
      const enumNames = [
        'schlagworte',
        'stationstypen',
        'vorgangstypen',
        'parlamente',
        'vgidtypen',
        'dokumententypen'
      ];
      
      const results = await Promise.all(
        enumNames.map(async (enumName) => {
          try {
            const data = await this.getEnumerations(enumName);
            return [enumName, data];
          } catch (error) {
            console.warn(`Failed to load enumeration ${enumName}:`, error);
            return [enumName, []];
          }
        })
      );
      
      return Object.fromEntries(results);
    } catch (error) {
      console.error('Failed to load enumerations:', error);
      return {};
    }
  }
  
  // API Key Management
  async loadApiKeys() {
    try {
      // For now, return a mock list since the API might not have a list endpoint
      // In a real implementation, you would call the appropriate endpoint
      return [
        {
          key: "current-key",
          scope: "admin",
          created_at: new Date().toISOString(),
          expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
        }
      ];
    } catch (error) {
      console.error('Failed to load API keys:', error);
      return [];
    }
  }
  
  // Vorgaenge (Legislative Processes)
  async getVorgaenge(params = {}) {
    try {
      const response = await this.request('/api/v1/vorgang', { params });
      
      // Extract pagination info from headers
      const totalCount = response.headers['x-total-count'];
      const totalPages = response.headers['x-total-pages'];
      const currentPage = response.headers['x-page'];
      const perPage = response.headers['x-per-page'];
      
      // Handle null data (empty results)
      const data = response.data || [];
      
      return {
        data: data,
        count: totalCount ? parseInt(totalCount) : data.length,
        totalPages: totalPages ? parseInt(totalPages) : 1,
        currentPage: currentPage ? parseInt(currentPage) : 1,
        perPage: perPage ? parseInt(perPage) : (params.per_page || 32)
      };
    } catch (error) {
      console.error('Error fetching vorgaenge:', error);
      throw error;
    }
  }
  
  async getVorgangById(id) {
    const response = await this.request(`/api/v1/vorgang/${id}`);
    return response.data;
  }
  
  async putVorgangById(id, vorgangData) {
    const response = await this.request(`/api/v1/vorgang/${id}`, {
      method: 'PUT',
      body: JSON.stringify(vorgangData)
    });
    return response.data;
  }
  
  // Documents
  async getDocumentById(apiId) {
    const response = await this.request(`/api/v1/dokument/${apiId}`);
    return response.data;
  }
  
  // Sitzungen (Sessions)
  async getSitzungen(params = {}) {
    try {
      const response = await this.request('/api/v1/sitzung', { params });
      
      // Extract pagination info from headers
      const totalCount = response.headers['x-total-count'];
      const totalPages = response.headers['x-total-pages'];
      const currentPage = response.headers['x-page'];
      const perPage = response.headers['x-per-page'];
      
      // Handle null data (empty results)
      const data = response.data || [];
      
      return {
        data: data,
        count: totalCount ? parseInt(totalCount) : data.length,
        totalPages: totalPages ? parseInt(totalPages) : 1,
        currentPage: currentPage ? parseInt(currentPage) : 1,
        perPage: perPage ? parseInt(perPage) : (params.per_page || 32)
      };
    } catch (error) {
      console.error('Error fetching sitzungen:', error);
      throw error;
    }
  }
  
  // Enumerations
  async getEnumerations(enumName, params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = `/api/v1/enumeration/${enumName}${queryString ? `?${queryString}` : ''}`;
    const response = await this.request(endpoint);
    return response.data;
  }
  
  async updateEnumeration(enumName, values, replacing = []) {
    const response = await this.request(`/api/v1/enumeration/${enumName}`, {
      method: 'PUT',
      body: JSON.stringify({ objects: values, replacing })
    });
    return response.data;
  }
  
  async deleteEnumerationValue(enumName, value) {
    const encodedValue = encodeURIComponent(value);
    const response = await this.request(`/api/v1/enumeration/${enumName}/${encodedValue}`, {
      method: 'DELETE'
    });
    return response.data;
  }
  
  // Autoren and Gremien
  async getAutoren(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = `/api/v1/autoren${queryString ? `?${queryString}` : ''}`;
    const response = await this.request(endpoint);
    return response.data;
  }
  
  async updateAutoren(autorenData) {
    const response = await this.request('/api/v1/autoren', {
      method: 'PUT',
      body: JSON.stringify({
        objects: autorenData.objects,
        replacing: autorenData.replacing || []
      })
    });
    return response.data;
  }
  
  async deleteAutorenByParams(params) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = `/api/v1/autoren${queryString ? `?${queryString}` : ''}`;
    const response = await this.request(endpoint, { method: 'DELETE' });
    return response.data;
  }
  
  async getGremien(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = `/api/v1/gremien${queryString ? `?${queryString}` : ''}`;
    const response = await this.request(endpoint);
    return response.data;
  }
  
  async updateGremien(gremienData) {
    const response = await this.request('/api/v1/gremien', {
      method: 'PUT',
      body: JSON.stringify({
        objects: gremienData.objects,
        replacing: gremienData.replacing || []
      })
    });
    return response.data;
  }
  
  async deleteGremienByParams(params) {
    const queryString = new URLSearchParams(params).toString();
    const endpoint = `/api/v1/gremien${queryString ? `?${queryString}` : ''}`;
    const response = await this.request(endpoint, { method: 'DELETE' });
    return response.data;
  }
  
  // Key Management
  async createApiKey(scope, expiresAt = null) {
    const body = { scope };
    if (expiresAt) body.expires_at = expiresAt;
    
    const response = await this.request('/api/v1/auth', {
      method: 'POST',
      body: JSON.stringify(body)
    });
    return response.data;
  }
  
  async deleteApiKey(keyToDelete) {
    const response = await this.request('/api/v1/auth', {
      method: 'DELETE',
      headers: { 'api-key-delete': keyToDelete }
    });
    return response.data;
  }
}

// Export for use in other modules
window.ApiClient = ApiClient; 