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
