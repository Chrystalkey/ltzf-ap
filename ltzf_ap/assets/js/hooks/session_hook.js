const SessionHook = {
  mounted() {
    console.log("SessionHook mounted");
    
    // Handle getting stored session
    this.handleEvent("get_stored_session", () => {
      console.log("get_stored_session event received");
      const session = window.SessionStorage.getSession();
      console.log("Retrieved session:", session);
      if (session) {
        console.log("Pushing restore_session event with ID:", session.sessionId);
        this.pushEvent("restore_session", {session_id: session.sessionId});
      } else {
        console.log("No stored session found, pushing no_stored_session event");
        this.pushEvent("no_stored_session", {});
      }
    });

    // Handle clearing session on logout
    this.handleEvent("clear_session", () => {
      console.log("clear_session event received");
      window.SessionStorage.clearSession();
    });
  }
};

export default SessionHook; 