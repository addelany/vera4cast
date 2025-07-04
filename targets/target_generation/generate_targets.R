library(tidyverse)
library(RCurl)

## set destination s3 paths
s3 <- arrow::s3_bucket("bio230121-bucket01", endpoint_override = "amnh1.osn.mghpcc.org")
s3$CreateDir("vera4cast/targets/duration=P1D")
s3$CreateDir("vera4cast/targets/duration=PT1H")

s3_daily <- arrow::s3_bucket("bio230121-bucket01/vera4cast/targets/project_id=vera4cast/duration=P1D", endpoint_override = "amnh1.osn.mghpcc.org")
s3_hourly <- arrow::s3_bucket("bio230121-bucket01/vera4cast/targets/project_id=vera4cast/duration=PT1H", endpoint_override = "amnh1.osn.mghpcc.org")

column_names <- c("project_id", "site_id","datetime","duration", "depth_m","variable","observation")

## EXO
print('EXO')
source('targets/target_functions/target_generation_exo_daily.R')
fcr_files <- c("https://pasta.lternet.edu/package/data/eml/edi/271/9/f23d27b67f71c25cb8e6232af739f986",
               "https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-catwalk-data-qaqc/fcre-waterquality_L1.csv")

bvr_files <- c("https://raw.githubusercontent.com/FLARE-forecast/BVRE-data/bvre-platform-data-qaqc/bvre-waterquality_L1.csv",
               "https://pasta.lternet.edu/package/data/eml/edi/725/5/f649de0e8a468922b40dcfa34285055e")

exo_daily <- target_generation_exo_daily(fcr_files, bvr_files)

exo_daily$duration <- 'P1D'
exo_daily$project_id <- 'vera4cast'


### NOTE : RDO DO DATA IS INCLUDED IN THE EXO TARGET GENERATION SCRIPT


## FLUOROPROBE
print('Fluoroprobe')
source('targets/target_functions/target_generation_FluoroProbe.R')
historic_data <- "https://pasta.lternet.edu/package/data/eml/edi/272/9/f246b36c591a888cc70ebc87a5abbcb7"
current_data <- "https://raw.githubusercontent.com/CareyLabVT/Reservoirs/master/Data/DataNotYetUploadedToEDI/Raw_fluoroprobe/fluoroprobe_L1.csv"

fluoro_daily <- target_generation_FluoroProbe(current_file = current_data, historic_file = historic_data)
fluoro_daily$duration <- 'P1D'
fluoro_daily$project_id <- 'vera4cast'


### TEMP STRING
source('targets/target_functions/target_generation_ThermistorTemp_C_daily.R')

#
print('FCR Thermistor')
fcr_latest <- "https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-catwalk-data-qaqc/fcre-waterquality_L1.csv"
fcr_edi <- "https://pasta.lternet.edu/package/data/eml/edi/271/9/f23d27b67f71c25cb8e6232af739f986"

fcr_thermistor_temp_daily <- target_generation_ThermistorTemp_C_daily(current_file = fcr_latest, historic_file = fcr_edi)
fcr_thermistor_temp_daily$duration <- 'P1D'
fcr_thermistor_temp_daily$project_id <- 'vera4cast'

# BVR
print('BVR Thermistor')
bvr_latest <- "https://raw.githubusercontent.com/FLARE-forecast/BVRE-data/bvre-platform-data-qaqc/bvre-waterquality_L1.csv"
bvr_edi <- "https://pasta.lternet.edu/package/data/eml/edi/725/5/f649de0e8a468922b40dcfa34285055e"

bvr_thermistor_temp_daily <- target_generation_ThermistorTemp_C_daily(current_file = bvr_latest, historic_file = bvr_edi)
bvr_thermistor_temp_daily$duration <- 'P1D'
bvr_thermistor_temp_daily$project_id <- 'vera4cast'


