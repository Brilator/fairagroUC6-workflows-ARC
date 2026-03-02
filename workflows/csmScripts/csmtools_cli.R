#!/usr/bin/env Rscript
## -----------------------------------------------------------------------------------
## Script name: csmtools_cli.R
## Purpose: Command-line interface for csmTools workflow
## Author: Joseph Gitahi
## Date Created: 2025-12-15
## -----------------------------------------------------------------------------------
## Usage examples:
##   Rscript csmtools_cli.R get-field-data --path template.xlsm --exp-id HWOC2501
##   Rscript csmtools_cli.R identify-production-season --input field_data.json
##   Rscript csmtools_cli.R get-weather-data --lon 10.645 --lat 49.208 --from 2024-01-01 --to 2025-12-31
##   Rscript csmtools_cli.R get-sensor-data --lon 10.645 --lat 49.208 --from 2024-01-01 --to 2025-12-31
##   Rscript csmtools_cli.R get-soil-profile --lon 10.645 --lat 49.208
##   Rscript csmtools_cli.R lookup-gs-dates --input phenology.csv --gs-scale zadok --gs-codes 10,65,87
##   Rscript csmtools_cli.R assemble-dataset --components file1.json file2.json file3.json
##   Rscript csmtools_cli.R convert-dataset --input data.json --from icasa --to dssat
##   Rscript csmtools_cli.R normalize-soil-profile --input dataset.json --depth-seq 5,10,20,30
##   Rscript csmtools_cli.R calculate-initial-layers --input soil.json
##   Rscript csmtools_cli.R build-simulation-files --input dataset.json
##   Rscript csmtools_cli.R run-simulations --filex path/to/file.WHX --treatments 1,3,7
##   Rscript csmtools_cli.R plot-results --dssat-dir ~/dssat --treatments 1,3,7 --output simulations/growth_plot.png
##   Rscript csmtools_cli.R plot-results --dssat-dir ~/dssat --treatments 1,3,7 --output simulations/growth_plot.png --pdf-output simulations/growth_plot.pdf --treatment-labels "0 kg N/ha,147 kg N/ha,180 kg N/ha" --legend-title "Fertilization"
## -----------------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(argparse)
  library(dplyr)
  library(lubridate)
})

# Load csmTools: prefer local source (devtools) when running from the repo,
# fall back to installed package otherwise
.cli_dir <- tryCatch(dirname(normalizePath(sub("^--file=", "",
  commandArgs(trailingOnly = FALSE)[grep("^--file=",
    commandArgs(trailingOnly = FALSE))]))), error = function(e) getwd())
.root_dir <- normalizePath(file.path(.cli_dir, ".."), mustWork = FALSE)

if (file.exists(file.path(.root_dir, "DESCRIPTION")) &&
    file.exists(file.path(.root_dir, "NAMESPACE"))) {
  if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools")
  suppressPackageStartupMessages(devtools::load_all(.root_dir, quiet = TRUE))
} else {
  suppressPackageStartupMessages(library(csmTools))
}

# Create main parser
parser <- ArgumentParser(description = "csmTools - Data integration utilities for crop modeling")

# Add subparsers for different commands
subparsers <- parser$add_subparsers(
  dest = "command",
  help = "Available commands"
)

# Command: get-field-data
get_field_data_parser <- subparsers$add_parser(
  "get-field-data",
  help = "Extract field data from ICASA template (get_field_data)"
)
get_field_data_parser$add_argument("--path", required = TRUE, help = "Path to template file")
get_field_data_parser$add_argument("--exp-id", required = TRUE, help = "Experiment ID")
get_field_data_parser$add_argument("--output", default = "field_data.json", help = "Output file path")
get_field_data_parser$add_argument("--headers", default = "long", choices = c("long", "short"), help = "Header format")

