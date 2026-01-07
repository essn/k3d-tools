# Local Kubernetes Toolkit

Personal collection of development and security tools running locally in k3d.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [k3d](https://k3d.io/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quick Start

```bash
./k3d-cluster-bootstrap.sh
```

Services available at `http://localhost:<port>`:

| Service | Port | Description |
|---------|------|-------------|
| [ipcheck](https://github.com/jason5ng32/MyIP) | 30070 | IP address checker |
| [it-tools](https://github.com/CorentinTh/it-tools) | 30080 | Developer toolbox |
| [cyberchef](https://github.com/gchq/CyberChef) | 30090 | Data transformation tool |
| [excalidraw](https://github.com/excalidraw/excalidraw) | 30100 | Diagramming tool |
| [web-check](https://github.com/Lissy93/web-check) | 30110 | Website analyzer |
| [networking-toolbox](https://github.com/Lissy93/networking-toolbox) | 30120 | Network diagnostics |

## Management

Check status:
```bash
kubectl get pods
kubectl get svc
```

Delete cluster:
```bash
k3d cluster delete local
```

## Adding Services

1. Create `<service>-deployment.yaml` with Deployment + NodePort Service
2. Update `k3d-cluster-bootstrap.sh`:
   - Add port to `REQUIRED_PORTS` array
   - Add port mapping to cluster create command
   - Add `kubectl apply -f <service>-deployment.yaml`
   - Add service URL to output
3. Run `./k3d-cluster-bootstrap.sh`

The bootstrap script is idempotent and handles both initial setup and updates.
