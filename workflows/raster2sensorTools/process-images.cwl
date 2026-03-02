#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: joemureithi/raster2sensor:latest
inputs:
- id: config
  type: File
  default: 
    class: File
    location: '../config/raster2sensor_config.yml'
  inputBinding:
    position: 0
    prefix: '--config'

outputs: []
baseCommand:
- process-images
- --dry-run