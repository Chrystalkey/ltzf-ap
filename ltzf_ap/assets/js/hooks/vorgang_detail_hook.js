// Vorgang Detail Hook for handling station toggle functionality
const VorgangDetailHook = {
  mounted() {
    // Handle station toggle clicks
    this.handleEvent("click", (e) => {
      if (e.target.closest('[phx-click="toggle_station"]')) {
        const button = e.target.closest('[phx-click="toggle_station"]');
        const stationDetails = button.closest('.border').querySelector('.p-4.border-t');
        
        // Toggle visibility
        if (stationDetails.style.display === 'none') {
          stationDetails.style.display = 'block';
          button.querySelector('svg').style.transform = 'rotate(180deg)';
        } else {
          stationDetails.style.display = 'none';
          button.querySelector('svg').style.transform = 'rotate(0deg)';
        }
      }
    });
  }
};

export default VorgangDetailHook; 