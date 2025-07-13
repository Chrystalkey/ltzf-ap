// Hook for handling add value button clicks
const AddValueHook = {
  mounted() {
    this.handleEvent("click", (e) => {
      // Get the filter input name from the button's data attribute
      const filterInputName = this.el.dataset.filterInput;
      
      // Find the input field with that name
      const inputElement = document.querySelector(`input[name="${filterInputName}"]`);
      
      if (inputElement) {
        // Get the current value from the input field
        const currentValue = inputElement.value;
        
        // Update the phx-value-value attribute with the current input value
        this.el.setAttribute('phx-value-value', currentValue);
      }
    });
  }
};

export default AddValueHook; 