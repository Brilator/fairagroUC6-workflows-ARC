#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Runs DSSAT crop simulations from DSSAT input files produced by
  build-simulation-files. Stages the FILEX (.WHX), soil (.SOL), and
  weather (.WTH) files in the working directory, then calls the
  run-simulations CLI which invokes the DSSAT CSM binary.
  The locally-built csmtools image (csmtools:latest) contains a patched
  run-simulations handler that automatically copies /root/dssat to a
  writable subdirectory when running as a non-root CWL user, ensuring
  DSSAT can write its working files.
  Output files are written to --output-dir (default: simulations/).

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.filex)
      - $(inputs.soil_file)
      - $(inputs.weather_files)

inputs:
- id: filex
  type: File
  doc: DSSAT experiment file (FILEX, *.WHX) from build-simulation-files
  inputBinding:
    prefix: --filex
    valueFrom: $(self.basename)
- id: soil_file
  type: File
  doc: DSSAT soil file (*.SOL) from build-simulation-files — staged alongside FILEX
- id: weather_files
  type: File[]
  doc: DSSAT weather files (*.WTH, *.CLI) from build-simulation-files — staged alongside FILEX
- id: treatments
  type: string?
  doc: "Comma-separated treatment numbers to run (e.g. '1,2,3'); omit for all"
  inputBinding:
    prefix: --treatments
- id: output_dir
  type: string
  default: "simulations"
  doc: Directory name for DSSAT simulation output files
  inputBinding:
    prefix: --output-dir

baseCommand:
  - run-simulations

outputs:
- id: simulations_dir
  type: Directory
  doc: Directory containing DSSAT output files (PlantGro.OUT, Summary.OUT, etc.)
  outputBinding:
    glob: $(inputs.output_dir)
