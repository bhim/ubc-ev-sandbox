#!/bin/bash

# Port Forward Script for EV Charging Sandbox - Microservice Architecture
# This script sets up port forwarding for all services (ONIX adapters and mock services)

NAMESPACE="${NAMESPACE:-ev-charging-sandbox}"
RELEASE_BAP="${RELEASE_BAP:-ev-charging-bap}"
RELEASE_BPP="${RELEASE_BPP:-ev-charging-bpp}"

echo "Setting up port forwarding for all EV Charging Sandbox services..."
echo "Press Ctrl+C to stop all port forwards"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Stopping all port forwards..."
    pkill -f "kubectl port-forward.*${NAMESPACE}" || true
    exit 0
}

# Trap Ctrl+C
trap cleanup SIGINT SIGTERM

# Start port forwards for all services
echo "Starting port forwards..."

# ONIX Adapters
kubectl port-forward -n $NAMESPACE svc/${RELEASE_BAP}-onix-api-microservice-bap-service 8001:8001 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/${RELEASE_BPP}-onix-api-microservice-bpp-service 8002:8002 > /dev/null 2>&1 &

# Mock Registry and CDS
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-registry 3030:3030 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-cds 8082:8082 > /dev/null 2>&1 &

# Mock BAP Services (ports 9001-9010) - using on_* prefix for callbacks
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bap-on-discover 9001:9001 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bap-on-select 9002:9002 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bap-on-init 9003:9003 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bap-on-confirm 9004:9004 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bap-on-status 9005:9005 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bap-on-track 9006:9006 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bap-on-cancel 9007:9007 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bap-on-update 9008:9008 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bap-on-rating 9009:9009 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bap-on-support 9010:9010 > /dev/null 2>&1 &

# Mock BPP Services (ports 9011-9020)
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bpp-discover 9011:9011 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bpp-select 9012:9012 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bpp-init 9013:9013 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bpp-confirm 9014:9014 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bpp-status 9015:9015 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bpp-track 9016:9016 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bpp-cancel 9017:9017 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bpp-update 9018:9018 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bpp-rating 9019:9019 > /dev/null 2>&1 &
kubectl port-forward -n $NAMESPACE svc/ev-charging-mock-bpp-support 9020:9020 > /dev/null 2>&1 &

sleep 2

echo "Port forwarding active! Services available at:"
echo ""
echo "  ONIX Adapters:"
echo "  - BAP ONIX Adapter:     http://localhost:8001"
echo "    - Caller endpoints:   http://localhost:8001/bap/caller/{action}"
echo "    - Receiver endpoints: http://localhost:8001/bap/receiver/{action}"
echo ""
echo "  - BPP ONIX Adapter:     http://localhost:8002"
echo "    - Caller endpoints:   http://localhost:8002/bpp/caller/{action}"
echo "    - Receiver endpoints: http://localhost:8002/bpp/receiver/{action}"
echo ""
echo "  Mock Services:"
echo "  - Mock Registry:        http://localhost:3030"
echo "  - Mock CDS:             http://localhost:8082"
echo ""
echo "  Mock BAP Services (on_* callbacks):"
echo "  - ev-charging-mock-bap-on-discover:    http://localhost:9001"
echo "  - ev-charging-mock-bap-on-select:      http://localhost:9002"
echo "  - ev-charging-mock-bap-on-init:        http://localhost:9003"
echo "  - ev-charging-mock-bap-on-confirm:     http://localhost:9004"
echo "  - ev-charging-mock-bap-on-status:      http://localhost:9005"
echo "  - ev-charging-mock-bap-on-track:       http://localhost:9006"
echo "  - ev-charging-mock-bap-on-cancel:      http://localhost:9007"
echo "  - ev-charging-mock-bap-on-update:      http://localhost:9008"
echo "  - ev-charging-mock-bap-on-rating:      http://localhost:9009"
echo "  - ev-charging-mock-bap-on-support:     http://localhost:9010"
echo ""
echo "  Mock BPP Services:"
echo "  - ev-charging-mock-bpp-discover:    http://localhost:9011"
echo "  - ev-charging-mock-bpp-select:      http://localhost:9012"
echo "  - ev-charging-mock-bpp-init:        http://localhost:9013"
echo "  - ev-charging-mock-bpp-confirm:     http://localhost:9014"
echo "  - ev-charging-mock-bpp-status:      http://localhost:9015"
echo "  - ev-charging-mock-bpp-track:       http://localhost:9016"
echo "  - ev-charging-mock-bpp-cancel:      http://localhost:9017"
echo "  - ev-charging-mock-bpp-update:      http://localhost:9018"
echo "  - ev-charging-mock-bpp-rating:      http://localhost:9019"
echo "  - ev-charging-mock-bpp-support:     http://localhost:9020"
echo ""
echo "Press Ctrl+C to stop all port forwards"

# Wait for user interrupt
wait

