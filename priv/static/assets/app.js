// For Phoenix.HTML support, including form and button helpers
// copy the following scripts into your javascript bundle:
// * deps/phoenix_html/priv/static/phoenix_html.js

// For Phoenix.Channels support, copy the following scripts
// into your javascript bundle:
// * deps/phoenix/priv/static/phoenix.js

// For Phoenix.LiveView support, copy the following scripts
// into your javascript bundle:
// * deps/phoenix_live_view/priv/static/phoenix_live_view.js

// Handle data-method links for DELETE and POST requests
document.addEventListener('DOMContentLoaded', function() {
  // Handle links with data-method attribute
  document.addEventListener('click', function(e) {
    var link = e.target.closest('a[data-method]');
    if (!link) return;
    
    e.preventDefault();
    
    var method = link.getAttribute('data-method');
    var url = link.getAttribute('href');
    var confirmMessage = link.getAttribute('data-confirm');
    
    if (confirmMessage && !confirm(confirmMessage)) {
      return;
    }
    
    // Create a form to submit the request
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = url;
    
    // Add CSRF token
    var csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    var csrfInput = document.createElement('input');
    csrfInput.type = 'hidden';
    csrfInput.name = '_csrf_token';
    csrfInput.value = csrfToken;
    form.appendChild(csrfInput);
    
    // Add method override for DELETE
    if (method.toUpperCase() === 'DELETE') {
      var methodInput = document.createElement('input');
      methodInput.type = 'hidden';
      methodInput.name = '_method';
      methodInput.value = 'DELETE';
      form.appendChild(methodInput);
    }
    
    document.body.appendChild(form);
    form.submit();
  });
});
