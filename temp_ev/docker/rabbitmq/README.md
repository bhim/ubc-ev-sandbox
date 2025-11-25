# Docker RabbitMQ Plugins for ONIX BAP and BPP

This directory contains Docker plugins for ONIX BAP (Buyer App Platform) and BPP (Buyer Provider Platform) adapters with RabbitMQ message queue integration.

## Overview

The RabbitMQ plugins are designed to handle BAP and BPP transactions using RabbitMQ for asynchronous message processing. Each adapter consists of two modules:

### BAP Adapter Modules

1. **bapTxnCaller**: Queue consumer that consumes requests from BAP Backend and routes them to BPP via HTTP
2. **bapTxnReceiver**: HTTP handler that receives callbacks from BPP and publishes them to BAP Backend via RabbitMQ

### BPP Adapter Modules

1. **bppTxnCaller**: Queue consumer that consumes callbacks from BPP Backend and routes them to BAP/CDS via HTTP
2. **bppTxnReceiver**: HTTP handler that receives requests from BAP adapter and publishes them to BPP Backend via RabbitMQ

## Architecture

### BAP Adapter

#### bapTxnCaller (Queue Consumer)

- **Queue-Based Consumption**: Consumes messages from `bap_caller_queue` bound to routing keys like `bap.discover`, `bap.select`, etc. (requests from BAP Backend)

- **Message Processing**: Messages are processed through configured steps (`validateSchema`, `addRoute`, `sign`)

- **HTTP Routing**: Routes processed messages to BPP adapter via HTTP using `targetType: bpp`

- **ACK/NACK Handling**: 
  - **ACK**: Sent when message processing succeeds
  - **NACK**: Sent with requeue when processing fails (allows retry)

- **Manual Acknowledgment**: Uses `autoAck: false` for reliable message processing

#### bapTxnReceiver (HTTP Handler)

- **HTTP Server**: Requires HTTP server to be enabled (port 8001) for receiving HTTP requests

- **HTTP Endpoint**: Receives HTTP requests at `/bap/receiver/` from BPP adapter

- **Message Processing**: Processes through steps (`validateSign`, `validateSchema`, `addRoute`)

- **Publishing**: Publishes processed messages to RabbitMQ with routing keys like `bap.on_discover`, `bap.on_select`, etc. (callbacks to BAP Backend)

### BPP Adapter

#### bppTxnCaller (Queue Consumer)

- **Queue-Based Consumption**: Consumes messages from `bpp_caller_queue` bound to routing keys like `bpp.on_discover`, `bpp.on_select`, etc. (callbacks from BPP Backend)

- **Message Processing**: Messages are processed through configured steps (`validateSchema`, `addRoute`, `sign`)

- **HTTP Routing**: Routes processed messages to BAP adapter or CDS via HTTP using `targetType: bap` or `url`

- **ACK/NACK Handling**: 
  - **ACK**: Sent when message processing succeeds
  - **NACK**: Sent with requeue when processing fails (allows retry)

- **Manual Acknowledgment**: Uses `autoAck: false` for reliable message processing

#### bppTxnReceiver (HTTP Handler)

- **HTTP Server**: Requires HTTP server to be enabled (port 8002) for receiving HTTP requests

- **HTTP Endpoint**: Receives HTTP requests at `/bpp/receiver/` from BAP adapter

- **Message Processing**: Processes through steps (`validateSign`, `validateSchema`, `addRoute`)

- **Publishing**: Publishes processed messages to RabbitMQ with routing keys like `bpp.discover`, `bpp.select`, etc. (requests to BPP Backend)

## Features

- **Dual-Mode Operation**: 
  - Queue consumer for requests/callbacks from Backend
  - HTTP handler for callbacks/requests from adapter

- **Queue-Based Message Consumption**: Consumes messages from Backend via RabbitMQ

- **HTTP-Based Request/Callback Reception**: Receives requests/callbacks from adapter via HTTP

- **Message Publishing**: Publishes messages to Backend via RabbitMQ

- **Manual ACK/NACK**: Reliable message processing with retry capability

- **Phase 1 Support**: Routes discover requests to CDS for aggregation

- **Phase 2+ Support**: Routes requests directly to BPP and receives callbacks

- **External Configuration**: Config files are mounted from the host

