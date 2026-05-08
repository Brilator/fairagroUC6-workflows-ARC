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
  trial_id: string
  sensorthingsapi_url: string
  ndvi_file: string
  sowing_date: string
  harvest_date: string
  results_csv: string
  visualization_png: string
  geojson: File
  longitude: float
  latitude: float
  season_file: File
  gs_scale: string
  gs_codes: string

####################################
#### Steps
####################################

steps:
  csmWorkflow
    run: ../../workflows/csmWorkflow/workflow.cwl
    in:
      trial_id: trial_id
      sensorthingsapi_url: sensorthingsapi_url
      ndvi_file: ndvi_file
      sowing_date: sowing_date
      harvest_date: harvest_date
      results_csv: results_csv
      visualization_png: visualization_png
      geojson: geojson
      longitude: longitude
      latitude: latitude
      season_file: season_file
      gs_scale: gs_scale
      gs_codes: gs_codes
    out:
      - ndvi_timeseries
      - phenology_results_csv
      - phenology_results_png
      - growth_stage_dates
      - weather_data
      - soil_data
      - integrated_dataset


####################################
#### Outputs
####################################

outputs:
- id: ndvi_timeseries
  type: File
  outputSource: csmWorkflow/ndvi_timeseries
- id: phenology_results_csv
  type: File
  outputSource: csmWorkflow/phenology_results_csv
- id: phenology_results_png
  type: File
  outputSource: csmWorkflow/phenology_results_png
- id: growth_stage_dates
  type: File
  outputSource: csmWorkflow/growth_stage_dates
- id: weather_data
  type: File
  outputSource: csmWorkflow/weather_data
- id: soil_data
  type: File
  outputSource: csmWorkflow/soil_data
- id: integrated_dataset
  type: File
  outputSource: csmWorkflow/integrated_dataset
