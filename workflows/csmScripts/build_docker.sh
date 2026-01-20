#!/bin/bash
# Quick setup script for csmTools namespace

echo "=========================================="
echo "csmTools CWL Setup"
echo "=========================================="
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

echo "✓ Docker is installed"
echo ""
echo "Building custom Docker image..."
cd "$(dirname "$0")"

# Check if csmtools_cli.R exists
if [ ! -f "csmtools_cli.R" ]; then
    echo "❌ csmtools_cli.R not found at csmtools_cli.R"
    exit 1
fi

# Build image
docker build -t fairagro/csmtools:latest .

echo ""
echo "✓ Docker image built: fairagro/csmtools:latest"
echo ""
echo "Next steps:"
echo "  1. Test the image:"
echo "     docker run --rm fairagro/csmtools:latest Rscript /uc6_csmTools/csmtools_cli.R --help"
echo ""
echo "  2. Update CWL tools to use fairagro/csmtools:latest"
echo "     See DOCKER_SETUP.md for details"
echo ""
echo "  3. (Optional) Push to Docker Hub:"
echo "     docker push fairagro/csmtools:latest"
