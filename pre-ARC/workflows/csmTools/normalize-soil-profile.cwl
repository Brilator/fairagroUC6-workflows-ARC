#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Normalizes a DSSAT soil profile to a standard depth sequence using
  linear interpolation (or spline). Takes the full DSSAT dataset JSON
  (output of convert-icasa-dssat), reads its SOIL section, and writes
  the normalized soil profile.
  Equivalent to: normalize_soil_profile(data = dataset_dssat$SOIL,
  depth_seq = c(5,10,20,...), method = "linear")

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
  doc: DSSAT-formatted dataset JSON (output of convert-icasa-dssat)
  inputBinding:
    prefix: --input
    valueFrom: $(self.basename)
- id: depth_seq
  type: string
  default: "5,10,20,30,40,50,60,70,90,110,130,150,170,190,210"
  doc: Comma-separated target depth sequence in cm
  inputBinding:
    prefix: --depth-seq
- id: method
  type: string
  default: "linear"
  doc: Interpolation method (linear or spline)
  inputBinding:
    prefix: --method
- id: normalized_soil_output
  type: string
  default: "normalized_soil.json"
  doc: Output file name for the normalized soil profile
  inputBinding:
    prefix: --output

baseCommand:
  - normalize-soil-profile

outputs:
- id: normalized_soil
  type: File
  outputBinding:
    glob: $(inputs.normalized_soil_output)
