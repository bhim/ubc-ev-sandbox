# Quick Start Guide - Meta Ledger APIs

This guide helps you quickly get started with the Meta Ledger APIs for the EV Charging Network.

## What Are Meta Ledger APIs?

Meta Ledger APIs are centralized data collection endpoints used by the network provider to store and manage data from all BAP and BPP participants in the network. Think of them as the "network's memory" for ratings, grievances, and transactions.

## The Three Ledgers

### 1. Rating Ledger 📊
**Purpose:** Track service quality and customer satisfaction

**When to use:** After any rating/feedback is submitted via `rating` or `on_rating` APIs

**What it stores:**
- Rating values (1-5 stars)
- Category (fulfillment, provider, item)
- Feedback comments and tags
- Order and fulfillment references

**Example scenario:** Customer rates their charging experience as 5 stars with comment "Fast and reliable"

### 2. Grievance Ledger 🎫
**Purpose:** Track support requests and grievances for dispute resolution

**When to use:** After any support request is initiated via `support` or `on_support` APIs

**What it stores:**
- Issue type and description
- Priority level
- Status (open, in_progress, resolved, closed)
- Contact information
- Order/fulfillment references

**Example scenario:** Customer reports charging stopped unexpectedly - this gets logged for tracking and resolution

### 3. Transaction Ledger 💰
**Purpose:** Record all financial transactions for reconciliation and audit

**When to use:** After order confirmation when payment is processed via `confirm` or `on_confirm` APIs

**What it stores:**
- Payment amount and currency
- Payment type (PREPAID, POSTPAID)
- Payment method (UPI, CARD, etc.)
- Transaction reference numbers
- Transaction dates and completion dates

**Example scenario:** Customer completes UPI payment of ₹100 for charging session

## Quick Setup (Postman)

### Step 1: Import Collection

Choose one option:
- **Option A:** Import `Meta-All-Ledgers.postman_collection.json` for all three APIs
- **Option B:** Import individual collections for specific ledgers

### Step 2: Set Environment Variables

Create a Postman environment with these variables:

```json
{
  "meta_service_url": "http://localhost:8090",
  "version": "2.0.0",
  "domain": "beckn.one:deg:ev-charging",
  "bap_id": "ev-charging.sandbox1.com",
  "bpp_id": "charging-provider.com",
  "transaction_id": "txn-12345",
  "timestamp": "2025-01-27T10:00:00Z"
}
```

**Note:** `timestamp` will be auto-generated if you use `{{timestamp}}` in Postman

### Step 3: Test the APIs

#### Test Rating Ledger

1. Select the `rating_ledger` request
2. Review the request body - it should look like:

```json
{
  "context": {
    "version": "2.0.0",
    "action": "rating_ledger",
    "domain": "beckn.one:deg:ev-charging",
    "bap_id": "ev-charging.sandbox1.com",
    "bpp_id": "charging-provider.com",
    "transaction_id": "txn-12345",
    "message_id": "msg-001",
    "timestamp": "2025-01-27T10:00:00Z"
  },
  "message": {
    "ledger_id": "rating-ledger-001",
    "entity_type": "bap",
    "entity_id": "ev-charging.sandbox1.com",
    "order_id": "order-123456",
    "fulfillment_id": "fulfillment-001",
    "rating": {
      "value": 5,
      "best": 5,
      "worst": 1,
      "category": "fulfillment"
    },
    "feedback": {
      "comments": "Excellent charging experience!",
      "tags": ["fast-charging", "clean-station"]
    },
    "timestamp": "2025-01-27T10:00:00Z"
  }
}
```

3. Click **Send**
4. You should receive:

```json
{
  "message": {
    "ack": {
      "status": "ACK",
      "ledger_id": "rating-ledger-001"
    }
  }
}
```

#### Test Grievance Ledger

Similar process, but use the `grievance_ledger` request with support-related data.

#### Test Transaction Ledger

Similar process, but use the `transaction_ledger` request with payment data.

## Integration Flow

Here's how these APIs fit into the typical EV charging workflow:

```
Customer Books & Completes Charging Session
                    ↓
┌─────────────────────────────────────────────┐
│  1. Order Confirmed (with payment)          │
│     → Call transaction_ledger API           │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  2. Issue Occurred? (optional)              │
│     → Call grievance_ledger API             │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  3. Session Completed (rating)              │
│     → Call rating_ledger API                │
└─────────────────────────────────────────────┘
```

## Code Integration Examples

### Example 1: Submit Rating Data (Python)

```python
import requests
import json
from datetime import datetime

def submit_rating_to_ledger(order_id, fulfillment_id, rating_value, comments):
    url = "http://localhost:8090/meta/rating_ledger"
    
    payload = {
        "context": {
            "version": "2.0.0",
            "action": "rating_ledger",
            "domain": "beckn.one:deg:ev-charging",
            "bap_id": "ev-charging.sandbox1.com",
            "bpp_id": "charging-provider.com",
            "transaction_id": "txn-12345",
            "message_id": "msg-001",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        },
        "message": {
            "ledger_id": f"rating-{order_id}",
            "entity_type": "bap",
            "entity_id": "ev-charging.sandbox1.com",
            "order_id": order_id,
            "fulfillment_id": fulfillment_id,
            "rating": {
                "value": rating_value,
                "best": 5,
                "worst": 1,
                "category": "fulfillment"
            },
            "feedback": {
                "comments": comments,
                "tags": ["charging-experience"]
            },
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
    }
    
    response = requests.post(url, json=payload)
    return response.json()

# Usage
result = submit_rating_to_ledger(
    order_id="order-123456",
    fulfillment_id="fulfillment-001",
    rating_value=5,
    comments="Excellent service!"
)
print(result)
```

