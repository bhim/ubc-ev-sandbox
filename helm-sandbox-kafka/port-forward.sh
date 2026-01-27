#!/bin/bash

# Port Forward Script for EV Charging Kafka Sandbox
# This script sets up port forwarding for Kafka services
#
# Note: Mock services (registry, CDS, mock-bap-kafka, mock-bpp-kafka) are ClusterIP (internal only)
#       and don't require port forwarding as they communicate internally via Kafka topics.

NAMESPACE="ev-charging-sandbox"

echo "Setting up port forwarding for Kafka sandbox services..."
echo "Press Ctrl+C to stop all port forwards"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Stopping all port forwards..."
    pkill -f "kubectl port-forward.*ev-charging-sandbox" || true
    exit 0
}

# Trap Ctrl+C
trap cleanup SIGINT SIGTERM

# Start port forwards for Kafka services
echo "Starting port forwards..."

# Kafka UI (from BAP release, shared resource)
kubectl port-forward -n $NAMESPACE svc/onix-kafka-ui 8080:8080 > /dev/null 2>&1 &

# BAP adapter HTTP endpoint (for bapTxnReceiver)
kubectl port-forward -n $NAMESPACE svc/onix-bap 8001:8001 > /dev/null 2>&1 &

# BPP adapter HTTP endpoint (for bppTxnReceiver)
kubectl port-forward -n $NAMESPACE svc/onix-bpp 8002:8002 > /dev/null 2>&1 &



sleep 2

echo "Port forwarding active! Services available at:"
echo "  - Kafka UI:                http://localhost:8080"
echo "    - Web UI for managing and monitoring Kafka topics"
echo ""
echo "  - BAP ONIX Adapter:        http://localhost:8001"
echo "    - Receiver endpoints:    http://localhost:8001/bap/receiver/{action}"
echo "    - Health check:          http://localhost:8001/health"
echo ""
echo "  - BPP ONIX Adapter:        http://localhost:8002"
echo "    - Receiver endpoints:     http://localhost:8002/bpp/receiver/{action}"
echo "    - Health check:          http://localhost:8002/health"

echo "Note: Mock Kafka services (mock-bap-kafka, mock-bpp-kafka) are queue-only"
echo "      and communicate via Kafka topics, not HTTP endpoints."
echo ""
echo "Note: To publish messages to Kafka topics, use the scripts in message/ directory"
echo "      or access Kafka directly via kubectl exec on the Kafka pod."
echo ""
echo "Press Ctrl+C to stop all port forwards"

# Wait for user interrupt
wait
