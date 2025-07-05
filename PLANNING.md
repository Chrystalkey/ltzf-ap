# LTZF Administration Panel (ltzf-ap)

## Summary
This project is intended to be used as a web application to administer the database accessible via the API specified in [openapi.yml](./openapi.yml).

## User and Session Concept
This application has no concept of "Users". Instead, a user is fully identified by supplying the API Key used to authenticate him with the backend.
The Key is stored locally for the duration of the current session.

If the user so chooses, he may extend the session to up to a week, after which he must reauthenticate with the key.

## Pages and Structure

### Overview

The page structure of the application should be as follows:

```mermaid
Login -> Dashboard
Dashboard -> KeyManagement
Dashboard -> Vorgaenge
Dashboard -> Sitzungen
Dashboard -> Enumerations
```
For all pages, if they depend on any data fetched from the backend, they should first load the page structure with a placeholder for snappy loading times and then fetch the data from the backend.

The Login page should be displayed if no session is active, otherwise the dashboard. 

If logged in, there should be a consistent header displaying 
1. the Name of the application
2. the authorization level of the key supplied
3. a logout button ending the session and redirecting to the login page
4. a timer until the session expires

### Login Page
The login page should display two input fields:
1. An input field for the Backend URL
    1. The value should be persisted across reloads.
    2. If no value is known, the input field should be empty and display a hint
    3. On change, a recheck of connectivity should happen, using the `/ping` endpoint of the API
2. An input field for the API Key
    1. should be protected with a side-button to reveal/hide

As well as a login button. The login button should check the validity of the key with the `/api/v1/auth/status`.
A key is valid, if it's authorization level is Keyadder or Admin. Otherwise the check fails.
On successful login, the page should redirect to the dashboard.

### The Dashboard.

Should display four panels leading to the key management, vorgangs, sitzungs, and enumerations subpages.
On the panels the number of elements should be displayed. 

### Key Management

TODO; Insert empty placeholder page

### Vorgänge
TODO; Insert empty placeholder page

### Sitzungen
TODO; Insert empty placeholder page

### Enumerations
TODO; Insert empty placeholder page

## Implementation Details

### Technology Stack

**Backend Framework**: Phoenix LiveView
- Provides real-time, reactive UI updates without JavaScript
- Server-side rendering with client-side interactivity
- Built-in WebSocket support for real-time features

**Database**: SQLite (for local session storage)
- Lightweight, file-based database for storing session data
- No external database dependencies required
- Perfect for local session management

**HTTP Client**: Finch
- High-performance HTTP client for Elixir
- Connection pooling for efficient API calls
- Built-in support for connection reuse

**Authentication**: Custom session-based
- Session tokens stored in SQLite
- API key encrypted in session storage
- Automatic session expiration handling

**UI Framework**: Tailwind CSS
- Utility-first CSS framework
- Responsive design out of the box
- Modern, clean aesthetic

**Build Tool**: Mix
- Standard Elixir build tool
- Asset compilation and optimization
- Development server with hot reload

### Architecture Patterns

**LiveView Architecture**
- Single-page application feel with server-side rendering
- Real-time updates for session timer and connectivity status
- Optimistic UI updates with fallback error handling

**Session Management**
- Encrypted session storage in SQLite
- Automatic session cleanup on expiration
- Secure API key handling with encryption at rest

**API Integration Layer**
- Centralized HTTP client with connection pooling
- Automatic retry logic for failed requests
- Rate limiting awareness and handling

**Error Handling**
- Graceful degradation for API connectivity issues
- User-friendly error messages
- Automatic reconnection attempts

### Core Modules and Responsibilities

**Session Management**
- Session creation, validation, and cleanup
- API key encryption/decryption
- Session expiration tracking
- Automatic logout on session expiry

**API Client**
- HTTP request handling with proper headers
- Response parsing and error handling
- Connection pooling and retry logic
- Rate limit monitoring

**Authentication Service**
- API key validation against backend
- Authorization level checking (Keyadder/Admin)
- Session token generation and validation

**Data Fetching**
- Lazy loading of dashboard statistics
- Pagination handling for large datasets
- Caching strategies for frequently accessed data
- Real-time data updates where appropriate

**UI Components**
- Reusable LiveView components
- Responsive design patterns
- Loading states and error handling
- Consistent styling with Tailwind

### Security Considerations

**API Key Security**
- Encryption at rest in session storage
- Secure transmission over HTTPS
- Automatic key rotation support
- No logging of sensitive key data

**Session Security**
- Secure session token generation
- Automatic session invalidation
- Protection against session hijacking
- Secure cookie handling

**Input Validation**
- Server-side validation of all inputs
- Protection against injection attacks
- Rate limiting on authentication attempts
- Secure error message handling

### Performance Optimizations

**Caching Strategy**
- Local caching of API responses
- Intelligent cache invalidation
- Background data prefetching
- Optimistic UI updates

**Connection Management**
- HTTP connection pooling
- Automatic connection health checks
- Graceful handling of network issues
- Efficient resource cleanup

**UI Performance**
- Lazy loading of page content
- Optimistic updates for better UX
- Efficient re-rendering with LiveView
- Minimal JavaScript usage

### Development Workflow

**Local Development**
- Hot reload for rapid development
- SQLite database for local testing
- Mock API responses for offline development
- Comprehensive logging and debugging

**Testing Strategy**
- Unit tests for core business logic
- Integration tests for API interactions
- LiveView testing for UI components
- End-to-end testing for critical flows

**Deployment Considerations**
- Single binary deployment with releases
- Environment-based configuration
- Health check endpoints
- Graceful shutdown handling

### Data Flow Patterns

**Authentication Flow**
1. User enters backend URL and API key
2. System validates connectivity with `/ping`
3. System validates API key with `/api/v1/auth/status`
4. On success, creates encrypted session
5. Redirects to dashboard with session token

**Dashboard Data Loading**
1. Load page structure immediately
2. Fetch statistics in background
3. Update UI with loading states
4. Display data when available
5. Handle errors gracefully

**Real-time Updates**
1. Session timer updates every minute
2. Connectivity status monitoring
3. Automatic reconnection attempts
4. User notification of status changes

### Error Handling Strategy

**Network Errors**
- Automatic retry with exponential backoff
- User-friendly error messages
- Graceful degradation of features
- Connection status indicators

**Authentication Errors**
- Clear error messages for invalid credentials
- Automatic session cleanup on auth failures
- Secure error logging without sensitive data
- Helpful guidance for resolution

**API Errors**
- Proper HTTP status code handling
- Rate limit awareness and user notification
- Retry logic for transient failures
- Fallback behavior for critical features

### Monitoring and Observability

**Application Metrics**
- Request/response timing
- Error rates and types
- Session duration statistics
- API call success rates

**User Experience Metrics**
- Page load times
- Authentication success rates
- Feature usage patterns
- Error recovery rates

**System Health**
- Database connection status
- API connectivity monitoring
- Resource usage tracking
- Performance degradation detection