# Command: identify-production-season
identify_parser <- subparsers$add_parser(
  "identify-production-season",
  help = "Identify cultivation season bounds from an ICASA template (identify_production_season)"
)
identify_parser$add_argument("--path", required = TRUE, help = "Path to ICASA template file")
identify_parser$add_argument("--exp-id", required = TRUE, help = "Experiment ID")
identify_parser$add_argument("--period", default = "cultivation_season",
                             choices = c("cultivation_season", "growing_season"),
                             help = "Period type to identify")
identify_parser$add_argument("--output-format", default = "bounds",
                             choices = c("bounds", "full"),
                             help = "Output format: 'bounds' returns start/end dates")

# Command: get-weather-data
get_weather_data_parser <- subparsers$add_parser(
  "get-weather-data",
  help = "Download weather data from NASA POWER (get_weather_data)"
)
get_weather_data_parser$add_argument("--lon", type = "double", required = TRUE, help = "Longitude")
get_weather_data_parser$add_argument("--lat", type = "double", required = TRUE, help = "Latitude")
get_weather_data_parser$add_argument("--from", required = TRUE, help = "Start date (YYYY-MM-DD)")
get_weather_data_parser$add_argument("--to", required = TRUE, help = "End date (YYYY-MM-DD)")
get_weather_data_parser$add_argument("--output", default = "weather_data.json", help = "Output file path")
get_weather_data_parser$add_argument("--source", default = "nasa_power", choices = c("nasa_power"), help = "Weather data source")

# Command: get-sensor-data
get_sensor_data_parser <- subparsers$add_parser(
  "get-sensor-data",
  help = "Download sensor data from FROST server (get_sensor_data)"
)
get_sensor_data_parser$add_argument("--lon", type = "double", required = TRUE, help = "Longitude")
get_sensor_data_parser$add_argument("--lat", type = "double", required = TRUE, help = "Latitude")
get_sensor_data_parser$add_argument("--from", required = TRUE, help = "Start date (YYYY-MM-DD)")
get_sensor_data_parser$add_argument("--to", required = TRUE, help = "End date (YYYY-MM-DD)")
get_sensor_data_parser$add_argument("--radius", type = "double", default = 10, help = "Search radius in meters")
get_sensor_data_parser$add_argument("--output", default = "sensor_data.json", help = "Output file path")
get_sensor_data_parser$add_argument("--vars", default = "air_temperature,solar_radiation,volume_of_hydrological_precipitation",
                                    help = "Comma-separated list of variables")

# Command: get-soil-profile
get_soil_profile_parser <- subparsers$add_parser(
  "get-soil-profile",
  help = "Extract soil profile data from SoilGrids (get_soil_profile)"
)
get_soil_profile_parser$add_argument("--lon", type = "double", required = TRUE, help = "Longitude")
get_soil_profile_parser$add_argument("--lat", type = "double", required = TRUE, help = "Latitude")
get_soil_profile_parser$add_argument("--output", default = "soil_data.json", help = "Output file path")

# Command: lookup-gs-dates
lookup_gs_dates_parser <- subparsers$add_parser(
  "lookup-gs-dates",
  help = "Look up growth stage dates from observed phenology data (lookup_gs_dates)"
)
lookup_gs_dates_parser$add_argument("--input", required = TRUE, help = "Path to phenology CSV or JSON file")
lookup_gs_dates_parser$add_argument("--gs-scale", default = "zadok", help = "Growth stage scale (e.g., zadok)")
lookup_gs_dates_parser$add_argument("--gs-codes", required = TRUE,
                                    help = "Comma-separated growth stage codes (e.g., 10,65,87)")
lookup_gs_dates_parser$add_argument("--date-select-rule", default = "median",
                                    choices = c("median", "mean", "first", "last"),
                                    help = "Rule for selecting a representative date per growth stage")
lookup_gs_dates_parser$add_argument("--output", default = "gs_dates.json", help = "Output file path")

