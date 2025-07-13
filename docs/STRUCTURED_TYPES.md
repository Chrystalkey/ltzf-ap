# Structured Types and State Management

This document outlines the improvements made to better represent state and objects throughout the application based on the OpenAPI specification.

## Overview

The original application used raw maps and strings throughout, which led to several issues:

1. **No type safety**: No compile-time validation of data structures
2. **Inconsistent data handling**: Manual parsing and validation scattered throughout
3. **No enum validation**: String values for enums without validation
4. **No required field validation**: Missing required fields could cause runtime errors
5. **Poor state management**: Unstructured state that was hard to reason about

## New Architecture

### 1. Structured Schemas (`LtzfAp.Schemas`)

The `Schemas` module provides structured data types based on the OpenAPI specification:

#### Enumeration Types
```elixir
@type parlament() :: 
  "BT" | "BR" | "BV" | "EK" | "BB" | "BY" | "BE" | "HB" | "HH" | "HE" | 
  "MV" | "NI" | "NW" | "RP" | "SL" | "SN" | "TH" | "SH" | "BW" | "ST"

@type vorgangstyp() :: 
  "gg-einspruch" | "gg-zustimmung" | "gg-land-parl" | "gg-land-volk" | 
  "bw-einsatz" | "sonstig"
```

#### Structured Objects
```elixir
defmodule Vorgang do
  defstruct [
    :api_id, :touched_by, :titel, :kurztitel, :wahlperiode, :verfassungsaendernd,
    :typ, :ids, :links, :initiatoren, :stationen, :lobbyregister
  ]
  @type t() :: %__MODULE__{
    api_id: String.t(), # required
    titel: String.t(), # required
    wahlperiode: non_neg_integer(), # required
    verfassungsaendernd: boolean(), # required
    typ: vorgangstyp(), # required
    # ... other fields
  }
end
```

#### Validation Functions
```elixir
@spec valid_parlament?(String.t()) :: boolean()
def valid_parlament?(parlament) when is_binary(parlament) do
  parlament in ["BT", "BR", "BV", "EK", "BB", "BY", "BE", "HB", "HH", "HE", 
                "MV", "NI", "NW", "RP", "SL", "SN", "TH", "SH", "BW", "ST"]
end
```

#### Conversion Functions
```elixir
@spec map_to_vorgang(map()) :: {:ok, Vorgang.t()} | {:error, String.t()}
def map_to_vorgang(map) when is_map(map) do
  # Converts raw map to structured Vorgang with validation
end

@spec vorgang_to_map(Vorgang.t()) :: map()
def vorgang_to_map(%Vorgang{} = vorgang) do
  # Converts structured Vorgang back to map for API calls
end
```

### 2. Form Helpers (`LtzfAp.FormHelpers`)

The `FormHelpers` module provides functions for working with form data:

#### Form Parameter Conversion
```elixir
@spec form_params_to_vorgang(map(), Schemas.Vorgang.t() | nil) :: Schemas.Vorgang.t()
def form_params_to_vorgang(params, current_vorgang) do
  # Converts form parameters to structured Vorgang object
end

@spec form_params_to_autor(map()) :: Schemas.Autor.t()
def form_params_to_autor(%{"person" => person, "organisation" => organisation}) do
  # Creates structured Autor from form parameters
end
```

#### Validation
```elixir
@spec validate_vorgang(Schemas.Vorgang.t()) :: :ok | {:error, [String.t()]}
def validate_vorgang(%Schemas.Vorgang{} = vorgang) do
  # Validates required fields and enum values
end
```

### 3. State Management (`LtzfAp.State`)

The `State` module provides structured state representation:

#### State Structs
```elixir
defmodule VorgangDetailState do
  defstruct [
    # Core data
    vorgang_id: nil,
    vorgang: nil,
    original_vorgang: nil,
    
    # Loading and error states
    loading: true,
    error: nil,
    
    # Session management
    session_id: nil,
    auth_info: %{scope: "unknown"},
    # ... other fields
  ]
end
```

#### State Management Functions
```elixir
@spec new_vorgang_detail_state(String.t()) :: VorgangDetailState.t()
def new_vorgang_detail_state(vorgang_id) do
  # Creates new state with default values
end

@spec update_vorgang(VorgangDetailState.t(), Schemas.Vorgang.t()) :: VorgangDetailState.t()
def update_vorgang(state, vorgang) do
  # Updates state with new vorgang data
end

@spec has_changes?(VorgangDetailState.t()) :: boolean()
def has_changes?(state) do
  # Checks if there are unsaved changes
end
```

## Benefits

### 1. Type Safety
- **Compile-time validation**: Dialyzer can catch type errors
- **Structured data**: No more guessing about data structure
- **Enum validation**: Invalid enum values are caught early

### 2. Better Error Handling
- **Structured errors**: Validation returns specific error messages
- **Early detection**: Problems are caught before API calls
- **User feedback**: Clear error messages for invalid data

