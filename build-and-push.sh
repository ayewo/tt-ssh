#!/bin/bash

set -e

# Configuration
GHCR_USERNAME="${GHCR_USERNAME:-your-github-username}"
IMAGE_NAME="${IMAGE_NAME:-tt-metal-custom}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
FULL_IMAGE_NAME="ghcr.io/${GHCR_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== TT-Metal Docker Build and Push Script ===${NC}\n"

# Check if running as root or with sudo
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}Warning: Running as root${NC}"
fi

# Check if /root/tt/tt-metal exists
if [ ! -d "/root/tt/tt-metal" ]; then
    echo -e "${RED}Error: /root/tt/tt-metal directory not found!${NC}"
    echo "Please ensure the tt-metal directory exists at /root/tt/tt-metal"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found /root/tt/tt-metal directory"

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}Error: Dockerfile not found in current directory!${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found Dockerfile"

# Check if start.sh exists
if [ ! -f "start.sh" ]; then
    echo -e "${YELLOW}Warning: start.sh not found. Creating a dummy start.sh${NC}"
    cat > start.sh << 'EOF'
#!/bin/bash
echo "Container started"
exec "$@"
EOF
    chmod +x start.sh
fi

echo -e "${GREEN}✓${NC} Found start.sh"

# Create build context directory
BUILD_DIR="./build-context"
echo -e "\n${YELLOW}Creating build context...${NC}"

if [ -d "$BUILD_DIR" ]; then
    echo "Removing existing build context..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"

# Copy tt-metal directory to build context
echo -e "${YELLOW}Copying /root/tt/tt-metal to build context (8GB+, this will take a while)...${NC}"
echo "Start time: $(date)"

# Use rsync if available for progress, otherwise cp
if command -v rsync &> /dev/null; then
    echo "Using rsync for faster copy with progress..."
    rsync -ah --info=progress2 /root/tt/tt-metal "$BUILD_DIR/"
else
    echo "Using cp (this may take several minutes without progress indicator)..."
    cp -r /root/tt/tt-metal "$BUILD_DIR/"
fi

echo "End time: $(date)"

# Copy Dockerfile and start.sh to build context
cp Dockerfile "$BUILD_DIR/"
cp start.sh "$BUILD_DIR/"

# Copy .dockerignore if it exists
if [ -f ".dockerignore" ]; then
    cp .dockerignore "$BUILD_DIR/"
    echo -e "${GREEN}✓${NC} Using .dockerignore to reduce build context"
fi

echo -e "${GREEN}✓${NC} Build context created"

# Show size of build context
BUILD_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
echo -e "Build context size: ${YELLOW}${BUILD_SIZE}${NC}"

# Check if logged in to GHCR
echo -e "\n${YELLOW}Checking GHCR authentication...${NC}"
if ! docker info 2>/dev/null | grep -q "ghcr.io"; then
    echo -e "${YELLOW}You may need to login to GHCR. Use:${NC}"
    echo -e "  echo \$GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin"
    echo -e "\n${YELLOW}Or set your PAT as an environment variable and we'll login now.${NC}"
    
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "Logging in to GHCR..."
        echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin
        echo -e "${GREEN}✓${NC} Logged in to GHCR"
    else
        echo -e "${RED}GITHUB_TOKEN not set. Please login manually or set GITHUB_TOKEN.${NC}"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Build the image
echo -e "\n${GREEN}Building Docker image: ${FULL_IMAGE_NAME}${NC}"
echo -e "${YELLOW}Note: With 8GB+ of data, this build will take significant time${NC}"
echo "Build start time: $(date)"
echo ""

cd "$BUILD_DIR"

# Use BuildKit for better performance
export DOCKER_BUILDKIT=1

docker build \
    --progress=plain \
    -t "$FULL_IMAGE_NAME" \
    .

BUILD_STATUS=$?
cd ..

echo ""
echo "Build end time: $(date)"

if [ $BUILD_STATUS -ne 0 ]; then
    echo -e "${RED}Error: Docker build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker image built successfully"

# Push to GHCR
echo -e "\n${GREEN}Pushing image to GHCR...${NC}"
docker push "$FULL_IMAGE_NAME"
PUSH_STATUS=$?

if [ $PUSH_STATUS -ne 0 ]; then
    echo -e "${RED}Error: Failed to push image to GHCR!${NC}"
    echo "Make sure you have proper permissions and are authenticated."
    exit 1
fi

echo -e "${GREEN}✓${NC} Image pushed successfully"

# Cleanup
echo -e "\n${YELLOW}Cleaning up build context...${NC}"
rm -rf "$BUILD_DIR"
echo -e "${GREEN}✓${NC} Cleanup complete"

# Summary
echo -e "\n${GREEN}=== Build Complete ===${NC}"
echo -e "Image: ${GREEN}${FULL_IMAGE_NAME}${NC}"
echo -e "\nTo pull and run this image:"
echo -e "  docker pull ${FULL_IMAGE_NAME}"
echo -e "  docker run -it ${FULL_IMAGE_NAME}"
echo -e "\nTo make the image public, go to:"
echo -e "  https://github.com/${GHCR_USERNAME}?tab=packages"
