#!/usr/bin/env bash

set -e

# Detect if OrbStack's built-in Kubernetes is the active context
USING_ORBSTACK_K8S=false
if command -v orb &> /dev/null; then
  CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
  if [[ "$CURRENT_CONTEXT" == "orbstack" ]]; then
    USING_ORBSTACK_K8S=true
  fi
fi

# Check required dependencies
MISSING_DEPS=()

if ! command -v docker &> /dev/null; then
  MISSING_DEPS+=("docker")
fi

if [[ "$USING_ORBSTACK_K8S" == "false" ]] && ! command -v k3d &> /dev/null; then
  MISSING_DEPS+=("k3d")
fi

if ! command -v kubectl &> /dev/null; then
  MISSING_DEPS+=("kubectl")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
  echo "Error: Missing required dependencies: ${MISSING_DEPS[*]}"
  echo ""
  echo "Please install the missing tools:"
  echo "  - docker:  https://docs.docker.com/get-docker/"
  echo "  - k3d:     https://k3d.io/#installation"
  echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
  exit 1
fi

# Define required port mappings
REQUIRED_PORTS=(30070 30080 30090 30100 30110 30120)

if [[ "$USING_ORBSTACK_K8S" == "true" ]]; then
  echo "OrbStack Kubernetes detected (context: orbstack), skipping k3d cluster setup..."
  echo "NodePort services will be accessible via localhost through OrbStack's networking."
else
  # Check if cluster already exists
  if k3d cluster list | grep -q "^local "; then
    echo "Cluster 'local' already exists, checking port mappings..."

    # Get current port mappings from the load balancer
    CURRENT_PORTS=$(docker port k3d-local-serverlb | grep -o '[0-9]\{5\}' | sort -u || true)

    # Check for missing ports and add them
    for port in "${REQUIRED_PORTS[@]}"; do
      if ! echo "$CURRENT_PORTS" | grep -q "^${port}$"; then
        echo "Adding missing port mapping: $port"
        k3d cluster edit local --port-add "${port}:${port}@server:0"
      fi
    done
  else
    echo "Creating new cluster with port mappings..."
    k3d cluster create local \
      -p "30070:30070@server:0" \
      -p "30080:30080@server:0" \
      -p "30090:30090@server:0" \
      -p "30100:30100@server:0" \
      -p "30110:30110@server:0" \
      -p "30120:30120@server:0"
  fi
fi

# Apply kubernetes manifests (kubectl apply is idempotent)
echo "Applying kubernetes manifests..."
kubectl apply -f cyberchef-deployment.yaml
kubectl apply -f excalidraw-deployment.yaml
kubectl apply -f ipcheck-deployment.yaml
kubectl apply -f it-tools-deployment.yaml
kubectl apply -f networking-toolbox-deployment.yaml
kubectl apply -f web-check-deployment.yaml

echo "Done! Services available at:"
echo "  - ipcheck:            http://localhost:30070"
echo "  - it-tools:           http://localhost:30080"
echo "  - cyberchef:          http://localhost:30090"
echo "  - excalidraw:         http://localhost:30100"
echo "  - web-check:          http://localhost:30110"
echo "  - networking-toolbox: http://localhost:30120"
