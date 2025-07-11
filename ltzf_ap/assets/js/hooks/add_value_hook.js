// Hook for handling add value button clicks
const AddValueHook = {
  mounted() {
    console.log("AddValueHook mounted on:", this.el);
    
    this.handleEvent("click", (e) => {
      console.log("AddValueHook click event triggered");
      
      // Get the filter input name from the button's data attribute
      const filterInputName = this.el.dataset.filterInput;
      console.log("Filter input name:", filterInputName);
      
      // Find the input field with that name
      const inputElement = document.querySelector(`input[name="${filterInputName}"]`);
      console.log("Found input element:", inputElement);
      
      if (inputElement) {
        // Get the current value from the input field
        const currentValue = inputElement.value;
        console.log("Current input value:", currentValue);
        
        // Update the phx-value-value attribute with the current input value
        this.el.setAttribute('phx-value-value', currentValue);
        console.log("Updated phx-value-value to:", currentValue);
      } else {
        console.error("Could not find input element with name:", filterInputName);
      }
    });
  }
};

export default AddValueHook; 