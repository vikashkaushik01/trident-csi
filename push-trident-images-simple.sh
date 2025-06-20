#!/bin/bash

# Trident Simple Multi-Arch Mirror Script using imagetools
# This is a faster alternative using docker buildx imagetools for direct mirroring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NIRMATA_REGISTRY="ghcr.io/nirmata"

echo -e "${BLUE}🚀 Starting Trident Simple Multi-Arch Mirror Process${NC}"
echo -e "${BLUE}Target Registry: ${NIRMATA_REGISTRY}${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check if docker buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker buildx is required but not available${NC}"
    exit 1
fi

# Check login to ghcr.io
echo -e "${YELLOW}🔐 Please ensure you're logged into ghcr.io...${NC}"
echo "Run: docker login ghcr.io -u <username>"
echo ""

# All Trident images to mirror
declare -a IMAGES=(
    # NetApp Trident Core Images
    "netapp/trident-operator:25.02.0"
    "netapp/trident:25.02.0"
    "netapp/trident-autosupport:25.02"
    
    # Kubernetes CSI Sidecar Images  
    "registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0"
    "registry.k8s.io/sig-storage/csi-attacher:v4.7.0"
    "registry.k8s.io/sig-storage/csi-provisioner:v5.1.0"
    "registry.k8s.io/sig-storage/csi-resizer:v1.12.0"
    "registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0"
)

# Function to get target image name
get_target_name() {
    local source_image=$1
    local image_name
    
    # Extract image name from registry/image:tag format
    if [[ $source_image == *"/"* ]]; then
        image_name=$(basename "$source_image")
    else
        image_name="$source_image"
    fi
    
    echo "$image_name"
}

# Function to mirror single image
mirror_image() {
    local source_image=$1
    local target_name=$(get_target_name "$source_image")
    local target_image="${NIRMATA_REGISTRY}/${target_name}"
    
    echo -e "${BLUE}📦 Mirroring: ${source_image}${NC}"
    echo -e "${BLUE}   → Target: ${target_image}${NC}"
    
    # Use docker buildx imagetools to copy multi-arch image
    if docker buildx imagetools create \
        --tag "$target_image" \
        "$source_image" 2>/dev/null; then
        echo -e "${GREEN}   ✅ Successfully mirrored${NC}"
        
        # Verify architectures
        echo -e "${YELLOW}   🔍 Checking architectures...${NC}"
        local archs=$(docker buildx imagetools inspect "$target_image" 2>/dev/null | grep -E "Platform:" | sed 's/.*Platform: *//' | tr '\n' ' ' || echo "unknown")
        echo -e "${BLUE}   📱 Available platforms: ${archs}${NC}"
        
        return 0
    else
        echo -e "${RED}   ❌ Failed to mirror${NC}"
        return 1
    fi
}

# Mirror all images
echo -e "${YELLOW}🚀 Starting image mirroring...${NC}"
success_count=0
failed_images=()

for image in "${IMAGES[@]}"; do
    echo ""
    if mirror_image "$image"; then
        ((success_count++))
    else
        failed_images+=("$image")
    fi
done

# Summary
echo ""
echo -e "${BLUE}📊 Migration Summary${NC}"
echo -e "${GREEN}✅ Successfully mirrored: ${success_count}/${#IMAGES[@]} images${NC}"

if [ ${#failed_images[@]} -gt 0 ]; then
    echo -e "${RED}❌ Failed images: ${#failed_images[@]}${NC}"
    for failed in "${failed_images[@]}"; do
        echo -e "${RED}   • ${failed}${NC}"
    done
fi

echo ""
echo -e "${GREEN}🎉 Multi-arch image mirroring complete!${NC}"

# Generate the mirrored image list
echo ""
echo -e "${YELLOW}📝 Mirrored Images in ghcr.io/nirmata:${NC}"
for image in "${IMAGES[@]}"; do
    target_name=$(get_target_name "$image")
    target_full="${NIRMATA_REGISTRY}/${target_name}"
    
    if [[ ! " ${failed_images[@]} " =~ " ${image} " ]]; then
        echo "✅ ${target_full}"
    else
        echo "❌ ${target_full} (failed)"
    fi
done

echo ""
echo -e "${GREEN}🚀 Ready to use Nirmata mirrored Trident images!${NC}" 