const SessionHook = {
  mounted() {
    // Handle getting stored session
    this.handleEvent("get_stored_session", () => {
      const session = window.SessionStorage.getSession();
      if (session) {
        this.pushEvent("restore_session", {session_id: session.sessionId});
      } else {
        this.pushEvent("no_stored_session", {});
      }
    });

    // Handle clearing session on logout
    this.handleEvent("clear_session", () => {
      window.SessionStorage.clearSession();
    });
  }
};

export default SessionHook; 