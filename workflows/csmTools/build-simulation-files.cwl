#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Builds DSSAT simulation input files from a DSSAT-format dataset JSON.
  Internally normalises the soil profile depth sequence and calculates
  initial soil-water/nitrogen conditions, then writes the full set of
  DSSAT input files (FILEX .WHX, soil .SOL, weather .WTH / .CLI) to the
  working directory.
  Equivalent R call:
    build_simulation_files(dataset = dataset, write = TRUE,
      write_in_dssat_dir = FALSE, control_config = list(SMODEL="WHAPS", ...))

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
- id: depth_seq
  type: string
  default: "5,10,20,30,40,50,60,70,90,110,130,150,170,190,210"
  doc: Comma-separated target depth sequence (cm) for soil normalisation
  inputBinding:
    prefix: --depth-seq
- id: method
  type: string
  default: "linear"
  doc: Interpolation method for soil normalisation (linear or spline)
  inputBinding:
    prefix: --method
- id: paw
  type: double
  default: 100
  doc: Percent available water for initial soil conditions (0-100)
  inputBinding:
    prefix: --paw
- id: total_n
  type: double
  default: 50
  doc: Total soil nitrogen in kg/ha for initial conditions
  inputBinding:
    prefix: --total-n

baseCommand:
  - build-simulation-files

outputs:
- id: filex
  type: File
  doc: DSSAT experiment file (FILEX, *.WHX) — passed to run-simulations
  outputBinding:
    glob: "*.WHX"
- id: soil_file
  type: File
  doc: DSSAT soil file (*.SOL)
  outputBinding:
    glob: "*.SOL"
- id: weather_files
  type: File[]
  doc: DSSAT weather / climate files (*.WTH, *.CLI, etc.)
  outputBinding:
    glob: ["*.WTH", "*.CLI", "*.WND"]