- **Plugin Support**: All required plugins are built and included

## Pre-built Images

Pre-built images are available from Docker Hub:

- `manendrapalsingh/onix-bap-plugin-rabbit-mq:latest`
- `manendrapalsingh/onix-bap-plugin-rabbit-mq:sha-{commit-sha}`
- `manendrapalsingh/onix-bpp-plugin-rabbit-mq:latest`
- `manendrapalsingh/onix-bpp-plugin-rabbit-mq:sha-{commit-sha}`

## Running with Docker Compose

### BAP Plugin

Use the provided `docker-compose-onix-bap-rabbit-mq-plugin.yml`:

```bash
docker-compose -f docker-compose-onix-bap-rabbit-mq-plugin.yml up -d
```

### BPP Plugin

Use the provided `docker-compose-onix-bpp-rabbit-mq-plugin.yml`:

```bash
docker-compose -f docker-compose-onix-bpp-rabbit-mq-plugin.yml up -d
```

## Configuration

### Required Services

1. **RabbitMQ**: Message queue server (default: `rabbitmq:5672`)
2. **Redis**: Cache server 
   - BAP: `redis-bap:6379`
   - BPP: `redis-bpp:6379`
3. **Registry**: Mock registry service (default: `http://mock-registry:3030`)

### Environment Variables

- `CONFIG_FILE`: Path to the adapter configuration file
  - BAP: `/app/config/message-baised/rabbit-mq/onix-bap/adapter.yaml`
  - BPP: `/app/config/message-baised/rabbit-mq/onix-bpp/adapter.yaml`

### RabbitMQ Credentials Configuration

**RabbitMQ credentials are configured in the `adapter.yaml` file**, not via environment variables. Each publisher and consumer plugin requires `username` and `password` in its configuration:

```yaml
# Publisher configuration
publisher:
  id: publisher
  config:
    addr: rabbitmq:5672
    exchange: beckn_exchange
    durable: "true"
    username: admin
    password: admin

# RabbitMQ Consumer configuration
rabbitmqConsumer:
  id: rabbitmqconsumer
  config:
    addr: rabbitmq:5672
    exchange: beckn_exchange
    routingKeys: "bap.discover,bap.select,..."
    queueName: "bap_caller_queue"
    durable: "true"
    autoDelete: "false"
    exclusive: "false"
    noWait: "false"
    autoAck: "false"
    prefetchCount: "10"
    consumerThreads: "2"
    queueArgs: ""
    username: admin
    password: admin
```

**Note**: The default credentials in the provided configuration files are `admin`/`admin` to match the Docker Compose setup. For production deployments, replace these with your actual RabbitMQ credentials and consider using secret management tools to inject credentials securely.

### HTTP Configuration

**HTTP server is required** for the Receiver modules to receive HTTP requests. The HTTP configuration must be enabled in `adapter.yaml`:

**BAP Adapter:**
```yaml
http:
  port: 8001
  timeout:
    read: 30
    write: 30
    idle: 30
```

**BPP Adapter:**
```yaml
http:
  port: 8002
  timeout:
    read: 30
    write: 30
    idle: 30
```

- **BAP Port**: 8001 (must be exposed in Docker Compose)
- **BPP Port**: 8002 (must be exposed in Docker Compose)
- **Purpose**: Enables Receiver modules to receive HTTP requests/callbacks
- **Required**: Yes - The Receiver modules use handler type `std` which requires an HTTP server

### RabbitMQ Configuration

#### Exchange Configuration

- **Exchange Name**: `beckn_exchange`
- **Exchange Type**: Topic exchange (allows routing based on routing keys)
- **Durability**: Durable (survives broker restarts)

#### BAP bapTxnCaller (Queue Consumer)

The adapter consumes requests from BAP Backend with the following configuration:

- **Exchange**: `beckn_exchange` (topic exchange, durable)
- **Queue**: `bap_caller_queue` (durable)
- **Routing Keys** (requests from BAP Backend): 
  - `bap.discover` - Discover request
  - `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support` - Other requests
- **Acknowledgment**: Manual (`autoAck: false`)
- **Prefetch Count**: 10
- **Consumer Threads**: 2

#### BAP bapTxnReceiver (HTTP Handler + Publisher)

