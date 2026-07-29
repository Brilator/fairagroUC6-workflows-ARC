#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

doc: |
  Extended FAIRagro UC6 workflow combining phenology analysis with crop modelling.
  This workflow extends the demo workflow by:
      1. Fetching NDVI data from a SensorThings API
      2. Running phenology analysis on NDVI time series
      3. Extracting growth stage dates from phenology results
      4. Converting growth stage dates to ICASA format
      5. Extracting field data from an ICASA Excel template
      6. Identifying the production season from field data
      7. Downloading sensor data from a SensorThings API
      8. Converting sensor data to ICASA format
      9. Downloading weather data from NASA POWER
      10. Converting weather data to ICASA format
      11. Downloading soil profile data
      12. Assembling all data into an integrated ICASA dataset
      13. Converting the ICASA dataset to DSSAT format
      14. Normalizing the soil profile
      15. Calculating initial layer conditions
      16. Building DSSAT simulation input files
      17. Running DSSAT crop simulations
      18. Plotting simulation results


####################################
#### Inputs
####################################

inputs:
# Inputs: fetch-ndvi
- id: trial_id
  type: string
- id: sensorthingsapi_url
  type: string
- id: ndvi_file
  type: string

# Inputs: phenology-analyzer

- id: sowing_date
  type: string
- id: harvest_date
  type: string
- id: results_csv
  type: string
- id: visualization_png
  type: string
- id: geojson_file
  type: File
  default:
    class: File
    # TODO: add path to run.yml
    # path: ../../data/field_location.geojson
  doc: "Field location GeoJSON file"

# Inputs: lookup-gs-dates
- id: gs_codes
  type: string
  doc: "Comma-separated Zadok growth stage codes to look up"
- id: gs_dates_output
  type: string
  doc: "Output file name for the growth stage dates JSON"

# Inputs: convert-gs-dates-icasa
- id: gs_icasa_output
  type: string 
  doc: "Output file name for the ICASA-formatted growth stage dates"

# Inputs: get-field-data
- id: template_path
  type: File
- id: experiment_id
  type: string
- id: field_data_output
  type: string

# Inputs: identify-production-season
- id: period
  type: string
- id: output_format
  type: string
- id: production_season_output
  type: string

# Inputs: get-sensor-data
- id: lon
  type: float
  doc: "Longitude of the field location"
- id: lat
  type: float
  doc: "Latitude of the field location"
- id: radius
  type: float
- id: vars
  type: string
- id: sensor_data_output
  type: string
# FROST credentials for accessing sensor data via a SensorThings API endpoint via Keycloak: config.yml (gitignored, copied from config-example.yml)
- id: frost_client_id
  type: string
- id: frost_client_secret
  type: string
- id: frost_username
  type: string
- id: frost_password
  type: string
- id: frost_user_url
  type: string

# Inputs: convert-sensor-data-icasa
- id: sensor_data
  type: File
- id: sensor_icasa_output
  type: string

# Inputs: get-weather-data
- id: nasa_data_output
  type: string

# Inputs: convert-nasa-data-icasa
- id: nasa_icasa_output
  type: string

# Inputs: get-soil-profile
- id: soil_data_output
  type: string
  doc: "Output file name for the extracted soil profile (ICASA JSON)"

# Inputs: assemble-icasa-dataset
- id: assembled_icasa_output
  type: string
  doc: "Output file name for the assembled ICASA dataset"

# Inputs: convert-icasa-to-dssat
- id: dataset_dssat_output
  type: string
  doc: "Output file name for the DSSAT-formatted dataset"

# Inputs: normalize-soil-profile
- id: normalized_soil_output
  type: string
  doc: "Output file name for the normalized soil profile"
- id: depth_seq
  type: string
  doc: "Comma-separated target depth sequence in cm"

# Inputs: calculate-initial-layers
- id: initial_layers_output
  type: string
  doc: "Output file name for the initial layer conditions"
- id: paw
  type: double
  doc: "Percent available water (0-100)"
- id: total_n
  type: double
  doc: "Total soil nitrogen in kg/ha"


# Inputs: run-dssat-simulation
- id: treatments
  type: string
  doc: "Comma-separated treatment numbers to run (e.g. '1,2,3'); omit for all"
- id: output_dir
  type: string
  doc: "Directory name for DSSAT simulation output files"

# Inputs: plot-results
- id: plot_output_file
  type: string
  doc: "Output PNG filename written to the staging directory"
- id: plot_treatment_labels
  type: string
  doc: "Comma-separated legend labels in treatment order, e.g. '0 kg N/ha,147 kg N/ha'"
- id: plot_legend_title
  type: string
  doc: "Title for the plot legend"


####################################
#### Steps
####################################

steps:
# Step 1: Fetch NDVI data (from demo workflow)
- id: fetch-ndvi
  in:
  - id: trial_id
    source: trial_id
  - id: sensorthingsapi_url
    source: sensorthingsapi_url
  - id: ndvi_file
    source: ndvi_file
  run: ./raster2sensorTools/fetch-ndvi.cwl
  out:
  - ndvi_timeseries

