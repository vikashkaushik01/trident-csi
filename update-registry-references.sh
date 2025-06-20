#!/bin/bash
# update-registry-references.sh
# Automatically updates all deployment files to use customer's private registry

set -e

CUSTOMER_REGISTRY="${1:-your-registry.company.com/trident}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Updating Trident Deployment Files${NC}"
echo -e "${BLUE}Target Registry: ${CUSTOMER_REGISTRY}${NC}"
echo ""

# Validate registry parameter
if [[ "$CUSTOMER_REGISTRY" == "your-registry.company.com/trident" ]]; then
    echo -e "${RED}❌ Please provide your registry URL as parameter${NC}"
    echo "Usage: $0 your-registry.company.com/trident"
    echo ""
    echo "Examples:"
    echo "  $0 harbor.company.com/trident"
    echo "  $0 nexus.company.com:8082/trident"
    echo "  $0 123456789012.dkr.ecr.us-east-1.amazonaws.com/trident"
    exit 1
fi

echo -e "${YELLOW}📋 Updating deployment files...${NC}"

# Backup and update bundle file
echo -e "${BLUE}📦 Updating bundle_post_1_25.yaml...${NC}"
if [ -f "deploy/bundle_post_1_25.yaml" ]; then
    cp deploy/bundle_post_1_25.yaml deploy/bundle_post_1_25.yaml.bak
    sed -i.tmp "s|netapp/trident-operator:25.02.0|$CUSTOMER_REGISTRY/trident-operator:25.02.0|g" deploy/bundle_post_1_25.yaml
    rm -f deploy/bundle_post_1_25.yaml.tmp
    echo -e "${GREEN}   ✅ Updated bundle file${NC}"
else
    echo -e "${YELLOW}   ⚠️  Bundle file not found${NC}"
fi

# Backup and update standalone operator
echo -e "${BLUE}📦 Updating operator.yaml...${NC}"
if [ -f "deploy/operator.yaml" ]; then
    cp deploy/operator.yaml deploy/operator.yaml.bak
    sed -i.tmp "s|netapp/trident-operator:25.02.0|$CUSTOMER_REGISTRY/trident-operator:25.02.0|g" deploy/operator.yaml
    rm -f deploy/operator.yaml.tmp
    echo -e "${GREEN}   ✅ Updated operator file${NC}"
else
    echo -e "${YELLOW}   ⚠️  Operator file not found${NC}"
fi

# Update TridentOrchestrator CR files
echo -e "${BLUE}📦 Updating TridentOrchestrator CR files...${NC}"

# K8s 1.29 optimized file
if [ -f "deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml" ]; then
    cp deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml.bak
    
    # Update all image references
    sed -i.tmp "s|netapp/trident:25.02.0|$CUSTOMER_REGISTRY/trident:25.02.0|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
    sed -i.tmp "s|netapp/trident-autosupport:25.02|$CUSTOMER_REGISTRY/trident-autosupport:25.02|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
    sed -i.tmp "s|registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0|$CUSTOMER_REGISTRY/csi-node-driver-registrar:v2.13.0|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
    sed -i.tmp "s|registry.k8s.io/sig-storage/csi-attacher:v4.7.0|$CUSTOMER_REGISTRY/csi-attacher:v4.7.0|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
    sed -i.tmp "s|registry.k8s.io/sig-storage/csi-provisioner:v5.1.0|$CUSTOMER_REGISTRY/csi-provisioner:v5.1.0|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
    sed -i.tmp "s|registry.k8s.io/sig-storage/csi-resizer:v1.12.0|$CUSTOMER_REGISTRY/csi-resizer:v1.12.0|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
    sed -i.tmp "s|registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0|$CUSTOMER_REGISTRY/csi-snapshotter:v8.2.0|g" deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml
    
    rm -f deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml.tmp
    echo -e "${GREEN}   ✅ Updated K8s 1.29 CR file${NC}"
else
    echo -e "${YELLOW}   ⚠️  K8s 1.29 CR file not found${NC}"
fi

