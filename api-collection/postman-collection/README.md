# API Collections for EV Charging APIs

This directory contains API collections for EV Charging APIs following the Beckn Protocol specification. It includes both **Postman collections** for testing and **Swagger/OpenAPI specifications** for API documentation.

## API Collection Directory Structure

```
api-collection/
├── postman-collection/           # Postman collections for API testing
│   ├── bap/                      # Buyer App Provider collections
│   │   ├── all-api/              # Combined collection of all BAP APIs
│   │   ├── discover/             # Discover charging stations
│   │   ├── select/               # Select a charging station
│   │   ├── init/                 # Initialize a charging session
│   │   ├── confirm/              # Confirm a booking
│   │   ├── update/               # Update booking details
│   │   ├── cancel/               # Cancel a booking
│   │   ├── track/                # Track charging session status
│   │   ├── support/              # Support queries
│   │   └── rating/               # Submit ratings
│   │
│   └── bpp/                      # Buyer Platform Provider collections
│       ├── all-apis/             # Combined collection of all BPP APIs
│       ├── on_discover/          # Response to discover request
│       ├── on_select/            # Response to select request
│       ├── on_init/              # Response to init request
│       ├── on_confirm/            # Response to confirm request
│       ├── on_update/            # Response to update request
│       ├── on_cancel/            # Response to cancel request
│       ├── on_track/             # Response to track request
│       ├── on_status/            # Status update callback
│       ├── on_support/           # Response to support request
│       └── on_rating/            # Response to rating request
│
├── meta/                         # Meta APIs for Network Provider
│   ├── postman-collection/       # Meta ledger API collections
│   │   ├── Meta-Rating-Ledger.postman_collection.json
│   │   ├── Meta-Grievance-Ledger.postman_collection.json
│   │   ├── Meta-Transaction-Ledger.postman_collection.json
│   │   └── Meta-All-Ledgers.postman_collection.json
│   ├── swagger/                  # Meta API OpenAPI specification
│   │   └── meta-ledger.yaml
│   └── README.md                 # Meta API documentation
│
└── swagger/                      # OpenAPI/Swagger specifications
    ├── bap.yaml                  # BAP API OpenAPI specification
    └── bpp.yaml                  # BPP API OpenAPI specification
```

## Swagger/OpenAPI Specifications

The `swagger/` directory contains OpenAPI 3.0.3 specifications for both BAP and BPP APIs. These specifications provide comprehensive API documentation with request/response schemas, examples, and detailed descriptions.

### Available Swagger Files

#### `bap.yaml` - BAP API Specification
- **Title**: BAP - EV Charging Network API
- **Version**: 1.0.0
- **Description**: Beckn Application Platform (BAP) API specification for EV Charging Network
- **Endpoints Documented**:
  - `/discover` - Discover EV charging stations
  - `/select` - Select a charging station
  - `/init` - Initialize a charging session
  - `/confirm` - Confirm a booking
  - `/update` - Update booking details
  - `/cancel` - Cancel a booking
  - `/track` - Track charging session status
  - `/support` - Support queries
  - `/rating` - Submit ratings

**Key Features**:
- Asynchronous communication pattern documentation
- Request/response schemas with validation
- Example payloads
- Error response definitions
- Server configurations for local and Docker environments

#### `bpp.yaml` - BPP API Specification
- **Title**: BPP - EV Charging Network API
- **Version**: 1.0.0
- **Description**: Beckn Provider Platform (BPP) API specification for EV Charging Network
- **Endpoints Documented**:
  - `/on_discover` - Response to discover request
  - `/on_select` - Response to select request
  - `/on_init` - Response to init request
  - `/on_confirm` - Response to confirm request
  - `/on_update` - Response to update request
  - `/on_cancel` - Response to cancel request
  - `/on_track` - Response to track request
  - `/on_status` - Status update callbacks
  - `/on_support` - Response to support queries
  - `/on_rating` - Response to rating submission

**Key Features**:
- Callback endpoint documentation
- Async response flow documentation
- Request/response schemas with validation
- Example payloads
- Server configurations for receiver and caller endpoints

### Using Swagger/OpenAPI Specifications

#### Option 1: View in Swagger UI
1. Install Swagger UI:
   ```bash
   npm install -g swagger-ui-serve
   ```
