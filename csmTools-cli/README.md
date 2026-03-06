# csmTools Command-Line Interface

A command-line interface for the [csmTools](https://github.com/fairagro/csmTools) package that allows you to run crop modeling workflows from the terminal. Each CLI command maps directly to its R function counterpart (e.g., `get-field-data` → `get_field_data()`).

## Installation

Install the required dependency:

```R
install.packages("argparse")
```

Make the CLI executable (Linux/macOS):

```bash
chmod +x csmtools_cli.R
```

## Usage

The CLI is organized into subcommands, one per workflow step:

### Workflow Steps

| # | Command | R function | Description |
|---|---------|-----------|-------------|
| 1 | `get-field-data` | `get_field_data()` | Extract field data from ICASA template |
| 2 | `identify-production-season` | `identify_production_season()` | Determine cultivation season date bounds |
| 3 | `get-sensor-data` | `get_sensor_data()` | Download IoT sensor data (FROST server) |
| 4 | `get-weather-data` | `get_weather_data()` | Download weather data (NASA POWER) |
| 5 | `get-soil-profile` | `get_soil_profile()` | Extract soil profile (SoilGrids) |
| 6 | `lookup-gs-dates` | `lookup_gs_dates()` | Look up growth stage dates from phenology data |
| 7 | `assemble-dataset` | `assemble_dataset()` | Combine data components into one dataset |
| 8 | `convert-dataset` | `convert_dataset()` | Convert between formats (user/NASA/ICASA/DSSAT) |
| 9 | `normalize-soil-profile` | `normalize_soil_profile()` | Interpolate soil profile to standard depth sequence |
| 10 | `calculate-initial-layers` | `calculate_initial_layers()` | Calculate initial soil water and N conditions |
| 11 | `build-simulation-files` | `build_simulation_files()` | Generate DSSAT input files |
| 12 | `run-simulations` | `run_simulations()` | Run DSSAT crop simulation |
| 13 | `plot-results` | `ggplot2` | Plot simulated growth vs. observed harvest data |

---

### 1. Get Field Data

Extract crop management and experimental metadata from an ICASA template:

```bash
Rscript csmtools_cli.R get-field-data \
  --path inst/extdata/template_icasa_vba.xlsm \
  --exp-id HWOC2501 \
  --output archive/field_data.json
```

### 2. Identify Production Season

Determine the cultivation season date bounds directly from an ICASA template:

```bash
Rscript csmtools_cli.R identify-production-season \
  --path inst/extdata/template_icasa_vba.xlsm \
  --exp-id HWOC2501 \
  --period cultivation_season \
  --output-format bounds
```

### 3. Download Sensor Data

Get IoT weather sensor data from a FROST server (requires credentials in `.Renviron`):

```bash
Rscript csmtools_cli.R get-sensor-data \
  --lon 10.645269 \
  --lat 49.20868 \
  --from 2024-01-01 \
  --to 2025-12-31 \
  --radius 10 \
  --vars "air_temperature,solar_radiation,volume_of_hydrological_precipitation" \
  --output archive/sensor_data.json
```

### 4. Download Weather Data

Get complementary weather data from NASA POWER:

```bash
Rscript csmtools_cli.R get-weather-data \
  --lon 10.645269 \
  --lat 49.20868 \
  --from 2024-01-01 \
  --to 2025-12-31 \
  --output archive/weather_nasa.json
```

### 5. Get Soil Profile

Extract and download the nearest soil profile from SoilGrids:

```bash
Rscript csmtools_cli.R get-soil-profile \
  --lon 10.645269 \
  --lat 49.20868 \
  --output archive/soil_data.json
```

### 6. Look Up Growth Stage Dates

Extract representative dates for specific growth stages from a phenology CSV:

```bash
Rscript csmtools_cli.R lookup-gs-dates \
  --input archive/wheat_phenology_results.csv \
  --gs-scale zadok \
  --gs-codes 10,65,87 \
  --date-select-rule median \
  --output archive/gs_dates.json
```

### 7. Assemble Dataset

Merge multiple data components into a single dataset:

```bash
Rscript csmtools_cli.R assemble-dataset \
  --components archive/field_data.json archive/weather_combined.json archive/soil_data.json \
  --output archive/icasa_dataset.json \
  --action merge_properties
```

### 8. Convert Dataset Format

Convert between input formats (`user`, `nasa-power`, `bonares`, `icasa`) and output formats (`icasa`, `dssat`):

```bash
Rscript csmtools_cli.R convert-dataset \
  --input archive/icasa_dataset.json \
  --from icasa \
  --to dssat \
  --output archive/dssat_dataset.json
```

### 9. Normalize Soil Profile

Interpolate a soil profile to a standard depth sequence:

```bash
Rscript csmtools_cli.R normalize-soil-profile \
  --input archive/dssat_dataset.json \
  --depth-seq "5,10,20,30,40,50,60,70,90,110,130,150,170,190,210" \
  --method linear \
  --output archive/soil_normalized.json
```

### 10. Calculate Initial Layers

Compute initial soil water and nitrogen conditions per depth layer:

```bash
Rscript csmtools_cli.R calculate-initial-layers \
  --input archive/dssat_dataset.json \
  --paw 100 \
  --total-n 50 \
  --output archive/initial_layers.json
```

### 11. Build Simulation Files

Generate all DSSAT input files (experiment, weather, soil) from the assembled dataset:

```bash
Rscript csmtools_cli.R build-simulation-files \
  --input archive/dssat_dataset.json \
  --write-dssat-dir
```

### 12. Run Simulations

Run DSSAT crop simulations for selected treatments:

```bash
Rscript csmtools_cli.R run-simulations \
  --filex ~/dssat/Wheat/HWOC2501.WHX \
  --treatments 1,3,7 \
  --dssat-dir ~/dssat \
  --output-dir ./simulations
```

### 13. Plot Results

Plot simulated crop growth (PlantGro.OUT) against observed harvest data (Summary.OUT). Reads DSSAT output files from `--dssat-dir` and saves a PNG/PDF/SVG via ggplot2:

```bash
Rscript csmtools_cli.R plot-results \
  --dssat-dir ~/dssat \
  --treatments 1,3,7 \
  --output simulations/growth_plot.png
```

Optional size/resolution flags:

```bash
Rscript csmtools_cli.R plot-results \
  --dssat-dir ~/dssat \
  --treatments 1,3,7 \
  --output simulations/growth_plot.pdf \
  --width 12 --height 7 --dpi 300
```

---

## Complete Workflow Example

Full end-to-end workflow for the Ochsenwäsen wheat experiment (HWOC2501):

```bash
#!/bin/bash
# Complete csmTools CLI workflow — Ochsenwäsen wheat experiment

export WORKDIR="archive"
export LON=10.645269
export LAT=49.20868
export FROM=2024-01-01
export TO=2025-12-31
export EXP_ID=HWOC2501

mkdir -p $WORKDIR simulations

# Step 1: Extract field/management data from template
Rscript csmtools_cli.R get-field-data \
  --path inst/extdata/template_icasa_vba.xlsm \
  --exp-id $EXP_ID \
  --output $WORKDIR/field.json

# Step 2: Identify cultivation season (prints date bounds for reference)
Rscript csmtools_cli.R identify-production-season \
  --path inst/extdata/template_icasa_vba.xlsm \
  --exp-id $EXP_ID \
  --period cultivation_season

# Step 3: Download IoT sensor weather data
Rscript csmtools_cli.R get-sensor-data \
  --lon $LON --lat $LAT \
  --from $FROM --to $TO \
  --vars "air_temperature,solar_radiation,volume_of_hydrological_precipitation" \
  --output $WORKDIR/weather_sensor.json

# Step 4: Convert sensor data to ICASA
Rscript csmtools_cli.R convert-dataset \
  --input $WORKDIR/weather_sensor.json \
  --from user --to icasa \
  --output $WORKDIR/weather_sensor_icasa.json

# Step 5: Download NASA POWER complementary weather
Rscript csmtools_cli.R get-weather-data \
  --lon $LON --lat $LAT \
  --from $FROM --to $TO \
  --output $WORKDIR/weather_nasa.json

# Step 6: Convert NASA data to ICASA
Rscript csmtools_cli.R convert-dataset \
  --input $WORKDIR/weather_nasa.json \
  --from nasa-power --to icasa \
  --output $WORKDIR/weather_nasa_icasa.json

# Step 7: Assemble combined weather dataset
Rscript csmtools_cli.R assemble-dataset \
  --components $WORKDIR/weather_sensor_icasa.json $WORKDIR/weather_nasa_icasa.json \
  --output $WORKDIR/weather_combined.json

# Step 8: Get soil profile from SoilGrids
Rscript csmtools_cli.R get-soil-profile \
  --lon $LON --lat $LAT \
  --output $WORKDIR/soil.json

# Step 9: (Optional) Look up phenology growth stage dates
Rscript csmtools_cli.R lookup-gs-dates \
  --input $WORKDIR/wheat_phenology_results.csv \
  --gs-scale zadok \
  --gs-codes 10,65,87 \
  --date-select-rule median \
  --output $WORKDIR/gs_dates.json

# Step 10: Assemble full ICASA dataset
Rscript csmtools_cli.R assemble-dataset \
  --components $WORKDIR/field.json $WORKDIR/soil.json $WORKDIR/weather_combined.json \
  --output $WORKDIR/icasa.json

# Step 11: Convert full dataset to DSSAT format
Rscript csmtools_cli.R convert-dataset \
  --input $WORKDIR/icasa.json \
  --from icasa --to dssat \
  --output $WORKDIR/dssat.json

# Step 12: Normalize soil profile to standard depth sequence
Rscript csmtools_cli.R normalize-soil-profile \
  --input $WORKDIR/dssat.json \
  --depth-seq "5,10,20,30,40,50,60,70,90,110,130,150,170,190,210" \
  --output $WORKDIR/soil_normalized.json

# Step 13: Calculate initial soil conditions
Rscript csmtools_cli.R calculate-initial-layers \
  --input $WORKDIR/dssat.json \
  --paw 100 --total-n 50 \
  --output $WORKDIR/initial_layers.json

# Step 14: Build DSSAT input files
Rscript csmtools_cli.R build-simulation-files \
  --input $WORKDIR/dssat.json \
  --write-dssat-dir

# Step 15: Run simulations
Rscript csmtools_cli.R run-simulations \
  --filex ~/dssat/Wheat/${EXP_ID}.WHX \
  --treatments 1,3,7 \
  --output-dir ./simulations

# Step 16: Plot results
Rscript csmtools_cli.R plot-results \
  --dssat-dir ~/dssat \
  --treatments 1,3,7 \
  --output simulations/growth_plot.png

echo "✓ Workflow complete!"
```

### Using the Shell Script

```bash
bash run_workflow.sh
```

---

## Help

```bash
# General help
Rscript csmtools_cli.R --help

# Command-specific help
Rscript csmtools_cli.R get-field-data --help
Rscript csmtools_cli.R get-weather-data --help
Rscript csmtools_cli.R run-simulations --help
Rscript csmtools_cli.R plot-results --help
```

## Environment Variables

For FROST server access, set these in `.Renviron`:

```
FROST_CLIENT_ID=your_client_id
FROST_CLIENT_SECRET=your_client_secret
FROST_USERNAME=your_username
FROST_PASSWORD=your_password
FROST_USER_URL=https://your-frost-server/v1.0/
```

For DSSAT on Linux, set the executable path:

```
DSSAT_CSM=/home/user/dssat/dscsm048
```

## Features

- **Modular**: Each workflow step is an independent command matching its R function name
- **Composable**: Chain commands together using shell scripts
- **Progress tracking**: Clear feedback on each step
- **Error handling**: Informative error messages with non-zero exit codes
- **Flexible**: Override defaults with command-line arguments