# Default CR file
if [ -f "deploy/crds/tridentorchestrator_cr.yaml" ]; then
    cp deploy/crds/tridentorchestrator_cr.yaml deploy/crds/tridentorchestrator_cr.yaml.bak
    
    sed -i.tmp "s|ghcr.io/nirmata/trident:25.02.0|$CUSTOMER_REGISTRY/trident:25.02.0|g" deploy/crds/tridentorchestrator_cr.yaml
    sed -i.tmp "s|ghcr.io/nirmata/trident-autosupport:25.02|$CUSTOMER_REGISTRY/trident-autosupport:25.02|g" deploy/crds/tridentorchestrator_cr.yaml
    sed -i.tmp "s|registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0|$CUSTOMER_REGISTRY/csi-node-driver-registrar:v2.13.0|g" deploy/crds/tridentorchestrator_cr.yaml
    sed -i.tmp "s|registry.k8s.io/sig-storage/csi-attacher:v4.7.0|$CUSTOMER_REGISTRY/csi-attacher:v4.7.0|g" deploy/crds/tridentorchestrator_cr.yaml
    sed -i.tmp "s|registry.k8s.io/sig-storage/csi-provisioner:v5.1.0|$CUSTOMER_REGISTRY/csi-provisioner:v5.1.0|g" deploy/crds/tridentorchestrator_cr.yaml
    sed -i.tmp "s|registry.k8s.io/sig-storage/csi-resizer:v1.12.0|$CUSTOMER_REGISTRY/csi-resizer:v1.12.0|g" deploy/crds/tridentorchestrator_cr.yaml
    sed -i.tmp "s|registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0|$CUSTOMER_REGISTRY/csi-snapshotter:v8.2.0|g" deploy/crds/tridentorchestrator_cr.yaml
    
    rm -f deploy/crds/tridentorchestrator_cr.yaml.tmp
    echo -e "${GREEN}   ✅ Updated default CR file${NC}"
else
    echo -e "${YELLOW}   ⚠️  Default CR file not found${NC}"
fi

# Update other optional CR files
echo -e "${BLUE}📦 Updating optional CR files...${NC}"

# Custom image CR
if [ -f "deploy/crds/tridentorchestrator_cr_customimage.yaml" ]; then
    cp deploy/crds/tridentorchestrator_cr_customimage.yaml deploy/crds/tridentorchestrator_cr_customimage.yaml.bak
    sed -i.tmp "s|localhost:5000/netapp/trident:25.02|$CUSTOMER_REGISTRY/trident:25.02.0|g" deploy/crds/tridentorchestrator_cr_customimage.yaml
    rm -f deploy/crds/tridentorchestrator_cr_customimage.yaml.tmp
    echo -e "${GREEN}   ✅ Updated custom image CR file${NC}"
fi

# Image pull secrets CR
if [ -f "deploy/crds/tridentorchestrator_cr_imagepullsecrets.yaml" ]; then
    cp deploy/crds/tridentorchestrator_cr_imagepullsecrets.yaml deploy/crds/tridentorchestrator_cr_imagepullsecrets.yaml.bak
    sed -i.tmp "s|netapp/trident:25.02.0|$CUSTOMER_REGISTRY/trident:25.02.0|g" deploy/crds/tridentorchestrator_cr_imagepullsecrets.yaml
    rm -f deploy/crds/tridentorchestrator_cr_imagepullsecrets.yaml.tmp
    echo -e "${GREEN}   ✅ Updated image pull secrets CR file${NC}"
fi

# Autosupport CR
if [ -f "deploy/crds/tridentorchestrator_cr_autosupport.yaml" ]; then
    cp deploy/crds/tridentorchestrator_cr_autosupport.yaml deploy/crds/tridentorchestrator_cr_autosupport.yaml.bak
    sed -i.tmp "s|netapp/trident-autosupport:25.02|$CUSTOMER_REGISTRY/trident-autosupport:25.02|g" deploy/crds/tridentorchestrator_cr_autosupport.yaml
    rm -f deploy/crds/tridentorchestrator_cr_autosupport.yaml.tmp
    echo -e "${GREEN}   ✅ Updated autosupport CR file${NC}"
fi

echo ""
echo -e "${GREEN}🎉 All deployment files updated successfully!${NC}"

echo ""
echo -e "${YELLOW}📝 Summary:${NC}"
echo -e "${BLUE}Registry: ${CUSTOMER_REGISTRY}${NC}"
echo -e "${BLUE}Backup files created with .bak extension${NC}"

echo ""
echo -e "${YELLOW}📋 Updated Images:${NC}"
echo "✅ $CUSTOMER_REGISTRY/trident-operator:25.02.0"
echo "✅ $CUSTOMER_REGISTRY/trident:25.02.0"
echo "✅ $CUSTOMER_REGISTRY/trident-autosupport:25.02"
echo "✅ $CUSTOMER_REGISTRY/csi-node-driver-registrar:v2.13.0"
echo "✅ $CUSTOMER_REGISTRY/csi-attacher:v4.7.0"
echo "✅ $CUSTOMER_REGISTRY/csi-provisioner:v5.1.0"
echo "✅ $CUSTOMER_REGISTRY/csi-resizer:v1.12.0"
echo "✅ $CUSTOMER_REGISTRY/csi-snapshotter:v8.2.0"

echo ""
echo -e "${GREEN}🚀 Ready to deploy Trident with your private registry!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Ensure all images are available in your registry"
echo "2. Deploy using: kubectl apply -f deploy/bundle_post_1_25.yaml"
echo "3. Create TridentOrchestrator: kubectl apply -f deploy/crds/tridentorchestrator_cr_k8s_1_29.yaml" 