2. Serve the specification:
   ```bash
   swagger-ui-serve swagger/bap.yaml
   swagger-ui-serve swagger/bpp.yaml
   ```
3. Open your browser to `http://localhost:3000` to view the interactive API documentation

#### Option 2: Use Online Swagger Editor
1. Go to [https://editor.swagger.io/](https://editor.swagger.io/)
2. Copy and paste the contents of `bap.yaml` or `bpp.yaml`
3. View the interactive documentation

#### Option 3: Import into API Testing Tools
- **Postman**: Import the YAML files directly into Postman
- **Insomnia**: Import as OpenAPI specification
- **REST Client Tools**: Most modern API clients support OpenAPI import

#### Option 4: Generate Client SDKs
Use code generation tools like:
- [OpenAPI Generator](https://openapi-generator.tech/)
- [Swagger Codegen](https://swagger.io/tools/swagger-codegen/)

Example:
```bash
openapi-generator generate -i swagger/bap.yaml -g python -o ./generated/bap-client
```

### Swagger Documentation Features

- **Asynchronous Communication**: Detailed documentation of the async request/response pattern
- **Request Validation**: Complete schema definitions for all request bodies
- **Response Schemas**: Detailed response structures with examples
- **Error Handling**: Comprehensive error response definitions
- **Server Configurations**: Pre-configured server URLs for different environments
- **Tags and Categories**: APIs organized by functional groups (Discovery, Order Management, Tracking, Support)

## Postman Collections

### Overview

#### BAP (Buyer App Provider) Collections

BAP collections contain APIs that the buyer application (user-facing app) uses to interact with charging service providers. These are outbound requests from the buyer app.

**Available APIs:**
- **discover**: Search for EV charging stations based on location, route, or filters
- **select**: Select a specific charging station or service
- **init**: Initialize a charging session with selected parameters
- **confirm**: Confirm and finalize the booking
- **update**: Update booking details (time, duration, etc.)
- **cancel**: Cancel an existing booking
- **track**: Track the status of an active charging session
- **support**: Get support information or raise support requests
- **rating**: Submit ratings and feedback for a completed session

#### BPP (Buyer Platform Provider) Collections

BPP collections contain callback APIs that the seller platform (charging provider) uses to respond to buyer requests. These are inbound responses/callbacks to the buyer app.

**Available APIs:**
- **on_discover**: Response containing available charging stations
- **on_select**: Response confirming selection with details
- **on_init**: Response with initialized session details
- **on_confirm**: Response confirming the booking
- **on_update**: Response with updated booking details
- **on_cancel**: Response confirming cancellation
- **on_track**: Response with current session status
- **on_status**: Status update callbacks (push notifications)
- **on_support**: Response to support queries
- **on_rating**: Acknowledgment of rating submission

#### Meta Ledger Collections

Meta collections contain APIs for the network provider to collect and store data from BAP and BPP participants. These are used for centralized ledger management.

**Available APIs:**
- **rating_ledger**: Store rating and feedback data from BAP/BPP
- **grievance_ledger**: Store support requests and grievance data from BAP/BPP
- **transaction_ledger**: Store transaction and payment data from BAP/BPP

These APIs enable the network provider to maintain comprehensive records for analytics, compliance, and dispute resolution.

For detailed documentation, see `/api-collection/meta/README.md`

## Getting Started

### Importing Collections

1. **Option 1: Import Individual Collections**
   - Open Postman
   - Click "Import" button
   - Select the specific collection file you want to import (e.g., `bap/discover/BAP-DEG-EV-Charging-Discover.postman_collection.json`)

2. **Option 2: Import Combined Collections**
   - For all BAP APIs: Import `bap/all-api/BAP-DEG-EV-Charging-All-APIs.postman_collection.json`
   - For all BPP APIs: Import `bpp/all-apis/BPP-DEG-EV-Charging-All-APIs.postman_collection.json`

### Environment Variables

Before using the collections, you need to set up environment variables in Postman. Create a new environment or use the existing one and configure the following variables:

#### Common Variables
- `version`: Protocol version (e.g., "2.0.0")
- `domain`: Domain identifier (e.g., "EV_CHARGING")
- `transaction_id`: Unique transaction identifier
- `bap_id`: Buyer App Provider ID
- `bap_uri`: Buyer App Provider callback URI
- `bpp_id`: Buyer Platform Provider ID (for BPP collections)
- `bpp_uri`: Buyer Platform Provider URI (for BPP collections)
- `bap_adapter_url`: BAP adapter/base URL for outgoing requests

#### Example Environment Variables

```json
{
  "version": "2.0.0",
  "domain": "EV_CHARGING",
  "bap_id": "example-bap-id",
  "bap_uri": "https://bap.example.com",
  "bpp_id": "example-bpp-id",
  "bpp_uri": "https://bpp.example.com",
  "bap_adapter_url": "https://bap-adapter.example.com",
  "transaction_id": "txn-123456"
}
```

**Note**: The collections use Postman's dynamic variables like `{{$guid}}` for generating unique message IDs and `{{$timestamp}}` for timestamps. These are automatically generated when you make requests.

## Usage Examples

### BAP - Discover Charging Stations

1. Import the `BAP-DEG-EV-Charging-Discover.postman_collection.json` collection
2. Set up the required environment variables
3. Select a request (e.g., "along-a-route" or "by-EVSE")
4. Review and modify the request body as needed
5. Send the request

### BPP - Respond to Discover Request

1. Import the `BPP-DEG-EV-Charging-On-Discover.postman_collection.json` collection
2. Set up the required environment variables
3. The collection contains sample response payloads with charging station catalogs
4. Modify the catalog data as per your requirements
5. Send the response to the BAP's callback URI

## Request/Response Format

All APIs follow the Beckn Protocol specification with the following structure:

```json
{
  "context": {
    "version": "{{version}}",
    "action": "<action_name>",
    "domain": "{{domain}}",
    "location": {
      "country": { "code": "IND" },
      "city": { "code": "std:080" }
    },
    "bap_id": "{{bap_id}}",
    "bap_uri": "{{bap_uri}}",
    "transaction_id": "{{transaction_id}}",
    "message_id": "{{$guid}}",
    "timestamp": "{{$timestamp}}",
    "ttl": "PT30S",
    "schema_context": [
      "https://raw.githubusercontent.com/beckn/protocol-specifications-new/refs/heads/main/schemas/charging_service/v1/context.jsonld"
    ]
  },
  "message": {
    // Action-specific message content
  }
}
```

## Collection Details

### Combined Collections
- **BAP-DEG-EV-Charging-All-APIs**: Contains all BAP APIs in a single collection, organized by action type
- **BPP-DEG-EV-Charging-All-APIs**: Contains all BPP callback APIs in a single collection

### Individual Collections
Each individual collection focuses on a specific API action and includes:
- Multiple request variations where applicable (e.g., different search methods for discover)
- Sample request/response bodies
- Pre-configured headers and authentication

## Testing Workflow

A typical EV charging flow using these collections:

1. **Discover**: BAP sends discover request → BPP responds with `on_discover`
2. **Select**: BAP selects a charging station → BPP responds with `on_select`
3. **Init**: BAP initializes session → BPP responds with `on_init`
4. **Confirm**: BAP confirms booking → BPP responds with `on_confirm`
5. **Track**: BAP tracks session status → BPP responds with `on_track`
6. **Update/Cancel**: BAP may update or cancel → BPP responds accordingly
7. **Rating**: After completion, BAP submits rating → BPP responds with `on_rating`

## Notes

- All requests use POST method with JSON payloads
- Content-Type header is automatically set to `application/json` in BPP collections
- Message IDs and timestamps are auto-generated using Postman variables
- Customize the request bodies according to your specific requirements
- Ensure your BAP adapter or BPP server is running and accessible before testing

## Related Documentation

- Beckn Protocol Specification: [https://github.com/beckn/protocol-specifications](https://github.com/beckn/protocol-specifications)
- EV Charging Domain Schema: Available in `/schemas/beckn.one_deg_ev-charging/v2.0.0/`
- Swagger/OpenAPI Specifications: 
  - BAP API: `/api-collection/swagger/bap.yaml`
  - BPP API: `/api-collection/swagger/bpp.yaml`
  - Meta Ledger API: `/api-collection/meta/swagger/meta-ledger.yaml`
- Meta Ledger APIs: `/api-collection/meta/README.md`

## Support

For issues or questions related to these API collections (Postman or Swagger), please refer to the main project README or contact the development team.