### Example 2: Submit Grievance Data (Node.js)

```javascript
const axios = require('axios');

async function submitGrievanceToLedger(orderId, issueType, description) {
    const url = 'http://localhost:8090/meta/grievance_ledger';
    
    const payload = {
        context: {
            version: '2.0.0',
            action: 'grievance_ledger',
            domain: 'beckn.one:deg:ev-charging',
            bap_id: 'ev-charging.sandbox1.com',
            bpp_id: 'charging-provider.com',
            transaction_id: 'txn-12345',
            message_id: 'msg-002',
            timestamp: new Date().toISOString()
        },
        message: {
            ledger_id: `grievance-${orderId}`,
            entity_type: 'bap',
            entity_id: 'ev-charging.sandbox1.com',
            ref_id: orderId,
            ref_type: 'order',
            support_request: {
                issue_type: issueType,
                description: description,
                priority: 'high',
                status: 'open'
            },
            contact: {
                phone: '+91-80-12345678',
                email: 'support@provider.com'
            },
            timestamp: new Date().toISOString()
        }
    };
    
    const response = await axios.post(url, payload);
    return response.data;
}

// Usage
submitGrievanceToLedger(
    'order-789012',
    'charging_failure',
    'Charging stopped unexpectedly after 10 minutes'
).then(result => console.log(result));
```

### Example 3: Submit Transaction Data (Java)

```java
import java.net.http.*;
import java.time.Instant;
import com.google.gson.Gson;

public class TransactionLedgerClient {
    
    public static void submitTransaction(String orderId, double amount, String paymentMethod) {
        String url = "http://localhost:8090/meta/transaction_ledger";
        
        var payload = new TransactionLedgerRequest();
        payload.context.version = "2.0.0";
        payload.context.action = "transaction_ledger";
        payload.context.timestamp = Instant.now().toString();
        
        payload.message.ledger_id = "txn-" + orderId;
        payload.message.entity_type = "bap";
        payload.message.order_id = orderId;
        payload.message.payment.amount.value = amount;
        payload.message.payment.amount.currency = "INR";
        payload.message.payment.payment_method = paymentMethod;
        payload.message.payment.status = "PAID";
        
        var gson = new Gson();
        String json = gson.toJson(payload);
        
        var client = HttpClient.newHttpClient();
        var request = HttpRequest.newBuilder()
            .uri(URI.create(url))
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(json))
            .build();
            
        var response = client.send(request, HttpResponse.BodyHandlers.ofString());
        System.out.println(response.body());
    }
}
```

## Common Pitfalls & Solutions

### Issue 1: Missing Required Fields
**Error:** `400 Bad Request - Missing required field: entity_id`

**Solution:** Ensure all required fields in the request are populated:
- context: version, action, domain, bap_id, transaction_id, message_id, timestamp
- message: ledger_id, entity_type, entity_id, and action-specific fields

### Issue 2: Invalid Timestamp Format
**Error:** `400 Bad Request - Invalid timestamp format`

**Solution:** Use ISO 8601 format: `2025-01-27T10:00:00Z`

### Issue 3: Connection Refused
**Error:** `Connection refused to http://localhost:8090`

**Solution:** Ensure the meta service is running. Check `meta_service_url` environment variable.

## Testing Checklist

Before going to production, test:

- ✅ All three ledger APIs respond with ACK
- ✅ Required fields validation works (try removing a field)
- ✅ Invalid data is rejected (wrong enum values, etc.)
- ✅ Both BAP and BPP can submit data (test entity_type: "bap" and "bpp")
- ✅ Large comments/descriptions are handled properly
- ✅ Concurrent requests don't cause issues

## Next Steps

1. **Set up the Meta Service:** Deploy the meta service that implements these endpoints
2. **Configure Database:** Set up database to store ledger data
3. **Integrate with BAP/BPP:** Add calls to meta ledger APIs in your BAP/BPP code
4. **Monitor & Analyze:** Use stored data for analytics and reporting
5. **Build Dashboards:** Create visualization dashboards for network insights

## Support & Resources

- **Full Documentation:** See `README.md` in this directory
- **API Specification:** See `swagger/meta-ledger.yaml`
- **Postman Collections:** All collections are in `postman-collection/` directory
- **Schema Reference:** Swagger file contains complete schema definitions

## FAQ

**Q: When should I call these APIs?**
A: Call them after the corresponding business event occurs (after rating, after support request, after payment confirmation).

**Q: What if the meta service is down?**
A: Implement retry logic with exponential backoff. Consider queuing requests for later submission.

**Q: Can I query the ledger data?**
A: This version only supports POST (write) operations. Query APIs will be added in future versions.

**Q: Is this data encrypted?**
A: Transport layer security (HTTPS) should be used in production. Database-level encryption is recommended.

**Q: How long is data retained?**
A: Retention policy depends on your network provider's requirements and compliance regulations.

---

**Happy Coding! 🚀**