The adapter publishes callbacks to BAP Backend with the following configuration:

- **Exchange**: `beckn_exchange` (topic exchange, durable)
- **HTTP Endpoint**: `/bap/receiver/` (receives HTTP requests from BPP adapter)
- **Publishing Routing Keys** (callbacks to BAP Backend):
  - `bap.on_discover` - Phase 1 aggregated search results
  - `bap.on_select`, `bap.on_init`, `bap.on_confirm`, `bap.on_status`, `bap.on_track`, `bap.on_cancel`, `bap.on_update`, `bap.on_rating`, `bap.on_support` - Phase 2+ callbacks

#### BPP bppTxnCaller (Queue Consumer)

The adapter consumes callbacks from BPP Backend with the following configuration:

- **Exchange**: `beckn_exchange` (topic exchange, durable)
- **Queue**: `bpp_caller_queue` (durable)
- **Routing Keys** (callbacks from BPP Backend): 
  - `bpp.on_discover` - Phase 1 on_discover callback
  - `bpp.on_select`, `bpp.on_init`, `bpp.on_confirm`, `bpp.on_status`, `bpp.on_track`, `bpp.on_cancel`, `bpp.on_update`, `bpp.on_rating`, `bpp.on_support` - Phase 2+ callbacks
- **Acknowledgment**: Manual (`autoAck: false`)
- **Prefetch Count**: 10
- **Consumer Threads**: 2

#### BPP bppTxnReceiver (HTTP Handler + Publisher)

The adapter publishes requests to BPP Backend with the following configuration:

- **Exchange**: `beckn_exchange` (topic exchange, durable)
- **HTTP Endpoint**: `/bpp/receiver/` (receives HTTP requests from BAP adapter)
- **Publishing Routing Keys** (requests to BPP Backend):
  - `bpp.discover` - Phase 1 discover request
  - `bpp.select`, `bpp.init`, `bpp.confirm`, `bpp.status`, `bpp.track`, `bpp.cancel`, `bpp.update`, `bpp.rating`, `bpp.support` - Phase 2+ requests

#### Queue Structure Summary

**BAP Queues and Routing Keys**:
- **Queue**: `bap_caller_queue` (consumed by `bapTxnCaller`)
  - Routing Keys: `bap.discover`, `bap.select`, `bap.init`, `bap.confirm`, `bap.status`, `bap.track`, `bap.cancel`, `bap.update`, `bap.rating`, `bap.support`
- **Publishing Routing Keys** (published by `bapTxnReceiver`):
  - `bap.on_discover`, `bap.on_select`, `bap.on_init`, `bap.on_confirm`, `bap.on_status`, `bap.on_track`, `bap.on_cancel`, `bap.on_update`, `bap.on_rating`, `bap.on_support`

**BPP Queues and Routing Keys**:
- **Queue**: `bpp_caller_queue` (consumed by `bppTxnCaller`)
  - Routing Keys: `bpp.on_discover`, `bpp.on_select`, `bpp.on_init`, `bpp.on_confirm`, `bpp.on_status`, `bpp.on_track`, `bpp.on_cancel`, `bpp.on_update`, `bpp.on_rating`, `bpp.on_support`
- **Publishing Routing Keys** (published by `bppTxnReceiver`):
  - `bpp.discover`, `bpp.select`, `bpp.init`, `bpp.confirm`, `bpp.status`, `bpp.track`, `bpp.cancel`, `bpp.update`, `bpp.rating`, `bpp.support`

#### Queue Configuration Options

All queue parameters are configurable in `adapter.yaml`:

```yaml
rabbitmqConsumer:
  config:
    durable: "true"        # Queue survives broker restarts (default: true)
    autoDelete: "false"    # Don't delete queue when unused (default: false)
    exclusive: "false"     # Queue can be used by multiple connections (default: false)
    noWait: "false"        # Wait for queue creation confirmation (default: false)
    queueArgs: ""          # Optional queue arguments (see below)
```

#### Queue Arguments (queueArgs)

The `queueArgs` parameter allows you to configure advanced RabbitMQ queue options. It accepts either JSON format or key=value pairs:

**JSON Format Example:**
```yaml
queueArgs: '{"x-message-ttl":3600000,"x-max-length":10000,"x-max-priority":10}'
```

