# JSON-LD Schema Summary - Meta Ledger APIs

This document provides a comprehensive summary of the JSON-LD schema structure used in the Meta Ledger APIs.

## Overview

All Meta Ledger APIs use **JSON-LD (JSON for Linking Data)** format, which is compatible with the Beckn Protocol specification. JSON-LD provides semantic meaning to JSON data through the use of contexts, types, and namespaced properties.

## JSON-LD Core Concepts

### 1. `@context`
The `@context` property defines the vocabulary and namespace mappings for the JSON-LD document. It links to schema definitions that provide semantic meaning.

### 2. `@type`
The `@type` property specifies the semantic type of an object, indicating what kind of entity it represents.

### 3. Namespaced Properties (`beckn:`)
Properties prefixed with `beckn:` belong to the Beckn Protocol vocabulary, ensuring semantic consistency across the network.

## Schema Contexts Used

### Core Context
All APIs use the standard Beckn context in the request:
```json
{
  "context": {
    "schema_context": [
      "https://raw.githubusercontent.com/beckn/protocol-specifications-new/refs/heads/main/schemas/charging_service/v1/context.jsonld"
    ]
  }
}
```

### Ledger Context
The ledger object uses:
```json
{
  "@context": "https://becknprotocol.io/schemas/core/v2/Ledger/schema-context.jsonld",
  "@type": "beckn:Ledger"
}
```

### Rating Context
Rating data uses:
```json
{
  "@context": "https://becknprotocol.io/schemas/core/v2/Rating/schema-context.jsonld",
  "@type": "beckn:Rating"
}
```

### Feedback Context
Feedback data uses:
```json
{
  "@context": "https://becknprotocol.io/schemas/core/v2/Feedback/schema-context.jsonld",
  "@type": "beckn:Feedback"
}
```

### Support Context
Support/grievance data uses:
```json
{
  "@context": "https://becknprotocol.io/schemas/core/v2/SupportInfo/schema-context.jsonld",
  "@type": "beckn:SupportInfo"
}
```

### Payment Context
Payment/transaction data uses:
```json
{
  "@context": "https://becknprotocol.io/schemas/core/v2/Payment/schema-context.jsonld",
  "@type": "beckn:Payment"
}
```

## Schema Structure by API

### 1. Rating Ledger API

#### Request Structure
```json
{
  "context": {
    "version": "2.0.0",
    "action": "rating_ledger",
    "domain": "beckn.one:deg:ev-charging",
    "location": {
      "country": { "code": "IND" },
      "city": { "code": "std:080" }
    },
    "bap_id": "...",
    "bap_uri": "...",
    "bpp_id": "...",
    "bpp_uri": "...",
    "transaction_id": "...",
    "message_id": "...",
    "timestamp": "...",
    "ttl": "PT30S",
    "schema_context": [
      "https://raw.githubusercontent.com/beckn/protocol-specifications-new/refs/heads/main/schemas/charging_service/v1/context.jsonld"
    ]
  },
  "message": {
    "ledger": {
      "@context": "https://becknprotocol.io/schemas/core/v2/Ledger/schema-context.jsonld",
      "@type": "beckn:Ledger",
      "beckn:id": "rating-ledger-001",
      "beckn:type": "RATING",
      "beckn:entity": {
        "@type": "beckn:Entity",
        "beckn:type": "bap",
        "beckn:id": "bap-id-123"
      },
      "beckn:reference": {
        "@type": "beckn:Reference",
        "beckn:orderId": "order-123456",
        "beckn:fulfillmentId": "fulfillment-001"
      },
      "beckn:rating": {
        "@context": "https://becknprotocol.io/schemas/core/v2/Rating/schema-context.jsonld",
        "@type": "beckn:Rating",
        "beckn:value": 5,
        "beckn:best": 5,
        "beckn:worst": 1,
        "beckn:category": "fulfillment"
      },
      "beckn:feedback": {
        "@context": "https://becknprotocol.io/schemas/core/v2/Feedback/schema-context.jsonld",
        "@type": "beckn:Feedback",
        "beckn:comments": "Excellent charging experience!",
        "beckn:tags": ["fast-charging", "clean-station"]
      },
      "beckn:timestamp": "2025-01-27T10:00:00Z"
    }
  }
}
```

#### Schema Elements

