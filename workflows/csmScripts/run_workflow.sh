#!/bin/bash
## -----------------------------------------------------------------------------------
## Script name: run_workflow.sh
## Purpose: Complete workflow example using csmTools CLI
## -----------------------------------------------------------------------------------

set -e  # Exit on error

# Configuration
WORKDIR="archive"
CLI_SCRIPT="cli/csmtools_cli.R"
LON=10.645269
LAT=49.20868
START_DATE="2024-01-01"
END_DATE="2025-12-31"
EXP_ID="HWOC2501"
TEMPLATE_PATH="inst/extdata/template_icasa_vba.xlsm"
PHENOLOGY_PATH="$WORKDIR/wheat_phenology_results.csv"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting csmTools workflow...${NC}\n"

# Create working directory
mkdir -p $WORKDIR simulations

# Step 1: Extract field/management data from ICASA template
echo -e "${GREEN}Step 1: Extracting field data...${NC}"
Rscript $CLI_SCRIPT get-field-data \
  --path $TEMPLATE_PATH \
  --exp-id $EXP_ID \
  --output $WORKDIR/field.json

# Step 2: Identify cultivation season bounds
echo -e "\n${GREEN}Step 2: Identifying production season...${NC}"
Rscript $CLI_SCRIPT identify-production-season \
  --path $TEMPLATE_PATH \
  --exp-id $EXP_ID \
  --period cultivation_season \
  --output-format bounds

# Step 3: Get sensor data (optional - requires FROST credentials)
if [ ! -z "$FROST_CLIENT_ID" ]; then
  echo -e "\n${GREEN}Step 3: Downloading IoT sensor data...${NC}"
  Rscript $CLI_SCRIPT get-sensor-data \
    --lon $LON --lat $LAT \
    --from $START_DATE --to $END_DATE \
    --radius 10 \
    --vars "air_temperature,solar_radiation,volume_of_hydrological_precipitation" \
    --output $WORKDIR/weather_sensor.json

  echo -e "\n${GREEN}Step 3b: Converting sensor data to ICASA...${NC}"
  Rscript $CLI_SCRIPT convert-dataset \
    --input $WORKDIR/weather_sensor.json \
    --from user --to icasa \
    --output $WORKDIR/weather_sensor_icasa.json

  SENSOR_ICASA="$WORKDIR/weather_sensor_icasa.json"
else
  echo -e "\n${BLUE}Step 3: Skipping sensor data (FROST_CLIENT_ID not set)${NC}"
  SENSOR_ICASA=""
fi

# Step 4: Download complementary weather data from NASA POWER
echo -e "\n${GREEN}Step 4: Downloading NASA POWER weather data...${NC}"
Rscript $CLI_SCRIPT get-weather-data \
  --lon $LON --lat $LAT \
  --from $START_DATE --to $END_DATE \
  --output $WORKDIR/weather_nasa.json

# Step 5: Convert NASA weather to ICASA
echo -e "\n${GREEN}Step 5: Converting NASA weather to ICASA...${NC}"
Rscript $CLI_SCRIPT convert-dataset \
  --input $WORKDIR/weather_nasa.json \
  --from nasa-power --to icasa \
  --output $WORKDIR/weather_nasa_icasa.json

# Step 6: Assemble combined weather dataset
echo -e "\n${GREEN}Step 6: Assembling combined weather dataset...${NC}"
if [ ! -z "$SENSOR_ICASA" ]; then
  WEATHER_COMPONENTS="$SENSOR_ICASA $WORKDIR/weather_nasa_icasa.json"
else
  WEATHER_COMPONENTS="$WORKDIR/weather_nasa_icasa.json"
fi
Rscript $CLI_SCRIPT assemble-dataset \
  --components $WEATHER_COMPONENTS \
  --output $WORKDIR/weather_combined.json \
  --action merge_properties

# Step 7: Extract soil profile from SoilGrids
echo -e "\n${GREEN}Step 7: Extracting soil profile...${NC}"
Rscript $CLI_SCRIPT get-soil-profile \
  --lon $LON --lat $LAT \
  --output $WORKDIR/soil.json

