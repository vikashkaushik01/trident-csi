# Trident Images for Multi-Arch Mirroring

## Overview
Complete list of all container images required for Trident CSI deployment on Kubernetes 1.29.

## Source Images to Mirror

### NetApp Trident Core Images
| Source Image | Target Image | Description |
|--------------|--------------|-------------|
| `netapp/trident-operator:25.02.0` | `ghcr.io/nirmata/trident-operator:25.02.0` | Trident operator for managing Trident lifecycle |
| `netapp/trident:25.02.0` | `ghcr.io/nirmata/trident:25.02.0` | Main Trident CSI driver |
| `netapp/trident-autosupport:25.02` | `ghcr.io/nirmata/trident-autosupport:25.02` | Trident telemetry and support bundle collection |

### Kubernetes CSI Sidecar Images
| Source Image | Target Image | Description |
|--------------|--------------|-------------|
| `registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0` | `ghcr.io/nirmata/csi-node-driver-registrar:v2.13.0` | Registers CSI driver with kubelet |
| `registry.k8s.io/sig-storage/csi-attacher:v4.7.0` | `ghcr.io/nirmata/csi-attacher:v4.7.0` | Handles volume attach/detach operations |
| `registry.k8s.io/sig-storage/csi-provisioner:v5.1.0` | `ghcr.io/nirmata/csi-provisioner:v5.1.0` | Provisions storage volumes |
| `registry.k8s.io/sig-storage/csi-resizer:v1.12.0` | `ghcr.io/nirmata/csi-resizer:v1.12.0` | Handles volume expansion |
| `registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0` | `ghcr.io/nirmata/csi-snapshotter:v8.2.0` | Manages volume snapshots |

## Multi-Architecture Support

All images will be mirrored with support for:
- **linux/amd64** - Intel/AMD 64-bit
- **linux/arm64** - ARM 64-bit (Apple Silicon, ARM servers)

## Image Usage in Deployment Files

### bundle_post_1_25.yaml
- `netapp/trident-operator:25.02.0` (line 476)

### operator.yaml  
- `netapp/trident-operator:25.02.0` (line 24)

### tridentorchestrator_cr_k8s_1_29.yaml
- `netapp/trident:25.02.0` (line 12)
- `netapp/trident-autosupport:25.02` (line 13)
- `registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0` (line 16)
- `registry.k8s.io/sig-storage/csi-attacher:v4.7.0` (line 17)
- `registry.k8s.io/sig-storage/csi-provisioner:v5.1.0` (line 18)
- `registry.k8s.io/sig-storage/csi-resizer:v1.12.0` (line 19)
- `registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0` (line 20)

## Mirroring Commands

### Prerequisites
```bash
# Install Docker with buildx support
docker --version
docker buildx version

# Login to GitHub Container Registry
docker login ghcr.io -u <username>
```

### Option 1: Use Automated Script (Recommended)
```bash
# Run the simple mirroring script
./push-trident-images-simple.sh
```

### Option 2: Manual Mirroring
```bash
# Mirror each image individually
docker buildx imagetools create --tag ghcr.io/nirmata/trident-operator:25.02.0 netapp/trident-operator:25.02.0
docker buildx imagetools create --tag ghcr.io/nirmata/trident:25.02.0 netapp/trident:25.02.0
docker buildx imagetools create --tag ghcr.io/nirmata/trident-autosupport:25.02 netapp/trident-autosupport:25.02
docker buildx imagetools create --tag ghcr.io/nirmata/csi-node-driver-registrar:v2.13.0 registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0
docker buildx imagetools create --tag ghcr.io/nirmata/csi-attacher:v4.7.0 registry.k8s.io/sig-storage/csi-attacher:v4.7.0
docker buildx imagetools create --tag ghcr.io/nirmata/csi-provisioner:v5.1.0 registry.k8s.io/sig-storage/csi-provisioner:v5.1.0
docker buildx imagetools create --tag ghcr.io/nirmata/csi-resizer:v1.12.0 registry.k8s.io/sig-storage/csi-resizer:v1.12.0
docker buildx imagetools create --tag ghcr.io/nirmata/csi-snapshotter:v8.2.0 registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0
```

## Verification

After mirroring, verify multi-arch support:
```bash
# Check each mirrored image for multi-arch support
docker buildx imagetools inspect ghcr.io/nirmata/trident-operator:25.02.0
docker buildx imagetools inspect ghcr.io/nirmata/trident:25.02.0
docker buildx imagetools inspect ghcr.io/nirmata/trident-autosupport:25.02
# ... and so on for all images
```

## Final Mirrored Image List

After successful mirroring, these images will be available:

```
ghcr.io/nirmata/trident-operator:25.02.0
ghcr.io/nirmata/trident:25.02.0
ghcr.io/nirmata/trident-autosupport:25.02
ghcr.io/nirmata/csi-node-driver-registrar:v2.13.0
ghcr.io/nirmata/csi-attacher:v4.7.0
ghcr.io/nirmata/csi-provisioner:v5.1.0
ghcr.io/nirmata/csi-resizer:v1.12.0
ghcr.io/nirmata/csi-snapshotter:v8.2.0
```

## Next Steps

1. Update deployment files to use `ghcr.io/nirmata/*` images
2. Test deployment with mirrored images
3. Update customer documentation with new image references
4. Set up automated image sync for future Trident releases 