**Key-Value Format Example:**
```yaml
queueArgs: "x-message-ttl=3600000,x-max-length=10000,x-dead-letter-exchange=dlx"
```

**Available Queue Arguments:**

| Argument | Type | Description | Example |
|----------|------|-------------|---------|
| `x-message-ttl` | int64 | Message time-to-live in milliseconds | `3600000` (1 hour) |
| `x-expires` | int64 | Queue expiration in milliseconds | `7200000` (2 hours) |
| `x-max-length` | int | Maximum number of messages in queue | `10000` |
| `x-max-priority` | int | Maximum priority level (0-255) | `10` |
| `x-dead-letter-exchange` | string | Dead letter exchange name | `"dlx"` |
| `x-dead-letter-routing-key` | string | Dead letter routing key | `"failed"` |
| `x-queue-type` | string | Queue type: `"classic"` or `"quorum"` | `"quorum"` |
| `x-overflow` | string | Behavior when full: `"drop-head"` or `"reject-publish"` | `"reject-publish"` |
| `x-single-active-consumer` | bool | Only one consumer processes messages | `true` |
| `x-queue-mode` | string | Queue mode: `"default"` or `"lazy"` | `"lazy"` |

**Example Configuration with Queue Arguments:**
```yaml
rabbitmqConsumer:
  config:
    queueName: "bap_caller_queue"
    durable: "true"
    autoDelete: "false"
    exclusive: "false"
    noWait: "false"
    # Set message TTL to 1 hour, max queue length to 10k, enable priority
    queueArgs: '{"x-message-ttl":3600000,"x-max-length":10000,"x-max-priority":10,"x-dead-letter-exchange":"dlx"}'
```

### Processing Steps

#### BAP bapTxnCaller (Queue Consumer)

Processes requests from BAP Backend through:
- `validateSchema` - Validates message schema
- `addRoute` - Determines routing destination (BPP or CDS)
- `sign` - Signs the message before forwarding

After processing:
- **Success**: Routes to BPP/CDS via HTTP, sends ACK → message removed from queue
- **Error**: Sends NACK with requeue → message retried

#### BAP bapTxnReceiver (HTTP Handler)

Processes callbacks from BPP adapter through:
- `validateSign` - Validates message signatures
- `validateSchema` - Validates message schema
- `addRoute` - Determines publishing routing key

After processing:
- **Success**: Publishes to RabbitMQ with appropriate routing key
- **Error**: Returns HTTP error response

#### BPP bppTxnCaller (Queue Consumer)

Processes callbacks from BPP Backend through:
- `validateSchema` - Validates message schema
- `addRoute` - Determines routing destination (BAP adapter or CDS)
- `sign` - Signs the message before forwarding

After processing:
- **Success**: Routes to BAP/CDS via HTTP, sends ACK → message removed from queue
- **Error**: Sends NACK with requeue → message retried

#### BPP bppTxnReceiver (HTTP Handler)

Processes requests from BAP adapter through:
- `validateSign` - Validates message signatures
- `validateSchema` - Validates message schema
- `addRoute` - Determines publishing routing key

After processing:
- **Success**: Publishes to RabbitMQ with appropriate routing key
- **Error**: Returns HTTP error response

## Message Flow

### Flow 1: BAP Backend → BPP Backend (Requests)

1. **BAP Backend**: Publishes requests to `beckn_exchange` with routing keys like `bap.discover`, `bap.select`, etc.
2. **bapTxnCaller**: Consumes from `bap_caller_queue`, processes, routes to BPP adapter via HTTP
3. **bppTxnReceiver**: Receives HTTP request at `/bpp/receiver/`, processes, publishes to RabbitMQ
4. **BPP Backend**: Consumes from queues bound to routing keys like `bpp.discover`, `bpp.select`, etc.

### Flow 2: BPP Backend → BAP Backend (Callbacks)

1. **BPP Backend**: Publishes callbacks to `beckn_exchange` with routing keys like `bpp.on_discover`, `bpp.on_select`, etc.
2. **bppTxnCaller**: Consumes from `bpp_caller_queue`, processes, routes to BAP adapter via HTTP
3. **bapTxnReceiver**: Receives HTTP request at `/bap/receiver/`, processes, publishes to RabbitMQ
4. **BAP Backend**: Consumes callbacks from queues bound to routing keys like `bap.on_discover`, `bap.on_select`, etc.

