# Meta Ledger APIs for EV Charging Network

This directory contains Meta Ledger APIs used by the network provider to collect and store data from BAP (Beckn Application Platform) and BPP (Beckn Provider Platform) participants in the EV charging network.

## Overview

The Meta Ledger APIs serve as centralized data collection endpoints for the network provider to maintain comprehensive ledgers for:

1. **Rating Ledger** - Stores all rating and feedback data
2. **Grievance Ledger** - Stores all support requests and grievances
3. **Transaction Ledger** - Stores all transaction and payment data

## Purpose

These APIs enable the network provider to:

- Maintain a centralized record of all ratings and feedback from charging point providers
- Track support requests and grievances for dispute resolution
- Monitor all financial transactions for reconciliation and analytics
- Provide network-level insights and reporting
- Ensure compliance and audit trail

## API Endpoints

All APIs follow the pattern: `POST /meta/{action}`

### 1. Rating Ledger API

**Endpoint:** `POST /meta/rating_ledger`

**Purpose:** Captures rating and feedback data from BAP and BPP related to charging sessions.

**Key Data Points:**
- Entity information (BAP/BPP ID)
- Order and fulfillment identifiers
- Rating values (score, category)
- Feedback comments and tags
- Timestamp

**Use Case:** Track quality of service provided by charging point operators, identify top-rated stations, monitor customer satisfaction trends.

### 2. Grievance Ledger API

**Endpoint:** `POST /meta/grievance_ledger`

**Purpose:** Captures support requests and grievances from BAP and BPP.

**Key Data Points:**
- Entity information (BAP/BPP ID)
- Reference ID (order, fulfillment, etc.)
- Issue type and description
- Priority and status
- Contact information
- Timestamp

**Use Case:** Track support tickets, monitor resolution times, identify recurring issues, facilitate dispute resolution.

### 3. Transaction Ledger API

**Endpoint:** `POST /meta/transaction_ledger`

**Purpose:** Captures transaction and payment data from BAP and BPP.

**Key Data Points:**
- Entity information (BAP/BPP ID)
- Order identifier
- Payment details (amount, currency)
- Payment type and method
- Transaction status
- Transaction and completion dates

**Use Case:** Financial reconciliation, transaction monitoring, payment analytics, audit trail.

## Directory Structure

```
meta/
├── README.md                          # This file
├── postman-collection/
│   ├── Meta-Rating-Ledger.postman_collection.json
│   ├── Meta-Grievance-Ledger.postman_collection.json
│   ├── Meta-Transaction-Ledger.postman_collection.json
│   └── Meta-All-Ledgers.postman_collection.json
└── swagger/
    └── meta-ledger.yaml               # OpenAPI 3.0 specification
```

## Using the APIs

### Postman Collections

1. Import any of the Postman collection files into Postman
2. Set up environment variables:
   - `meta_service_url` - URL of the meta service (e.g., `http://localhost:8090`)
   - `version` - Protocol version (e.g., `2.0.0`)
   - `domain` - Domain identifier (e.g., `beckn.one:deg:ev-charging`)
   - `bap_id` - BAP identifier
   - `bpp_id` - BPP identifier
   - `transaction_id` - Transaction identifier
   - `timestamp` - Current timestamp (ISO 8601 format)

3. Execute the requests

### Swagger/OpenAPI

The OpenAPI specification (`meta-ledger.yaml`) can be used to:
- Generate client libraries in various languages
- Set up API documentation using Swagger UI or ReDoc
- Validate requests and responses
- Generate mock servers for testing

## Data Flow

```
┌─────────┐                    ┌──────────────────┐
│   BAP   │───── Rating ──────>│                  │
└─────────┘                    │                  │
                               │   Meta Service   │
┌─────────┐                    │                  │
│   BPP   │───── Grievance ───>│  (Network Ledger)│
└─────────┘                    │                  │
                               │                  │
┌─────────┐                    │                  │
│  BAP/   │─── Transaction ───>│                  │
│  BPP    │                    └──────────────────┘
└─────────┘
```

## Response Format

All APIs return a standard acknowledgment response:

**Success (200 OK):**
```json
{
  "message": {
    "ack": {
      "status": "ACK",
      "ledger_id": "ledger-entry-001"
    }
  }
}
```

**Error (400/500):**
```json
{
  "error": {
    "type": "VALIDATION_ERROR",
    "code": "INVALID_REQUEST",
    "message": "Missing required field: entity_id",
    "path": "message.entity_id"
  }
}
```

## Data Minimization

These APIs are designed to capture **only essential data** required for:
- Network provider oversight
- Compliance and audit
- Dispute resolution
- Analytics and reporting

No sensitive customer information (like full personal details) is stored beyond what's necessary for the ledger purpose.

## Integration with BAP/BPP

### When to Call These APIs

1. **Rating Ledger:** Call after `rating` or `on_rating` operations
2. **Grievance Ledger:** Call after `support` or `on_support` operations
3. **Transaction Ledger:** Call after `confirm` or `on_confirm` operations when payment is completed

### Example Integration Flow

```
1. BAP calls /rating to BPP
2. BPP processes and responds with /on_rating
3. BAP/BPP posts data to /meta/rating_ledger
4. Meta service stores in rating ledger and returns ACK
```

## Security Considerations

- All API calls should be authenticated using appropriate network credentials
- Use HTTPS in production environments
- Implement rate limiting to prevent abuse
- Validate all input data before processing
- Ensure proper access controls are in place

## Deployment

The meta service should be deployed as a separate microservice that:
- Accepts requests from verified BAP and BPP participants
- Stores data in a secure, scalable database
- Provides query APIs for network provider analytics (not included in this basic version)
- Implements proper logging and monitoring

## Future Enhancements

Potential future additions:
- Query APIs for retrieving ledger data
- Analytics and reporting endpoints
- Real-time dashboards
- Alert and notification system
- Data export capabilities

## Support

For questions or issues related to Meta Ledger APIs:
- Email: support@metaledger.network
- Documentation: See swagger/meta-ledger.yaml for detailed API specifications

## Version History

- **v1.0.0** - Initial release with three core ledger APIs

