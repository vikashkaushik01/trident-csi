# Trident Storage Provisioner - Complete Setup Guide for Kubernetes 1.29

## 📋 Overview

NetApp Trident is a dynamic storage provisioner for Kubernetes that enables persistent storage for containerized applications. This guide provides step-by-step instructions for deploying Trident 25.02.0 on Kubernetes 1.29.

### ✅ Compatibility
- **Kubernetes Version**: 1.29.x (tested on 1.29.12)
- **Trident Version**: 25.02.0
- **Container Runtime**: Docker, containerd, CRI-O
- **Architecture**: amd64, arm64

---

## 🚀 Quick Start

### Step 1: Prerequisites Check

Before beginning the installation, ensure you have:

```bash
# 1. Verify Kubernetes version
kubectl version --short

# Expected output should show v1.29.x
# Client Version: v1.29.12
# Server Version: v1.29.12

# 2. Verify cluster admin privileges
kubectl auth can-i '*' '*' --all-namespaces
# Expected output: yes

# 3. Check cluster nodes
kubectl get nodes
# Ensure all nodes are in Ready state
```

### Step 2: Download and Prepare Trident Installer

```bash
# If you don't have the installer, download it:
# wget https://github.com/NetApp/trident/releases/download/v25.02.0/trident-installer-25.02.0.tar.gz
# tar -xf trident-installer-25.02.0.tar.gz
# cd trident-installer

# Or if using this package, navigate to the installer directory:
cd /path/to/trident-installer
```

---

## 📦 Installation Methods

Choose one of the following installation methods:

### Method 1: Operator-Based Installation (Recommended)

#### Step 1: Create Trident Namespace
```bash
kubectl create namespace trident
```

#### Step 2: Install Trident CRDs and Operator
```bash
# For Kubernetes 1.25+ (including 1.29)
kubectl apply -f deploy/bundle_post_1_25.yaml

# Wait for operator to be ready
kubectl wait --for=condition=available deployment/trident-operator -n trident --timeout=120s
```

#### Step 3: Deploy TridentOrchestrator
```bash
# Apply the K8s 1.29 optimized configuration
kubectl apply -f deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml

# Monitor the deployment progress
kubectl get tridentorchestrator trident -w
```

### Method 2: Using tridentctl (Alternative)

```bash
# Make tridentctl executable
chmod +x tridentctl

# Install Trident
./tridentctl install -n trident

# Verify installation
./tridentctl -n trident version
```

---

## ✅ Verification and Testing

### Verify Installation Success

```bash
# 1. Check TridentOrchestrator status
kubectl get tridentorchestrator trident

# Expected output:
# NAME      AGE
# trident   2m

# 2. Check detailed status
kubectl describe tridentorchestrator trident | grep -A 5 "Status:"

# Expected status: Installed
# Version: v25.02.0

# 3. Verify all pods are running
kubectl get pods -n trident

# Expected output (pod names may vary):
# NAME                                  READY   STATUS    RESTARTS   AGE
# trident-controller-7c9789fc59-qrxnc   6/6     Running   0          5m
# trident-node-linux-8nmdl              2/2     Running   0          5m
# trident-node-linux-f46xl              2/2     Running   0          5m
# trident-operator-6fcd8c68b9-s46mj     1/1     Running   0          8m

# 4. Verify CSI driver registration
kubectl get csidriver

# Should include: csi.trident.netapp.io

# 5. Check Trident version
kubectl get tridentversion -n trident
```

### Test Basic Functionality

```bash
# 1. Create a test storage class
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: trident-test
provisioner: csi.trident.netapp.io
parameters:
  backendType: "ontap-nas"
allowVolumeExpansion: true
EOF

# 2. Create a test PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: trident-test
EOF

# 3. Check PVC status
kubectl get pvc test-pvc
# Status should be Bound once backend is configured
```

---

## 🔧 Configuration

### Configure Storage Backend

After successful installation, you need to configure at least one storage backend. Here are examples for common NetApp storage systems:

#### ONTAP NAS Backend
```bash
cat <<EOF | kubectl apply -f -
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata:
  name: backend-ontap-nas
spec:
  version: 1
  storageDriverName: ontap-nas
  managementLIF: "10.0.0.1"
  dataLIF: "10.0.0.2"
  svm: "trident_svm"
  username: "admin"
  password: "password"
  storagePrefix: "trident_"
EOF
```

#### ONTAP SAN Backend
```bash
cat <<EOF | kubectl apply -f -
apiVersion: trident.netapp.io/v1
kind: TridentBackendConfig
metadata:
  name: backend-ontap-san
spec:
  version: 1
  storageDriverName: ontap-san
  managementLIF: "10.0.0.1"
  dataLIF: "10.0.0.3"
  svm: "trident_svm"
  username: "admin"
  password: "password"
  igroupName: "trident"
EOF
```

### Create Storage Classes

