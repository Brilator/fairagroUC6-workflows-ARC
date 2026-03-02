#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

inputs:
- id: config
  type: File
  default: 
    class: File
    location: '../config/config.yml'
  inputBinding:
    position: 0
    prefix: '--config'

outputs: []
baseCommand:
- raster2sensor
- process-images
- --dry-run