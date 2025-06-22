# Landtagszusammenfasser Administration Panel

This is the administration panel for the Landtagszusammenfasser API server. It provides a web interface for managing API keys, data, and manual data input.

The code is AI generated, I cannot program Elixir even in the slightest.

## Overview

The administration panel is built using Elixir and Phoenix, providing a secure and efficient interface for managing the Landtagszusammenfasser API server. The panel is divided into three main sections:

1. Key Management and Authorization
2. Data Management
3. Manual Data Input
## User Management Concept
The system employs an user account concept. 
Each user of the administration panel is uniquely identified by their email.
Each user of the administration panel is authorized by their password.

There is a superuser, which is the first user to register. They have the unique ability to activate/deactivate other accounts.

The first page of the web app is the registration page for the superuser.

## Key Management and Authorization Panel

### Features
- API Key Management
  - Create new API keys with different scopes (admin, collector, keyadder)
  - View existing API keys and their status
  - Rotate API keys with transition periods
  - Delete/revoke API keys
  - Set expiration dates for keys
- Authorization Control
  - View key usage statistics
  - Monitor rate limiting
  - Track key health and rotation status

The API Keys used to authorize the operations with the server are stored locally _only_.
They are to be put in by the user at each session entry.
They are deleted after the session expires.

### Components Needed
- API Key CRUD operations interface
- Key rotation workflow
- Key status dashboard
- Usage monitoring and analytics
- Rate limit visualization

## Data Management Panel

### Features
- Legislative Process Management
  - View and search through legislative processes (Vorgänge)
  - Edit or delete existing processes
  - View process history and modifications
- Session Management
  - Manage parliamentary sessions (Sitzungen)
  - Edit session details and documents
  - Handle session scheduling
- Document Management
  - Upload and manage documents
  - Edit document metadata
  - Link documents to processes and sessions
- Committee and Enumeration Management
  - Manage committees (Gremien), authors (Autoren) and the various enumerations
  - Edit details
  - Dedup and Delete entries

### Components Needed
- Data browser with filtering and search
- CRUD interfaces for all data types
- Document upload and management system
- Data validation and integrity checks
- Audit logging system

## Manual Data Input Panel

### Features
- Process Creation
  - Create new legislative processes
  - Add stations and documents
  - Set process metadata
- Session Creation
  - Create new parliamentary sessions
  - Add agenda items (TOPs)
  - Manage session documents
- Document Creation
  - Create new documents
  - Add document metadata
  - Link documents to processes/sessions
- Author Management
  - Add new authors
  - Manage author metadata
  - Link authors to documents

### Components Needed
- Form-based input interfaces
- Rich text editor for document content
- Document template system
- Validation and error handling
- Preview functionality

## Technical Requirements

### Backend
- Elixir/Phoenix application
- Authentication system
- Role-based access control
- API integration with main server
- Data validation and sanitization
- Audit logging

### Frontend
- Modern, responsive UI
- Real-time updates
- Form validation
- Rich text editing
- File upload handling
- Search and filtering
- Data visualization

### Security
- Secure authentication
- CSRF protection
- XSS prevention
- Input sanitization
- Rate limiting
- Audit logging

## Development Phases

1. **Phase 1: Foundation**
   - Basic application setup
   - Authentication system
   - Core UI components
   - API integration

2. **Phase 2: Key Management**
   - API key CRUD
   - Key rotation system
   - Usage monitoring

3. **Phase 3: Data Management**
   - Data browser
   - CRUD operations
   - Document management
   - Search and filtering

4. **Phase 4: Manual Input**
   - Form interfaces
   - Document creation
   - Validation system
   - Preview functionality

5. **Phase 5: Polish**
   - UI/UX improvements
   - Performance optimization
   - Additional features
   - Documentation

## Getting Started

(To be added as development progresses)

## Contributing

(To be added as development progresses)

## License

(To be added as development progresses)
