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
- id: sensor_icasa_output
  type: string
- id: nasa_data_output
  type: string
- id: nasa_icasa_output
  type: string
- id: soil_data_output
  type: string
- id: gs_codes
  type: string
- id: gs_dates_output
  type: string
- id: gs_icasa_output
  type: string
- id: assembled_icasa_output
  type: string
- id: dataset_dssat_output
  type: string
- id: normalized_soil_output
  type: string
- id: initial_layers_output
  type: string
- id: depth_seq
  type: string
- id: paw
  type: double
- id: total_n
  type: double
- id: simulations_output_dir
  type: string
- id: treatments
  type: string
- id: plot_output_file
  type: string
- id: plot_treatment_labels
  type: string?
- id: plot_legend_title
  type: string?



steps:
  fairagroUC6:
    run: ../../workflows/fairagroUC6/workflow.cwl
    in:
      trial_id: trial_id
      sensorthingsapi_url: sensorthingsapi_url
      ndvi_file: ndvi_file
      geojson_file: geojson_file
      sowing_date: sowing_date
      harvest_date: harvest_date
      results_csv: results_csv
      visualization_png: visualization_png
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
      # FROST credentials flow: config.yml (gitignored, copied from config-example.yml)
      frost_client_id: frost_client_id
      frost_client_secret: frost_client_secret
      frost_username: frost_username
      frost_password: frost_password
      frost_user_url: frost_user_url
      sensor_icasa_output: sensor_icasa_output
      nasa_data_output: nasa_data_output
      nasa_icasa_output: nasa_icasa_output
      soil_data_output: soil_data_output
      gs_codes: gs_codes
      gs_dates_output: gs_dates_output
      gs_icasa_output: gs_icasa_output
      assembled_icasa_output: assembled_icasa_output
      dataset_dssat_output: dataset_dssat_output
      normalized_soil_output: normalized_soil_output
      initial_layers_output: initial_layers_output
      depth_seq: depth_seq
      paw: paw
      total_n: total_n
      simulations_output_dir: simulations_output_dir
      treatments: treatments
      plot_output_file: plot_output_file
      plot_treatment_labels: stplot_treatment_labels 
      plot_legend_title: plot_legend_title
    out:
      - phenology_results_png
      - phenology_results_csv
      - ndvi_timeseries
      - field_data
      - production_season
      - sensor_data
      - sensor_data_icasa
      - nasa_data
      - nasa_data_icasa
      - soil_data
      - gs_dates
      - gs_dates_icasa
      - assembled_icasa
      - dataset_dssat
      - normalized_soil
      - initial_layers
      - simulations_dir
      - growth_plot


outputs:
  - id: phenology_results_png
    type: File
    outputSource: fairagroUC6/phenology_results_png
  - id: phenology_results_csv
    type: File
    outputSource: fairagroUC6/phenology_results_csv
  - id: ndvi_timeseries
    type: File
    outputSource: fairagroUC6/ndvi_timeseries
  - id: field_data
    type: File
    outputSource: fairagroUC6/field_data
  - id: production_season
    type: File
    outputSource: fairagroUC6/production_season
  - id: sensor_data
    type: File
    outputSource: fairagroUC6/sensor_data
  - id: sensor_data_icasa
    type: File
    outputSource: fairagroUC6/sensor_data_icasa
  - id: nasa_data
    type: File
    outputSource: fairagroUC6/nasa_data
  - id: nasa_data_icasa
    type: File
    outputSource: fairagroUC6/nasa_data_icasa
  - id: soil_data
    type: File
    outputSource: fairagroUC6/soil_data
  - id: gs_dates
    type: File
    outputSource: fairagroUC6/gs_dates
  - id: gs_dates_icasa
    type: File
    outputSource: fairagroUC6/gs_dates_icasa
  - id: assembled_icasa
    type: File
    outputSource: fairagroUC6/assembled_icasa
  - id: dataset_dssat
    type: File
    outputSource: fairagroUC6/dataset_dssat
  - id: normalized_soil
    type: File
    outputSource: fairagroUC6/normalized_soil
  - id: initial_layers
    type: File
    outputSource: fairagroUC6/initial_layers
  - id: simulations_dir
    type: Directory
    outputSource: fairagroUC6/simulations_dir
  - id: growth_plot
    type: File
    outputSource: fairagroUC6/growth_plot
