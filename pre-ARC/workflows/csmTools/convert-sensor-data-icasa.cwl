#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Converts raw sensor weather data (output of get-sensor-data) from the
  internal 'user' format to ICASA format using convert_dataset.
  Equivalent to: convert_dataset(dataset, input_model="user",
  output_model="icasa", unmatched_code="na")

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.sensor_data)

inputs:
- id: sensor_data
  type: File
  doc: Raw sensor weather JSON from get-sensor-data
  inputBinding:
    prefix: --input
    valueFrom: $(self.basename)
- id: from_format
  type: string
  default: "user"
  doc: Input format (always 'user' for raw sensor data)
  inputBinding:
    prefix: --from
- id: unmatched_code
  type: string
  default: "na"
  doc: Value to use for unmatched fields
  inputBinding:
    prefix: --unmatched-code
- id: sensor_icasa_output
  type: string
  default: "weather_sensor_icasa.json"
  doc: Output file path for ICASA-formatted sensor data
  inputBinding:
    prefix: --output

arguments:
- prefix: --to
  valueFrom: "icasa"

outputs:
- id: sensor_data_icasa
  type: File
  outputBinding:
    glob: $(inputs.sensor_icasa_output)

baseCommand:
  - convert-dataset
