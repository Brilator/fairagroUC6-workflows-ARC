#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Looks up observed growth stage dates from a phenology CSV file produced by
  the phenology-analyzer tool. Growth stage codes follow the Zadok scale by
  default. A representative date is selected per growth stage using the
  specified rule (median by default). The output is a JSON file with the
  matched dates that can be converted to ICASA format in the next step.

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.phenology_csv)

inputs:
- id: phenology_csv
  type: File
  doc: Phenology results CSV file from the phenology-analyzer tool
  inputBinding:
    prefix: --input
    valueFrom: $(self.basename)
- id: gs_scale
  type: string
  default: "zadok"
  doc: Growth stage scale (e.g. zadok)
  inputBinding:
    prefix: --gs-scale
- id: gs_codes
  type: string
  default: "10,65,87"
  doc: Comma-separated Zadok growth stage codes to look up
  inputBinding:
    prefix: --gs-codes
- id: date_select_rule
  type: string
  default: "median"
  doc: Rule for selecting a representative date per GS (median, mean, first, last)
  inputBinding:
    prefix: --date-select-rule
- id: gs_dates_output
  type: string
  default: "gs_dates.json"
  doc: Output file name for the growth stage dates JSON
  inputBinding:
    prefix: --output

baseCommand:
  - lookup-gs-dates

outputs:
- id: gs_dates
  type: File
  outputBinding:
    glob: $(inputs.gs_dates_output)