| Element | Type | Description | Required |
|---------|------|-------------|----------|
| `ledger.@context` | URI | Ledger schema context | Yes |
| `ledger.@type` | String | Type: "beckn:Ledger" | Yes |
| `ledger.beckn:id` | String | Unique ledger entry ID | Yes |
| `ledger.beckn:type` | Enum | "RATING" | Yes |
| `ledger.beckn:entity` | Object | Entity information (BAP/BPP) | Yes |
| `ledger.beckn:entity.@type` | String | "beckn:Entity" | Yes |
| `ledger.beckn:entity.beckn:type` | Enum | "bap" or "bpp" | Yes |
| `ledger.beckn:entity.beckn:id` | String | Entity identifier | Yes |
| `ledger.beckn:reference` | Object | Order/fulfillment references | Yes |
| `ledger.beckn:reference.@type` | String | "beckn:Reference" | Yes |
| `ledger.beckn:reference.beckn:orderId` | String | Order identifier | Yes |
| `ledger.beckn:reference.beckn:fulfillmentId` | String | Fulfillment identifier | Yes |
| `ledger.beckn:rating` | Object | Rating information | Yes |
| `ledger.beckn:rating.@context` | URI | Rating schema context | Yes |
| `ledger.beckn:rating.@type` | String | "beckn:Rating" | Yes |
| `ledger.beckn:rating.beckn:value` | Number | Rating value (1-5) | Yes |
| `ledger.beckn:rating.beckn:best` | Number | Best possible rating | No |
| `ledger.beckn:rating.beckn:worst` | Number | Worst possible rating | No |
| `ledger.beckn:rating.beckn:category` | Enum | "fulfillment", "provider", "item" | Yes |
| `ledger.beckn:feedback` | Object | Feedback information | No |
| `ledger.beckn:feedback.@context` | URI | Feedback schema context | Yes (if present) |
| `ledger.beckn:feedback.@type` | String | "beckn:Feedback" | Yes (if present) |
| `ledger.beckn:feedback.beckn:comments` | String | Textual feedback | No |
| `ledger.beckn:feedback.beckn:tags` | Array | Feedback tags | No |
| `ledger.beckn:timestamp` | DateTime | Timestamp (ISO 8601) | Yes |

### 2. Grievance Ledger API

#### Request Structure
```json
{
  "context": {
    "version": "2.0.0",
    "action": "grievance_ledger",
    "domain": "beckn.one:deg:ev-charging",
    "location": {
      "country": { "code": "IND" },
      "city": { "code": "std:080" }
    },
    "bap_id": "...",
    "bap_uri": "...",
    "bpp_id": "...",
    "bpp_uri": "...",
    "transaction_id": "...",
    "message_id": "...",
    "timestamp": "...",
    "ttl": "PT30S",
    "schema_context": [
      "https://raw.githubusercontent.com/beckn/protocol-specifications-new/refs/heads/main/schemas/charging_service/v1/context.jsonld"
    ]
  },
  "message": {
    "ledger": {
      "@context": "https://becknprotocol.io/schemas/core/v2/Ledger/schema-context.jsonld",
      "@type": "beckn:Ledger",
      "beckn:id": "grievance-ledger-001",
      "beckn:type": "GRIEVANCE",
      "beckn:entity": {
        "@type": "beckn:Entity",
        "beckn:type": "bap",
        "beckn:id": "bap-id-123"
      },
      "beckn:reference": {
        "@type": "beckn:Reference",
        "beckn:refId": "order-789012",
        "beckn:refType": "order"
      },
      "beckn:support": {
        "@context": "https://becknprotocol.io/schemas/core/v2/SupportInfo/schema-context.jsonld",
        "@type": "beckn:SupportInfo",
        "beckn:issueType": "charging_failure",
        "beckn:description": "Charging stopped unexpectedly",
        "beckn:priority": "high",
        "beckn:status": "open",
        "beckn:contact": {
          "@type": "beckn:Contact",
          "beckn:phone": "+91-80-12345678",
          "beckn:email": "support@provider.com"
        }
      },
      "beckn:timestamp": "2025-01-27T10:00:00Z"
    }
  }
}
```

#### Schema Elements

