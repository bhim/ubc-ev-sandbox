# beckn.one:deg:ev-charging Schema Documentation

This directory contains JSON Schema definitions for the **beckn.one:deg:ev-charging** domain, following the Beckn Protocol specification. These schemas define the structure, validation rules, and data types for all API requests and responses in the EV charging ecosystem.

## Directory Structure

```
schemas/
└── beckn.one_deg_ev-charging/
    └── v2.0.0/
        ├── all.json              # Combined schema with all API definitions
        ├── discover.json         # Discover charging stations schema
        ├── select.json           # Select charging station schema
        ├── init.json             # Initialize session schema
        ├── confirm.json          # Confirm booking schema
        ├── update.json           # Update booking schema
        ├── cancel.json           # Cancel booking schema
        ├── track.json            # Track session schema
        ├── support.json          # Support request schema
        ├── rating.json           # Rating submission schema
        ├── on_discover.json      # Response to discover request
        ├── on_search.json        # Response to search request
        ├── on_select.json        # Response to select request
        ├── on_init.json          # Response to init request
        ├── on_confirm.json       # Response to confirm request
        ├── on_update.json        # Response to update request
        ├── on_cancel.json        # Response to cancel request
        ├── on_track.json         # Response to track request
        ├── on_status.json        # Status update callback schema
        ├── on_support.json       # Response to support request
        └── on_rating.json        # Response to rating request
```

## Schema Version

- **Domain**: beckn.one:deg:ev-charging
- **Schema Version**: v2.0.0
- **Protocol**: Beckn Protocol
- **JSON Schema Standard**: Draft 2020-12

## Domain Identifiers

The schemas support multiple domain identifier formats for backward compatibility:

- **`beckn.one:deg:ev-charging`** - Beckn One DEG format (recommended)
- **`dent:ev-charging:`** - DENT format
- **`ev_charging_network`** - Legacy format

The domain pattern is validated as: `^(dent:ev-charging:|ev_charging_network|beckn.one:deg:ev-charging)`

## API Schema Categories

### BAP (Buyer App Provider) Schemas

These schemas define requests sent by the buyer application (user-facing app):

| Schema File | API Action | Description |
|------------|-----------|-------------|
| `discover.json` | `discover` | Search for EV charging stations based on location, route, or filters |
| `select.json` | `select` | Select a specific charging station or service |
| `init.json` | `init` | Initialize a charging session with selected parameters |
| `confirm.json` | `confirm` | Confirm and finalize the booking |
| `update.json` | `update` | Update booking details (time, duration, etc.) |
| `cancel.json` | `cancel` | Cancel an existing booking |
| `track.json` | `track` | Track the status of an active charging session |
| `support.json` | `support` | Get support information or raise support requests |
| `rating.json` | `rating` | Submit ratings and feedback for a completed session |

### BPP (Buyer Platform Provider) Schemas

These schemas define responses/callbacks sent by the seller platform (charging provider):

| Schema File | API Action | Description |
|------------|-----------|-------------|
| `on_discover.json` | `on_discover` | Response containing available charging stations |
| `on_search.json` | `on_search` | Response to search queries |
| `on_select.json` | `on_select` | Response confirming selection with details |
| `on_init.json` | `on_init` | Response with initialized session details |
| `on_confirm.json` | `on_confirm` | Response confirming the booking |
| `on_update.json` | `on_update` | Response with updated booking details |
| `on_cancel.json` | `on_cancel` | Response confirming cancellation |
| `on_track.json` | `on_track` | Response with current session status |
| `on_status.json` | `on_status` | Status update callbacks (push notifications) |
| `on_support.json` | `on_support` | Response to support queries |
| `on_rating.json` | `on_rating` | Acknowledgment of rating submission |

### Combined Schema

- **`all.json`**: A comprehensive schema file containing definitions for all API actions. Useful for complete validation or as a reference.

## Schema Structure

