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
- id: sensor_data_icasa
  type: File
  outputSource: convert-sensor-data-icasa/sensor_data_icasa
- id: nasa_data
  type: File
  outputSource: get-weather-data/nasa_data
- id: nasa_data_icasa
  type: File
  outputSource: convert-nasa-data-icasa/nasa_data_icasa
- id: soil_data
  type: File
  outputSource: get-soil-profile/soil_data
- id: gs_dates
  type: File
  outputSource: lookup-gs-dates/gs_dates
- id: gs_dates_icasa
  type: File
  outputSource: convert-gs-dates-icasa/gs_dates_icasa
- id: assembled_icasa
  type: File
  outputSource: assemble-icasa-dataset/assembled_icasa
- id: dataset_dssat
  type: File
  outputSource: convert-icasa-dssat/dataset_dssat
- id: normalized_soil
  type: File
  outputSource: normalize-soil-profile/normalized_soil
- id: initial_layers
  type: File
  outputSource: calculate-initial-layers/initial_layers
- id: simulations_dir
  type: Directory
  outputSource: run-simulations/simulations_dir
- id: growth_plot
  type: File
  outputSource: plot-results/growth_plot

steps:
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
- id: convert-sensor-data-icasa
  in:
  - id: sensor_data
    source: get-sensor-data/sensor_data
  - id: sensor_icasa_output
    source: sensor_icasa_output
  run: ./csmTools/convert-sensor-data-icasa.cwl
  out:
  - sensor_data_icasa
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
- id: convert-nasa-data-icasa
  in:
  - id: nasa_data
    source: get-weather-data/nasa_data
  - id: nasa_icasa_output
    source: nasa_icasa_output
  run: ./csmTools/convert-nasa-data-icasa.cwl
  out:
  - nasa_data_icasa
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
- id: convert-gs-dates-icasa
  in:
  - id: gs_dates
    source: lookup-gs-dates/gs_dates
  - id: gs_icasa_output
    source: gs_icasa_output
  run: ./csmTools/convert-gs-dates-icasa.cwl
  out:
  - gs_dates_icasa
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
- id: convert-icasa-dssat
  in:
  - id: assembled_icasa
    source: assemble-icasa-dataset/assembled_icasa
  - id: dataset_dssat_output
    source: dataset_dssat_output
  run: ./csmTools/convert-icasa-dssat.cwl
  out:
  - dataset_dssat
- id: normalize-soil-profile
  in:
  - id: dataset_dssat
    source: convert-icasa-dssat/dataset_dssat
  - id: normalized_soil_output
    source: normalized_soil_output
  run: ./csmTools/normalize-soil-profile.cwl
  out:
  - normalized_soil
- id: calculate-initial-layers
  in:
  - id: dataset_dssat
    source: convert-icasa-dssat/dataset_dssat
  - id: initial_layers_output
    source: initial_layers_output
  run: ./csmTools/calculate-initial-layers.cwl
  out:
  - initial_layers
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
    source: simulations_output_dir
  run: ./csmTools/run-simulations.cwl
  out:
  - simulations_dir
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