## Producer and Consumer Examples

### BAP Backend Publishing Requests

#### Node.js Producer

```javascript
const amqp = require('amqplib');

async function publishMessage() {
  const connection = await amqp.connect('amqp://guest:guest@localhost:5672');
  const channel = await connection.createChannel();
  
  const exchange = 'beckn_exchange';
  await channel.assertExchange(exchange, 'topic', { durable: true });
  
  const message = {
    context: {
      domain: "ev_charging_network",
      action: "discover",
      bap_id: "example-bap.com",
      bpp_id: "example-bpp.com",
      transaction_id: "123e4567-e89b-12d3-a456-426614174000",
      message_id: "msg-123",
      timestamp: new Date().toISOString()
    },
    message: {
      // Your message payload
    }
  };
  
  const routingKey = 'bap.discover';  // Request routing key (from BAP Backend)
  const messageBuffer = Buffer.from(JSON.stringify(message));
  
  channel.publish(exchange, routingKey, messageBuffer, {
    persistent: true,
    contentType: 'application/json'
  });
  
  console.log(`Published message to ${routingKey}`);
  
  setTimeout(() => {
    connection.close();
  }, 500);
}

publishMessage().catch(console.error);
```

### BAP Backend Consuming Callbacks

#### Node.js Consumer

```javascript
const amqp = require('amqplib');

async function consumeMessages() {
  const connection = await amqp.connect('amqp://guest:guest@localhost:5672');
  const channel = await connection.createChannel();
  
  const exchange = 'beckn_exchange';
  await channel.assertExchange(exchange, 'topic', { durable: true });
  
  // Consume callbacks from the adapter
  // The adapter publishes to routing keys like:
  // bap.on_discover, bap.on_select, etc.
  const routingKey = 'bap.on_discover';
  const queueName = `bap_${routingKey.replace(/\./g, '_')}_queue`;
  
  const queue = await channel.assertQueue(queueName, { durable: true });
  await channel.bindQueue(queue.queue, exchange, routingKey);
  
  // Set prefetch to process one message at a time
  channel.prefetch(1);
  
  console.log(`Waiting for messages on ${routingKey}. To exit press CTRL+C`);
  
  channel.consume(queue.queue, (msg) => {
    if (msg) {
      try {
        const content = JSON.parse(msg.content.toString());
        console.log('Received callback:', content);
        
        // Process your callback here
        // ...
        
        // Acknowledge after successful processing
        channel.ack(msg);
      } catch (error) {
        console.error('Error processing message:', error);
        // Reject and requeue on error
        channel.nack(msg, false, true);
      }
    }
  }, {
    noAck: false // Manual acknowledgment
  });
}

consumeMessages().catch(console.error);
```

### BPP Backend Publishing Callbacks

#### Node.js Producer

```javascript
const amqp = require('amqplib');

async function publishMessage() {
  const connection = await amqp.connect('amqp://guest:guest@localhost:5672');
  const channel = await connection.createChannel();
  
  const exchange = 'beckn_exchange';
  await channel.assertExchange(exchange, 'topic', { durable: true });
  
  const message = {
    context: {
      domain: "ev_charging_network",
      action: "on_discover",
      bap_id: "example-bap.com",
      bpp_id: "example-bpp.com",
      transaction_id: "123e4567-e89b-12d3-a456-426614174000",
      message_id: "msg-123",
      timestamp: new Date().toISOString()
    },
    message: {
      // Your message payload
    }
  };
  
  const routingKey = 'bpp.on_discover';  // Callback routing key
  const messageBuffer = Buffer.from(JSON.stringify(message));
  
  channel.publish(exchange, routingKey, messageBuffer, {
    persistent: true,
    contentType: 'application/json'
  });
  
  console.log(`Published message to ${routingKey}`);
  
  setTimeout(() => {
    connection.close();
  }, 500);
}

publishMessage().catch(console.error);
```

### BPP Backend Consuming Requests

#### Node.js Consumer

