#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Converts raw NASA POWER weather data (output of get-weather-data) from
  'nasa-power' format to ICASA format using convert_dataset.
  Equivalent to: convert_dataset(dataset, input_model="nasa-power",
  output_model="icasa")

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.nasa_data)

inputs:
- id: nasa_data
  type: File
  doc: Raw NASA POWER weather JSON from get-weather-data
  inputBinding:
    prefix: --input
    valueFrom: $(self.basename)
- id: nasa_icasa_output
  type: string
  default: "weather_nasa_icasa.json"
  doc: Output file path for ICASA-formatted NASA weather data
  inputBinding:
    prefix: --output

arguments:
- prefix: --from
  valueFrom: "nasa-power"
- prefix: --to
  valueFrom: "icasa"

outputs:
- id: nasa_data_icasa
  type: File
  outputBinding:
    glob: $(inputs.nasa_icasa_output)

baseCommand:
  - convert-dataset
