#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Converts the assembled ICASA dataset (output of assemble-icasa-dataset)
  to DSSAT format using convert_dataset.
  Equivalent to: convert_dataset(dataset, input_model="icasa",
  output_model="dssat")

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  NetworkAccess:
    networkAccess: true
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.assembled_icasa)

inputs:
- id: assembled_icasa
  type: File
  doc: Assembled ICASA dataset (output of assemble-icasa-dataset)
  inputBinding:
    prefix: --input
    valueFrom: $(self.basename)
- id: dataset_dssat_output
  type: string
  default: "dataset_dssat.json"
  doc: Output file name for the DSSAT-formatted dataset
  inputBinding:
    prefix: --output

arguments:
- prefix: --from
  valueFrom: "icasa"
- prefix: --to
  valueFrom: "dssat"

baseCommand:
  - convert-dataset

outputs:
- id: dataset_dssat
  type: File
  outputBinding:
    glob: $(inputs.dataset_dssat_output)
