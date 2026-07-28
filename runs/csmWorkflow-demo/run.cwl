#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

doc: |
  Runner for the extended FAIRagro UC6 workflow combining phenology analysis with crop modelling.
  This workflow calls the csmWorkflow subworkflow, which:
      1. Fetches NDVI data from a SensorThings API
      2. Runs phenology analysis on NDVI time series
      3. Extracts growth stage dates from phenology results
      4. Converts growth stage dates to ICASA format
      5. Extracts field data from an ICASA Excel template
      6. Identifies the production season from field data
      7. Downloads sensor data from a SensorThings API
      8. Converts sensor data to ICASA format
      9. Downloads weather data from NASA POWER
      10. Converts weather data to ICASA format
      11. Downloads soil profile data
      12. Assembles all data into an integrated ICASA dataset
      13. Converts the ICASA dataset to DSSAT format
      14. Normalizes the soil profile
      15. Calculates initial layer conditions
      16. Builds DSSAT simulation input files
      17. Runs DSSAT crop simulations
      18. Plots simulation results

requirements:
  SubworkflowFeatureRequirement: {}


####################################
#### Inputs
####################################

inputs:
# Inputs: fetch-ndvi
  trial_id: string
  sensorthingsapi_url: string
  ndvi_file: string

# Inputs: phenology-analyzer
  sowing_date: string
  harvest_date: string
  results_csv: string
  visualization_png: string
  geojson_file: File

# Inputs: lookup-gs-dates
  gs_codes: string
  gs_dates_output: string

# Inputs: convert-gs-dates-icasa
  gs_icasa_output: string

# Inputs: get-field-data
  template_path: File
  experiment_id: string
  field_data_output: string

# Inputs: identify-production-season
  period: string
  output_format: string
  production_season_output: string

# Inputs: get-sensor-data
  lon: float
  lat: float
  radius: float
  vars: string
  sensor_data_output: string
  frost_client_id: string
  frost_client_secret: string
  frost_username: string
  frost_password: string
  frost_user_url: string

# Inputs: convert-sensor-data-icasa
  sensor_icasa_output: string

# Inputs: get-weather-data
  nasa_data_output: string

# Inputs: convert-nasa-data-icasa
  nasa_icasa_output: string

# Inputs: get-soil-profile
  soil_data_output: string

# Inputs: assemble-icasa-dataset
  assembled_icasa_output: string

# Inputs: convert-icasa-to-dssat
  dataset_dssat_output: string

# Inputs: normalize-soil-profile
  normalized_soil_output: string
  depth_seq: string

# Inputs: calculate-initial-layers
  initial_layers_output: string
  paw: double
  total_n: double

# Inputs: run-dssat-simulation
  treatments: string
  output_dir: string

# Inputs: plot-results
  plot_output_file: string
  plot_treatment_labels: string
  plot_legend_title: string


####################################
#### Steps
####################################

steps:
  csmWorkflow:
    run: ../../workflows/csmWorkflow/workflow.cwl
    in:
      trial_id: trial_id
      sensorthingsapi_url: sensorthingsapi_url
      ndvi_file: ndvi_file
      sowing_date: sowing_date
      harvest_date: harvest_date
      results_csv: results_csv
      visualization_png: visualization_png
      geojson_file: geojson_file
      gs_codes: gs_codes
      gs_dates_output: gs_dates_output
      gs_icasa_output: gs_icasa_output
      template_path: template_path
      experiment_id: experiment_id
      field_data_output: field_data_output
      period: period
      output_format: output_format
      production_season_output: production_season_output
      lon: lon
      lat: lat
      radius: radius
      vars: vars
      sensor_data_output: sensor_data_output
      frost_client_id: frost_client_id
      frost_client_secret: frost_client_secret
      frost_username: frost_username
      frost_password: frost_password
      frost_user_url: frost_user_url
      sensor_icasa_output: sensor_icasa_output
      nasa_data_output: nasa_data_output
      nasa_icasa_output: nasa_icasa_output
      soil_data_output: soil_data_output
      assembled_icasa_output: assembled_icasa_output
      dataset_dssat_output: dataset_dssat_output
      normalized_soil_output: normalized_soil_output
      depth_seq: depth_seq
      initial_layers_output: initial_layers_output
      paw: paw
      total_n: total_n
      treatments: treatments
      output_dir: output_dir
      plot_output_file: plot_output_file
      plot_treatment_labels: plot_treatment_labels
      plot_legend_title: plot_legend_title
    out:
      - ndvi_timeseries
      - phenology_results_csv
      - phenology_results_png
      - gs_dates
      - gs_dates_icasa
      - field_data
      - production_season
      - sensor_data
      - sensor_data_icasa
      - nasa_data
      - nasa_data_icasa
      - soil_data
      - assembled_icasa
      - dataset_dssat
      - normalized_soil
      - initial_layers
      - simulations_dir
      - growth_plot


####################################
#### Outputs
####################################

outputs:
# Outputs: fetch-ndvi
- id: ndvi_timeseries
  type: File
  outputSource: csmWorkflow/ndvi_timeseries

# Outputs: phenology-analyzer
- id: phenology_results_csv
  type: File
  outputSource: csmWorkflow/phenology_results_csv
- id: phenology_results_png
  type: File
  outputSource: csmWorkflow/phenology_results_png

# Outputs: lookup-gs-dates
- id: gs_dates
  type: File
  outputSource: csmWorkflow/gs_dates

# Outputs: convert-gs-dates-icasa
- id: gs_dates_icasa
  type: File
  outputSource: csmWorkflow/gs_dates_icasa

# Outputs: get-field-data
- id: field_data
  type: File
  outputSource: csmWorkflow/field_data

# Outputs: identify-production-season
- id: production_season
  type: File
  outputSource: csmWorkflow/production_season

# Outputs: get-sensor-data
- id: sensor_data
  type: File
  outputSource: csmWorkflow/sensor_data

# Outputs: convert-sensor-data-icasa
- id: sensor_data_icasa
  type: File
  outputSource: csmWorkflow/sensor_data_icasa

# Outputs: get-weather-data
- id: nasa_data
  type: File
  outputSource: csmWorkflow/nasa_data

# Outputs: convert-nasa-data-icasa
- id: nasa_data_icasa
  type: File
  outputSource: csmWorkflow/nasa_data_icasa

# Outputs: get-soil-profile
- id: soil_data
  type: File
  outputSource: csmWorkflow/soil_data

# Outputs: assemble-icasa-dataset
- id: assembled_icasa
  type: File
  outputSource: csmWorkflow/assembled_icasa

# Outputs: convert-icasa-dssat
- id: dataset_dssat
  type: File
  outputSource: csmWorkflow/dataset_dssat

# Outputs: normalize-soil-profile
- id: normalized_soil
  type: File
  outputSource: csmWorkflow/normalized_soil

# Outputs: calculate-initial-layers
- id: initial_layers
  type: File
  outputSource: csmWorkflow/initial_layers

# Outputs: run-simulations
- id: simulations_dir
  type: Directory
  outputSource: csmWorkflow/simulations_dir

# Outputs: plot-results
- id: growth_plot
  type: File
  outputSource: csmWorkflow/growth_plot
