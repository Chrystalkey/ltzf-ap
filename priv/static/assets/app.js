// For Phoenix.HTML support, including form and button helpers
// copy the following scripts into your javascript bundle:
// * deps/phoenix_html/priv/static/phoenix_html.js

// For Phoenix.Channels support, copy the following scripts
// into your javascript bundle:
// * deps/phoenix/priv/static/phoenix.js

// For Phoenix.LiveView support, copy the following scripts
// into your javascript bundle:
// * deps/phoenix_live_view/priv/static/phoenix_live_view.js

// Shared edit function generator to eliminate duplication
function createEditFunction(entityType) {
  return function(id, item) {
    console.log(`Edit ${entityType}:`, id, item);
    // TODO: Implement proper edit functionality
    alert('Edit functionality not yet implemented');
  };
}

// Shared JavaScript for data management pages
class DataManagementPage {
  constructor(config) {
    this.config = config;
    
    // Ensure renderItem is a function
    if (typeof this.config.renderItem !== 'function') {
      this.config.renderItem = function(item) {
        return `<li class="px-6 py-4 border-b border-gray-100">
          <div class="text-red-600">Error: renderItem is not a function</div>
          <pre>${JSON.stringify(item, null, 2)}</pre>
        </li>`;
      };
    }
    
    this.currentPage = 1;
    this.totalPages = 1;
    this.currentFilters = {};
    
    this.init();
  }

  init() {
    this.setupEventListeners();
    this.loadData(1, {});
  }

  setupEventListeners() {
    // Filter form
    const filterForm = document.getElementById('filter-form');
    if (filterForm) {
      filterForm.addEventListener('submit', (e) => this.handleFilterSubmit(e));
    }

    // Pagination buttons
    const prevBtn = document.getElementById('prev-page');
    const nextBtn = document.getElementById('next-page');
    const prevBtnMobile = document.getElementById('prev-page-mobile');
    const nextBtnMobile = document.getElementById('next-page-mobile');

    if (prevBtn) prevBtn.addEventListener('click', () => this.handlePagination('prev'));
    if (nextBtn) nextBtn.addEventListener('click', () => this.handlePagination('next'));
    if (prevBtnMobile) prevBtnMobile.addEventListener('click', () => this.handlePagination('prev'));
    if (nextBtnMobile) nextBtnMobile.addEventListener('click', () => this.handlePagination('next'));
  }

  showLoading() {
    document.getElementById('loading-state').style.display = 'block';
    document.getElementById('results-container').style.display = 'none';
    document.getElementById('empty-state').style.display = 'none';
    document.getElementById('pagination').style.display = 'none';
  }

  showResults() {
    document.getElementById('loading-state').style.display = 'none';
    document.getElementById('results-container').style.display = 'block';
    document.getElementById('pagination').style.display = 'block';
  }

  showEmpty() {
    document.getElementById('loading-state').style.display = 'none';
    document.getElementById('results-container').style.display = 'none';
    document.getElementById('empty-state').style.display = 'block';
    document.getElementById('pagination').style.display = 'none';
  }

  buildQueryString(params) {
    const searchParams = new URLSearchParams();
    Object.keys(params).forEach(key => {
      if (params[key] && params[key] !== '') {
        searchParams.append(key, params[key]);
      }
    });
    return searchParams.toString();
  }

  updatePaginationButtons() {
    const prevBtn = document.getElementById('prev-page');
    const nextBtn = document.getElementById('next-page');
    const prevBtnMobile = document.getElementById('prev-page-mobile');
    const nextBtnMobile = document.getElementById('next-page-mobile');
    
    // Update desktop buttons
    if (this.currentPage <= 1) {
      prevBtn.disabled = true;
      prevBtn.className = 'relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-gray-100 text-sm font-medium text-gray-400 cursor-not-allowed';
    } else {
      prevBtn.disabled = false;
      prevBtn.className = 'relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50';
    }
    
    if (this.currentPage >= this.totalPages) {
      nextBtn.disabled = true;
      nextBtn.className = 'relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-gray-100 text-sm font-medium text-gray-400 cursor-not-allowed';
    } else {
      nextBtn.disabled = false;
      nextBtn.className = 'relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50';
    }
    
    // Update mobile buttons
    if (this.currentPage <= 1) {
      prevBtnMobile.disabled = true;
      prevBtnMobile.className = 'relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-400 bg-gray-100 cursor-not-allowed';
    } else {
      prevBtnMobile.disabled = false;
      prevBtnMobile.className = 'relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50';
    }
    
    if (this.currentPage >= this.totalPages) {
      nextBtnMobile.disabled = true;
      nextBtnMobile.className = 'ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-400 bg-gray-100 cursor-not-allowed';
    } else {
      nextBtnMobile.disabled = false;
      nextBtnMobile.className = 'ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50';
    }
  }