# Command: assemble-dataset
assemble_dataset_parser <- subparsers$add_parser(
  "assemble-dataset",
  help = "Assemble dataset from multiple components (assemble_dataset)"
)
assemble_dataset_parser$add_argument("--components", nargs = "+", required = TRUE, help = "List of component files")
assemble_dataset_parser$add_argument("--output", default = "assembled_data.json", help = "Output file path")
assemble_dataset_parser$add_argument("--action", default = "merge_properties",
                                     choices = c("merge_properties", "append_rows", "replace_section"),
                                     help = "Assembly action")

# Command: convert-dataset
convert_dataset_parser <- subparsers$add_parser(
  "convert-dataset",
  help = "Convert dataset between different formats (convert_dataset)"
)
convert_dataset_parser$add_argument("--input", required = TRUE, help = "Input file path")
convert_dataset_parser$add_argument("--from", required = TRUE, choices = c("user", "icasa", "nasa-power", "bonares"),
                                    help = "Input model format")
convert_dataset_parser$add_argument("--to", required = TRUE, choices = c("icasa", "dssat"),
                                    help = "Output model format")
convert_dataset_parser$add_argument("--output", default = "converted_data.json", help = "Output file path")

# Command: normalize-soil-profile
normalize_soil_profile_parser <- subparsers$add_parser(
  "normalize-soil-profile",
  help = "Normalize soil profile to a standard depth sequence (normalize_soil_profile)"
)
normalize_soil_profile_parser$add_argument("--input", required = TRUE,
                                           help = "Path to DSSAT dataset JSON containing a SOIL section")
normalize_soil_profile_parser$add_argument("--depth-seq",
                                           default = "5,10,20,30,40,50,60,70,90,110,130,150,170,190,210",
                                           help = "Comma-separated target depth sequence in cm")
normalize_soil_profile_parser$add_argument("--method", default = "linear",
                                           choices = c("linear", "spline"),
                                           help = "Interpolation method")
normalize_soil_profile_parser$add_argument("--output", default = "normalized_soil.json", help = "Output file path")

# Command: calculate-initial-layers
calculate_initial_layers_parser <- subparsers$add_parser(
  "calculate-initial-layers",
  help = "Calculate initial soil water and nitrogen conditions per layer (calculate_initial_layers)"
)
calculate_initial_layers_parser$add_argument("--input", required = TRUE,
                                             help = "Path to DSSAT dataset JSON with a SOIL section")
calculate_initial_layers_parser$add_argument("--paw", type = "double", default = 100,
                                             help = "Percent available water (0-100)")
calculate_initial_layers_parser$add_argument("--total-n", type = "double", default = 50,
                                             help = "Total soil nitrogen in kg/ha")
calculate_initial_layers_parser$add_argument("--output", default = "initial_layers.json", help = "Output file path")

# Command: build-simulation-files
build_simulation_files_parser <- subparsers$add_parser(
  "build-simulation-files",
  help = "Build DSSAT simulation input files (build_simulation_files)"
)
build_simulation_files_parser$add_argument("--input", required = TRUE, help = "Input DSSAT dataset (JSON)")
build_simulation_files_parser$add_argument("--write-dssat-dir", action = "store_true",
                                           help = "Write files to DSSAT directory")
build_simulation_files_parser$add_argument("--depth-seq",
  default = "5,10,20,30,40,50,60,70,90,110,130,150,170,190,210",
  help = "Comma-separated target depth sequence (cm) for soil normalization")
build_simulation_files_parser$add_argument("--method", default = "linear",
  choices = c("linear", "spline"),
  help = "Interpolation method for soil normalization")
build_simulation_files_parser$add_argument("--paw", type = "double", default = 100,
  help = "Percent available water for initial conditions (0-100)")
build_simulation_files_parser$add_argument("--total-n", type = "double", default = 50,
  help = "Total soil nitrogen in kg/ha for initial conditions")