#Secchi
print('Secchi')
source('targets/target_functions/target_generation_daily_secchi_m.R')
current = "https://raw.githubusercontent.com/CareyLabVT/Reservoirs/master/Data/DataNotYetUploadedToEDI/Secchi/secchi_L1.csv"
edi = "https://pasta.lternet.edu/package/data/eml/edi/198/13/3ee0ddb9f2183ad4d8c955d50d1b8fba"

secchi_daily <- target_generation_daily_secchi_m(current = current, edi = edi) |>
  filter(site_id %in% c('fcre', 'bvre'))

secchi_daily$duration <- 'P1D'
secchi_daily$project_id <- 'vera4cast'



##Eddy Flux
print( 'Eddy Flux')
source('targets/target_functions/generate_EddyFlux_ghg_targets_function.R')
eddy_flux <- generate_EddyFlux_ghg_targets_function(
flux_current_data_file = "https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-eddyflux-data-qaqc/EddyFlux_streaming_L1.csv",
flux_edi_data_file = "https://pasta.lternet.edu/package/data/eml/edi/1061/4/311d766dd7275d578699380f8996f089",
met_current_data_file = "https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-metstation-data-qaqc/FCRmet_L1.csv",
met_edi_data_file = "https://pasta.lternet.edu/package/data/eml/edi/389/8/d4c74bbb3b86ea293e5c52136347fbb0")

eddy_flux$datetime <- lubridate::as_datetime(eddy_flux$datetime)


## CHEM
print('Chemistry')
source('targets/target_functions/target_generation_chemistry_daily.R')
chem_data <- target_generation_chemistry_daily(current_data_file = NULL,
                                               historic_data_file = 'https://pasta.lternet.edu/package/data/eml/edi/199/12/a33a5283120c56e90ea414e76d5b7ddb')
chem_data$datetime <- lubridate::as_datetime(chem_data$datetime)


## GHG
print('GHG')
source('targets/target_functions/target_generation_ghg_daily.R')
ghg_data <- target_generation_ghg_daily(current_data_file = 'https://raw.githubusercontent.com/CareyLabVT/Reservoirs/master/Data/DataNotYetUploadedToEDI/Raw_GHG/L1_manual_GHG.csv',
                                        edi_data_file = 'https://pasta.lternet.edu/package/data/eml/edi/551/9/98f19e7acae8bea7d127c463b1bb5fbc')
ghg_data$datetime <- lubridate::as_datetime(ghg_data$datetime)


## CTD  - MOM
print('CTD - MOM')
source('targets/target_functions/targets_generation_daily_MOM.R')
historic_file  <- "https://pasta.lternet.edu/package/data/eml/edi/200/13/27ceda6bc7fdec2e7d79a6e4fe16ffdf"
current_file <-  "https://raw.githubusercontent.com/CareyLabVT/Reservoirs/master/Data/DataNotYetUploadedToEDI/Raw_CTD/ctd_L1.csv"

mom_daily_targets <- targets_generation_daily_MOM(current_file = current_file, historic_file = historic_file)

## CTD  - MOM BOUNDS
print('CTD - MOM BOUNDS')
source('targets/target_functions/targets_generation_MOM_bounds_daily.R')
historic_file  <- "https://pasta.lternet.edu/package/data/eml/edi/200/13/27ceda6bc7fdec2e7d79a6e4fe16ffdf"
current_file <-  "https://raw.githubusercontent.com/CareyLabVT/Reservoirs/master/Data/DataNotYetUploadedToEDI/Raw_CTD/ctd_L1.csv"

mom_bounds_daily_targets <- targets_generation_daily_MOM_bounds(current_file = current_file, historic_file = historic_file)

## METALS
print('METALS')
source('targets/target_functions/target_generation_metals_daily.R')
current_file <- 'https://raw.githubusercontent.com/CareyLabVT/Reservoirs/refs/heads/master/Data/DataNotYetUploadedToEDI/Metals_Data/metals_L1.csv'
historic_file <- "https://pasta.lternet.edu/package/data/eml/edi/455/9/9a072c4e4af39f96f60954fc4f7d8be5"

