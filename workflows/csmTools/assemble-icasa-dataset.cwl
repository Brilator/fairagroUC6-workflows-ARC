#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Assembles all ICASA-formatted datasets into a single combined ICASA JSON
  in one step. This replaces the two assemble_dataset calls in the reference
  R script (lines ~170 and ~253):
    1. sensor_icasa + nasa_icasa  → combined weather
    2. combined weather + soil + field_data → full ICASA dataset
  By passing all four components directly to assemble_dataset, the
  intermediate weather assembly is avoided. The --components flag is built
  from the basenames of all staged input files.

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.sensor_icasa)
      - $(inputs.nasa_icasa)
      - $(inputs.soil_data)
      - $(inputs.field_data)
      - $(inputs.gs_dates_icasa)

inputs:
- id: sensor_icasa
  type: File
  doc: ICASA-formatted sensor weather data (output of convert-sensor-data-icasa)
- id: nasa_icasa
  type: File
  doc: ICASA-formatted NASA POWER weather data (output of convert-nasa-data-icasa)
- id: soil_data
  type: File
  doc: ICASA-formatted soil profile (output of get-soil-profile)
- id: field_data
  type: File
  doc: ICASA-formatted field/management data (output of get-field-data)
- id: gs_dates_icasa
  type: File
  doc: ICASA-formatted growth stage dates (output of convert-gs-dates-icasa)
- id: assembled_icasa_output
  type: string
  default: "assembled_icasa.json"
  doc: Output file name for the assembled ICASA dataset
  inputBinding:
    prefix: --output
    position: 20

arguments:
  - valueFrom: "--components"
    position: 10
  - valueFrom: $(inputs.sensor_icasa.basename)
    position: 11
  - valueFrom: $(inputs.nasa_icasa.basename)
    position: 12
  - valueFrom: $(inputs.soil_data.basename)
    position: 13
  - valueFrom: $(inputs.field_data.basename)
    position: 14
  - valueFrom: $(inputs.gs_dates_icasa.basename)
    position: 15

baseCommand:
  - assemble-dataset

outputs:
- id: assembled_icasa
  type: File
  outputBinding:
    glob: $(inputs.assembled_icasa_output)
