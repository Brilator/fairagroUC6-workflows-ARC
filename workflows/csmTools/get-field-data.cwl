#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Reads and processes field experiment data from an Excel template, 
  converting it to ICASA-compliant format..

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  InitialWorkDirRequirement:
    listing:
        - $(inputs.template_path)


inputs:
- id: template_path
  type: File
  doc: Path to ICASA template file
  inputBinding:
    prefix: --path
    valueFrom: $(self.basename)
- id: experiment_id
  type: string
  doc: Experiment ID
  inputBinding:
    prefix: --exp-id
- id: headers
  type: string
  default: "long"
  doc: Header format
  inputBinding:
    prefix: --headers
- id: field_data_output
  type: string
  inputBinding:
    prefix: --output

outputs:
- id: field_data
  type: File
  outputBinding:
    glob: $(inputs.field_data_output)


baseCommand: 
  - get-field-data
