#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull: joemureithi/raster2sensor:latest
  NetworkAccess:
    networkAccess: true
  

inputs:
- id: trial_id
  type: string
  inputBinding:
    prefix: --trial-id
- id: sensorthingsapi_url
  type: string
  inputBinding:
    prefix: --sensorthingsapi-url
- id: ndvi_file
  type: string
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