### 3. Improved Maintainability
- **Single source of truth**: OpenAPI schema drives all data structures
- **Consistent validation**: All validation logic is centralized
- **Clear interfaces**: Well-defined function signatures

### 4. Enhanced Developer Experience
- **Better IDE support**: Autocomplete and type hints
- **Easier debugging**: Structured data is easier to inspect
- **Documentation**: Types serve as documentation

### 5. Reduced Runtime Errors
- **Required field validation**: Missing fields are caught early
- **Type conversion**: Proper handling of string/integer conversions
- **Enum validation**: Invalid enum values are rejected

## Migration Guide

### 1. Update LiveView Modules

Replace raw map handling with structured types:

```elixir
# Before
def handle_event("api_response", %{"request_id" => "vorgang_load", "result" => result}, socket) do
  vorgang = ensure_vorgang_fields(result)
  socket = assign(socket, vorgang: vorgang)
  {:noreply, socket}
end

# After
def handle_event("api_response", %{"request_id" => "vorgang_load", "result" => result}, socket) do
  case Schemas.map_to_vorgang(result) do
    {:ok, vorgang} ->
      state = State.update_vorgang(socket.assigns, vorgang)
      socket = assign(socket, Map.from_struct(state))
      {:noreply, socket}
    
    {:error, reason} ->
      state = State.set_error(socket.assigns, "Failed to parse vorgang: #{reason}")
      socket = assign(socket, Map.from_struct(state))
      {:noreply, socket}
  end
end
```

### 2. Update Form Handling

Use form helpers for parameter conversion:

```elixir
# Before
def handle_event("form_change", %{"vorgang" => vorgang_params}, socket) do
  new_vorgang = form_params_to_vorgang(vorgang_params, socket.assigns.vorgang)
  socket = assign(socket, vorgang: new_vorgang)
  {:noreply, socket}
end

# After
def handle_event("form_change", %{"vorgang" => vorgang_params}, socket) do
  new_vorgang = FormHelpers.form_params_to_vorgang(vorgang_params, socket.assigns.vorgang)
  
  case FormHelpers.validate_vorgang(new_vorgang) do
    :ok ->
      socket = assign(socket, vorgang: new_vorgang)
      {:noreply, socket}
    
    {:error, errors} ->
      state = State.set_error(socket.assigns, "Validation failed: #{Enum.join(errors, ", ")}")
      socket = assign(socket, Map.from_struct(state))
      {:noreply, socket}
  end
end
```

### 3. Update State Management

Use structured state:

```elixir
# Before
def mount(%{"id" => vorgang_id}, _session, socket) do
  socket = assign(socket,
    vorgang_id: vorgang_id,
    vorgang: nil,
    loading: true,
    # ... many more fields
  )
  {:ok, socket}
end

# After
def mount(%{"id" => vorgang_id}, _session, socket) do
  state = State.new_vorgang_detail_state(vorgang_id)
  socket = assign(socket, Map.from_struct(state))
  {:ok, socket}
end
```

## Best Practices

### 1. Always Validate Input
```elixir
case FormHelpers.validate_vorgang(new_vorgang) do
  :ok -> # proceed with valid data
  {:error, errors} -> # handle validation errors
end
```

### 2. Use Structured State
```elixir
# Instead of raw maps, use structured state
state = State.new_vorgang_detail_state(vorgang_id)
socket = assign(socket, Map.from_struct(state))
```

### 3. Leverage Type Specifications
```elixir
# Use @spec annotations for better documentation and type checking
@spec update_vorgang(VorgangDetailState.t(), Schemas.Vorgang.t()) :: VorgangDetailState.t()
def update_vorgang(state, vorgang) do
  # implementation
end
```

### 4. Centralize Validation Logic
```elixir
# Use the validation functions from Schemas module
if Schemas.valid_vorgangstyp?(typ) do
  # proceed with valid type
else
  # handle invalid type
end
```

## Future Improvements

### 1. Database Integration
- Create Ecto schemas that mirror the API schemas
- Add database constraints that match API validation
- Implement automatic migration between API and database formats

### 2. API Client Integration
- Create structured API client that uses the schemas
- Add automatic validation of API responses
- Implement retry logic with proper error handling

### 3. Testing Improvements
- Add property-based testing using the schemas
- Create test data generators based on the OpenAPI specification
- Implement contract testing between frontend and API

### 4. Performance Optimizations
- Add caching for frequently accessed data
- Implement lazy loading for large objects
- Add pagination support for list operations

## Conclusion

The structured types approach provides significant improvements in type safety, maintainability, and developer experience. By basing all data structures on the OpenAPI specification, we ensure consistency between the frontend and backend while providing better error handling and validation.

The modular approach allows for gradual migration and makes it easy to extend the system with new features while maintaining the benefits of structured data. 