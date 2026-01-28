#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
- class: InitialWorkDirRequirement
  listing:
  - entryname: workflows/scripts/main.py
    entry:
      $include: ../scripts/main.py

inputs:
- id: process_images
  type: string
  default: process-images
  inputBinding:
    position: 0
- id: help
  type: boolean
  default: true
  inputBinding:
    prefix: --help

outputs: []
baseCommand:
- python
- workflows/scripts/main.py
