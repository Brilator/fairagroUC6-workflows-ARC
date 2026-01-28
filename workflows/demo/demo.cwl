#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

inputs:
- id: geojson
  type: File
  default:
    class: File
    path: ../../data/field_location.geojson

outputs:
- id: results_png
  type: File
  outputSource: phenology-analyzer/phenology_results_png
- id: results_csv
  type: File
  outputSource: phenology-analyzer/phenology_results_csv
- id: ndvi_file
  type: File
  outputSource: fetch-ndvi/ndvi_timeseries

steps:
- id: fetch-ndvi
  in: []
  run: ../raster2sensorTools/fetch-ndvi.cwl
  out:
  - ndvi_timeseries
- id: phenology-analyzer
  in:
  - id: ndvi_file
    source: fetch-ndvi/ndvi_timeseries
  - id: geojson_file
    source: geojson
  run: ../phenocoverTools/phenology-analyzer.cwl
  out:
  - phenology_results_csv
  - phenology_results_png
