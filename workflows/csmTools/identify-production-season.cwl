#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  Identifies cultivation season bounds (start/end dates) from the JSON
  output of the get-field-data step.

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.field_data)

inputs:
- id: field_data
  type: File
  doc: Field data JSON output from get-field-data
  inputBinding:
    prefix: --input
    valueFrom: $(self.basename)
- id: period
  type: string
  default: "cultivation_season"
  doc: "Period type to identify: cultivation_season or growing_season"
  inputBinding:
    prefix: --period
- id: output_format
  type: string
  default: "bounds"
  doc: "Output format: bounds (start/end dates) or full"
  inputBinding:
    prefix: --format
- id: production_season_output
  type: string
  default: "production_season.json"
  doc: Filename for the JSON output with start_date and end_date fields
  inputBinding:
    prefix: --output

outputs:
- id: production_season
  type: File
  outputBinding:
    glob: $(inputs.production_season_output)
- id: start_date
  type: string
  outputBinding:
    glob: $(inputs.production_season_output)
    loadContents: true
    outputEval: |
      ${
        var data = JSON.parse(self[0].contents);
        return data.start_date;
      }
- id: end_date
  type: string
  outputBinding:
    glob: $(inputs.production_season_output)
    loadContents: true
    outputEval: |
      ${
        var data = JSON.parse(self[0].contents);
        return data.end_date;
      }

baseCommand:
  - identify-production-season