Each schema file follows a standard Beckn Protocol structure:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "<action_name>",
  "type": "object",
  "properties": {
    "context": {
      "type": "object",
      "properties": {
        "version": { "type": "string" },
        "action": { 
          "type": "string",
          "enum": ["<action_name>"]
        },
        "domain": { 
          "type": "string",
          "pattern": "^(dent:ev-charging:|ev_charging_network|beckn.one:deg:ev-charging)"
        },
        "location": { /* location object */ },
        "bap_id": { "type": "string" },
        "bap_uri": { "type": "string", "format": "uri" },
        "bpp_id": { "type": "string" },
        "bpp_uri": { "type": "string", "format": "uri" },
        "transaction_id": { "type": "string" },
        "message_id": { "type": "string" },
        "timestamp": { "type": "string", "format": "date-time" },
        "ttl": { "type": "string" },
        "schema_context": { 
          "type": "array",
          "items": { "type": "string", "format": "uri" }
        }
      },
      "required": [ /* required context fields */ ]
    },
    "message": {
      "type": "object",
      "properties": {
        /* Action-specific message properties */
      }
    }
  },
  "required": ["context", "message"],
  "additionalProperties": false
}
```

### Context Object Requirements

Every API request/response includes a `context` object with domain-specific requirements:

- **version**: Beckn protocol version
- **action**: The API action being performed (enum restricted to specific action)
- **domain**: Domain identifier matching pattern `^(dent:ev-charging:|ev_charging_network|beckn.one:deg:ev-charging)`
- **location**: Geographic location object with:
  - **country**: Object with `code` (ISO 3166-1 alpha-3 standard)
  - **city**: Object with `code`
- **bap_id** / **bap_uri**: Buyer App Provider identification and endpoint (URI format)
- **bpp_id** / **bpp_uri**: Buyer Platform Provider identification and endpoint (URI format, required in BPP responses)
- **transaction_id**: Unique transaction identifier
- **message_id**: Unique message identifier
- **timestamp**: ISO 8601 date-time format
- **ttl**: Time-to-live for the message (ISO 8601 duration format)
- **schema_context**: Array of schema context URIs

### Message Object

The `message` object contains action-specific data for EV charging operations:
- **discover**: Text search, spatial queries (Point, LineString, Polygon), and JSONPath filters
- **on_discover**: Catalog of available charging stations
- **init**: Session initialization parameters
- **on_init**: Initialized session details with order, fulfillment, payment, and quote information
- **track**: Session tracking queries
- **on_track**: Current session status updates
- And other action-specific payloads for the EV charging domain

## Usage Examples

### Basic Validation

```javascript
import Ajv from 'ajv';
import discoverSchema from './schemas/beckn.one_deg_ev-charging/v2.0.0/discover.json';

const ajv = new Ajv();
const validate = ajv.compile(discoverSchema);

const isValid = validate(requestPayload);
if (!isValid) {
  console.error(validate.errors);
}
```

```python
from jsonschema import validate
import json

with open('schemas/beckn.one_deg_ev-charging/v2.0.0/discover.json') as f:
    schema = json.load(f)

try:
    validate(instance=request_payload, schema=schema)
    print("Valid!")
except ValidationError as e:
    print(f"Validation error: {e.message}")
```

## Integration

### Postman Collections

These schemas complement the Postman collections in `/api-collection/postman-collection/`. You can:
1. Use the schemas to validate request/response payloads
2. Generate mock data from schemas
3. Set up automated schema validation in Postman tests

### Request/Response Flow

Typical EV charging flow with schema validation:

1. **BAP sends discover request**
   - Validates against `beckn.one_deg_ev-charging/v2.0.0/discover.json` before sending
   - BPP validates against `discover.json` on receipt

2. **BPP responds with on_discover**
   - Validates response against `on_discover.json` before sending
   - BAP validates against `on_discover.json` on receipt

3. **Continue for each action in the flow**
   - Each request validated against corresponding schema
   - Each response validated against corresponding `on_*` schema

## Schema Maintenance

### Version Updates

When updating schemas:
1. **Version bump**: Create a new version directory (e.g., `v2.1.0/`)
2. **Document changes**: Maintain changelog for breaking changes
3. **Test compatibility**: Ensure backward compatibility or document migration path
4. **Update documentation**: Keep this README updated

### Schema Validation Rules

- All schemas use `additionalProperties: false` for strict validation
- Domain pattern validation enforces supported domain formats
- Required fields are explicitly marked in each schema
- Enum values restrict actions to valid operations
- Location codes follow ISO 3166-1 standards for countries and city codes

## Related Resources

- **Postman Collections**: `/api-collection/postman-collection/`
- **Swagger Documentation**: `/api-collection/swagger/`
- **Beckn Protocol Specification**: [https://github.com/beckn/protocol-specifications](https://github.com/beckn/protocol-specifications)

## Notes

- All schemas use JSON Schema Draft 2020-12
- Field descriptions are provided for better understanding
- Required fields are explicitly marked in each schema
- Enum values restrict actions to valid operations
- Location codes follow ISO 3166-1 standards for countries and city codes
- Domain identifier must match the pattern: `^(dent:ev-charging:|ev_charging_network|beckn.one:deg:ev-charging)`
