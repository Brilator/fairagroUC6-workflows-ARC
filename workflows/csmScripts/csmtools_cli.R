#!/usr/bin/env Rscript
## -----------------------------------------------------------------------------------
## Script name: csmtools_cli.R
## Purpose: Command-line interface for csmTools workflow
## Author: Joseph Gitahi
## Date Created: 2025-12-15
## -----------------------------------------------------------------------------------
## Usage examples:
##   Rscript csmtools_cli.R extract-field --path template.xlsm --exp-id HWOC2501
##   Rscript csmtools_cli.R get-weather --lon 10.645 --lat 49.208 --from 2024-01-01 --to 2025-12-31
##   Rscript csmtools_cli.R get-soil --lon 10.645 --lat 49.208
##   Rscript csmtools_cli.R get-sensor --lon 10.645 --lat 49.208 --from 2024-01-01 --to 2025-12-31
##   Rscript csmtools_cli.R assemble --components file1.json file2.json file3.json
##   Rscript csmtools_cli.R convert --input data.json --from icasa --to dssat
##   Rscript csmtools_cli.R simulate --filex path/to/file.WHX --treatments 1,3,7
## -----------------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(csmTools)
  library(argparse)
  library(dplyr)
  library(lubridate)
})

# Create main parser
parser <- ArgumentParser(description = "csmTools - Data integration utilities for crop modeling")

# Add subparsers for different commands
subparsers <- parser$add_subparsers(
  dest = "command",
  help = "Available commands"
)

# Command: extract-field
extract_parser <- subparsers$add_parser(
  "extract-field-data",
  help = "Extract field data from ICASA template"
)
extract_parser$add_argument("--path", required = TRUE, help = "Path to template file")
extract_parser$add_argument("--exp-id", required = TRUE, help = "Experiment ID")
extract_parser$add_argument("--output", default = "field_data.json", help = "Output file path")
extract_parser$add_argument("--headers", default = "long", choices = c("long", "short"), help = "Header format")

# Command: get-weather
weather_parser <- subparsers$add_parser(
  "get-weather",
  help = "Download weather data from NASA POWER"
)
weather_parser$add_argument("--lon", type = "double", required = TRUE, help = "Longitude")
weather_parser$add_argument("--lat", type = "double", required = TRUE, help = "Latitude")
weather_parser$add_argument("--from", required = TRUE, help = "Start date (YYYY-MM-DD)")
weather_parser$add_argument("--to", required = TRUE, help = "End date (YYYY-MM-DD)")
weather_parser$add_argument("--output", default = "weather_data.json", help = "Output file path")
weather_parser$add_argument("--source", default = "nasa_power", choices = c("nasa_power"), help = "Weather data source")

# Command: get-sensor
sensor_parser <- subparsers$add_parser(
  "get-sensor",
  help = "Download sensor data from FROST server"
)
sensor_parser$add_argument("--lon", type = "double", required = TRUE, help = "Longitude")
sensor_parser$add_argument("--lat", type = "double", required = TRUE, help = "Latitude")
sensor_parser$add_argument("--from", required = TRUE, help = "Start date (YYYY-MM-DD)")
sensor_parser$add_argument("--to", required = TRUE, help = "End date (YYYY-MM-DD)")
sensor_parser$add_argument("--radius", type = "double", default = 10, help = "Search radius in meters")
sensor_parser$add_argument("--output", default = "sensor_data.json", help = "Output file path")
sensor_parser$add_argument("--vars", default = "air_temperature,solar_radiation,volume_of_hydrological_precipitation", 
                          help = "Comma-separated list of variables")

# Command: get-soil
soil_parser <- subparsers$add_parser(
  "get-soil",
  help = "Extract soil profile data from SoilGrids"
)
soil_parser$add_argument("--lon", type = "double", required = TRUE, help = "Longitude")
soil_parser$add_argument("--lat", type = "double", required = TRUE, help = "Latitude")
soil_parser$add_argument("--output", default = "soil_data.json", help = "Output file path")

# Command: assemble
assemble_parser <- subparsers$add_parser(
  "assemble",
  help = "Assemble dataset from multiple components"
)
assemble_parser$add_argument("--components", nargs = "+", required = TRUE, help = "List of component files")
assemble_parser$add_argument("--output", default = "assembled_data.json", help = "Output file path")
assemble_parser$add_argument("--action", default = "merge_properties", 
                            choices = c("merge_properties", "append_rows", "replace_section"),
                            help = "Assembly action")