  async loadData(page = 1, filters = {}) {
    this.showLoading();
    
    const root = document.getElementById(this.config.pageId);
    const backendUrl = root.getAttribute('data-backend-url');
    const apiKey = root.getAttribute('data-api-key');
    
    if (!backendUrl || !apiKey) {
      this.showEmpty();
      return;
    }

    const params = { ...filters, page: page, per_page: 10 };
    const queryString = this.buildQueryString(params);
    const url = `${this.config.apiEndpoint}?${queryString}`;
    
    try {
      const response = await fetch(url, {
        headers: { 'X-API-Key': apiKey }
      });
      
      if (!response.ok) {
        throw new Error('Network response was not ok');
      }
      
      // Capture pagination headers before parsing JSON (case-insensitive)
      const totalCount = response.headers.get('x-total-count') || response.headers.get('X-Total-Count');
      const responseTotalPages = response.headers.get('x-total-pages') || response.headers.get('X-Total-Pages');
      
      const data = await response.json();
      const resultsList = document.getElementById('results-list');
      resultsList.innerHTML = '';
      
      if (data && data.length > 0) {
        data.forEach((item, index) => {
          const li = document.createElement('li');
          const renderedHtml = this.config.renderItem(item);
          li.innerHTML = renderedHtml;
          resultsList.appendChild(li);
        });
        
        // Update pagination info and state
        if (totalCount && responseTotalPages) {
          document.getElementById('page-info').textContent = `page ${page} of ${responseTotalPages} (${totalCount} total)`;
          this.currentPage = page;
          this.totalPages = parseInt(responseTotalPages);
        } else {
          // Fallback: if no pagination headers, assume single page
          document.getElementById('page-info').textContent = `page 1 of 1 (${data.length} items)`;
          this.currentPage = 1;
          this.totalPages = 1;
        }
        
        this.updatePaginationButtons();
        this.showResults();
      } else {
        // No data returned - show appropriate message
        if (page === 1) {
          // First page with no results
          document.getElementById('empty-state').innerHTML = `
            <h3 class="mt-2 text-sm font-medium text-gray-900">${this.config.emptyText}</h3>
            <p class="mt-1 text-sm text-gray-500">No items match your current filters.</p>
          `;
        } else {
          // Later page with no results - this shouldn't happen with proper pagination
          document.getElementById('empty-state').innerHTML = `
            <h3 class="mt-2 text-sm font-medium text-gray-900">No more items available</h3>
            <p class="mt-1 text-sm text-gray-500">This is all the data we can retrieve from the backend.</p>
          `;
        }
        this.showEmpty();
      }
    } catch (error) {
      this.showEmpty();
    }
  }

  handleFilterSubmit(event) {
    event.preventDefault();
    const formData = new FormData(event.target);
    const filters = {};
    for (let [key, value] of formData.entries()) {
      if (value) filters[key] = value;
    }
    this.currentFilters = filters;
    this.currentPage = 1;
    this.loadData(this.currentPage, filters);
  }

  handlePagination(direction) {
    if (direction === 'prev' && this.currentPage > 1) {
      this.loadData(this.currentPage - 1, this.currentFilters);
    } else if (direction === 'next' && this.currentPage < this.totalPages) {
      this.loadData(this.currentPage + 1, this.currentFilters);
    }
  }
}

// Export for use in other modules
window.DataManagementPage = DataManagementPage;
window.createEditFunction = createEditFunction;

// Global edit functions for data management pages
window.editVorgang = function(id) {
  // TODO: Implement proper edit functionality
  alert('Bearbeiten-Funktionalität noch nicht implementiert');
};

window.editSitzung = function(id) {
  // TODO: Implement proper edit functionality
  alert('Bearbeiten-Funktionalität noch nicht implementiert');
};

// Flash message auto-dismiss functionality
function setupFlashMessages() {
  const flashMessages = document.querySelectorAll('.flash-message');
  
  flashMessages.forEach(function(flash) {
    const timeout = flash.dataset.timeout || 5000;
    
    // Auto-dismiss after timeout
    const timer = setTimeout(function() {
      flash.style.opacity = '0';
      flash.style.transform = 'translate(-50%, -100%)';
      setTimeout(function() {
        flash.remove();
      }, 300);
    }, parseInt(timeout));
    
    // Manual close button
    const closeBtn = flash.querySelector('.flash-close');
    if (closeBtn) {
      closeBtn.addEventListener('click', function() {
        clearTimeout(timer);
        flash.style.opacity = '0';
        flash.style.transform = 'translate(-50%, -100%)';
        setTimeout(function() {
          flash.remove();
        }, 300);
      });
    }
  });
}

// Handle data-method links for DELETE and POST requests
document.addEventListener('DOMContentLoaded', function() {
  // Setup flash messages
  setupFlashMessages();
  
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