```bash
# Basic storage class
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ontap-gold
provisioner: csi.trident.netapp.io
parameters:
  selector: "performance=gold"
  fsType: "ext4"
allowVolumeExpansion: true
reclaimPolicy: Delete
EOF

# High-performance storage class
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ontap-platinum
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: csi.trident.netapp.io
parameters:
  selector: "performance=platinum"
  fsType: "ext4"
allowVolumeExpansion: true
reclaimPolicy: Delete
EOF
```

---

## 🛠 Troubleshooting

### Common Issues and Solutions

#### 1. Pod Startup Issues
```bash
# Check pod events
kubectl describe pod <pod-name> -n trident

# Check operator logs
kubectl logs -n trident -l app=operator.trident.netapp.io

# Check controller logs
kubectl logs -n trident -l app=controller.csi.trident.netapp.io
```

#### 2. Image Pull Errors
```bash
# Verify image availability
kubectl describe pod <pod-name> -n trident

# For air-gapped environments, ensure images are mirrored
# to your private registry
```

#### 3. CSI Driver Issues
```bash
# Check CSI driver registration
kubectl get csidriver csi.trident.netapp.io -o yaml

# Check node CSI driver pods
kubectl get pods -n trident -l app=node.csi.trident.netapp.io
```

#### 4. Backend Connection Issues
```bash
# Check backend status
kubectl get tbc -n trident

# Check backend logs
kubectl logs -n trident -l app=controller.csi.trident.netapp.io | grep backend
```

### Diagnostic Commands

```bash
# Get comprehensive status
kubectl get tridentorchestrator trident -o yaml

# Check all Trident resources
kubectl get all -n trident

# View recent events
kubectl get events -n trident --sort-by='.lastTimestamp'

# Check storage classes
kubectl get storageclass

# Check backends
kubectl get tridentbackendconfig -n trident

# Using tridentctl (if available)
./tridentctl -n trident get backend
./tridentctl -n trident get volume
./tridentctl -n trident logs
```

---

## 🔒 Security Considerations

### RBAC and Permissions
The Trident operator requires specific RBAC permissions. The bundled deployment includes:
- ServiceAccount: `trident-operator`
- ClusterRole: `trident-operator`
- ClusterRoleBinding: `trident-operator`

### Network Security
- Ensure proper network connectivity between Kubernetes nodes and NetApp storage systems
- Configure appropriate firewall rules for management and data LIFs
- Use secure protocols (HTTPS/TLS) where possible

### Secrets Management
```bash
# Create secret for backend credentials
kubectl create secret generic backend-secret \
  --from-literal=username=admin \
  --from-literal=password=your-password \
  -n trident

# Reference secret in backend configuration
# credentials:
#   name: backend-secret
#   type: Opaque
```

---

## 📊 Monitoring and Maintenance

### Health Checks
```bash
# Regular health check script
#!/bin/bash
echo "=== Trident Health Check ==="
echo "TridentOrchestrator Status:"
kubectl get tridentorchestrator trident -o jsonpath='{.status.status}'
echo ""

echo "Pod Status:"
kubectl get pods -n trident --no-headers | grep -v Running | wc -l
echo " non-running pods"

echo "Backend Status:"
kubectl get tbc -n trident --no-headers | wc -l
echo " backends configured"
```

### Log Collection
```bash
# Collect all Trident logs
kubectl logs -n trident -l app=operator.trident.netapp.io > trident-operator.log
kubectl logs -n trident -l app=controller.csi.trident.netapp.io > trident-controller.log
kubectl logs -n trident -l app=node.csi.trident.netapp.io > trident-node.log
```

### Upgrades
```bash
# Upgrade process
# 1. Download new version
# 2. Update operator image
kubectl set image deployment/trident-operator trident-operator=netapp/trident-operator:25.02.0 -n trident

# 3. Update TridentOrchestrator CR
kubectl patch tridentorchestrator trident --type merge -p '{"spec":{"tridentImage":"netapp/trident:25.02.0"}}'
```

---

## 🆘 Support and Resources

### Getting Help
- **Documentation**: [NetApp Trident Documentation](https://docs.netapp.com/us-en/trident/)
- **Community**: [NetApp Community Forums](https://community.netapp.com/)
- **Issues**: [GitHub Issues](https://github.com/NetApp/trident/issues)

### Useful Commands Reference
```bash
# Quick status check
alias trident-status='kubectl get tridentorchestrator,pods -n trident'

# Check backends
alias trident-backends='kubectl get tbc -n trident'

# Check volumes
alias trident-volumes='kubectl get pv | grep trident'

# Clean up test resources
kubectl delete pvc test-pvc
kubectl delete storageclass trident-test
```

---

## 📝 Next Steps

After successful installation:

1. **Configure Storage Backends**: Set up connections to your NetApp storage systems
2. **Create Storage Classes**: Define storage tiers and policies
3. **Test Persistent Volumes**: Deploy applications with persistent storage
4. **Set up Monitoring**: Implement monitoring for storage health and performance
5. **Plan Backup Strategy**: Configure backup and disaster recovery procedures

---

**✅ Installation Complete!**

Your Trident installation is now ready. You can start using dynamic storage provisioning in your Kubernetes 1.29 cluster. 