# Step 2: Run phenology analysis (from demo workflow)
- id: phenology-analyzer
  in:
  - id: ndvi_file
    source: fetch-ndvi/ndvi_timeseries
  - id: geojson_file
    source: geojson_file
  - id: sowing_date
    source: sowing_date
  - id: harvest_date
    source: harvest_date
  - id: results_csv
    source: results_csv
  - id: visualization_png
    source: visualization_png
  run: ./phenocoverTools/phenology-analyzer.cwl
  out:
  - phenology_results_csv
  - phenology_results_png

# Step 3: Extract growth stage dates from phenology results
- id: lookup-gs-dates
  in:
  - id: phenology_csv
    source: phenology-analyzer/phenology_results_csv
  - id: gs_codes
    source: gs_codes
  - id: gs_dates_output
    source: gs_dates_output
  run: ./csmTools/lookup-gs-dates.cwl
  out:
  - gs_dates

# Step 4: Convert phenology data to ICASA format
- id: convert-gs-dates-icasa
  in:
  - id: gs_dates
    source: lookup-gs-dates/gs_dates
  - id: gs_icasa_output
    source: gs_icasa_output
  run: ./csmTools/convert-gs-dates-icasa.cwl
  out:
  - gs_dates_icasa

# Step 5: Exract field data from an ICASA Excel template
- id: get-field-data
  in:
  - id: template_path
    source: template_path
  - id: experiment_id
    source: experiment_id
  - id: field_data_output
    source: field_data_output
  run: ./csmTools/get-field-data.cwl
  out:
  - field_data

# Step 6: Identify production season from field data
- id: identify-production-season
  in:
  - id: field_data
    source: get-field-data/field_data
  - id: period
    source: period
  - id: output_format
    source: output_format
  - id: production_season_output
    source: production_season_output
  run: ./csmTools/identify-production-season.cwl
  out:
  - production_season
  - start_date
  - end_date

# Step 7: Get sensor data from SensorThings API
- id: get-sensor-data
  in:
  - id: lon
    source: lon
  - id: lat
    source: lat
  - id: season_file
    source: identify-production-season/production_season
  - id: radius
    source: radius
  - id: vars
    source: vars
  - id: sensor_data_output
    source: sensor_data_output
  - id: frost_client_id
    source: frost_client_id
  - id: frost_client_secret
    source: frost_client_secret
  - id: frost_username
    source: frost_username
  - id: frost_password
    source: frost_password
  - id: frost_user_url
    source: frost_user_url
  run: ./csmTools/get-sensor-data.cwl
  out:
  - sensor_data

# Step 8: Convert sensor data to ICASA format
- id: convert-sensor-data-icasa
  in:
  - id: sensor_data
    source: get-sensor-data/sensor_data
  - id: sensor_icasa_output
    source: sensor_icasa_output
  run: ./csmTools/convert-sensor-data-icasa.cwl
  out:
  - sensor_data_icasa


# Step 9: Download weather data from NASA POWER
- id: get-weather-data
  in:
  - id: lon
    source: lon
  - id: lat
    source: lat
  - id: season_file
    source: identify-production-season/production_season
  - id: nasa_data_output
    source: nasa_data_output
  run: ./csmTools/get-weather-data.cwl
  out:
  - nasa_data

# Step 10: Convert weather data to ICASA format
- id: convert-nasa-data-icasa
  in:
  - id: nasa_data
    source: get-weather-data/nasa_data
  - id: nasa_icasa_output
    source: nasa_icasa_output
  run: ./csmTools/convert-nasa-data-icasa.cwl
  out:
  - nasa_data_icasa

# Step 11: Get soil profile data
- id: get-soil-profile
  in:
  - id: lon
    source: lon
  - id: lat
    source: lat
  - id: soil_data_output
    source: soil_data_output
  run: ./csmTools/get-soil-profile.cwl
  out:
  - soil_data

# Step 12: Assemble all data sources
- id: assemble-icasa-dataset
  in:
  - id: sensor_icasa
    source: convert-sensor-data-icasa/sensor_data_icasa
  - id: nasa_icasa
    source: convert-nasa-data-icasa/nasa_data_icasa
  - id: soil_data
    source: get-soil-profile/soil_data
  - id: field_data
    source: get-field-data/field_data
  - id: gs_dates_icasa
    source: convert-gs-dates-icasa/gs_dates_icasa
  - id: assembled_icasa_output
    source: assembled_icasa_output
  run: ./csmTools/assemble-icasa-dataset.cwl
  out:
  - assembled_icasa

# Step 13: Convert ICASA dataset to DSSAT format
- id: convert-icasa-dssat
  in:
  - id: assembled_icasa
    source: assemble-icasa-dataset/assembled_icasa
  - id: dataset_dssat_output
    source: dataset_dssat_output
  run: ./csmTools/convert-icasa-dssat.cwl
  out:
  - dataset_dssat