```javascript
const amqp = require('amqplib');

async function consumeMessages() {
  const connection = await amqp.connect('amqp://guest:guest@localhost:5672');
  const channel = await connection.createChannel();
  
  const exchange = 'beckn_exchange';
  await channel.assertExchange(exchange, 'topic', { durable: true });
  
  // Consume requests from the adapter
  // The adapter publishes to routing keys like:
  // bpp.discover, bpp.select, etc.
  const routingKey = 'bpp.discover';
  const queueName = `bpp_${routingKey.replace(/\./g, '_')}_queue`;
  
  const queue = await channel.assertQueue(queueName, { durable: true });
  await channel.bindQueue(queue.queue, exchange, routingKey);
  
  // Set prefetch to process one message at a time
  channel.prefetch(1);
  
  console.log(`Waiting for messages on ${routingKey}. To exit press CTRL+C`);
  
  channel.consume(queue.queue, (msg) => {
    if (msg) {
      try {
        const content = JSON.parse(msg.content.toString());
        console.log('Received request:', content);
        
        // Process your request here
        // ...
        
        // Acknowledge after successful processing
        channel.ack(msg);
      } catch (error) {
        console.error('Error processing message:', error);
        // Reject and requeue on error
        channel.nack(msg, false, true);
      }
    }
  }, {
    noAck: false // Manual acknowledgment
  });
}

consumeMessages().catch(console.error);
```

## RabbitMQ Management UI

The RabbitMQ Management Plugin is enabled by default in the Docker Compose setup and provides a web-based UI for monitoring and managing RabbitMQ. This is essential for testing consumer behavior, monitoring queues, and debugging message flow.

### Accessing the Management UI

1. **Start the services**:
   ```bash
   docker-compose -f docker-compose-onix-bap-rabbit-mq-plugin.yml up -d
   # Or for BPP:
   docker-compose -f docker-compose-onix-bpp-rabbit-mq-plugin.yml up -d
   ```

2. **Open the Management UI**:
   - URL: `http://localhost:15672`
   - Username: `admin` (default, as configured in docker-compose)
   - Password: `admin` (default, as configured in docker-compose)

### Key Features for Monitoring Adapters

#### 1. **Overview Dashboard**
   - **Location**: Home page after login
   - **What to Monitor**:
     - Total messages published/consumed
     - Message rates (messages per second)
     - Connection count
     - Queue count
     - Consumer count

#### 2. **Queues Tab** - Monitor Queue Status
   - **Location**: Click "Queues" in the top navigation
   - **Key Queues to Monitor**:
     - `bap_caller_queue` - Messages consumed by BAP adapter's `bapTxnCaller`
     - `bpp_caller_queue` - Messages consumed by BPP adapter's `bppTxnCaller`
   
   **What to Check**:
   - **Ready**: Number of messages waiting to be consumed
   - **Unacked**: Messages being processed (not yet acknowledged)
   - **Total**: Total messages that have passed through the queue
   - **Consumers**: Number of active consumers connected to the queue
   - **Consumer utilization**: How efficiently consumers are processing messages
   - **Message rates**: Messages per second being published/consumed

   **Testing Consumer Behavior**:
   - Watch the "Ready" count decrease as consumers process messages
   - Monitor "Unacked" to see messages currently being processed
   - If "Ready" grows, consumers may be slower than message producers
   - If "Unacked" stays high, consumers may be stuck or processing slowly

#### 3. **Exchanges Tab** - Monitor Message Publishing
   - **Location**: Click "Exchanges" in the top navigation
   - **Key Exchange**: `beckn_exchange`
   
   **What to Check**:
   - **Publish rate**: Messages per second being published
   - **Bindings**: See which queues are bound to which routing keys
   - Click on `beckn_exchange` to see all bound queues and routing keys

#### 4. **Connections Tab** - Monitor Consumer Connections
   - **Location**: Click "Connections" in the top navigation
   - **What to Check**:
     - Active connections from ONIX adapters
     - Connection state (running, idle)
     - Channels per connection
     - Message rates per connection

#### 5. **Channels Tab** - Monitor Consumer Channels
   - **Location**: Click "Channels" in the top navigation
   - **What to Check**:
     - Active channels (each consumer uses a channel)
     - Prefetch count (how many unacked messages per consumer)
     - Consumer count per channel
     - Message acknowledgment rates