| Element | Type | Description | Required |
|---------|------|-------------|----------|
| `ledger.@context` | URI | Ledger schema context | Yes |
| `ledger.@type` | String | Type: "beckn:Ledger" | Yes |
| `ledger.beckn:id` | String | Unique ledger entry ID | Yes |
| `ledger.beckn:type` | Enum | "GRIEVANCE" | Yes |
| `ledger.beckn:entity` | Object | Entity information (BAP/BPP) | Yes |
| `ledger.beckn:reference` | Object | Reference information | Yes |
| `ledger.beckn:reference.beckn:refId` | String | Reference ID (order, fulfillment, etc.) | Yes |
| `ledger.beckn:reference.beckn:refType` | Enum | "order", "fulfillment", "item", "payment" | Yes |
| `ledger.beckn:support` | Object | Support/grievance information | Yes |
| `ledger.beckn:support.@context` | URI | Support schema context | Yes |
| `ledger.beckn:support.@type` | String | "beckn:SupportInfo" | Yes |
| `ledger.beckn:support.beckn:issueType` | String | Type of issue | Yes |
| `ledger.beckn:support.beckn:description` | String | Issue description | Yes |
| `ledger.beckn:support.beckn:priority` | Enum | "low", "medium", "high", "critical" | No |
| `ledger.beckn:support.beckn:status` | Enum | "open", "in_progress", "resolved", "closed" | Yes |
| `ledger.beckn:support.beckn:contact` | Object | Contact information | No |
| `ledger.beckn:support.beckn:contact.@type` | String | "beckn:Contact" | Yes (if present) |
| `ledger.beckn:support.beckn:contact.beckn:phone` | String | Phone number | No |
| `ledger.beckn:support.beckn:contact.beckn:email` | String | Email address | No |
| `ledger.beckn:timestamp` | DateTime | Timestamp (ISO 8601) | Yes |

### 3. Transaction Ledger API

#### Request Structure
```json
{
  "context": {
    "version": "2.0.0",
    "action": "transaction_ledger",
    "domain": "beckn.one:deg:ev-charging",
    "location": {
      "country": { "code": "IND" },
      "city": { "code": "std:080" }
    },
    "bap_id": "...",
    "bap_uri": "...",
    "bpp_id": "...",
    "bpp_uri": "...",
    "transaction_id": "...",
    "message_id": "...",
    "timestamp": "...",
    "ttl": "PT30S",
    "schema_context": [
      "https://raw.githubusercontent.com/beckn/protocol-specifications-new/refs/heads/main/schemas/charging_service/v1/context.jsonld"
    ]
  },
  "message": {
    "ledger": {
      "@context": "https://becknprotocol.io/schemas/core/v2/Ledger/schema-context.jsonld",
      "@type": "beckn:Ledger",
      "beckn:id": "txn-ledger-001",
      "beckn:type": "TRANSACTION",
      "beckn:entity": {
        "@type": "beckn:Entity",
        "beckn:type": "bap",
        "beckn:id": "bap-id-123"
      },
      "beckn:reference": {
        "@type": "beckn:Reference",
        "beckn:orderId": "order-123456"
      },
      "beckn:payment": {
        "@context": "https://becknprotocol.io/schemas/core/v2/Payment/schema-context.jsonld",
        "@type": "beckn:Payment",
        "beckn:id": "payment-001",
        "beckn:txnRef": "TXN-123456789",
        "beckn:amount": {
          "currency": "INR",
          "value": 100.0
        },
        "beckn:paymentType": "PREPAID",
        "beckn:paymentMethod": "UPI",
        "beckn:status": "PAID"
      },
      "beckn:transactionDate": "2025-01-27T10:00:00Z",
      "beckn:completionDate": "2025-01-27T11:30:00Z"
    }
  }
}
```

#### Schema Elements

