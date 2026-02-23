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
https://savenow.gis.lrg.tum.de/frost/v1.1/Datastreams?%24expand=Observations(%24filter%3Doverlaps(phenomenonTime%2C2024-09-30T22%3A00%3A00.000Z%2F2024-10-01T21%3A59%3A59.000Z)%3B%24orderBy%3DphenomenonTime%20desc%3B%24top%3D1%3B%24select%3Dresult%3B%24expand%3DFeatureOfInterest(%24select%3Dfeature))%2CThing(%24select%3Dproperties%2Faggregation_type)&%24filter=Thing%2Fproperties%2Faggregation_type%20eq%20%27whole_intersection%27%20and%20phenomenonTime%20lt%20now()&%24select=name%2CThing%2CObservations&%24top=10000
steps:
- id: fetch-ndvi
  in: []
  run: ../fetch-ndvi/fetch-ndvi.cwl
  out:
  - ndvi_timeseries
- id: phenology-analyzer
  in:
  - id: ndvi_file
    source: fetch-ndvi/ndvi_timeseries
  - id: geojson_file
    source: geojson
  run: ../phenology-analyzer/phenology-analyzer.cwl
  out:
  - phenology_results_csv
  - phenology_results_png
