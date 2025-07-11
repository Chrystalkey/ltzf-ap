// Data store for client-side caching and state management
// Provides caching, subscription system, and data synchronization

class DataStore {
  constructor() {
    this.cache = new Map();
    this.subscribers = new Map();
    this.cacheTimeout = 5 * 60 * 1000; // 5 minutes default
  }
  
  set(key, data, timeout = null) {
    const cacheTimeout = timeout || this.cacheTimeout;
    const cacheEntry = {
      data,
      timestamp: Date.now(),
      timeout: cacheTimeout
    };
    
    this.cache.set(key, cacheEntry);
    
    // Notify subscribers
    this.notifySubscribers(key, data);
  }
  
  get(key) {
    const cached = this.cache.get(key);
    if (!cached) return null;
    
    // Check if cache is still valid
    if (Date.now() - cached.timestamp > cached.timeout) {
      this.cache.delete(key);
      return null;
    }
    
    return cached.data;
  }
  
  delete(key) {
    this.cache.delete(key);
    this.notifySubscribers(key, null);
  }
  
  clear() {
    this.cache.clear();
    this.subscribers.clear();
  }
  
  subscribe(key, callback) {
    if (!this.subscribers.has(key)) {
      this.subscribers.set(key, []);
    }
    this.subscribers.get(key).push(callback);
    
    // Immediately call with current data if available
    const currentData = this.get(key);
    if (currentData !== null) {
      callback(currentData);
    }
  }
  
  unsubscribe(key, callback) {
    if (this.subscribers.has(key)) {
      const callbacks = this.subscribers.get(key);
      const index = callbacks.indexOf(callback);
      if (index > -1) {
        callbacks.splice(index, 1);
      }
      
      // Remove empty subscriber arrays
      if (callbacks.length === 0) {
        this.subscribers.delete(key);
      }
    }
  }
  
  notifySubscribers(key, data) {
    if (this.subscribers.has(key)) {
      this.subscribers.get(key).forEach(callback => {
        try {
          callback(data);
        } catch (error) {
          console.error('Error in data store subscriber:', error);
        }
      });
    }
  }
  
  // Get cache statistics
  getStats() {
    const keys = Array.from(this.cache.keys());
    const totalSubscribers = Array.from(this.subscribers.values())
      .reduce((sum, callbacks) => sum + callbacks.length, 0);
    
    return {
      cachedKeys: keys.length,
      totalSubscribers,
      cacheSize: keys.length
    };
  }
  
  // Clear expired cache entries
  cleanup() {
    const now = Date.now();
    const expiredKeys = [];
    
    for (const [key, entry] of this.cache.entries()) {
      if (now - entry.timestamp > entry.timeout) {
        expiredKeys.push(key);
      }
    }
    
    expiredKeys.forEach(key => this.cache.delete(key));
    return expiredKeys.length;
  }
  
  // Set custom cache timeout for specific keys
  setCacheTimeout(key, timeout) {
    const cached = this.cache.get(key);
    if (cached) {
      cached.timeout = timeout;
    }
  }
  
  // Get all cached keys
  getCachedKeys() {
    return Array.from(this.cache.keys());
  }
  
  // Check if key is cached and valid
  isCached(key) {
    return this.get(key) !== null;
  }
}

// Export for use in other modules
window.DataStore = DataStore; 