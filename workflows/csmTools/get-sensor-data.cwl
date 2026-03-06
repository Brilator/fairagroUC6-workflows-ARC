#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Downloads IoT sensor data from a FROST SensorThings API server for a
  given location and date range. The date range is supplied via a
  production_season.json file from the identify-production-season step
  (--season-file). FROST credentials are read from environment variables.

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
- id: radius
  type: float
  default: 50000
  doc: Search radius in meters
  inputBinding:
    prefix: --radius
- id: vars
  type: string
  default: "air_temperature,solar_radiation,volume_of_hydrological_precipitation"
  doc: Comma-separated list of variables to download
  inputBinding:
    prefix: --vars
- id: sensor_data_output
  type: string
  default: "weather_sensor.json"
  doc: Output file path
  inputBinding:
    prefix: --output

# FROST SensorThings API credentials
- id: frost_client_id
  type: string
  default: ""
  doc: FROST API client ID
  inputBinding:
    prefix: --frost-client-id
- id: frost_client_secret
  type: string
  default: ""
  doc: FROST API client secret
  inputBinding:
    prefix: --frost-client-secret
- id: frost_username
  type: string
  default: ""
  doc: FROST API username
  inputBinding:
    prefix: --frost-username
- id: frost_password
  type: string
  default: ""
  doc: FROST API password
  inputBinding:
    prefix: --frost-password
- id: frost_user_url
  type: string
  default: ""
  doc: FROST API server URL
  inputBinding:
    prefix: --frost-user-url

outputs:
- id: sensor_data
  type: File
  outputBinding:
    glob: $(inputs.sensor_data_output)

baseCommand:
  - get-sensor-data
