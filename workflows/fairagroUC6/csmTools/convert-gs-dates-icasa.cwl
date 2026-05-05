#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Converts growth stage dates (output of lookup-gs-dates) from the generic
  'user' format to ICASA-compliant JSON using convert-dataset.
  The --from and --to flags are hardcoded as 'user' and 'icasa' respectively.

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.gs_dates)

inputs:
- id: gs_dates
  type: File
  doc: Growth stage dates JSON file from lookup-gs-dates
  inputBinding:
    prefix: --input
    valueFrom: $(self.basename)
- id: gs_icasa_output
  type: string
  default: "gs_dates_icasa.json"
  doc: Output file name for the ICASA-formatted growth stage dates
  inputBinding:
    prefix: --output

arguments:
  - prefix: --from
    valueFrom: "user"
  - prefix: --to
    valueFrom: "icasa"

baseCommand:
  - convert-dataset

outputs:
- id: gs_dates_icasa
  type: File
  outputBinding:
    glob: $(inputs.gs_icasa_output)
