# 🏢 Private Registry Quick Start Guide

## 🎯 For Customers Using Private Registries / On-Premises Environments

This guide provides everything you need to deploy Trident CSI using your private container registry instead of public registries.

---

## 📦 What's Included

| File | Description |
|------|-------------|
| `trident-images.txt` | List of all Trident images |
| `customer-private-registry-setup.sh` | Script to mirror images to your registry |
| `update-registry-references.sh` | Script to update deployment files |
| `CUSTOMER_REGISTRY_DEPLOYMENT_GUIDE.md` | Detailed deployment guide |

---

## ⚡ Quick Setup (3 Steps)

### Step 1: Mirror Images to Your Registry
```bash
# Set your registry URL
export CUSTOMER_REGISTRY=harbor.company.com/trident

# Run the mirroring script
./customer-private-registry-setup.sh
```

### Step 2: Update Deployment Files
```bash
# Update all deployment files to use your registry
./update-registry-references.sh harbor.company.com/trident
```

### Step 3: Deploy Trident
```bash
# Deploy Trident using your private registry
kubectl create namespace trident
kubectl apply -f deploy/bundle_post_1_25.yaml
kubectl wait --for=condition=available deployment/trident-operator -n trident --timeout=300s
kubectl apply -f deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
```

---

## 📋 Required Images

These 8 images will be mirrored from `ghcr.io/nirmata` to your private registry:

```
YOUR_REGISTRY/trident-operator:25.02.0
YOUR_REGISTRY/trident:25.02.0
YOUR_REGISTRY/trident-autosupport:25.02
YOUR_REGISTRY/csi-node-driver-registrar:v2.13.0
YOUR_REGISTRY/csi-attacher:v4.7.0
YOUR_REGISTRY/csi-provisioner:v5.1.0
YOUR_REGISTRY/csi-resizer:v1.12.0
YOUR_REGISTRY/csi-snapshotter:v8.2.0
```

---

## 🔧 Registry Examples

### Harbor
```bash
export CUSTOMER_REGISTRY=harbor.company.com/trident
./customer-private-registry-setup.sh
./update-registry-references.sh harbor.company.com/trident
```

### Nexus
```bash
export CUSTOMER_REGISTRY=nexus.company.com:8082/trident
./customer-private-registry-setup.sh
./update-registry-references.sh nexus.company.com:8082/trident
```

### AWS ECR
```bash
export CUSTOMER_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com/trident
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
./customer-private-registry-setup.sh
./update-registry-references.sh 123456789012.dkr.ecr.us-east-1.amazonaws.com/trident
```

### Azure ACR
```bash
export CUSTOMER_REGISTRY=myregistry.azurecr.io/trident
az acr login --name myregistry
./customer-private-registry-setup.sh
./update-registry-references.sh myregistry.azurecr.io/trident
```

---

## 📝 Files Updated Automatically

The `update-registry-references.sh` script updates these files:

| File | Line(s) | What's Updated |
|------|---------|----------------|
| `deploy/bundle_post_1_25.yaml` | 476 | Trident operator image |
| `deploy/operator.yaml` | 24 | Trident operator image |
| `deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml` | 12-20 | All Trident and CSI images |
| `deploy/crds/tridentorchestrator_cr.yaml` | 12-20 | All Trident and CSI images |
| `deploy/crds/tridentorchestrator_cr_*.yaml` | Various | Optional configuration files |

✅ **Backup files are created automatically** (`.bak` extension)

---

## 🔐 Image Pull Secrets (If Needed)

If your registry requires authentication:

```bash
# Create image pull secret
kubectl create secret docker-registry trident-registry-secret \
  --docker-server=your-registry.company.com \
  --docker-username=username \
  --docker-password=password \
  -n trident

# Update TridentOrchestrator CR to use the secret
# Add to spec section:
imagePullSecrets:
- trident-registry-secret
```

---

## ✅ Verification

After deployment, verify all pods use your private registry:

```bash
# Check pod images
kubectl get pods -n trident -o yaml | grep "image:" | head -10

# Expected: All images should show YOUR_REGISTRY instead of public registries
```

---

## 🆘 Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| **Image pull errors** | Verify images exist in your registry: `docker pull YOUR_REGISTRY/trident:25.02.0` |
| **Authentication failed** | Login to your registry: `docker login your-registry.com` |
| **Pod not starting** | Check image pull secrets: `kubectl get secrets -n trident` |
| **Multi-arch issues** | Ensure your registry supports multi-arch images |

---

## 📚 Detailed Documentation

For comprehensive instructions, see:
- **`CUSTOMER_REGISTRY_DEPLOYMENT_GUIDE.md`** - Complete deployment guide
- **`TRIDENT_IMAGES_LIST.md`** - All image details and mirroring info

---

## 🎯 Summary

1. **Mirror 8 images** from `ghcr.io/nirmata` to your private registry
2. **Update 5+ deployment files** to reference your registry
3. **Deploy Trident** using standard kubectl commands
4. **Verify** all pods use your private registry

**🚀 Total setup time: ~10-15 minutes**

**✅ Result: Trident CSI deployed entirely from your private registry with multi-arch support!** 