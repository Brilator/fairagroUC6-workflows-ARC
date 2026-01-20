# Setting Up csmTools Namespace for CWL Execution

## The Challenge

The CWL tools in `workflows/csmTools/` require the R package `csmTools` which is not available in standard Docker images. We need to make this package available in the execution environment.

## Solutions

### Solution 1: Custom Docker Image (Recommended)

Build a Docker image with csmTools pre-installed for fast, reliable execution.

#### Step 1: Build the Image

```bash
cd workflows/csmTools
./build_docker.sh
```

This creates a Docker image `fairagro/csmtools:latest` with:

- R 4.3
- All system dependencies (GDAL, UDUNITS, etc.)
- csmTools package from GitHub
- csmtools_cli.R script at `workflows/csmScripts/csmtools_cli.R`

#### Step 2: Update CWL Tools

Change the `dockerPull` in all CWL tools from:
```yaml
requirements:
  DockerRequirement:
    dockerPull: rocker/r-ver:4.3
```

To:
```yaml
requirements:
  DockerRequirement:
    dockerPull: fairagro/csmtools:latest
```

#### Step 3: (Optional) Push to Docker Hub

```bash
# Login to Docker Hub
docker login

# Tag for your organization
docker tag fairagro/csmtools:latest your-org/csmtools:latest

# Push
docker push your-org/csmtools:latest
```

#### Pros:
- ✅ Fast execution (no installation during runtime)
- ✅ Reproducible (same environment every time)
- ✅ Cacheable (Docker layers)
- ✅ Can be shared via Docker Hub

#### Cons:
- ❌ Requires Docker build step
- ❌ Need to rebuild when csmTools updates
- ❌ Larger initial download

---

### Solution 2: Runtime Installation

Install csmTools during workflow execution using InitialWorkDirRequirement.

#### Implementation

The tool uses a wrapper script that:
1. Installs R dependencies
2. Installs csmTools from GitHub
3. Runs the command

Example: See `convert-dataset-runtime.cwl`

```yaml
requirements:
  DockerRequirement:
    dockerPull: rocker/r-ver:4.3
  NetworkAccess:
    networkAccess: true
  InitialWorkDirRequirement:
    listing:
      - entryname: install_and_run.sh
        entry: |
          #!/bin/bash
          R -e "install.packages('remotes', repos='https://cloud.r-project.org/')"
          R -e "remotes::install_github('leroy-bml/uc6_csmTools')"
          Rscript /opt/csmtools_cli.R "$@"
```

#### Pros:
- ✅ No Docker build needed
- ✅ Always uses latest csmTools from GitHub
- ✅ Self-contained in CWL file

#### Cons:
- ❌ Slow (installs packages every run)
- ❌ Requires network access during execution
- ❌ May fail if GitHub is down
- ❌ Less reproducible (gets latest version)

---

### Solution 3: Local Package Mount (Development Only)

Mount local R library into the container.

#### Using Docker Directly

```bash
docker run -v /path/to/R/library:/usr/local/lib/R/site-library \
  -v $(pwd):/work -w /work \
  rocker/r-ver:4.3 \
  Rscript /work/csmtools_cli.R convert --input data.json
```

#### In CWL (not standard, runner-specific)

Some CWL runners support volume mounts, but this is **not portable**.

#### Pros:
- ✅ Quick for local development
- ✅ Easy to test package changes

#### Cons:
- ❌ Not portable across systems
- ❌ Not standard CWL
- ❌ Won't work on remote execution

---

## Recommended Approach

### For Production Workflows:
**Use Solution 1 (Custom Docker Image)**

1. Build image: `./workflows/csmTools/build_docker.sh`
2. Update all CWL tools to use `fairagro/csmtools:latest`
3. Push to Docker Hub for sharing
4. Rebuild when csmTools updates

### For Development/Testing:
**Use Solution 2 (Runtime Installation)**

- Slower but doesn't require Docker build
- Good for testing changes
- Use the `-runtime.cwl` versions of tools

### For Quick Local Testing:
**Use Solution 3 (Local Mount)**

- Only works on your machine
- Fast iteration during development

---

## Implementation Examples

### Update All CWL Tools to Use Custom Image

Run this to update all tools:

```bash
cd workflows/csmTools

# Update dockerPull in all CWL files
find . -name "*.cwl" -type f -exec sed -i 's/dockerPull: rocker\/r-ver:4.3/dockerPull: fairagro\/csmtools:latest/g' {} \;
```

### Test the Docker Image

```bash
# Test that csmTools is installed
docker run --rm fairagro/csmtools:latest R -e "library(csmTools); packageVersion('csmTools')"

# Test the CLI script
docker run --rm fairagro/csmtools:latest Rscript /opt/csmtools_cli.R --help

# Test a conversion (with sample data mounted)
docker run --rm -v $(pwd):/work -w /work \
  fairagro/csmtools:latest \
  Rscript /opt/csmtools_cli.R convert \
    --input test.json \
    --from user \
    --to icasa
```

---

## Environment Variables

Some csmTools functions need environment variables for API access:

### For FROST Server (sensor data)
```bash
export FROST_CLIENT_ID="your_client_id"
export FROST_CLIENT_SECRET="your_secret"
export FROST_USERNAME="your_username"
export FROST_PASSWORD="your_password"
export FROST_USER_URL="https://your-frost-server.com/frost/v1.1"
```

### Pass to Docker

```bash
docker run --rm \
  -e FROST_CLIENT_ID \
  -e FROST_CLIENT_SECRET \
  -e FROST_USERNAME \
  -e FROST_PASSWORD \
  -e FROST_USER_URL \
  fairagro/csmtools:latest \
  Rscript /opt/csmtools_cli.R get-sensor --lon 10.6 --lat 49.2 --from 2024-01-01 --to 2024-12-31
```

### In CWL (using EnvVarRequirement)

```yaml
requirements:
  EnvVarRequirement:
    envDef:
      FROST_CLIENT_ID: $(inputs.frost_client_id)
      FROST_CLIENT_SECRET: $(inputs.frost_secret)
```

---

## Troubleshooting

### Package Installation Fails
```
Error: installation of package 'csmTools' had non-zero exit status
```

**Solution**: Install system dependencies first
```dockerfile
RUN apt-get update && apt-get install -y \
    libgdal-dev \
    libudunits2-dev \
    libcurl4-openssl-dev
```

### CLI Script Not Found
```
Error: cannot open file '/opt/csmtools_cli.R': No such file
```

**Solution**: Ensure script is copied in Dockerfile
```dockerfile
COPY csmtools_cli.R /opt/csmtools_cli.R
```

### Network Access Denied
```
Error: unable to access 'https://github.com/...'
```

**Solution**: Add NetworkAccess requirement to CWL
```yaml
requirements:
  NetworkAccess:
    networkAccess: true
```

---

## Files Created

- **Dockerfile**: Defines custom Docker image with csmTools
- **build_docker.sh**: Script to build the Docker image
- **convert-dataset-runtime.cwl**: Example CWL tool with runtime installation
- **DOCKER_SETUP.md**: This documentation

## Next Steps

1. Choose your approach (custom image recommended)
2. Build Docker image if using approach 1
3. Update CWL tools to reference the image
4. Test with sample data
5. Push image to Docker Hub for team sharing
