#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: joemureithi/raster2sensor:latest
  NetworkAccess:
    networkAccess: true
  InlineJavascriptRequirement: {}

inputs:
- id: trial_id
  type: string
  default: "Goetheweg-2024"
  inputBinding:
    prefix: --trial-id
- id: sensorthingsapi_url
  type: string
  default: "https://tuzehez-fairagro.srv.mwn.de/frost/v1.1"
  inputBinding:
    prefix: --sensorthingsapi-url
- id: ndvi_file
  type: string
  default: "ndvi_timeseries.csv"
  inputBinding:
    prefix: --ndvi-file

outputs:
- id: ndvi_timeseries
  type: File
  outputBinding:
    glob: $(inputs.ndvi_file)

baseCommand:
- plots
- fetch-ndvi