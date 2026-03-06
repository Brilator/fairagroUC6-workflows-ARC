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

# Time period
- id: start_date
  type: string
  default: "2024-01-01"
  doc: Start date for data collection (YYYY-MM-DD)

- id: end_date
  type: string
  default: "2025-08-09"
  doc: End date for data collection (YYYY-MM-DD)

# Growth stage parameters
- id: gs_scale
  type: string
  default: "zadoks"
  doc: Growth stage scale (zadoks, bbch)

- id: gs_codes
  type: string
  default: "65,87"
  doc: Zadoks codes for key growth stages (65=anthesis, 87=maturity)

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
  outputSource: convert-phenology/converted_data
  doc: Growth stage dates in ICASA format for crop modeling

- id: weather_data
  type: File
  outputSource: convert-weather/converted_data
  doc: Weather data in ICASA format

- id: soil_data
  type: File
  outputSource: get-soil/soil_data
  doc: Soil profile data

- id: integrated_dataset
  type: File
  outputSource: assemble-data/assembled_data
  doc: Fully integrated dataset for crop modeling

steps:
# Step 1: Fetch NDVI data (from demo workflow)
- id: fetch-ndvi
  run: ../raster2sensorTools/fetch-ndvi.cwl
  in: []
  out: [ndvi_timeseries]

# Step 2: Run phenology analysis (from demo workflow)
- id: phenology-analyzer
  run: ../phenocoverTools/phenology-analyzer.cwl
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
  run: ../csmTools/lookup-gs-dates.cwl
  in:
  - id: phenology_results
    source: phenology-analyzer/phenology_results_csv
  - id: gs_scale
    source: gs_scale
  - id: gs_codes
    source: gs_codes
  out: [phenology_json]

# Step 4: Convert phenology data to ICASA format
- id: convert-phenology
  run: ../csmTools/convert-dataset.cwl
  in:
  - id: input_file
    source: lookup-gs-dates/phenology_json
  - id: input_model
    valueFrom: "user"
  - id: output_model
    valueFrom: "icasa"
  - id: output_filename
    valueFrom: "phenology_icasa.json"
  out: [converted_data]

# Step 5: Download weather data from NASA POWER
- id: get-weather
  run: ../csmTools/get-weather.cwl
  in:
  - id: longitude
    source: longitude
  - id: latitude
    source: latitude
  - id: start_date
    source: start_date
  - id: end_date
    source: end_date
  - id: output_filename
    valueFrom: "weather_nasapower.json"
  out: [weather_data]

# Step 6: Convert weather data to ICASA format
- id: convert-weather
  run: ../csmTools/convert-dataset.cwl
  in:
  - id: input_file
    source: get-weather/weather_data
  - id: input_model
    valueFrom: "nasa-power"
  - id: output_model
    valueFrom: "icasa"
  - id: output_filename
    valueFrom: "weather_icasa.json"
  out: [converted_data]

# Step 7: Get soil profile data
- id: get-soil
  run: ../csmTools/get-soil.cwl
  in:
  - id: longitude
    source: longitude
  - id: latitude
    source: latitude
  - id: output_filename
    valueFrom: "soil_icasa.json"
  out: [soil_data]

# Step 8: Assemble all data sources
- id: assemble-data
  run: ../csmTools/assemble-dataset.cwl
  in:
  - id: component_files
    source:
    - convert-phenology/converted_data
    - convert-weather/converted_data
    - get-soil/soil_data
  - id: action
    valueFrom: "merge_properties"
  - id: output_filename
    valueFrom: "integrated_dataset.json"
  out: [assembled_data]
