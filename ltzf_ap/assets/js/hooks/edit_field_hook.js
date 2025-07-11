// Edit Field Hook for handling editable field interactions
const EditFieldHook = {
  mounted() {
    this.input = this.el.querySelector('input[type="text"]');
    
    if (this.input) {
      // Handle Enter key to save
      this.input.addEventListener('keyup', (e) => {
        if (e.key === 'Enter') {
          this.saveField();
        } else if (e.key === 'Escape') {
          this.cancelEdit();
        }
      });
    }

    // Handle save button clicks to send the current value
    const saveButton = this.el.querySelector('button[phx-click*="save"]');
    if (saveButton) {
      saveButton.addEventListener('click', (e) => {
        e.preventDefault();
        const value = this.input.value;
        const eventName = saveButton.getAttribute('phx-click');
        this.pushEvent(eventName, { value: value });
      });
    }
  },

  saveField() {
    const value = this.input.value;
    const saveButton = this.el.querySelector('button[phx-click*="save"]');
    if (saveButton) {
      // Get the event name from the button's phx-click attribute
      const eventName = saveButton.getAttribute('phx-click');
      // Push the event with the current value
      this.pushEvent(eventName, { value: value });
    }
  },

  cancelEdit() {
    const cancelButton = this.el.querySelector('button[phx-click*="cancel"]');
    if (cancelButton) {
      cancelButton.click();
    }
  }
};

export default EditFieldHook; 