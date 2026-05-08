#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

doc: |
  Extended FAIRagro UC6 workflow combining phenology analysis with crop modeling.
  This workflow extends the demo workflow by:
  1. Running NDVI data acquisition and phenology analysis (from demo.cwl)
  2. Extracting growth stage dates from phenology results
  3. Converting phenology data to ICASA format
  4. Downloading weather and soil data
  5. Assembling all data for crop simulation with DSSAT


####################################
#### Inputs
####################################

inputs:
# Inputs from demo workflow
- id: geojson
  type: File
  default:
    class: File
    path: ../../data/field_location.geojson
  doc: Field location GeoJSON file

# Location parameters for data acquisition
- id: longitude
  type: double
  default: 10.645269
  doc: Field longitude coordinate

- id: latitude
  type: double
  default: 49.20868
  doc: Field latitude coordinate

# Input file for 
- id: season_file
  type: File
  doc: JSON file from identify-production-season with start_date/end_date fields

# Growth stage parameters
- id: gs_scale
  type: string
  default: "zadoks"
  doc: Growth stage scale (zadoks, bbch)

- id: gs_codes
  type: string
  default: "65,87"
  doc: Zadoks codes for key growth stages (65=anthesis, 87=maturity)


####################################
#### Steps
####################################

steps:
# Step 1: Fetch NDVI data (from demo workflow)
- id: fetch-ndvi
  run: ./raster2sensorTools/fetch-ndvi.cwl
  in: []
  out: [ndvi_timeseries]

# Step 2: Run phenology analysis (from demo workflow)
- id: phenology-analyzer
  run: ./phenocoverTools/phenology-analyzer.cwl
  in:
  - id: ndvi_file
    source: fetch-ndvi/ndvi_timeseries
  - id: geojson_file
    source: geojson
  out:
  - phenology_results_csv
  - phenology_results_png

# Step 3: Extract growth stage dates from phenology results
- id: lookup-gs-dates
  run: ./csmTools/lookup-gs-dates.cwl
  in:
  - id: phenology_csv
    source: phenology-analyzer/phenology_results_csv
  - id: gs_scale
    source: gs_scale
  - id: gs_codes
    source: gs_codes
  out: [gs_dates]

# Step 4: Convert phenology data to ICASA format
- id: convert-phenology
  run: ./csmTools/convert-gs-dates-icasa.cwl
  in:
  - id: gs_dates
    source: lookup-gs-dates/gs_dates
  - id: gs_icasa_output
    valueFrom: "phenology_icasa.json"
  out: [gs_dates_icasa]

# Step 5: Download weather data from NASA POWER
- id: get-weather
  run: ./csmTools/get-weather-data.cwl
  in:
  - id: lon
    source: longitude
  - id: lat
    source: latitude
  - id: season_file
    source: season_file
  - id: nasa_data_output
    valueFrom: "weather_nasapower.json"
  out: [nasa_data]

# Step 6: Convert weather data to ICASA format
- id: convert-weather
  run: ./csmTools/convert-nasa-data-icasa.cwl
  in:
  - id: nasa_data
    source: get-weather/nasa_data
  - id: nasa_icasa_output
    valueFrom: "weather_icasa.json"
  out: [nasa_data_icasa]

# Step 7: Get soil profile data
- id: get-soil
  run: ./csmTools/get-soil-profile.cwl
  in:
  - id: lon
    source: longitude
  - id: lat
    source: latitude
  - id: soil_data_output
    valueFrom: "soil_icasa.json"
  out: [soil_data]

# Step 8: Assemble all data sources
- id: assemble-data
  run: ./csmTools/assemble-icasa-dataset.cwl
  in:
  - id: sensor_icasa
# TODO TODO
    source:
  - id: nasa_icasa
    source: convert-weather/nasa_data_icasa
  - id: soil_data
    source: get-soil/soil_data
  - id: field_data
    source: geojson
  - id: gs_dates_icasa
    source: convert-phenology/gs_dates_icasa
  - id: assembled_icasa_output
    valueFrom: "assembled_icasa.json"
  out: [assembled_icasa]

####################################
#### Outputs
####################################

outputs:
# Original demo outputs
- id: ndvi_timeseries
  type: File
  outputSource: fetch-ndvi/ndvi_timeseries
  doc: NDVI time series data

- id: phenology_results_csv
  type: File
  outputSource: phenology-analyzer/phenology_results_csv
  doc: Detailed phenology analysis results

- id: phenology_results_png
  type: File
  outputSource: phenology-analyzer/phenology_results_png
  doc: Phenology visualization

# CSM workflow outputs
- id: growth_stage_dates
  type: File
  outputSource: convert-phenology/gs_dates_icasa
  doc: Growth stage dates in ICASA format for crop modeling

- id: weather_data
  type: File
  outputSource: convert-weather/nasa_data_icasa
  doc: Weather data in ICASA format

- id: soil_data
  type: File
  outputSource: get-soil/soil_data
  doc: Soil profile data

- id: integrated_dataset
  type: File
  outputSource: assemble-data/assembled_icasa
  doc: Fully integrated dataset for crop modeling