| Element | Type | Description | Required |
|---------|------|-------------|----------|
| `ledger.@context` | URI | Ledger schema context | Yes |
| `ledger.@type` | String | Type: "beckn:Ledger" | Yes |
| `ledger.beckn:id` | String | Unique ledger entry ID | Yes |
| `ledger.beckn:type` | Enum | "TRANSACTION" | Yes |
| `ledger.beckn:entity` | Object | Entity information (BAP/BPP) | Yes |
| `ledger.beckn:reference` | Object | Order reference | Yes |
| `ledger.beckn:reference.beckn:orderId` | String | Order identifier | Yes |
| `ledger.beckn:payment` | Object | Payment information | Yes |
| `ledger.beckn:payment.@context` | URI | Payment schema context | Yes |
| `ledger.beckn:payment.@type` | String | "beckn:Payment" | Yes |
| `ledger.beckn:payment.beckn:id` | String | Payment identifier | Yes |
| `ledger.beckn:payment.beckn:txnRef` | String | Transaction reference | Yes |
| `ledger.beckn:payment.beckn:amount` | Object | Payment amount | Yes |
| `ledger.beckn:payment.beckn:amount.currency` | String | Currency code (ISO 4217) | Yes |
| `ledger.beckn:payment.beckn:amount.value` | Number | Amount value | Yes |
| `ledger.beckn:payment.beckn:paymentType` | Enum | "PREPAID", "POSTPAID", "ON_ORDER" | Yes |
| `ledger.beckn:payment.beckn:paymentMethod` | Enum | "UPI", "CARD", "NET_BANKING", "WALLET", "BANK_TRANSFER" | Yes |
| `ledger.beckn:payment.beckn:status` | Enum | "PENDING", "PAID", "FAILED", "REFUNDED" | Yes |
| `ledger.beckn:transactionDate` | DateTime | Transaction date (ISO 8601) | Yes |
| `ledger.beckn:completionDate` | DateTime | Completion date (ISO 8601) | No |

## Common Context Structure

All three APIs share the same context structure at the root level:

```json
{
  "context": {
    "version": "2.0.0",                    // Protocol version
    "action": "rating_ledger|grievance_ledger|transaction_ledger",
    "domain": "beckn.one:deg:ev-charging", // Domain identifier
    "location": {                           // Location information
      "country": { "code": "IND" },
      "city": { "code": "std:080" }
    },
    "bap_id": "...",                       // BAP identifier
    "bap_uri": "...",                      // BAP endpoint URI
    "bpp_id": "...",                       // BPP identifier (optional)
    "bpp_uri": "...",                      // BPP endpoint URI (optional)
    "transaction_id": "...",              // Transaction identifier
    "message_id": "...",                   // Unique message ID
    "timestamp": "...",                    // ISO 8601 timestamp
    "ttl": "PT30S",                        // Time to live
    "schema_context": [                    // Schema context URLs
      "https://raw.githubusercontent.com/beckn/protocol-specifications-new/refs/heads/main/schemas/charging_service/v1/context.jsonld"
    ]
  }
}
```

## Response Structure

All APIs return a simple ACK response:

```json
{
  "message": {
    "ack": {
      "status": "ACK"
    }
  }
}
```

## Enum Values Reference

### Ledger Types
- `RATING` - Rating ledger entry
- `GRIEVANCE` - Grievance/support ledger entry
- `TRANSACTION` - Transaction ledger entry

### Entity Types
- `bap` - Buyer App Provider
- `bpp` - Buyer Platform Provider

### Rating Categories
- `fulfillment` - Rating for fulfillment/service
- `provider` - Rating for provider
- `item` - Rating for item/product

### Reference Types (Grievance)
- `order` - Order reference
- `fulfillment` - Fulfillment reference
- `item` - Item reference
- `payment` - Payment reference

### Priority Levels (Grievance)
- `low` - Low priority
- `medium` - Medium priority
- `high` - High priority
- `critical` - Critical priority

### Status Values (Grievance)
- `open` - Issue is open
- `in_progress` - Issue is being worked on
- `resolved` - Issue is resolved
- `closed` - Issue is closed

### Payment Types
- `PREPAID` - Prepaid payment
- `POSTPAID` - Postpaid payment
- `ON_ORDER` - Payment on order

### Payment Methods
- `UPI` - Unified Payments Interface
- `CARD` - Credit/Debit card
- `NET_BANKING` - Net banking
- `WALLET` - Digital wallet
- `BANK_TRANSFER` - Bank transfer

### Payment Status
- `PENDING` - Payment pending
- `PAID` - Payment completed
- `FAILED` - Payment failed
- `REFUNDED` - Payment refunded

## JSON-LD Best Practices

### 1. Always Include @context
Every object with semantic meaning should include its `@context` URI.

### 2. Use @type for Semantic Types
Always specify `@type` to indicate the semantic type of the object.

### 3. Use beckn: Prefix for Beckn Properties
All Beckn Protocol properties should use the `beckn:` prefix for consistency.

