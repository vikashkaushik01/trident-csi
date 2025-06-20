# Customer Private Registry Deployment Guide

## 🎯 Overview
This guide helps customers who use private registries or on-premises environments to deploy Trident CSI using their own container registry instead of public registries.

## 📋 Prerequisites

### Step 1: Mirror Images to Your Private Registry

**Using the automated script (recommended):**
```bash
# Set your private registry URL
export CUSTOMER_REGISTRY=your-registry.company.com/trident

# Run the mirroring script
./customer-private-registry-setup.sh
```

**Manual mirroring:**
```bash
# Login to both registries
docker login ghcr.io
docker login your-registry.company.com

# Pull and push each image
docker pull ghcr.io/nirmata/trident-operator:25.02.0
docker tag ghcr.io/nirmata/trident-operator:25.02.0 your-registry.company.com/trident/trident-operator:25.02.0
docker push your-registry.company.com/trident/trident-operator:25.02.0

# Repeat for all images listed in trident-images.txt
```

---

## 🔧 Deployment File Updates Required

### **1. Bundle Deployment File**

**File:** `deploy/bundle_post_1_25.yaml`
**Line:** 476

**Current:**
```yaml
image: netapp/trident-operator:25.02.0
```

**Update to:**
```yaml
image: YOUR_REGISTRY/trident-operator:25.02.0
```

### **2. Standalone Operator File**

**File:** `deploy/operator.yaml`
**Line:** 24

**Current:**
```yaml
image: netapp/trident-operator:25.02.0
```

**Update to:**
```yaml
image: YOUR_REGISTRY/trident-operator:25.02.0
```

### **3. TridentOrchestrator Custom Resource**

**File:** `deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml`
**Lines:** 12-20

**Current:**
```yaml
spec:
  debug: true
  namespace: trident
  tridentImage: "netapp/trident:25.02.0"
  autosupportImage: "netapp/trident-autosupport:25.02"
  imageRegistry: ""
  # CSI sidecar images
  nodeDriverRegistrarImage: "registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0"
  csiAttacherImage: "registry.k8s.io/sig-storage/csi-attacher:v4.7.0"
  csiProvisionerImage: "registry.k8s.io/sig-storage/csi-provisioner:v5.1.0"
  csiResizerImage: "registry.k8s.io/sig-storage/csi-resizer:v1.12.0"
  csiSnapshotterImage: "registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0"
```

**Update to:**
```yaml
spec:
  debug: true
  namespace: trident
  tridentImage: "YOUR_REGISTRY/trident:25.02.0"
  autosupportImage: "YOUR_REGISTRY/trident-autosupport:25.02"
  imageRegistry: ""
  # CSI sidecar images
  nodeDriverRegistrarImage: "YOUR_REGISTRY/csi-node-driver-registrar:v2.13.0"
  csiAttacherImage: "YOUR_REGISTRY/csi-attacher:v4.7.0"
  csiProvisionerImage: "YOUR_REGISTRY/csi-provisioner:v5.1.0"
  csiResizerImage: "YOUR_REGISTRY/csi-resizer:v1.12.0"
  csiSnapshotterImage: "YOUR_REGISTRY/csi-snapshotter:v8.2.0"
```

### **4. Default TridentOrchestrator**

**File:** `deploy/crds/tridentorchestrator_cr.yaml`
**Lines:** 12-20

**Current:**
```yaml
tridentImage: "ghcr.io/nirmata/trident:25.02.0"
autosupportImage: "ghcr.io/nirmata/trident-autosupport:25.02"
```

**Update to:**
```yaml
tridentImage: "YOUR_REGISTRY/trident:25.02.0"
autosupportImage: "YOUR_REGISTRY/trident-autosupport:25.02"
```

### **5. Other TridentOrchestrator Examples**

Update these files if you use them:

- `deploy/crds/tridentorchestrator_cr_customimage.yaml` (line 7)
- `deploy/crds/tridentorchestrator_cr_imagepullsecrets.yaml` (line 7)
- `deploy/crds/tridentorchestrator_cr_autosupport.yaml` (line 8)

---

## 🔨 Automated Update Script

Create this script to automatically update all deployment files:

