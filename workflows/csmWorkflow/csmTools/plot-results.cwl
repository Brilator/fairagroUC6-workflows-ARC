#!/usr/bin/env cwl-runner
# ---------------------------------------------------------------------------
# plot-results.cwl
#
# Reads DSSAT simulation output files (PlantGro.OUT, Summary.OUT) from a
# directory and produces a ggplot2 PNG showing simulated crop growth vs.
# observed harvest points, one line per treatment.
#
# Inputs
#   simulations_dir   – Directory containing DSSAT .OUT files
#   output_file       – Output plot filename (default: growth_plot.png)
#   treatments        – Optional comma-separated treatment numbers (default: all)
#   width / height    – Plot dimensions in inches (default: 10 × 6)
#   dpi               – Resolution (default: 150)
#   treatment_labels  – Optional comma-separated legend labels
#   legend_title      – Legend colour scale title (default: "Treatment")
#   pdf_output        – Optional filename for an additional PDF copy
# ---------------------------------------------------------------------------
cwlVersion: v1.2
class: CommandLineTool

doc: |
  Plot DSSAT simulated crop growth vs. observed harvest data using ggplot2.
  Reads PlantGro.OUT (daily biomass) and Summary.OUT (harvest yield) from
  the supplied simulations directory and writes a PNG (and optionally a PDF).

requirements:
  DockerRequirement:
    dockerPull: joemureithi/csmtools-cli:latest
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing:
      - $(inputs.simulations_dir)

baseCommand: [plot-results]

inputs:
  - id: simulations_dir
    type: Directory
    doc: "Directory containing DSSAT .OUT files (PlantGro.OUT, Summary.OUT, …)"
    inputBinding:
      prefix: --dssat-dir

  - id: output_file
    type: string
    default: "growth_plot.png"
    doc: "Output PNG filename written to the staging directory"
    inputBinding:
      prefix: --output

  - id: treatments
    type: string?
    doc: "Comma-separated treatment numbers to include, e.g. '1,3,7' (default: all)"
    inputBinding:
      prefix: --treatments

  - id: width
    type: double?
    doc: "Plot width in inches (default: 10)"
    inputBinding:
      prefix: --width

  - id: height
    type: double?
    doc: "Plot height in inches (default: 6)"
    inputBinding:
      prefix: --height

  - id: dpi
    type: int?
    doc: "Plot resolution in DPI (default: 150)"
    inputBinding:
      prefix: --dpi

  - id: treatment_labels
    type: string?
    doc: "Comma-separated legend labels in treatment order, e.g. '0 kg N/ha,147 kg N/ha'"
    inputBinding:
      prefix: --treatment-labels

  - id: legend_title
    type: string?
    doc: "Legend colour-scale title (default: 'Treatment')"
    inputBinding:
      prefix: --legend-title

  - id: pdf_output
    type: string?
    doc: "Optional additional PDF filename (vector copy)"
    inputBinding:
      prefix: --pdf-output

outputs:
  - id: growth_plot
    type: File
    doc: "PNG plot of simulated crop growth vs. observed harvest yield"
    outputBinding:
      glob: $(inputs.output_file)

  - id: growth_plot_pdf
    type: File?
    doc: "Optional PDF vector copy of the plot"
    outputBinding:
      glob: $(inputs.pdf_output)
