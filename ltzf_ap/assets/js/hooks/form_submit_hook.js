// Hook for handling form submissions without page reload
const FormSubmitHook = {
  mounted() {
    this.handleEvent("submit", (e) => {
      e.preventDefault();
      
      // Get the form element
      const form = this.el;
      
      // Collect form data
      const formData = new FormData(form);
      const data = {};
      
      for (let [key, value] of formData.entries()) {
        data[key] = value;
      }
      
      // Send the data to the LiveView
      this.pushEvent("form_submit", data);
    });
  }
};

export default FormSubmitHook;