metals_daily_targets <- target_generation_metals_daily(current_data_file = current_file, edi_data_file = historic_file)

## Thermocline Depth
print('Thermocline Depth')
source('targets/target_functions/generate_thermoclineD.R')
fcr_latest <- "https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-catwalk-data-qaqc/fcre-waterquality_L1.csv"
fcr_edi <- "https://pasta.lternet.edu/package/data/eml/edi/271/9/f23d27b67f71c25cb8e6232af739f986"

thermocline_depth <- generate_thermocline_depth(current_file = fcr_latest,
                                                historic_file = fcr_edi)

## Schmidt Stability
print('Schmidt Stability')
source('targets/target_functions/target_generation_SchmidtStability.R')
fcr_files <- c("https://pasta.lternet.edu/package/data/eml/edi/271/9/f23d27b67f71c25cb8e6232af739f986",
               "https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-catwalk-data-qaqc/fcre-waterquality_L1.csv")

schmidt_stability <- generate_schmidt.stability(current_file = fcr_files[2], historic_file = fcr_files[1])


## MIXED BINARY
print('Mixed Binary')
source('targets/target_functions/target_generation_mixed_binary_daily.R')
source('targets/target_functions/target_generation_mixed_binary_hourly.R')

bvr_current <- c("https://raw.githubusercontent.com/FLARE-forecast/BVRE-data/bvre-platform-data-qaqc/bvre-waterquality_L1.csv")
bvr_historic <- c("https://pasta.lternet.edu/package/data/eml/edi/725/5/f649de0e8a468922b40dcfa34285055e")

fcr_current <- "https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-catwalk-data-qaqc/fcre-waterquality_L1.csv"
fcr_historic <- "https://pasta.lternet.edu/package/data/eml/edi/271/9/f23d27b67f71c25cb8e6232af739f986"

mixed_binary_targets_daily <- dplyr::bind_rows(target_generation_mixed_binary_daily(current_file = fcr_current, historic_file = fcr_historic),
                                         target_generation_mixed_binary_daily(current_file = bvr_current, historic_file = bvr_historic))

mixed_binary_targets_hourly <- dplyr::bind_rows(target_generation_mixed_binary_hourly(current_file = fcr_current, historic_file = fcr_historic),
                                         target_generation_mixed_binary_hourly(current_file = bvr_current, historic_file = bvr_historic))

## combine the data and perform final adjustments (depth, etc.)

combined_targets <- bind_rows(exo_daily, fluoro_daily, fcr_thermistor_temp_daily, bvr_thermistor_temp_daily, secchi_daily,
                              mom_daily_targets, thermocline_depth, schmidt_stability, eddy_flux, chem_data, ghg_data, mixed_binary_targets,
                              metals_daily_targets, mom_bounds_daily_targets) |>
  select(all_of(column_names))

combined_targets_deduped <- combined_targets |>
  group_by(datetime, site_id, variable, depth_m) |>
  mutate(obs_deduped = mean(observation, na.rm = TRUE)) |>
  ungroup() |>
  distinct(datetime, site_id, variable, depth_m, .keep_all = TRUE) |>
  select(project_id, site_id, datetime, duration, depth_m, variable, observation)

combined_targets_deduped$project_id <- 'vera4cast'

combined_dup_check <- combined_targets_deduped  %>%
  dplyr::group_by(datetime, site_id, variable, depth_m) %>%
  dplyr::summarise(n = dplyr::n(), .groups = "drop") %>%
  dplyr::filter(n > 1)

if (nrow(combined_dup_check) != 0){
  print('target duplicates found...please fix')
  stop()
}

arrow::write_csv_arrow(combined_targets_deduped, sink = s3_daily$path("daily-insitu-targets.csv.gz"))


