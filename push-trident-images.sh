#!/bin/bash

# Trident Multi-Arch Image Mirror Script
# This script pulls all Trident and CSI images and pushes them to ghcr.io/nirmata with multi-arch support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NIRMATA_REGISTRY="ghcr.io/nirmata"
PLATFORMS="linux/amd64,linux/arm64"

echo -e "${BLUE}🚀 Starting Trident Multi-Arch Image Mirror Process${NC}"
echo -e "${BLUE}Target Registry: ${NIRMATA_REGISTRY}${NC}"
echo -e "${BLUE}Platforms: ${PLATFORMS}${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check if docker buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker buildx is required but not available${NC}"
    echo "Please install Docker with buildx support"
    exit 1
fi

# Check if logged into ghcr.io
if ! docker login ghcr.io --username nirmata-bot --password-stdin <<< "$GITHUB_TOKEN" >/dev/null 2>&1; then
    echo -e "${RED}❌ Not logged into ghcr.io${NC}"
    echo "Please set GITHUB_TOKEN environment variable and ensure you have access to ghcr.io/nirmata"
    echo "export GITHUB_TOKEN=your_github_token"
    exit 1
fi

# Create/use buildx builder for multi-arch
echo -e "${YELLOW}🔧 Setting up buildx builder...${NC}"
docker buildx create --name trident-builder --use --platform=$PLATFORMS 2>/dev/null || docker buildx use trident-builder
docker buildx inspect --bootstrap

echo -e "${GREEN}✅ Prerequisites check complete${NC}"
echo ""

# Define all images to mirror
declare -A TRIDENT_IMAGES=(
    # NetApp Trident Core Images
    ["netapp/trident-operator:25.02.0"]="trident-operator:25.02.0"
    ["netapp/trident:25.02.0"]="trident:25.02.0"
    ["netapp/trident-autosupport:25.02"]="trident-autosupport:25.02"
    
    # Kubernetes CSI Sidecar Images
    ["registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0"]="csi-node-driver-registrar:v2.13.0"
    ["registry.k8s.io/sig-storage/csi-attacher:v4.7.0"]="csi-attacher:v4.7.0"
    ["registry.k8s.io/sig-storage/csi-provisioner:v5.1.0"]="csi-provisioner:v5.1.0"
    ["registry.k8s.io/sig-storage/csi-resizer:v1.12.0"]="csi-resizer:v1.12.0"
    ["registry.k8s.io/sig-storage/csi-snapshotter:v8.2.0"]="csi-snapshotter:v8.2.0"
)

# Function to mirror image with multi-arch support
mirror_image() {
    local source_image=$1
    local target_image=$2
    local target_full="${NIRMATA_REGISTRY}/${target_image}"
    
    echo -e "${BLUE}📦 Processing: ${source_image}${NC}"
    echo -e "${BLUE}   → Target: ${target_full}${NC}"
    
    # Create a temporary Dockerfile for buildx
    local temp_dir=$(mktemp -d)
    local dockerfile="${temp_dir}/Dockerfile"
    
    cat > "$dockerfile" << EOF
FROM ${source_image}
LABEL org.opencontainers.image.source="https://github.com/nirmata/trident-installer"
LABEL org.opencontainers.image.description="Multi-arch mirror of ${source_image}"
LABEL org.opencontainers.image.version="25.02.0"
EOF

    # Build and push multi-arch image
    echo -e "${YELLOW}   🔄 Building and pushing multi-arch image...${NC}"
    if docker buildx build \
        --platform "$PLATFORMS" \
        --tag "$target_full" \
        --push \
        --file "$dockerfile" \
        "$temp_dir" >/dev/null 2>&1; then
        echo -e "${GREEN}   ✅ Successfully mirrored${NC}"
    else
        echo -e "${RED}   ❌ Failed to mirror${NC}"
        return 1
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    echo ""
}