# Step 14: Normalize soil profile
- id: normalize-soil-profile
  in:
  - id: dataset_dssat
    source: convert-icasa-dssat/dataset_dssat
  - id: normalized_soil_output
    source: normalized_soil_output
  run: ./csmTools/normalize-soil-profile.cwl
  out:
  - normalized_soil

# Step 15: Calculate initial layer conditions
- id: calculate-initial-layers
  in:
  - id: dataset_dssat
    source: convert-icasa-dssat/dataset_dssat
  - id: initial_layers_output
    source: initial_layers_output
  run: ./csmTools/calculate-initial-layers.cwl
  out:
  - initial_layers

# Step 16: Prepare DSSAT input files
- id: build-simulation-files
  in:
  - id: dataset_dssat
    source: convert-icasa-dssat/dataset_dssat
  - id: depth_seq
    source: depth_seq
  - id: paw
    source: paw
  - id: total_n
    source: total_n
  run: ./csmTools/build-simulation-files.cwl
  out:
  - filex
  - soil_file
  - weather_files

# Step 17: Run DSSAT simulation
- id: run-simulations
  in:
  - id: filex
    source: build-simulation-files/filex
  - id: soil_file
    source: build-simulation-files/soil_file
  - id: weather_files
    source: build-simulation-files/weather_files
  - id: treatments
    source: treatments
  - id: output_dir
    source: dataset_dssat_output
  run: ./csmTools/run-simulations.cwl
  out:
  - simulations_dir

# Step 18: Plot simulation results
- id: plot-results
  in:
  - id: simulations_dir
    source: run-simulations/simulations_dir
  - id: output_file
    source: plot_output_file
  - id: treatment_labels
    source: plot_treatment_labels
  - id: legend_title
    source: plot_legend_title
  run: ./csmTools/plot-results.cwl
  out:
  - growth_plot

####################################
#### Outputs
####################################

outputs:
# Outputs: fetch-ndvi
- id: ndvi_timeseries
  type: File
  outputSource: fetch-ndvi/ndvi_timeseries
  doc: "NDVI time series data"

# Outputs: phenology-analyzer
- id: phenology_results_csv
  type: File
  outputSource: phenology-analyzer/phenology_results_csv
  doc: "Detailed phenology analysis results"
- id: phenology_results_png
  type: File
  outputSource: phenology-analyzer/phenology_results_png
  doc: "Phenology visualisation"

# Outputs: lookup-gs-dates
- id: gs_dates
  type: File
  outputSource: lookup-gs-dates/gs_dates
  doc: "Growth stage dates extracted from phenology results"

# Outputs: convert-gs-dates-icasa
- id: gs_dates_icasa
  type: File
  outputSource: convert-gs-dates-icasa/gs_dates_icasa
  doc: "Growth stage dates in ICASA format"

# Outputs: get-field-data
- id: field_data
  type: File
  outputSource: get-field-data/field_data
  doc: "Field experiment data extracted from ICASA Excel template"

# Outputs: identify-production-season
- id: production_season
  type: File
  outputSource: identify-production-season/production_season
  doc: "Identified production season with start and end dates"

# Outputs: get-sensor-data
- id: sensor_data
  type: File
  outputSource: get-sensor-data/sensor_data
  doc: "Raw sensor data retrieved from SensorThings API"

# Outputs: convert-sensor-data-icasa
- id: sensor_data_icasa
  type: File
  outputSource: convert-sensor-data-icasa/sensor_data_icasa
  doc: "Sensor data in ICASA format"

# Outputs: get-weather-data
- id: nasa_data
  type: File
  outputSource: get-weather-data/nasa_data
  doc: "Raw weather data from NASA POWER"

# Outputs: convert-nasa-data-icasa
- id: nasa_data_icasa
  type: File
  outputSource: convert-nasa-data-icasa/nasa_data_icasa
  doc: "Weather data in ICASA format"

# Outputs: get-soil-profile
- id: soil_data
  type: File
  outputSource: get-soil-profile/soil_data
  doc: "Soil profile data"

# Outputs: assemble-icasa-dataset
- id: assembled_icasa
  type: File
  outputSource: assemble-icasa-dataset/assembled_icasa
  doc: "Fully integrated ICASA dataset"

# Outputs: convert-icasa-dssat
- id: dataset_dssat
  type: File
  outputSource: convert-icasa-dssat/dataset_dssat
  doc: "Integrated dataset in DSSAT format"

# Outputs: normalize-soil-profile
- id: normalized_soil
  type: File
  outputSource: normalize-soil-profile/normalized_soil
  doc: "Normalized soil profile"

# Outputs: calculate-initial-layers
- id: initial_layers
  type: File
  outputSource: calculate-initial-layers/initial_layers
  doc: "Initial soil layer conditions"

# Outputs: run-simulations
- id: simulations_dir
  type: Directory
  outputSource: run-simulations/simulations_dir
  doc: "DSSAT simulation output files"

# Outputs: plot-results
- id: growth_plot
  type: File
  outputSource: plot-results/growth_plot
  doc: "Simulation results plot"