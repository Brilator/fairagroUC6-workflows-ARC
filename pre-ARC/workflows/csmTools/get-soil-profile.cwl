#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Extracts a soil profile from the SoilGrids Global 10-km DSSAT dataset
  published on Harvard Dataverse (https://doi.org/10.7910/DVN/1PEEY0).
  The full dataset is downloaded to a temporary directory inside the
  container; the profile closest to the supplied coordinates is then
  extracted and written to the output file in ICASA-compatible JSON format.
  No conversion step is required because SoilGrids profiles are already in
  DSSAT-ready format.

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  NetworkAccess:
    networkAccess: true

inputs:
- id: lon
  type: float
  doc: Longitude of the field location
  inputBinding:
    prefix: --lon
- id: lat
  type: float
  doc: Latitude of the field location
  inputBinding:
    prefix: --lat
- id: soil_data_output
  type: string
  default: "soil_data.json"
  doc: Output file name for the extracted soil profile (ICASA JSON)
  inputBinding:
    prefix: --output

baseCommand:
  - get-soil-profile

outputs:
- id: soil_data
  type: File
  outputBinding:
    glob: $(inputs.soil_data_output)