#### 6. **Publish/Get Messages** - Test Message Publishing
   - **Location**: Go to "Exchanges" → Click on `beckn_exchange` → Scroll to "Publish message"
   - **How to Test**:
     1. Select routing key (e.g., `bap.discover`, `bap.select`, etc. for BAP or `bpp.on_discover`, `bpp.on_select`, etc. for BPP)
     2. Enter message payload (JSON format)
     3. Click "Publish message"
     4. Monitor the target queue to see if the message appears
     5. Watch consumer process the message

   **Example Test Message** (for `bap.discover`):
   ```json
   {
     "context": {
       "version": "2.0.0",
       "action": "discover",
       "domain": "beckn.one:deg:ev-charging",
       "location": {
         "country": { "code": "IND" },
         "city": { "code": "std:080" }
       },
       "bap_id": "example-bap.com",
       "bap_uri": "http://example-bap.com",
       "transaction_id": "550e8400-e29b-41d4-a716-446655440000",
       "message_id": "110e8400-e29b-41d4-a716-446655440009",
       "timestamp": "2025-01-27T10:00:00Z",
       "ttl": "PT30S"
     },
     "message": {
       "spatial": [{
         "op": "s_dwithin",
         "targets": "$['beckn:availableAt'][*]['geo']",
         "geometry": {
           "type": "Point",
           "coordinates": [77.59, 12.94]
         },
         "distanceMeters": 10000
       }]
     }
   }
   ```

#### 7. **Get Messages** - Manually Consume Messages
   - **Location**: Go to "Queues" → Click on a queue → Scroll to "Get messages"
   - **How to Use**:
     1. Select acknowledgment mode (Ack mode: `Nack message requeue true/false`)
     2. Set number of messages to retrieve
     3. Click "Get messages"
     4. View message payload and headers
   
   **Note**: This is useful for debugging but doesn't test actual consumer behavior. Use this to inspect messages without consuming them permanently.

### Testing Consumer Behavior - Step by Step

#### Test 1: Verify Consumers are Connected
1. Go to **Queues** → Click `bap_caller_queue` (or `bpp_caller_queue`)
2. Check **"Consumers"** column - should show 2 (from adapter configuration: `consumerThreads: "2"`)
3. If 0, check adapter logs: `docker logs onix-bap-plugin-rabbitmq` or `docker logs onix-bpp-plugin-rabbitmq`

#### Test 2: Monitor Message Consumption
1. Publish a test message to `beckn_exchange` with routing key `bap.discover` (for BAP) or `bpp.on_discover` (for BPP)
2. Go to **Queues** → `bap_caller_queue` (or `bpp_caller_queue`)
3. Watch **"Ready"** count - should increase briefly
4. Watch **"Unacked"** count - should increase as consumer processes
5. Watch **"Ready"** decrease to 0 as message is consumed
6. Check **"Message rates"** - should show consumption rate

#### Test 3: Test Consumer Prefetch
1. Publish multiple messages (e.g., 10 messages)
2. Monitor **"Unacked"** - should not exceed prefetch count (configured as 10 in adapter: `prefetchCount: "10"`)
3. If messages are processed faster than prefetch, **"Unacked"** should stay at prefetch limit
4. As messages are acknowledged, new ones should be delivered

#### Test 4: Test Consumer Failure/Recovery
1. Stop a consumer: `docker-compose stop onix-bap-plugin-rabbitmq`
2. Publish messages - they should accumulate in **"Ready"**
3. Restart consumer: `docker-compose start onix-bap-plugin-rabbitmq`
4. Watch **"Ready"** decrease as consumer resumes processing

### Using RabbitMQ CLI Tools (Alternative)

If you prefer command-line tools:

```bash
# List queues
docker exec rabbitmq rabbitmqctl list_queues

# List exchanges
docker exec rabbitmq rabbitmqctl list_exchanges

# List bindings
docker exec rabbitmq rabbitmqctl list_bindings

# Get queue info
docker exec rabbitmq rabbitmqctl list_queues name messages consumers

# Monitor queue in real-time
watch -n 1 'docker exec rabbitmq rabbitmqctl list_queues name messages consumers'
```

## Troubleshooting

### RabbitMQ Connection Issues

