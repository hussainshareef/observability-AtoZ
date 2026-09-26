#!/bin/bash
set -e

echo "========================================"
echo " Observability Lab - Prerequisites"
echo "========================================"

# Homebrew is the preferred package manager on macOS.
if ! command -v brew >/dev/null 2>&1; then
    echo "[1/6] Homebrew not found."
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Make brew available in the current shell on Apple Silicon and Intel Macs.
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "[1/6] Homebrew already installed."
fi

echo "[2/6] Installing/updating required tools..."

# Docker CLI is required by Colima and Docker Compose.
brew install docker docker-compose 2>/dev/null || true

# Colima provides the Linux VM/Docker runtime on macOS.
brew install colima 2>/dev/null || true

# Kubernetes CLI, Kind, and Helm.
brew install kubectl kind helm 2>/dev/null || true

echo "[3/6] Verifying installed tools..."

commands=(brew docker docker-compose colima kubectl kind helm)

for cmd in "${commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "  ✓ $cmd"
    else
        echo "  ✗ $cmd"
        echo "ERROR: $cmd is not available."
        exit 1
    fi
done

echo "[4/6] Checking Docker Compose..."

docker-compose --version

echo "[5/6] Checking Kubernetes tools..."

kubectl version --client
kind version
helm version --short

echo "[6/6] Checking Colima..."

colima version

echo ""
echo "========================================"
echo " Prerequisites completed successfully"
echo "========================================"
echo ""
echo "Installed/verified:"
echo "  ✓ Homebrew"
echo "  ✓ Docker CLI"
echo "  ✓ Docker Compose"
echo "  ✓ Colima"
echo "  ✓ kubectl"
echo "  ✓ Kind"
echo "  ✓ Helm"
echo ""
echo "Next step:"
echo "  ./start-observability.sh"
echo ""
echo "Note: This script does not start Colima or create the"
echo "Kubernetes cluster. The start script handles those steps."
