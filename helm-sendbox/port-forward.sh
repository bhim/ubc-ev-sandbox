#!/bin/bash

# Port Forward Script for EV Charging Sandbox
# This script sets up port forwarding for BAP and BPP ONIX adapters only
#
# Note: Mock services (registry, CDS, mock-bap, mock-bpp) are ClusterIP (internal only)
#       and don't require port forwarding as they communicate internally with ONIX adapters.

NAMESPACE="ev-charging-sandbox"

echo "Setting up port forwarding for BAP and BPP ONIX adapters..."
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

# Start port forwards for BAP and BPP ONIX adapters only
echo "Starting port forwards..."
kubectl port-forward -n $NAMESPACE svc/onix-bap-service 8001:8001 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/onix-bpp-service 8002:8002 > /dev/null 2>&1 &

sleep 2

echo "Port forwarding active! Services available at:"
echo "  - BAP ONIX Adapter:     http://localhost:8001"
echo "    - Caller endpoints:   http://localhost:8001/bap/caller/{action}"
echo "    - Receiver endpoints: http://localhost:8001/bap/receiver/{action}"
echo ""
echo "  - BPP ONIX Adapter:     http://localhost:8002"
echo "    - Caller endpoints:   http://localhost:8002/bpp/caller/{action}"
echo "    - Receiver endpoints: http://localhost:8002/bpp/receiver/{action}"
echo ""
echo "Note: Mock services (registry, CDS, mock-bap, mock-bpp) are internal only"
echo "      and communicate with ONIX adapters via Kubernetes internal DNS."
echo ""
echo "Press Ctrl+C to stop all port forwards"

# Wait for user interrupt
wait