# Command: run-simulations
run_simulations_parser <- subparsers$add_parser(
  "run-simulations",
  help = "Run DSSAT crop simulations (run_simulations)"
)
run_simulations_parser$add_argument("--filex", required = TRUE, help = "Path to DSSAT filex")
run_simulations_parser$add_argument("--treatments", help = "Comma-separated treatment numbers (e.g., 1,3,7)")
run_simulations_parser$add_argument("--dssat-dir", help = "DSSAT installation directory")
run_simulations_parser$add_argument("--output-dir", default = "./simulations", help = "Output directory")

# Command: plot-results
plot_results_parser <- subparsers$add_parser(
  "plot-results",
  help = "Plot simulated crop growth against observed harvest data (ggplot2)"
)
plot_results_parser$add_argument("--dssat-dir",
  default = file.path(Sys.getenv("HOME"), "dssat"),
  help = "Directory containing DSSAT output files (PlantGro.OUT, Summary.OUT)")
plot_results_parser$add_argument("--treatments",
  help = "Comma-separated treatment numbers to plot (default: all)")
plot_results_parser$add_argument("--output", default = "simulations/growth_plot.png",
  help = "Output plot file path (.png, .pdf, or .svg)")
plot_results_parser$add_argument("--width", type = "double", default = 10,
  help = "Plot width in inches (default: 10)")
plot_results_parser$add_argument("--height", type = "double", default = 6,
  help = "Plot height in inches (default: 6)")
plot_results_parser$add_argument("--dpi", type = "integer", default = 150,
  help = "Plot resolution in DPI (default: 150)")
plot_results_parser$add_argument("--pdf-output", default = NULL,
  help = "Optional path to also save a vector PDF copy of the plot (e.g. simulations/growth_plot.pdf)")
plot_results_parser$add_argument("--treatment-labels", default = NULL,
  help = "Optional comma-separated labels for each treatment in legend order (e.g. '0 kg N/ha,147 kg N/ha,180 kg N/ha')")
plot_results_parser$add_argument("--legend-title", default = "Treatment",
  help = "Legend title for the colour scale (default: 'Treatment')")

# Parse arguments
args <- parser$parse_args()

