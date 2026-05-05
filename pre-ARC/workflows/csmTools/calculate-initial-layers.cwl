#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Calculates initial soil water and nitrogen conditions per depth layer.
  Takes the full DSSAT dataset JSON (output of convert-icasa-dssat), which
  contains the SOIL data in column-oriented tibble format that the R function
  requires. Internally normalises the depth sequence before computing layers.
  Equivalent to: calculate_initial_layers(soil_profile = dataset_dssat$SOIL,
  percent_available_water = 100, total_n_kgha = 50)

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.dataset_dssat)

inputs:
- id: dataset_dssat
  type: File
  doc: Full DSSAT dataset JSON (output of convert-icasa-dssat)
  inputBinding:
    prefix: --input
    valueFrom: $(self.basename)
- id: paw
  type: double
  default: 100
  doc: Percent available water (0-100)
  inputBinding:
    prefix: --paw
- id: total_n
  type: double
  default: 50
  doc: Total soil nitrogen in kg/ha
  inputBinding:
    prefix: --total-n
- id: initial_layers_output
  type: string
  default: "initial_layers.json"
  doc: Output file name for the initial layer conditions
  inputBinding:
    prefix: --output

baseCommand:
  - calculate-initial-layers

outputs:
- id: initial_layers
  type: File
  outputBinding:
    glob: $(inputs.initial_layers_output)