```bash
#!/bin/bash
# update-registry-references.sh

CUSTOMER_REGISTRY="${1:-your-registry.company.com/trident}"

echo "Updating all deployment files to use registry: $CUSTOMER_REGISTRY"

# Update bundle file
sed -i.bak "s|netapp/trident-operator:25.02.0|$CUSTOMER_REGISTRY/trident-operator:25.02.0|g" deploy/bundle_post_1_25.yaml

# Update standalone operator
sed -i.bak "s|netapp/trident-operator:25.02.0|$CUSTOMER_REGISTRY/trident-operator:25.02.0|g" deploy/operator.yaml

# Update TridentOrchestrator CR files
sed -i.bak "s|netapp/trident:25.02.0|$CUSTOMER_REGISTRY/trident:25.02.0|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
sed -i.bak "s|netapp/trident-autosupport:25.02|$CUSTOMER_REGISTRY/trident-autosupport:25.02|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
sed -i.bak "s|registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0|$CUSTOMER_REGISTRY/csi-node-driver-registrar:v2.13.0|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
sed -i.bak "s|registry.k8s.io/sig-storage/csi-attacher:v4.7.0|$CUSTOMER_REGISTRY/csi-attacher:v4.7.0|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
sed -i.bak "s|registry.k8s.io/sig-storage/csi-provisioner:v5.1.0|$CUSTOMER_REGISTRY/csi-provisioner:v5.1.0|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
sed -i.bak "s|registry.k8s.io/sig-storage/csi-resizer:v1.12.0|$CUSTOMER_REGISTRY/csi-resizer:v1.12.0|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
sed -i.bak "s|registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0|$CUSTOMER_REGISTRY/csi-snapshotter:v8.2.0|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml

# Update other CR files
sed -i.bak "s|ghcr.io/nirmata/trident:25.02.0|$CUSTOMER_REGISTRY/trident:25.02.0|g" deploy/crds/tridentorchestrator_cr.yaml
sed -i.bak "s|ghcr.io/nirmata/trident-autosupport:25.02|$CUSTOMER_REGISTRY/trident-autosupport:25.02|g" deploy/crds/tridentorchestrator_cr.yaml

echo "✅ All files updated successfully!"
echo "📝 Backup files created with .bak extension"
```

---

## 📝 Required Images List

Make sure these images are available in your private registry:

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

## 🚀 Step-by-Step Deployment

### Step 1: Mirror Images
```bash
export CUSTOMER_REGISTRY=harbor.company.com/trident
./customer-private-registry-setup.sh
```

### Step 2: Update Deployment Files
```bash
# Option A: Use automated script
./update-registry-references.sh harbor.company.com/trident

# Option B: Manual updates (follow the file update instructions above)
```

### Step 3: Deploy Trident
```bash
# Create namespace
kubectl create namespace trident

# Deploy operator
kubectl apply -f deploy/bundle_post_1_25.yaml

# Wait for operator
kubectl wait --for=condition=available deployment/trident-operator -n trident --timeout=300s

# Deploy Trident
kubectl apply -f deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml

# Verify deployment
kubectl get tridentorchestrator trident -w
```

---

## 🔐 Image Pull Secrets (If Required)

If your private registry requires authentication, create image pull secrets:

```bash
# Create image pull secret
kubectl create secret docker-registry trident-registry-secret \
  --docker-server=your-registry.company.com \
  --docker-username=username \
  --docker-password=password \
  -n trident

# Update TridentOrchestrator to use the secret
# Add this to your TridentOrchestrator CR:
spec:
  imagePullSecrets:
  - trident-registry-secret
```

---

## ✅ Verification

After deployment, verify all pods are using your private registry:

```bash
# Check all pods in trident namespace
kubectl get pods -n trident -o yaml | grep "image:"

# Expected output should show YOUR_REGISTRY instead of public registries
```

---

## 🔧 Common Registry Examples

### Harbor Registry
```bash
export CUSTOMER_REGISTRY=harbor.company.com/trident
./customer-private-registry-setup.sh
./update-registry-references.sh harbor.company.com/trident
```

### Nexus Registry
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

### Azure Container Registry
```bash
export CUSTOMER_REGISTRY=myregistry.azurecr.io/trident
az acr login --name myregistry
./customer-private-registry-setup.sh
./update-registry-references.sh myregistry.azurecr.io/trident
```

---

## 🆘 Troubleshooting

### Image Pull Errors
```bash
# Check if images exist in your registry
docker pull YOUR_REGISTRY/trident-operator:25.02.0

# Check image pull secrets
kubectl get secrets -n trident
```

### Authentication Issues
```bash
# Verify registry login
docker login your-registry.company.com

# Test image access
docker pull YOUR_REGISTRY/trident:25.02.0
```

### Multi-Architecture Issues
Ensure your private registry supports multi-arch images. Some registries may need special configuration for ARM64 support.

---

## 📞 Support

If you encounter issues:
1. Verify all images are properly mirrored to your registry
2. Check image pull secrets and registry authentication
3. Ensure your registry supports the required architectures
4. Contact your registry administrator for registry-specific issues

---

**✅ Once completed, your Trident deployment will use only your private registry images!** 