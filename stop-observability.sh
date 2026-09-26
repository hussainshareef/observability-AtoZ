#!/bin/bash
set -e

PROJECT_DIR="/Users/shareef/prometheus-grafana"
CLUSTER_NAME="observability-cluster"
PID_FILE="$PROJECT_DIR/.kube-state-metrics-port-forward.pid"

echo "========================================"
echo " Stopping Observability Stack"
echo "========================================"

cd "$PROJECT_DIR"

echo "[1/3] Stopping kube-state-metrics port-forward..."
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID" || true
        echo "Port-forward stopped (PID $PID)"
    else
        echo "Port-forward process is not running"
    fi
    rm -f "$PID_FILE"
else
    echo "No port-forward PID file found"
fi

echo "[2/3] Removing Kind cluster..."
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
    kind delete cluster --name "$CLUSTER_NAME"
else
    echo "Kind cluster does not exist"
fi

echo "[3/3] Stopping Docker Compose..."
docker-compose down

echo "Stopping Colima..."
colima stop

echo ""
echo "========================================"
echo " Observability Stack Stopped"
echo "========================================"
echo ""
echo "Docker named volumes were NOT deleted."
echo "Grafana/Prometheus/Alertmanager data is preserved."
echo ""
echo "To start again:"
echo "  ./start-observability.sh"
