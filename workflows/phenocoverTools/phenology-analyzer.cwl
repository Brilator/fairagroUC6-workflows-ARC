#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: joemureithi/phenocover:latest
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.geojson_file)
      - $(inputs.ndvi_file)

inputs:
- id: ndvi_file
  type: File
  inputBinding:
    prefix: --ndvi-file
- id: geojson_file
  type: File
  inputBinding:
    prefix: --geojson-file
- id: sowing_date
  type: string
  inputBinding:
    prefix: --sowing-date
- id: harvest_date
  type: string
  inputBinding:
    prefix: --harvest-date
- id: results_csv
  type: string
  inputBinding:
    prefix: --results-csv
- id: visualization_png
  type: string
  inputBinding:
    prefix: --visualization-png
 
outputs:
- id: phenology_results_csv
  type: File
  outputBinding:
    glob: $(inputs.results_csv)
- id: phenology_results_png
  type: File
  outputBinding:
    glob: $(inputs.visualization_png)


baseCommand:
- phenology-analyzer