# Step 8: Look up phenology growth stage dates (optional)
if [ -f "$PHENOLOGY_PATH" ]; then
  echo -e "\n${GREEN}Step 8: Looking up growth stage dates...${NC}"
  Rscript $CLI_SCRIPT lookup-gs-dates \
    --input $PHENOLOGY_PATH \
    --gs-scale zadok \
    --gs-codes 10,65,87 \
    --date-select-rule median \
    --output $WORKDIR/gs_dates.json

  echo -e "\n${GREEN}Step 8b: Converting phenology to ICASA...${NC}"
  Rscript $CLI_SCRIPT convert-dataset \
    --input $WORKDIR/gs_dates.json \
    --from user --to icasa \
    --output $WORKDIR/gs_dates_icasa.json
else
  echo -e "\n${BLUE}Step 8: Skipping phenology (file not found: $PHENOLOGY_PATH)${NC}"
fi

# Step 9: Assemble full ICASA dataset
echo -e "\n${GREEN}Step 9: Assembling full ICASA dataset...${NC}"
Rscript $CLI_SCRIPT assemble-dataset \
  --components $WORKDIR/field.json $WORKDIR/soil.json $WORKDIR/weather_combined.json \
  --output $WORKDIR/icasa.json \
  --action merge_properties

# Step 10: Convert full dataset to DSSAT format
echo -e "\n${GREEN}Step 10: Converting to DSSAT format...${NC}"
Rscript $CLI_SCRIPT convert-dataset \
  --input $WORKDIR/icasa.json \
  --from icasa --to dssat \
  --output $WORKDIR/dssat.json

# Step 11: Normalize soil profile to standard depth sequence
echo -e "\n${GREEN}Step 11: Normalizing soil profile...${NC}"
Rscript $CLI_SCRIPT normalize-soil-profile \
  --input $WORKDIR/dssat.json \
  --depth-seq "5,10,20,30,40,50,60,70,90,110,130,150,170,190,210" \
  --method linear \
  --output $WORKDIR/soil_normalized.json

# Step 12: Calculate initial soil conditions per layer
echo -e "\n${GREEN}Step 12: Calculating initial soil layers...${NC}"
Rscript $CLI_SCRIPT calculate-initial-layers \
  --input $WORKDIR/dssat.json \
  --paw 100 \
  --total-n 50 \
  --output $WORKDIR/initial_layers.json

# Set DSSAT executable path for Linux
if [ -f ~/dssat/dscsm048 ]; then
  export DSSAT_CSM="$HOME/dssat/dscsm048"
fi

# Step 13: Build DSSAT input files
echo -e "\n${GREEN}Step 13: Building DSSAT input files...${NC}"
Rscript $CLI_SCRIPT build-simulation-files \
  --input $WORKDIR/dssat.json \
  --depth-seq "5,10,20,30,40,50,60,70,90,110,130,150,170,190,210" \
  --method linear \
  --paw 100 \
  --total-n 50 \
  --write-dssat-dir

# Step 14: Run simulations (if DSSAT is installed)
if [ -d ~/dssat ]; then
  echo -e "\n${GREEN}Step 14: Running DSSAT simulation...${NC}"
  Rscript $CLI_SCRIPT run-simulations \
    --filex ~/dssat/Wheat/${EXP_ID}.WHX \
    --treatments 1,3,7 \
    --dssat-dir ~/dssat \
    --output-dir ./simulations
else
  echo -e "\n${BLUE}Step 14: Skipping simulation (DSSAT not found at ~/dssat)${NC}"
  echo "To install DSSAT, run: bash install_dssat.sh"
fi

# Step 15: Plot simulation results
if [ -f ~/dssat/PlantGro.OUT ] && [ -f ~/dssat/Summary.OUT ]; then
  echo -e "\n${GREEN}Step 15: Plotting simulation results...${NC}"
  Rscript $CLI_SCRIPT plot-results \
    --dssat-dir ~/dssat \
    --treatments 1,3,7 \
    --treatment-labels "0 kg N/ha,147 kg N/ha,180 kg N/ha" \
    --legend-title "Fertilization" \
    --output simulations/growth_plot.png \
    --pdf-output simulations/growth_plot.pdf
else
  echo -e "\n${BLUE}Step 15: Skipping plot (no DSSAT output found at ~/dssat)${NC}"
fi

echo -e "\n${GREEN}✓ Workflow complete!${NC}"
echo "Output files saved to: $WORKDIR/"
ls -lh $WORKDIR/