# Execute command
execute_command <- function(args) {

  if (is.null(args$command)) {
    parser$print_help()
    quit(status = 1)
  }

  tryCatch({

    switch(args$command,

           # get_field_data
           "get-field-data" = {
             message("Extracting field data from: ", args$path)
             data <- get_field_data(
               path = args$path,
               exp_id = args$exp_id,
               headers = args$headers,
               keep_null_events = FALSE,
               output_path = args$output
             )
             message("✓ Field data saved to: ", args$output)
           },

           # identify_production_season
           "identify-production-season" = {
             message("Identifying production season from template: ", args$path)
             field_data <- get_field_data(
               path = args$path,
               exp_id = args$exp_id,
               headers = "long",
               keep_null_events = FALSE
             )
             mngt_tables <- field_data[!names(field_data) %in% c("GENERAL", "PERSONS", "INSTITUTIONS")]
             bounds <- identify_production_season(
               mngt_tables,
               period = args$period,
               output = args$output_format
             )
             message("Season bounds:")
             print(bounds)
           },

           # get_weather_data
           "get-weather-data" = {
             message("Downloading weather data from NASA POWER...")
             data <- get_weather_data(
               lon = args$lon,
               lat = args$lat,
               pars = c("air_temperature", "precipitation", "solar_radiation"),
               res = "daily",
               from = args$from,
               to = args$to,
               src = args$source,
               output_path = args$output
             )
             message("✓ Weather data saved to: ", args$output)
           },

           # get_sensor_data
           "get-sensor-data" = {
             frost_creds <- list(
               url = "https://keycloak.hef.tum.de/realms/master/protocol/openid-connect/token",
               client_id = Sys.getenv("FROST_CLIENT_ID"),
               client_secret = Sys.getenv("FROST_CLIENT_SECRET"),
               username = Sys.getenv("FROST_USERNAME"),
               password = Sys.getenv("FROST_PASSWORD")
             )
             if (any(sapply(frost_creds, function(x) x == ""))) {
               stop("FROST credentials not set. Please set environment variables in .Renviron")
             }
             message("Downloading sensor data from FROST server...")
             vars <- strsplit(args$vars, ",")[[1]]
             data <- get_sensor_data(
               url = Sys.getenv("FROST_USER_URL"),
               creds = frost_creds,
               var = vars,
               lon = args$lon,
               lat = args$lat,
               radius = args$radius,
               from = args$from,
               to = args$to,
               output_path = args$output
             )
             message("✓ Sensor data saved to: ", args$output)
           },

           # get_soil_profile
           "get-soil-profile" = {
             message("Extracting soil profile from SoilGrids...")
             data <- get_soil_profile(
               lon = args$lon,
               lat = args$lat,
               dir = tempdir(),
               output_path = args$output
             )
             message("✓ Soil profile saved to: ", args$output)
           },

           # lookup_gs_dates
           "lookup-gs-dates" = {
             message("Looking up growth stage dates from: ", args$input)
             gs_codes <- as.integer(strsplit(args$gs_codes, ",")[[1]])
             data <- lookup_gs_dates(
               data = args$input,
               gs_scale = args$gs_scale,
               gs_codes = gs_codes,
               date_select_rule = args$date_select_rule,
               output_path = args$output
             )
             message("✓ Growth stage dates saved to: ", args$output)
           },

           # assemble_dataset
           "assemble-dataset" = {
             message("Assembling dataset from ", length(args$components), " components...")
             data <- assemble_dataset(
               components = args$components,
               keep_all = TRUE,
               action = args$action,
               output_path = args$output
             )
             message("✓ Assembled dataset saved to: ", args$output)
           },

           # convert_dataset
           "convert-dataset" = {
             message("Converting dataset from ", args$from, " to ", args$to, "...")
             data <- convert_dataset(
               dataset = args$input,
               input_model = args$from,
               output_model = args$to,
               output_path = args$output
             )
             message("✓ Converted dataset saved to: ", args$output)
           },

           # normalize_soil_profile
           "normalize-soil-profile" = {
             message("Normalizing soil profile from: ", args$input)
             dataset <- csmTools:::resolve_input(args$input)
             depth_seq <- as.numeric(strsplit(args$depth_seq, ",")[[1]])
             result <- normalize_soil_profile(
               data = dataset$SOIL,
               depth_seq = depth_seq,
               method = args$method
             )
             jsonlite::write_json(result, args$output, auto_unbox = TRUE, pretty = TRUE)
             message("✓ Normalized soil profile saved to: ", args$output)
           },

           # calculate_initial_layers
           "calculate-initial-layers" = {
             message("Calculating initial soil layers from: ", args$input)
             dataset <- csmTools:::resolve_input(args$input)
             init_layers <- calculate_initial_layers(
               soil_profile = dataset$SOIL,
               percent_available_water = args$paw,
               total_n_kgha = args$total_n
             )
             jsonlite::write_json(init_layers, args$output, auto_unbox = TRUE, pretty = TRUE)
             message("✓ Initial layers saved to: ", args$output)
           },

           # build_simulation_files
           "build-simulation-files" = {
             message("Building DSSAT input files from: ", args$input)
             # Set DSSAT executable path (cross-platform) if not already set
             if (.Platform$OS.type == "unix" && Sys.getenv("DSSAT_CSM") == "") {
               Sys.setenv(DSSAT_CSM = file.path(Sys.getenv("HOME"), "dssat", "dscsm048"))
             }
             dataset <- csmTools:::resolve_input(args$input)

             # Capture SOL file name and soil ID before normalization may strip attributes
             .written_sol_name <- attr(dataset$SOIL, "file_name")   # e.g. "LL.SOL"
             .id_soil          <- dataset$MANAGEMENT$FIELDS$ID_SOIL[1]  # e.g. "DE02114767"

             # Normalize soil profile in-memory
             message("Normalizing soil profile (depth-seq: ", args$depth_seq, ")...")
             depth_seq <- as.numeric(strsplit(args$depth_seq, ",")[[1]])
             soil_norm <- normalize_soil_profile(
               data = dataset$SOIL,
               depth_seq = depth_seq,
               method = args$method
             )
             dataset$SOIL <- soil_norm$SOIL
             dataset$SOIL$SRGF <- 1
             # Restore file_name attribute (normalize_soil_profile may strip it)
             if (!is.null(.written_sol_name))
               attr(dataset$SOIL, "file_name") <- .written_sol_name

             # Calculate initial soil conditions in-memory
             message("Calculating initial soil layers (PAW: ", args$paw, "%, N: ", args$total_n, " kg/ha)...")
             init_layers <- calculate_initial_layers(
               soil_profile = dataset$SOIL,
               percent_available_water = args$paw,
               total_n_kgha = args$total_n
             )
             dataset$MANAGEMENT$INITIAL_CONDITIONS$ICBL <- list(init_layers$INITIAL_CONDITIONS$ICBL)
             dataset$MANAGEMENT$INITIAL_CONDITIONS$SH2O <- list(init_layers$INITIAL_CONDITIONS$SH2O)
             dataset$MANAGEMENT$INITIAL_CONDITIONS$SNH4 <- list(init_layers$INITIAL_CONDITIONS$SNH4)
             dataset$MANAGEMENT$INITIAL_CONDITIONS$SNO3 <- list(init_layers$INITIAL_CONDITIONS$SNO3)

             result <- build_simulation_files(
               dataset = dataset,
               sol_append = FALSE,
               write = TRUE,
               write_in_dssat_dir = args$write_dssat_dir,
               control_config = list(
                 RSEED = 1243,
                 SMODEL = "WHAPS",  # APSIM wheat (cultivar LL0001 is in WHAPS048.CUL)
                 WATER = "Y",
                 NITRO = "Y",
                 TILL  = "Y",
                 PHOTO = "C",
                 MESEV = "S",
                 FERTI = "R",
                 HARVS = "M",
                 GROUT = "Y",
                 VBOSE = "Y"
               )
             )

             # DSSAT names the SOL file from INST_NAME prefix (e.g., "LL.SOL"),
             # but the WHX ID_SOIL is the soil profile EXP_ID (e.g., "DE02114767")
             # which leads DSSAT to look for "DE.SOL". Copy to bridge the mismatch.
             tryCatch({
               dssat_soil_dir <- file.path(dirname(Sys.getenv("DSSAT_CSM")), "Soil")
               expected_sol_name <- paste0(toupper(substr(trimws(.id_soil), 1, 2)), ".SOL")
               if (!is.null(.written_sol_name) && !identical(expected_sol_name, .written_sol_name)) {
                 written_sol_path  <- file.path(dssat_soil_dir, .written_sol_name)
                 expected_sol_path <- file.path(dssat_soil_dir, expected_sol_name)
                 if (file.exists(written_sol_path)) {
                   file.copy(written_sol_path, expected_sol_path, overwrite = TRUE)
                   message("Copied soil file: ", .written_sol_name, " → ", expected_sol_name)
                 }
               }
             }, error = function(e) {
               message("Note: could not align soil file name: ", e$message)
             })
             # Ensure cultivar is present in the DSSAT genotype CUL file.
             # DSSAT requires the cultivar coefficients (VSEN, PPSEN, …) to be in the
             # model-specific CUL file. They are not stored in the csmTools dataset JSON,
             # so we look them up in the bundled DSSAT48.INP reference file and inject
             # the entry if it is not already in the installed CUL file.
             tryCatch({
               dssat_dir  <- dirname(Sys.getenv("DSSAT_CSM"))
               cul_file   <- file.path(dssat_dir, "Genotype", "WHAPS048.CUL")
               if (file.exists(cul_file)) {
                 cul_ingeno <- dataset$MANAGEMENT$CULTIVARS$INGENO[1]
                 cul_tbl    <- DSSAT::read_cul(cul_file)
                 if (!cul_ingeno %in% cul_tbl$`VAR#`) {
                   # Find the *CULTIVAR section in the bundled INP reference file
                   inp_path <- system.file("examples/sciwin/DSSAT48.INP", package = "csmTools")
                   if (nchar(inp_path) > 0 && file.exists(inp_path)) {
                     inp_lines   <- readLines(inp_path, warn = FALSE)
                     cv_sec_idx  <- which(trimws(inp_lines) == "*CULTIVAR")
                     if (length(cv_sec_idx) > 0) {
                       cv_block <- inp_lines[(cv_sec_idx[1] + 1):length(inp_lines)]
                       cv_block <- cv_block[nchar(trimws(cv_block)) > 0]
                       cv_match <- cv_block[grepl(paste0("^\\s*", cul_ingeno, "\\b"), cv_block)]
                       if (length(cv_match) > 0) {
                         # Format: INGENO  NAME...  ECONO  VSEN PPSEN P1 P5 PHINT  GRNO MXFIL STMMX SLAP1
                         parts   <- strsplit(trimws(cv_match[1]), "\\s+")[[1]]
                         n       <- length(parts)   # e.g. 13 for "LL0001 SU Mangold IB0001 ..."
                         cv_gpars <- as.numeric(parts[(n - 3):n])          # last 4
                         cv_ppars <- as.numeric(parts[(n - 8):(n - 4)])    # 5 before gpars
                         cv_ecode <- parts[n - 9]                           # ecotype code
                         cv_name  <- paste(parts[2:(n - 10)], collapse = " ")  # name words
                         cul_tbl_new <- add_cultivar(
                           cul   = cul_tbl,
                           ccode = cul_ingeno,
                           cname = cv_name,
                           ecode = cv_ecode,
                           ppars = cv_ppars,
                           gpars = cv_gpars
                         )
                         DSSAT::write_cul(cul_tbl_new, file_name = cul_file)
                         message("Added cultivar ", cul_ingeno, " (", cv_name,
                                 ") to ", basename(cul_file))
                       } else {
                         warning("Cultivar ", cul_ingeno,
                                 " not found in DSSAT48.INP — ensure it exists in ", cul_file)
                       }
                     }
                   }
                 } else {
                   message("Cultivar ", cul_ingeno, " already present in ", basename(cul_file))
                 }
               }
             }, error = function(e) {
               message("Note: could not ensure cultivar in CUL file: ", e$message)
             })

             message("✓ DSSAT input files created")
           },

           # run_simulations
           "run-simulations" = {
             message("Running DSSAT simulation...")
             # Set DSSAT executable path (cross-platform) if not already set
             if (.Platform$OS.type == "unix" && Sys.getenv("DSSAT_CSM") == "") {
               Sys.setenv(DSSAT_CSM = file.path(Sys.getenv("HOME"), "dssat", "dscsm048"))
             }
             treatments <- if (!is.null(args$treatments)) {
               as.integer(strsplit(args$treatments, ",")[[1]])
             } else {
               NULL
             }
             sims <- run_simulations(
               filex_path = args$filex,
               treatments = treatments,
               framework = "dssat",
               dssat_dir = args$dssat_dir,
               sim_dir = args$output_dir
             )
             message("✓ Simulation complete. Results in: ", args$output_dir)
             if (!is.null(sims$Summary)) {
               message("\nSimulation Summary:")
               print(sims$Summary %>% select(TRNO, HWAM, MDAT, HDAT))
             }
           },

           # plot_results
           "plot-results" = {
             suppressPackageStartupMessages(library(ggplot2))

             plantgro_path <- file.path(args$dssat_dir, "PlantGro.OUT")
             summary_path  <- file.path(args$dssat_dir, "Summary.OUT")

             if (!file.exists(plantgro_path))
               stop("PlantGro.OUT not found in: ", args$dssat_dir)
             if (!file.exists(summary_path))
               stop("Summary.OUT not found in: ", args$dssat_dir)

             message("Reading simulation output from: ", args$dssat_dir)
             sim_growth  <- DSSAT::read_output(plantgro_path)
             obs_summary <- DSSAT::read_output(summary_path)

             treatments <- if (!is.null(args$treatments)) {
               as.integer(strsplit(args$treatments, ",")[[1]])
             } else {
               unique(sim_growth$TRNO)
             }

             sim_growth  <- sim_growth  %>% filter(TRNO %in% treatments) %>%
               mutate(TRNO = as.factor(TRNO))
             obs_summary <- obs_summary %>% filter(TRNO %in% treatments) %>%
               mutate(TRNO = as.factor(TRNO))

             trt_levels <- as.character(sort(treatments))

             # Optional custom legend labels (e.g. fertilization rates)
             lbl_map <- if (!is.null(args$treatment_labels)) {
               lbl_vec <- trimws(strsplit(args$treatment_labels, ",")[[1]])
               setNames(lbl_vec, trt_levels)
             } else {
               setNames(trt_levels, trt_levels)
             }

             # Default palette matching the R workflow script's colours
             default_colours <- c("#999999", "#E18727", "#BC3C29",
                                   "#0072B5", "#20854E", "#7876B1")
             colour_vals <- setNames(
               default_colours[seq_along(trt_levels)],
               trt_levels
             )

             plot_growth <- ggplot(sim_growth, aes(x = DATE, y = GWAD)) +
               geom_line(aes(group = TRNO, colour = TRNO, linewidth = "Simulated")) +
               geom_point(
                 data = obs_summary,
                 aes(x = HDAT, y = HWAM, colour = TRNO, size = "Observed"),
                 shape = 20
               ) +
               scale_colour_manual(
                 name   = args$legend_title,
                 breaks = trt_levels,
                 labels = lbl_map[trt_levels],
                 values = colour_vals
               ) +
               scale_size_manual(
                 values = c(Simulated = 1, Observed = 2),
                 limits = c("Simulated", "Observed")
               ) +
               scale_linewidth_manual(
                 values = c(Simulated = 1, Observed = 2),
                 limits = c("Simulated", "Observed")
               ) +
               guides(
                 size = guide_legend(
                   override.aes = list(
                     linetype = c("solid", "blank"),
                     shape    = c(NA, 16)
                   )
                 )
               ) +
               labs(size = NULL, linewidth = NULL,
                    title = "Simulated crop growth vs. observed harvest",
                    x = "Date", y = "Yield (kg/ha)") +
               theme_bw() +
               theme(
                 legend.text  = element_text(size = 8),
                 legend.title = element_text(size = 8),
                 axis.title.x = element_text(size = 10),
                 axis.title.y = element_text(size = 10),
                 axis.text    = element_text(size = 9, colour = "black")
               )

             dir.create(dirname(normalizePath(args$output, mustWork = FALSE)),
                        recursive = TRUE, showWarnings = FALSE)
             ggsave(args$output, plot = plot_growth,
                    width = args$width, height = args$height, dpi = args$dpi)
             message("✓ Plot saved to: ", args$output)

             # Optionally save a vector PDF copy (explicit ggsave, not the
             # incidental Rplots.pdf that Rscript writes to cwd when print() is
             # called without an open graphics device)
             if (!is.null(args$pdf_output)) {
               dir.create(dirname(normalizePath(args$pdf_output, mustWork = FALSE)),
                          recursive = TRUE, showWarnings = FALSE)
               ggsave(args$pdf_output, plot = plot_growth,
                      width = args$width, height = args$height)
               message("✓ PDF plot saved to: ", args$pdf_output)
             }
           },

           {
             message("Unknown command: ", args$command)
             parser$print_help()
             quit(status = 1)
           }
    )

    message("\n✓ Command completed successfully")

  }, error = function(e) {
    message("\n✗ Error: ", e$message)
    quit(status = 1)
  })
}

# Run
execute_command(args)
