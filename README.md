# FAIRagro UC6 Crop Simulation Modelling Workflows

> **Work in progress** — this repository is under active development. Workflows, tooling, and documentation are subject to change.

## Introduction

The repository contains computational workflows for crop simulation modelling created using the [FAIRagro Scientific Workflow Infrastructure (SciWIn)](https://github.com/fairagro/sciwin) tool.

Workflows are expressed in [CWL v1.2](https://www.commonwl.org/) and executed with [s4n](https://github.com/fairagro/sciwin), which runs each tool step inside a Docker container.

### Implemented Workflow

The full pipeline takes field observations (UAV-derived NDVI, crop calendar, and field metadata) and produces ready-to-run DSSAT crop simulation files alongside a results plot:

![CSM Workflow diagram](documentation/csm_workflow.png)

### Requirements

| Dependency | Purpose |
|---|---|
| [s4n](https://github.com/fairagro/sciwin) | CWL workflow runner |
| [Docker](https://www.docker.com/) | Container runtime used by s4n for each tool step |
| [raster2sensor](https://github.com/tum-gis/raster2sensor) | Process and manage temporal vegetation indices from UAV images using the  OGC SensorThings API standard |
| [phenocover](https://github.com/tum-gis/phenocover) | Phenology analysis and ground-cover estimation |
| [csmTools](https://github.com/fairagro/csmTools) | ETL functions for DSSAT data integration |

## Quick Start

1. Copy `config-example.yml` to `config.yml` and fill in your FROST credentials:
   ```bash
   cp config-example.yml config.yml
   ```
2. Run the full pipeline:
   ```bash
   ./run-demo.sh
   ```
   The script calls `s4n execute local ./workflows/demo/demo.cwl config.yml` and moves outputs to `outputs/`.

> **Note**: `config.yml` is gitignored — secret credentials are never committed.

## Repository Structure

```
fairagroUC6-workflows/
│
├── config-example.yml          # Template for workflow configuration (copy → config.yml)
├── run-demo.sh                 # Entry-point script: executes demo.cwl via s4n
├── workflow.toml               # Workflow metadata (name, version)
│
└── workflows/
    ├── raster2sensorTools/
    │   └── fetch-ndvi.cwl              # Download NDVI time series from FROST server
    │
    ├── phenocoverTools/
    │   └── phenology-analyzer.cwl      # Wheat phenology analysis with weather integration
    │
    ├── csmTools/                       # Individual ETL steps (all backed by csmtools-cli image)
    │   ├── get-field-data.cwl          # Extract field metadata from ICASA template
    │   ├── identify-production-season.cwl
    │   ├── get-sensor-data.cwl         # Download observations from FROST server
    │   ├── convert-sensor-data-icasa.cwl
    │   ├── get-weather-data.cwl        # Download weather from NASA POWER
    │   ├── convert-nasa-data-icasa.cwl
    │   ├── get-soil-profile.cwl        # Extract soil data from SoilGrids
    │   ├── lookup-gs-dates.cwl         # Identify growth stage dates from phenology
    │   ├── convert-gs-dates-icasa.cwl
    │   ├── assemble-icasa-dataset.cwl  # Merge all data into a single ICASA dataset
    │   ├── convert-icasa-dssat.cwl     # Convert ICASA → DSSAT file format
    │   ├── normalize-soil-profile.cwl
    │   ├── calculate-initial-layers.cwl
    │   ├── build-simulation-files.cwl  # Generate DSSAT .filex, .sol, .wth files
    │   ├── run-simulations.cwl         # Execute DSSAT crop simulations
    │   └── plot-results.cwl            # Plot simulated vs. observed growth
    │
    ├── demo/
    │   └── demo.cwl            # Top-level workflow wiring all steps above
    │
    └── csmWorkflow/
        └── csm-workflow.cwl    # Alternative / pruned workflow variant
```

