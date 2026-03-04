#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

inputs:
- id: trial_id
  type: string
- id: sensorthingsapi_url
  type: string
- id: ndvi_file
  type: string
- id: geojson_file
  type: File
- id: sowing_date
  type: string
- id: harvest_date
  type: string
- id: results_csv
  type: string
- id: visualization_png
  type: string
- id: template_path
  type: File
- id: experiment_id
  type: string
- id: field_data_output
  type: string
- id: period
  type: string
- id: output_format
  type: string
- id: production_season_output
  type: string
- id: lon
  type: float
- id: lat
  type: float
- id: radius
  type: float
- id: vars
  type: string
- id: sensor_data_output
  type: string
# FROST credentials flow: config.yml (gitignored, copied from config-example.yml)
# → CWL inputs below → EnvVarRequirement → Docker container
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

outputs:
- id: phenology_results_png
  type: File
  outputSource: phenology-analyzer/phenology_results_png
- id: phenology_results_csv
  type: File
  outputSource: phenology-analyzer/phenology_results_csv
- id: ndvi_timeseries
  type: File
  outputSource: fetch-ndvi/ndvi_timeseries
- id: field_data
  type: File
  outputSource: get-field-data/field_data
- id: production_season
  type: File
  outputSource: identify-production-season/production_season
- id: sensor_data
  type: File
  outputSource: get-sensor-data/sensor_data

steps:
- id: fetch-ndvi
  in:
  - id: trial_id
    source: trial_id
  - id: sensorthingsapi_url
    source: sensorthingsapi_url
  - id: ndvi_file
    source: ndvi_file
  run: ../raster2sensorTools/fetch-ndvi.cwl
  out:
  - ndvi_timeseries
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
  run: ../phenocoverTools/phenology-analyzer.cwl
  out:
  - phenology_results_csv
  - phenology_results_png
- id: get-field-data
  in:
  - id: template_path
    source: template_path
  - id: experiment_id
    source: experiment_id
  - id: field_data_output
    source: field_data_output
  run: ../csmTools/get-field-data.cwl
  out:
  - field_data
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
  run: ../csmTools/identify-production-season.cwl
  out:
  - production_season
  - start_date
  - end_date
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
  run: ../csmTools/get-sensor-data.cwl
  out:
  - sensor_data
