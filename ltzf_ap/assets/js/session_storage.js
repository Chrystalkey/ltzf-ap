// Session storage utilities for LTZF Admin Panel
const SESSION_STORAGE_KEY = 'ltzf_session';

export const SessionStorage = {
  // Store session data in localStorage
  storeSession(sessionId, backendUrl, expiresAt) {
    const sessionData = {
      sessionId,
      backendUrl,
      expiresAt: expiresAt.toISOString(),
      storedAt: new Date().toISOString()
    };
    localStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(sessionData));
  },

  // Retrieve session data from localStorage
  getSession() {
    try {
      const data = localStorage.getItem(SESSION_STORAGE_KEY);
      if (!data) return null;

      const sessionData = JSON.parse(data);
      
      // Check if session has expired
      const expiresAt = new Date(sessionData.expiresAt);
      if (expiresAt <= new Date()) {
        this.clearSession();
        return null;
      }

      return sessionData;
    } catch (error) {
      console.error('Error reading session from localStorage:', error);
      this.clearSession();
      return null;
    }
  },

  // Clear session data from localStorage
  clearSession() {
    localStorage.removeItem(SESSION_STORAGE_KEY);
  },

  // Check if user has a valid stored session
  hasValidSession() {
    return this.getSession() !== null;
  }
};

// Note: Auto-redirect logic removed to prevent redirect loops
// Session validation is now handled by LiveView session restoration 