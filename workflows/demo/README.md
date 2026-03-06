# FAIRagro UC6 Workflows - Demo Workflow

## Workflow Description
This workflow demonstrates agricultural data analysis by:
1. Fetching NDVI (Normalized Difference Vegetation Index) timeseries data
2. Analyzing wheat phenology with weather integration
3. Generating visualizations and results

## Quick Start

### Execute the workflow
```bash
s4n execute local ./workflows/demo/demo.cwl
```

### Organize outputs (optional)
After workflow completion, organize output files into the `data/` directory:
```bash
./organize_outputs.sh
```

## Workflow Outputs

The workflow produces three output files:

1. **ndvi_timeseries.csv** - NDVI observation data from the sensor network
2. **phenology_results.csv** - Detailed phenology analysis with weather data
3. **phenology_analysis.png** - Visualization of phenology stages and NDVI trends

## File Organization

### Default (after execution)
Files are output to the workspace root:
```
fairagroUC6-workflows/
├── ndvi_timeseries.csv
├── phenology_results.csv
└── phenology_analysis.png
```

### Organized (after running organize_outputs.sh)
Files are moved to the data/ directory:
```
fairagroUC6-workflows/
└── data/
    ├── field_location.geojson (input)
    ├── ndvi_timeseries.csv
    ├── phenology_results.csv
    └── phenology_analysis.png
```

## Workflow Steps

### Step 1: fetch-ndvi
Fetches NDVI data from a SensorThings API for a specific trial.

**Tool:** `workflows/raster2sensorTools/fetch-ndvi.cwl`
**Command:** `raster2sensor plots fetch-ndvi`
**Default inputs:**
- Trial ID: `Goetheweg-2024`
- API URL: `https://tuzehez-fairagro.srv.mwn.de/frost/v1.1`

### Step 2: phenology-analyzer  
Analyzes wheat phenology using NDVI data and field location.

**Tool:** `workflows/phenocoverTools/phenology-analyzer.cwl`
**Command:** `phenocover phenology-analyzer`
**Inputs:**
- NDVI timeseries (from step 1)
- Field location GeoJSON
- Sowing date: `03.10.2023`
- Harvest date: `30.07.2024`

**Features:**
- Weather-enhanced analysis using Open-Meteo API
- Growing Degree Days (GDD) calculation
- Growth stage estimation
- Ground cover percentage
- Agricultural stress indices

## Technical Details

### CWL File Path Handling
The workflow uses `InitialWorkDirRequirement` in the phenology-analyzer tool to stage input files:

```yaml
requirements:
  InitialWorkDirRequirement:
    listing:
      - $(inputs.geojson_file)
      - $(inputs.ndvi_file)
```

This allows commands to reference files by basename:
```yaml
--ndvi-file "$(inputs.ndvi_file.basename)"
--geojson-file "$(inputs.geojson_file.basename)"
```

### Why outputs are not in data/ during execution
CWL runners handle subdirectory outputs differently. To ensure portability:
- **During execution**: Files are output to the root of the working directory
- **After execution**: Use `organize_outputs.sh` to move files to `data/`

See [DEBUGGING_NOTES.md](DEBUGGING_NOTES.md) for detailed explanation.

## Troubleshooting

### Error: File not found
If you see errors about missing files, check that:
1. Input files exist in `data/` directory
2. The workflow has network access (for API calls)

### Error: No such file or directory (data/)
This error occurs when trying to output directly to `data/` subdirectory. Solution:
1. Use the current implementation (outputs to root)
2. Run `organize_outputs.sh` after workflow completion

## References
- [SciWIn Client Examples](https://github.com/fairagro/m4.4_sciwin_client_examples)
- [CWL Specification](https://www.commonwl.org/v1.2/)
- [InitialWorkDirRequirement Documentation](https://www.commonwl.org/v1.2/CommandLineTool.html#InitialWorkDirRequirement)