# Command: convert
convert_parser <- subparsers$add_parser(
  "convert",
  help = "Convert dataset between different formats"
)
convert_parser$add_argument("--input", required = TRUE, help = "Input file path")
convert_parser$add_argument("--from", required = TRUE, choices = c("user", "icasa", "nasa-power", "bonares"),
                           help = "Input model format")
convert_parser$add_argument("--to", required = TRUE, choices = c("icasa", "dssat"),
                           help = "Output model format")
convert_parser$add_argument("--output", default = "converted_data.json", help = "Output file path")

# Command: simulate
simulate_parser <- subparsers$add_parser(
  "simulate",
  help = "Run DSSAT crop simulations"
)
simulate_parser$add_argument("--filex", required = TRUE, help = "Path to DSSAT filex")
simulate_parser$add_argument("--treatments", help = "Comma-separated treatment numbers (e.g., 1,3,7)")
simulate_parser$add_argument("--dssat-dir", help = "DSSAT installation directory")
simulate_parser$add_argument("--output-dir", default = "./simulations", help = "Output directory")

# Command: build-inputs
build_parser <- subparsers$add_parser(
  "build-inputs",
  help = "Build DSSAT simulation input files"
)
build_parser$add_argument("--input", required = TRUE, help = "Input DSSAT dataset (JSON)")
build_parser$add_argument("--write-dssat-dir", action = "store_true", 
                         help = "Write files to DSSAT directory")

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
           
           # Extract field data
           "extract-field-data" = {
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
           
           # Get weather data
           "get-weather" = {
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
           
           # Get sensor data
           "get-sensor" = {
             # Load credentials from environment
             frost_creds <- list(
               url = "https://keycloak.hef.tum.de/realms/master/protocol/openid-connect/token",
               client_id = Sys.getenv("FROST_CLIENT_ID"),
               client_secret = Sys.getenv("FROST_CLIENT_SECRET"),
               username = Sys.getenv("FROST_USERNAME"),
               password = Sys.getenv("FROST_PASSWORD")
             )
             
             # Check credentials
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
           
           # Get soil data
           "get-soil" = {
             message("Extracting soil profile from SoilGrids...")
             data <- get_soil_profile(
               lon = args$lon,
               lat = args$lat,
               dir = tempdir(),
               output_path = args$output
             )
             message("✓ Soil profile saved to: ", args$output)
           },
           
           # Assemble dataset
           "assemble" = {
             message("Assembling dataset from ", length(args$components), " components...")
             data <- assemble_dataset(
               components = args$components,
               keep_all = TRUE,
               action = args$action,
               output_path = args$output
             )
             message("✓ Assembled dataset saved to: ", args$output)
           },
           
           # Convert dataset
           "convert" = {
             message("Converting dataset from ", args$from, " to ", args$to, "...")
             data <- convert_dataset(
               dataset = args$input,
               input_model = args$from,
               output_model = args$to,
               output_path = args$output
             )
             message("✓ Converted dataset saved to: ", args$output)
           },
           
           # Build inputs
           "build-inputs" = {
             message("Building DSSAT input files from: ", args$input)
             
             # Load dataset
             dataset <- jsonlite::fromJSON(args$input)
             
             # Build files
             result <- build_simulation_files(
               dataset = dataset,
               sol_append = FALSE,
               write = TRUE,
               write_in_dssat_dir = args$write_dssat_dir,
               control_args = list(
                 RSEED = 1243,
                 WATER = "Y",
                 NITRO = "Y",
                 PHOTO = "C",
                 GROUT = "Y"
               )
             )
             message("✓ DSSAT input files created")
           },
           
           # Run simulation
           "simulate" = {
             message("Running DSSAT simulation...")
             
             # Parse treatments
             treatments <- if (!is.null(args$treatments)) {
               as.integer(strsplit(args$treatments, ",")[[1]])
             } else {
               NULL
             }
             
             # Run simulation
             sims <- run_simulations(
               filex_path = args$filex,
               treatments = treatments,
               framework = "dssat",
               dssat_dir = args$dssat_dir,
               sim_dir = args$output_dir
             )
             
             message("✓ Simulation complete. Results in: ", args$output_dir)
             
             # Print summary
             if (!is.null(sims$SUMMARY)) {
               message("\nSimulation Summary:")
               print(sims$SUMMARY %>% select(TRNO, GWAM, MDAT, HDAT))
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