- Verify RabbitMQ is running: `docker ps | grep rabbitmq`
- Check RabbitMQ logs: `docker logs rabbitmq`
- Verify network connectivity: Ensure plugin container can reach `rabbitmq:5672`
- Check credentials: Ensure `username` and `password` are configured in `adapter.yaml` for both `publisher` and `rabbitmqConsumer` plugins

### Messages Not Consumed

- Verify queue exists: Access RabbitMQ Management UI at `http://localhost:15672`
- Check queue bindings: Ensure queue is bound to exchange with correct routing key
- Review adapter logs: `docker logs onix-bap-plugin-rabbitmq` or `docker logs onix-bpp-plugin-rabbitmq`
- Verify routing keys match: 
  - For BAP: Check `routingKeys` in `bapTxnCaller` config match your BAP Backend producer (e.g., `bap.discover`)
  - For BPP: Check `routingKeys` in `bppTxnCaller` config match your BPP Backend producer (e.g., `bpp.on_discover`)

### ACK/NACK Issues

- Check adapter logs for processing errors
- Verify message format matches expected schema
- Check signature validation if `validateSign` step is enabled
- Messages with errors will be NACKed and requeued automatically

### Config Not Found

- Verify config directory is mounted correctly
- Check that `adapter.yaml` exists at the mounted path
- Verify file permissions

### HTTP Endpoint Issues

- Verify HTTP port is exposed in Docker Compose (8001 for BAP, 8002 for BPP)
- Check HTTP configuration is enabled in `adapter.yaml`
- Verify network connectivity between adapters
- Check adapter logs for HTTP connection errors

### Consumer Issues

1. **No Consumers Connected**:
   - Check adapter logs: `docker logs onix-bap-plugin-rabbitmq` or `docker logs onix-bpp-plugin-rabbitmq`
   - Verify RabbitMQ connection in logs
   - Check network connectivity
   - Verify credentials in `adapter.yaml` match RabbitMQ server credentials
   - Use RabbitMQ Management UI → Queues → Check "Consumers" column

2. **Messages Not Being Consumed**:
   - Verify consumers are connected (Management UI → Queues → Consumers column)
   - Check if messages are in "Ready" state
   - Verify routing keys match queue bindings
   - Check adapter logs for errors
   - Ensure queue name in config matches the queue name in RabbitMQ

3. **High Unacked Messages**:
   - Consumers may be processing slowly
   - Check adapter processing time in logs
   - Consider increasing consumer threads in adapter config (`consumerThreads`)
   - Check for errors causing message processing to hang
   - Verify prefetch count is appropriate for your workload

4. **Messages Accumulating**:
   - Consumers may be stopped or crashed
   - Check consumer count in Management UI
   - Restart consumers if needed: `docker-compose restart onix-bap-plugin-rabbitmq`
   - Verify message format matches expected schema
   - Check for repeated NACKs causing message requeue loops

### Configuration Issues

1. **Verify config files are mounted**:
   ```bash
   # Check ONIX adapter configs
   docker exec onix-bap-plugin-rabbitmq ls -la /app/config/message-baised/rabbit-mq/onix-bap/
   
   # Check routing configurations
   docker exec onix-bap-plugin-rabbitmq cat /app/config/message-baised/rabbit-mq/onix-bap/adapter.yaml
   ```

2. **Check config file syntax**:
   - Verify YAML syntax is correct
   - Check indentation (YAML is sensitive to spacing)
   - Verify all required fields are present

3. **Verify RabbitMQ queue bindings**:
   - Open RabbitMQ Management UI: `http://localhost:15672`
   - Navigate to "Exchanges" → `beckn_exchange`
   - Check "Bindings" to see queue bindings
   - Verify routing keys match between producer and consumer configs

### Registry Lookup Failures

1. **Verify registry is running**:
   ```bash
   curl http://localhost:3030/health
   ```

2. **Check subscriber registration**:
   ```bash
   curl http://localhost:3030/lookup?subscriber_id=example-bap.com
   ```

3. **Verify registry URL in adapter config**:
   - Check `registry.url` in `adapter.yaml` matches your registry service
   - Default: `http://mock-registry:3030`

## Related Documentation

- [Configuration Guide](../../../../CONFIG.md)
- [Setup Guide](../../../../SETUP.md)