# ## HOURLY INSITU (TEMPERATURE)
# source('targets/target_functions/target_generation_ThermistorTemp_C_hourly.R')
#
# #FCR
# print('Hourly Temperature')
# fcr_latest <- "https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-catwalk-data-qaqc/fcre-waterquality_L1.csv"
# fcr_edi <- "https://pasta.lternet.edu/package/data/eml/edi/271/9/f23d27b67f71c25cb8e6232af739f986"
#
# fcr_thermistor_temp_hourly <- target_generation_ThermistorTemp_C_hourly(current_file = fcr_latest, historic_file = fcr_edi)
# fcr_thermistor_temp_hourly$duration <- 'P1D'
# fcr_thermistor_temp_hourly$project_id <- 'vera4cast'
#
#
# # BVR
# print('BVR Thermistor')
# bvr_latest <- "https://raw.githubusercontent.com/FLARE-forecast/BVRE-data/bvre-platform-data-qaqc/bvre-waterquality_L1.csv"
# bvr_edi <- "https://pasta.lternet.edu/package/data/eml/edi/725/5/f649de0e8a468922b40dcfa34285055e"
#
# bvr_thermistor_temp_hourly <- target_generation_ThermistorTemp_C_hourly(current_file = bvr_latest, historic_file = bvr_edi)
# bvr_thermistor_temp_hourly$duration <- 'P1D'
# bvr_thermistor_temp_hourly$project_id <- 'vera4cast'
#
#
# s3_hourly <- arrow::s3_bucket("bio230121-bucket01/vera4cast/targets/project_id=vera4cast/duration=PT1H", endpoint_override = "amnh1.osn.mghpcc.org")
# vera_hourly_thermistor_df <- dplyr::bind_rows(fcr_thermistor_temp_hourly, bvr_thermistor_temp_hourly)
#
# arrow::write_csv_arrow(vera_hourly_thermistor_df, sink = s3_hourly$path("hourly-insitu-targets.csv.gz"))



## INFLOWS
print('Inflows')
source('targets/target_functions/inflow/target_generation_inflows.R')

current_inflow <- 'https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-weir-data-qaqc/FCRWeir_L1.csv'

historic_inflow <- "https://pasta.lternet.edu/package/data/eml/edi/202/13/da4beae4df936f513ac7600d44871c07"

historic_silica <- 'https://pasta.lternet.edu/package/data/eml/edi/542/1/791ec9ca0f1cb9361fa6a03fae8dfc95'

historic_nutrients <- "https://pasta.lternet.edu/package/data/eml/edi/199/12/a33a5283120c56e90ea414e76d5b7ddb"

historic_ghg <- "https://pasta.lternet.edu/package/data/eml/edi/551/9/98f19e7acae8bea7d127c463b1bb5fbc"


inflow_daily <- target_generation_inflows(historic_inflow = historic_inflow,
                                          current_inflow = current_inflow,
                                          historic_nutrients = historic_nutrients,
                                          historic_silica = historic_silica,
                                          historic_ghg = historic_ghg)

inflow_daily <- inflow_daily |> select(column_names)

arrow::write_csv_arrow(inflow_daily, sink = s3_daily$path("daily-inflow-targets.csv.gz"))


# MET TARGETS
print('Met Targets')
current_met <- 'https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-metstation-data-qaqc/FCRmet_L1.csv'
historic_met <- 'https://pasta.lternet.edu/package/data/eml/edi/389/9/62647ecf8525cdfc069b8aaee14c0478'

source('targets/target_functions/meteorology/target_generation_met.R')

met_daily <- target_generation_met(current_met = current_met, historic_met = historic_met, time_interval = 'daily')

met_daily <- met_daily |>
  select(all_of(column_names))

arrow::write_csv_arrow(met_daily, sink = s3_daily$path("daily-met-targets.csv.gz"))

met_hourly <- target_generation_met(current_met = current_met, historic_met = historic_met, time_interval = 'hourly')

met_hourly <- met_hourly |>
  select(all_of(column_names))

arrow::write_csv_arrow(met_hourly, sink = s3_hourly$path("hourly-met-targets.csv.gz"))