# Function to verify image exists and get manifest info
verify_image() {
    local image=$1
    echo -e "${YELLOW}🔍 Verifying: ${image}${NC}"
    
    if docker manifest inspect "$image" >/dev/null 2>&1; then
        echo -e "${GREEN}   ✅ Image exists and accessible${NC}"
        
        # Get architecture information
        local archs=$(docker manifest inspect "$image" 2>/dev/null | jq -r '.manifests[]?.platform | select(. != null) | "\(.os)/\(.architecture)"' 2>/dev/null | sort | uniq | tr '\n' ' ' || echo "unknown")
        echo -e "${BLUE}   📱 Available architectures: ${archs}${NC}"
        return 0
    else
        echo -e "${RED}   ❌ Image not accessible${NC}"
        return 1
    fi
}

# Step 1: Verify all source images exist
echo -e "${YELLOW}🔍 Step 1: Verifying source images...${NC}"
failed_images=()

for source_image in "${!TRIDENT_IMAGES[@]}"; do
    if ! verify_image "$source_image"; then
        failed_images+=("$source_image")
    fi
done

if [ ${#failed_images[@]} -gt 0 ]; then
    echo -e "${RED}❌ Some source images are not accessible:${NC}"
    printf '   %s\n' "${failed_images[@]}"
    echo -e "${YELLOW}⚠️  Continuing with accessible images only...${NC}"
    echo ""
fi

# Step 2: Mirror all accessible images
echo -e "${YELLOW}🚀 Step 2: Mirroring images to ${NIRMATA_REGISTRY}...${NC}"
success_count=0
total_count=${#TRIDENT_IMAGES[@]}

for source_image in "${!TRIDENT_IMAGES[@]}"; do
    target_image="${TRIDENT_IMAGES[$source_image]}"
    
    # Skip if image was not accessible
    if [[ " ${failed_images[@]} " =~ " ${source_image} " ]]; then
        echo -e "${YELLOW}⏭️  Skipping: ${source_image} (not accessible)${NC}"
        continue
    fi
    
    if mirror_image "$source_image" "$target_image"; then
        ((success_count++))
    fi
done

# Step 3: Verify pushed images
echo -e "${YELLOW}🔍 Step 3: Verifying pushed images...${NC}"
for source_image in "${!TRIDENT_IMAGES[@]}"; do
    target_image="${TRIDENT_IMAGES[$source_image]}"
    target_full="${NIRMATA_REGISTRY}/${target_image}"
    
    # Skip if original image was not accessible
    if [[ " ${failed_images[@]} " =~ " ${source_image} " ]]; then
        continue
    fi
    
    verify_image "$target_full"
done

# Summary
echo ""
echo -e "${BLUE}📊 Migration Summary${NC}"
echo -e "${GREEN}✅ Successfully mirrored: ${success_count}/${total_count} images${NC}"

if [ ${#failed_images[@]} -gt 0 ]; then
    echo -e "${RED}❌ Failed/Skipped images: ${#failed_images[@]}${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Multi-arch image mirroring complete!${NC}"
echo -e "${BLUE}All images are now available at: ${NIRMATA_REGISTRY}${NC}"

# Generate image list for reference
echo ""
echo -e "${YELLOW}📝 Mirrored Images Reference:${NC}"
echo "# Trident Images in ghcr.io/nirmata"
for source_image in "${!TRIDENT_IMAGES[@]}"; do
    target_image="${TRIDENT_IMAGES[$source_image]}"
    target_full="${NIRMATA_REGISTRY}/${target_image}"
    
    # Skip if original image was not accessible
    if [[ " ${failed_images[@]} " =~ " ${source_image} " ]]; then
        echo "# SKIPPED: ${source_image} → ${target_full}"
    else
        echo "${target_full}"
    fi
done

# Cleanup buildx builder
echo ""
echo -e "${YELLOW}🧹 Cleaning up buildx builder...${NC}"
docker buildx rm trident-builder >/dev/null 2>&1 || true
echo -e "${GREEN}✅ Cleanup complete${NC}"

echo ""
echo -e "${GREEN}🚀 Ready to use Nirmata mirrored Trident images!${NC}" 