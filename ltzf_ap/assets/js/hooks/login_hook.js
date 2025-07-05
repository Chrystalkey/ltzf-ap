const LoginHook = {
  mounted() {
    // Handle session storage when login is successful
    this.handleEvent("store_session", ({session_id, backend_url, expires_at}) => {
      const expiresAt = new Date(expires_at);
      window.SessionStorage.storeSession(session_id, backend_url, expiresAt);
    });
  }
};

export default LoginHook; 