### 4. Maintain Context Hierarchy
Nested objects should include their own `@context` and `@type` when they represent distinct semantic entities.

### 5. ISO 8601 for Timestamps
All timestamp fields should use ISO 8601 format: `YYYY-MM-DDTHH:mm:ssZ`

## Schema Validation

When implementing these APIs, ensure:

1. **Context Validation**: Verify that all `@context` URIs are valid and accessible
2. **Type Validation**: Ensure all `@type` values match expected semantic types
3. **Required Fields**: All required fields (marked in tables above) must be present
4. **Enum Validation**: Enum values must match the allowed values listed above
5. **Format Validation**: 
   - Timestamps must be valid ISO 8601 format
   - URIs must be valid URI format
   - Email addresses must be valid email format

## Example: Complete Rating Ledger Request

```json
{
  "context": {
    "version": "2.0.0",
    "action": "rating_ledger",
    "domain": "beckn.one:deg:ev-charging",
    "location": {
      "country": { "code": "IND" },
      "city": { "code": "std:080" }
    },
    "bap_id": "ev-charging.sandbox1.com",
    "bap_uri": "http://onix-bap:8081/bap/receiver",
    "bpp_id": "charging-provider.com",
    "bpp_uri": "http://onix-bpp:8082/bpp/receiver",
    "transaction_id": "txn-123456",
    "message_id": "msg-001",
    "timestamp": "2025-01-27T10:00:00Z",
    "ttl": "PT30S",
    "schema_context": [
      "https://raw.githubusercontent.com/beckn/protocol-specifications-new/refs/heads/main/schemas/charging_service/v1/context.jsonld"
    ]
  },
  "message": {
    "ledger": {
      "@context": "https://becknprotocol.io/schemas/core/v2/Ledger/schema-context.jsonld",
      "@type": "beckn:Ledger",
      "beckn:id": "rating-ledger-001",
      "beckn:type": "RATING",
      "beckn:entity": {
        "@type": "beckn:Entity",
        "beckn:type": "bap",
        "beckn:id": "ev-charging.sandbox1.com"
      },
      "beckn:reference": {
        "@type": "beckn:Reference",
        "beckn:orderId": "order-123456",
        "beckn:fulfillmentId": "fulfillment-001"
      },
      "beckn:rating": {
        "@context": "https://becknprotocol.io/schemas/core/v2/Rating/schema-context.jsonld",
        "@type": "beckn:Rating",
        "beckn:value": 5,
        "beckn:best": 5,
        "beckn:worst": 1,
        "beckn:category": "fulfillment"
      },
      "beckn:feedback": {
        "@context": "https://becknprotocol.io/schemas/core/v2/Feedback/schema-context.jsonld",
        "@type": "beckn:Feedback",
        "beckn:comments": "Excellent charging experience! The station was clean and easy to find.",
        "beckn:tags": ["fast-charging", "easy-to-use", "clean-station"]
      },
      "beckn:timestamp": "2025-01-27T10:00:00Z"
    }
  }
}
```

## References

- **Beckn Protocol**: https://github.com/beckn/protocol-specifications
- **JSON-LD Specification**: https://www.w3.org/TR/json-ld/
- **Schema Contexts**: 
  - Ledger: `https://becknprotocol.io/schemas/core/v2/Ledger/schema-context.jsonld`
  - Rating: `https://becknprotocol.io/schemas/core/v2/Rating/schema-context.jsonld`
  - Feedback: `https://becknprotocol.io/schemas/core/v2/Feedback/schema-context.jsonld`
  - Support: `https://becknprotocol.io/schemas/core/v2/SupportInfo/schema-context.jsonld`
  - Payment: `https://becknprotocol.io/schemas/core/v2/Payment/schema-context.jsonld`

## Summary

The Meta Ledger APIs use a consistent JSON-LD structure that:

1. ✅ Follows Beckn Protocol standards
2. ✅ Uses semantic types (`@type`) for all objects
3. ✅ Includes context URIs (`@context`) for vocabulary definition
4. ✅ Uses `beckn:` prefix for Beckn Protocol properties
5. ✅ Maintains compatibility with existing Beckn APIs
6. ✅ Provides clear semantic meaning for all data elements

This structure ensures interoperability, semantic clarity, and compatibility with the broader Beckn ecosystem.

