#!/bin/bash
set -e

PROJECT_DIR="/Users/shareef/prometheus-grafana"
CLUSTER_NAME="observability-cluster"
PORT_FORWARD_PORT="18080"
PID_FILE="$PROJECT_DIR/.kube-state-metrics-port-forward.pid"
LOG_FILE="$PROJECT_DIR/kube-state-metrics-port-forward.log"

echo "========================================"
echo " Starting Observability Stack"
echo "========================================"

cd "$PROJECT_DIR"

echo "[1/7] Starting Colima..."
colima start

echo "[2/7] Starting Docker Compose stack..."
docker-compose up -d

echo "[3/7] Checking Kind..."
if kind get clusters | grep -qx "$CLUSTER_NAME"; then
    echo "Kind cluster already exists: $CLUSTER_NAME"
else
    echo "Creating Kind cluster: $CLUSTER_NAME"
    kind create cluster --name "$CLUSTER_NAME"
fi

echo "[4/7] Applying Kubernetes application..."
kubectl apply -f k8s/app.yaml

echo "[5/7] Installing/ensuring kube-state-metrics..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null

if helm status kube-state-metrics >/dev/null 2>&1; then
    echo "kube-state-metrics Helm release already exists"
else
    helm install kube-state-metrics prometheus-community/kube-state-metrics
fi

echo "[6/7] Waiting for kube-state-metrics..."
kubectl rollout status deployment/kube-state-metrics --timeout=120s

echo "[7/7] Ensuring kube-state-metrics is NodePort..."
kubectl patch svc kube-state-metrics \
  -p '{"spec":{"type":"NodePort"}}' >/dev/null

# Stop an old port-forward if its PID is still running.
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Stopping existing kube-state-metrics port-forward..."
        kill "$OLD_PID" || true
        sleep 1
    fi
    rm -f "$PID_FILE"
fi

echo "Starting kube-state-metrics port-forward..."
nohup kubectl port-forward svc/kube-state-metrics \
    ${PORT_FORWARD_PORT}:8080 \
    --address 0.0.0.0 >"$LOG_FILE" 2>&1 &

PF_PID=$!
echo "$PF_PID" > "$PID_FILE"

sleep 3

echo ""
echo "========================================"
echo " Observability Stack Started"
echo "========================================"
echo ""
echo "Docker Compose:"
docker-compose ps
echo ""
echo "Kubernetes:"
kubectl get nodes
echo ""
kubectl get pods
echo ""
kubectl get svc kube-state-metrics
echo ""
echo "Port-forward:"
echo "  http://localhost:${PORT_FORWARD_PORT}/metrics"
echo ""
echo "Prometheus:"
echo "  http://localhost:9090"
echo "Grafana:"
echo "  http://localhost:3000"
echo "Alertmanager:"
echo "  http://localhost:9093"
echo "Blackbox:"
echo "  http://localhost:9115"
echo ""
echo "Port-forward PID: $PF_PID"
echo "Log: $LOG_FILE"
