#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Downloads complementary daily weather data from NASA POWER for the
  full production season. The date range is taken from the
  production_season.json file produced by identify-production-season.
  Used to fill temporal gaps where field sensors were not yet installed.

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  NetworkAccess:
    networkAccess: true
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.season_file)

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
- id: season_file
  type: File
  doc: JSON file from identify-production-season with start_date/end_date fields
  inputBinding:
    prefix: --season-file
    valueFrom: $(self.basename)
- id: nasa_data_output
  type: string
  default: "weather_nasa.json"
  doc: Output file path for raw NASA POWER data
  inputBinding:
    prefix: --output

baseCommand:
  - get-weather-data

outputs:
- id: nasa_data
  type: File
  outputBinding:
    glob: $(inputs.nasa_data_output)
