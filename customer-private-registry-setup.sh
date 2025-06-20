#!/bin/bash

# Customer Private Registry Setup Script
# This script pulls all Trident images from ghcr.io/nirmata and pushes them to your private registry

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values - Customer should modify these
NIRMATA_REGISTRY="ghcr.io/nirmata"
CUSTOMER_REGISTRY="${CUSTOMER_REGISTRY:-your-private-registry.com/trident}"

echo -e "${BLUE}🏢 Trident Customer Private Registry Setup${NC}"
echo -e "${BLUE}Source Registry: ${NIRMATA_REGISTRY}${NC}"
echo -e "${BLUE}Target Registry: ${CUSTOMER_REGISTRY}${NC}"
echo ""

# Validate required environment variables
if [[ "$CUSTOMER_REGISTRY" == "your-private-registry.com/trident" ]]; then
    echo -e "${RED}❌ Please set CUSTOMER_REGISTRY environment variable${NC}"
    echo "Example: export CUSTOMER_REGISTRY=harbor.company.com/trident"
    echo "Or modify this script to set your registry URL"
    exit 1
fi

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check if Docker is available
if ! docker --version >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is required but not available${NC}"
    exit 1
fi

# Check if Docker buildx is available (for multi-arch support)
if ! docker buildx version >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker buildx not available - will use regular docker commands${NC}"
    USE_BUILDX=false
else
    USE_BUILDX=true
fi

echo -e "${GREEN}✅ Prerequisites check complete${NC}"
echo ""

# All Trident images to mirror
declare -a IMAGES=(
    "trident-operator:25.02.0"
    "trident:25.02.0"
    "trident-autosupport:25.02"
    "csi-node-driver-registrar:v2.13.0"
    "csi-attacher:v4.7.0"
    "csi-provisioner:v5.1.0"
    "csi-resizer:v1.12.0"
    "csi-snapshotter:v8.2.0"
)

# Function to mirror image with multi-arch support
mirror_image() {
    local image_name=$1
    local source_image="${NIRMATA_REGISTRY}/${image_name}"
    local target_image="${CUSTOMER_REGISTRY}/${image_name}"
    
    echo -e "${BLUE}📦 Processing: ${image_name}${NC}"
    echo -e "${BLUE}   Source: ${source_image}${NC}"
    echo -e "${BLUE}   Target: ${target_image}${NC}"
    
    if [[ "$USE_BUILDX" == true ]]; then
        # Use buildx imagetools for multi-arch support
        echo -e "${YELLOW}   🔄 Using buildx imagetools (multi-arch)...${NC}"
        if docker buildx imagetools create \
            --tag "$target_image" \
            "$source_image" 2>/dev/null; then
            echo -e "${GREEN}   ✅ Successfully mirrored with multi-arch support${NC}"
            
            # Show available architectures
            local archs=$(docker buildx imagetools inspect "$target_image" 2>/dev/null | grep -E "Platform:" | sed 's/.*Platform: *//' | tr '\n' ' ' || echo "unknown")
            echo -e "${BLUE}   📱 Available platforms: ${archs}${NC}"
            
            return 0
        else
            echo -e "${RED}   ❌ Failed with buildx, trying regular docker...${NC}"
        fi
    fi
    
    # Fallback to regular docker pull/tag/push
    echo -e "${YELLOW}   🔄 Using regular docker commands...${NC}"
    
    # Pull from source
    if docker pull "$source_image" >/dev/null 2>&1; then
        echo -e "${GREEN}   ✅ Pulled from source${NC}"
    else
        echo -e "${RED}   ❌ Failed to pull from source${NC}"
        return 1
    fi
    
    # Tag for target
    if docker tag "$source_image" "$target_image" >/dev/null 2>&1; then
        echo -e "${GREEN}   ✅ Tagged for target${NC}"
    else
        echo -e "${RED}   ❌ Failed to tag${NC}"
        return 1
    fi
    
    # Push to target
    if docker push "$target_image" >/dev/null 2>&1; then
        echo -e "${GREEN}   ✅ Pushed to target registry${NC}"
        return 0
    else
        echo -e "${RED}   ❌ Failed to push to target${NC}"
        return 1
    fi
}

# Check registry access
echo -e "${YELLOW}🔐 Checking registry access...${NC}"

# Check if we can access the source registry
echo -e "${YELLOW}   Checking access to ${NIRMATA_REGISTRY}...${NC}"
if docker pull "${NIRMATA_REGISTRY}/trident-operator:25.02.0" >/dev/null 2>&1; then
    echo -e "${GREEN}   ✅ Can access source registry${NC}"
    docker rmi "${NIRMATA_REGISTRY}/trident-operator:25.02.0" >/dev/null 2>&1 || true
else
    echo -e "${RED}   ❌ Cannot access source registry${NC}"
    echo "   Please ensure you have access to ghcr.io/nirmata"
    echo "   You may need to: docker login ghcr.io"
    exit 1
fi

# Check if we can push to target registry
echo -e "${YELLOW}   Checking access to ${CUSTOMER_REGISTRY}...${NC}"
echo "   Please ensure you're logged into your private registry"
echo "   Example: docker login your-registry.com"
echo ""

# Mirror all images
echo -e "${YELLOW}🚀 Starting image mirroring to private registry...${NC}"
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
echo -e "${GREEN}🎉 Private registry setup complete!${NC}"

# Generate the final image list for customer reference
echo ""
echo -e "${YELLOW}📝 Images now available in your private registry:${NC}"
for image in "${IMAGES[@]}"; do
    target_image="${CUSTOMER_REGISTRY}/${image}"
    
    if [[ ! " ${failed_images[@]} " =~ " ${image} " ]]; then
        echo "✅ ${target_image}"
    else
        echo "❌ ${target_image} (failed)"
    fi
done

# Generate deployment file updates
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Update your Trident deployment files to use these images"
echo "2. See CUSTOMER_REGISTRY_DEPLOYMENT_GUIDE.md for detailed instructions"
echo "3. Deploy Trident using your private registry images"

echo ""
echo -e "${GREEN}🚀 Ready to deploy Trident with your private registry!${NC}" 