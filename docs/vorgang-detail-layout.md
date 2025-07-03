# Vorgang Detail View Layout

## Overview
The vorgang detail view serves as both a display and editing interface for legislative processes. It uses the PUT endpoint for saving changes and provides a compact, organized representation of all vorgang data.

## Page Structure

### Header Section
- **Page Title**: "Vorgang Details" with the vorgang's `titel` as subtitle
- **Action Buttons**: 
  - "Save Changes" (PUT to `/api/v1/vorgang/{vorgang_id}`)
  - "Cancel" (navigate back)
  - "Delete" (DELETE to `/api/v1/vorgang/{vorgang_id}`)

### Main Content - Two Column Layout

#### Left Column - Core Information
**Basic Details**
- `api_id` (read-only, UUID format)
- `titel` (text input, required)
- `kurztitel` (text input, optional)
- `typ` (dropdown, required) - values from `vorgangstyp` enum
- `wahlperiode` (number input, required, min 0)
- `verfassungsaendernd` (checkbox)

**Identifiers**
- `ids` (array of objects)
  - Each item: `id` (text) + `typ` (dropdown: initdrucks, vorgnr, api-id, sonstig)
  - Add/Remove buttons for array management

**Links**
- `links` (array of URLs)
  - Each item: URL input field
  - Add/Remove buttons for array management

#### Right Column - Participants & Metadata
**Initiators**
- `initiatoren` (array of `autor` objects)
  - Each item: `person` (text), `organisation` (text, required), `fachgebiet` (text)
  - Add/Remove buttons for array management

**Lobby Register**
- `lobbyregister` (array of `lobbyregeintrag` objects)
  - Each item: `organisation` (autor object), `interne_id` (text), `intention` (textarea), `link` (URL), `betroffene_drucksachen` (array of strings)
  - Add/Remove buttons for array management

**System Information**
- `touched_by` (read-only, display scraper information)

### Stations Section - Collapsible List

**Header**: "Stations" with expand/collapse all button

**Station Items** (default: folded)
Each station displays in collapsed state:
- **Triangle indicator** (▶ when folded, ▼ when expanded)
- **Date**: `zp_start` (formatted as DD.MM.YYYY)
- **Type**: `typ` (from `stationstyp` enum)
- **Title**: `titel` (if available)
- **Parliament**: `parlament` code

**Expanded Station Content**:
- **Basic Info**:
  - `api_id` (read-only)
  - `titel` (text input)
  - `zp_start` (datetime input)
  - `zp_modifiziert` (datetime input)
  - `parlament` (dropdown)
  - `typ` (dropdown)
  - `gremium_federf` (checkbox)
  - `trojanergefahr` (number input, 1-10)
  - `link` (URL input)

- **Gremium** (object):
  - `parlament` (dropdown)
  - `wahlperiode` (number)
  - `name` (text)
  - `link` (URL)

- **Keywords**:
  - `schlagworte` (array of strings)
  - Add/Remove buttons

- **Additional Links**:
  - `additional_links` (array of URLs)
  - Add/Remove buttons

- **Documents** (collapsible subsection):
  - Header: "Documents" with triangle indicator
  - Collapsed view: Document count + first few titles
  - Expanded view: List of document objects (see below)

- **Stellungnahmen** (collapsible subsection):
  - Header: "Stellungnahmen" with triangle indicator
  - Collapsed view: Count of statements
  - Expanded view: List of document objects (see below)

### Document Objects (within Stations)

**Collapsed Document View**:
- Triangle indicator
- `typ` (document type)
- `titel` (truncated if long)
- `drucksnr` (if available)

**Expanded Document Content**:
- **Basic Info**:
  - `api_id` (read-only)
  - `typ` (dropdown from `doktyp` enum)
  - `titel` (text input, required)
  - `kurztitel` (text input)
  - `drucksnr` (text input)
  - `link` (URL input, required)
  - `hash` (text input, required)

- **Content**:
  - `vorwort` (textarea)
  - `volltext` (large textarea, required)
  - `zusammenfassung` (textarea)

- **Dates**:
  - `zp_modifiziert` (datetime, required)
  - `zp_referenz` (datetime, required)
  - `zp_erstellt` (datetime)

- **Metadata**:
  - `meinung` (number input, 1-5, for statements/recommendations)
  - `schlagworte` (array of strings)
  - Add/Remove buttons

- **Authors**:
  - `autoren` (array of `autor` objects)
  - Each item: `person` (text), `organisation` (text, required), `fachgebiet` (text)
  - Add/Remove buttons

## Interaction Patterns

### Collapsible Sections
- **Default State**: Stations are folded, documents within stations are folded
- **Triangle Indicators**: 
  - ▶ (right-pointing) = folded
  - ▼ (down-pointing) = expanded
- **Click Behavior**: Toggle between folded/expanded states
- **Animation**: Smooth slide down/up animation

### Form Validation
- Required fields marked with asterisk (*)
- Real-time validation feedback
- Save button disabled if validation fails
- Error messages displayed inline

### Data Management
- **Arrays**: Add/Remove buttons for dynamic content
- **Nested Objects**: Expandable sections for complex data
- **Auto-save**: Optional auto-save functionality with visual indicator

## Responsive Design
- **Desktop**: Two-column layout as described
- **Tablet**: Stacked columns, maintain collapsible sections
- **Mobile**: Single column, simplified collapsible behavior

## Accessibility
- Keyboard navigation support for all interactive elements
- Screen reader friendly collapsible sections
- Proper ARIA labels for form controls
- Focus management for dynamic content 