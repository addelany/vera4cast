### SCRIPT FOR MAKING LOG SCORE PLOT TO BE USED IN ASLO PRESENTATION
### AUTHOR: AUSTIN DELANY
### CREATED: 2024-05-24

library(tidyverse)
library(lubridate)
library(scales)

config <- yaml::read_yaml("./challenge_configuration.yaml")
s3_scores <- arrow::s3_bucket(paste0(config$scores_bucket), endpoint_override = config$endpoint, anonymous = TRUE)
sites <- readr::read_csv(paste0("./", config$site_table), show_col_types = FALSE)

interest_vars <- c('Bloom_binary','Chla_ugL_mean','DO_mgL_mean','DOsat_percent_mean','fDOM_QSU_mean',
                   'Secchi_m_sample','SpCond_uScm_mean','Temp_C_mean','Turbidid')

df_scores <- arrow::open_dataset(s3_scores) |>
  dplyr::filter(duration == 'P1D',
         project_id == 'vera4cast',
         site_id == 'fcre') |>
  #left_join(sites, by = "site_id") |>
  #dplyr::filter(site_id %in% sites$site_id) |>
  dplyr::mutate(reference_datetime = lubridate::as_datetime(reference_datetime),
         datetime = lubridate::as_datetime(datetime)) |>
  distinct(reference_datetime) |>
  dplyr::collect()

googlesheets4::gs4_deauth()
target_metadata <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1fOWo6zlcWA8F6PmRS9AD6n1pf-dTWSsmGKNpaX3yHNE/edit?usp=sharing")
target_metadata <- target_metadata |>
  rename(variable = `"official" targets name`,
         priority = `priority target`) |>
  filter(duration == 'P1D') |>
  select(variable, class)

met_vars <- c("AirTemp_C_mean", "BP_kPa_mean", "Rain_mm_sum", "ShortwaveRadiationUp_Wm2_mean", "RH_percent_mean", "WindSpeed_ms_mean")

df_var_logs <- df_scores |>
  left_join(target_metadata, by = c('variable')) |>
  mutate(horizon = as.numeric(as.Date(date) - as.Date(reference_datetime)))

## fcr plot
fcr_score_summary <- df_var_logs |>
  filter(horizon < 60,
         site_id == 'fcre',
         !(variable %in% met_vars),
         !is.na(class),
         !(variable %in% c('CH4flux_umolm2s_mean','Bloom_binary_mean',"CO2flux_umolm2s_mean"))) |>
  filter(!is.infinite(logs),
         !is.nan(logs),
         variable != 'Turbidity_FNU_mean') |>
  group_by(variable, horizon, class) |>
  summarise(logs = mean(logs, na.rm=TRUE),
            #crps = mean(crps, na.rm=TRUE),
            .groups = "drop") |>
  tidyr::pivot_longer(cols = c(logs), names_to="metric", values_to="score")

fcr_score_summary |>
  #pivot_longer(cols = c(logs), names_to="metric", values_to="score") |>
  #ggplot(aes(x = horizon, y= score,  col=class)) +
  ggplot(aes(x = horizon, y= score, group = variable, col=class)) +
  geom_line() +
  facet_wrap(~metric, scales='free') +
  scale_y_log10(labels = function(x) format(x, scientific = FALSE)) +
  scale_y_log10(limits = c(0.8,250)) +
  labs(title = 'FCRE') +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme_bw() +
  ggplot2::scale_color_manual(values = c(biological = 'green3',
                                         chemical = 'red',
                                         physical = 'blue'))

## bvre plot
bvr_score_summary <- df_var_logs |>
  filter(!is.infinite(logs),
         !is.nan(logs),
         horizon < 60,
         site_id == 'bvre',
         !(variable %in% met_vars),
         !is.na(class),
         !(variable %in% c('CH4flux_umolm2s_mean','Bloom_binary_mean',"CO2flux_umolm2s_mean"))) |> #,
         #variable != 'Turbidity_FNU_mean') |>
  group_by(variable, horizon, class) |>
  summarise(logs = mean(logs, na.rm=TRUE),
            #crps = mean(crps, na.rm=TRUE),
            .groups = "drop") |>
  tidyr::pivot_longer(cols = c(logs), names_to="metric", values_to="score")

bvr_score_summary |>
  #pivot_longer(cols = c(logs), names_to="metric", values_to="score") |>
  #ggplot(aes(x = horizon, y= score,  col=class)) +
  ggplot(aes(x = horizon, y= score, group = variable, col=class)) +
  geom_line() +
  facet_wrap(~metric, scales='free') +
  scale_y_log10(labels = function(x) format(x, scientific = FALSE)) +
  scale_y_log10(limits = c(0.1,20)) +
  labs(title = 'BVRE') +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme_bw() +
  scale_x_continuous(labels = label_comma()) +
  ggplot2::scale_color_manual(values = c(biological = 'green3',
                                         chemical = 'red',
                                         physical = 'blue'))

################################

bio_check <- df_scores |> filter(variable %in% c('Bloom_binary_mean', "Chla_ugL_mean")) |>
  left_join(target_metadata, by = c('variable')) |>
  mutate(horizon = as.numeric(as.Date(date) - as.Date(reference_datetime))) |>
  group_by(variable, horizon, class) |>
  summarise(logs = mean(logs, na.rm=TRUE))



#### r2 plot
## fcr plot
fcr_score_summary <- df_var_logs |>
  tidyr::drop_na(observation) |>
  filter(horizon < 60,
         site_id == 'fcre',
         !(variable %in% met_vars),
         !is.na(class),
         !(variable %in% c('CH4flux_umolm2s_mean','Bloom_binary_mean',"CO2flux_umolm2s_mean"))) |>
  group_by(variable, horizon, class) |>
  summarise(r2 = (stats::cor(mean, observation, use = "complete.obs")^2)) |>
  #ungroup() |>
  #distinct(variable, horizon, .keep_all = TRUE) |>
  drop_na(r2)

fcr_score_summary |>
  #pivot_longer(cols = c(logs), names_to="metric", values_to="score") |>
  #ggplot(aes(x = horizon, y= score,  col=class)) +
  ggplot(aes(x = horizon, y= r2, col= variable)) +
  geom_line() +
  #facet_wrap(~metric, scales='free') +
  # scale_y_log10(labels = function(x) format(x, scientific = FALSE)) +
  # scale_y_log10(limits = c(0.1,250)) +
  labs(title = 'FCRE') +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme_bw() #+
  #ggplot2::scale_color_manual(values = c(biological = 'green3',
  #                                       chemical = 'red',
  #                                       physical = 'blue'))

## fcr plot
bvr_score_summary <- df_var_logs |>
  tidyr::drop_na(observation) |>
  filter(horizon < 60,
         site_id == 'bvre',
         !(variable %in% met_vars),
         !is.na(class),
         !(variable %in% c('CH4flux_umolm2s_mean','Bloom_binary_mean',"CO2flux_umolm2s_mean"))) |>
  group_by(variable, horizon, class) |>
  summarise(r2 = (stats::cor(mean, observation, use = "complete.obs")^2)) |>
  #ungroup() |>
  #distinct(variable, horizon, .keep_all = TRUE) |>
  drop_na(r2)

bvr_score_summary |>
  #pivot_longer(cols = c(logs), names_to="metric", values_to="score") |>
  #ggplot(aes(x = horizon, y= score,  col=class)) +
  ggplot(aes(x = horizon, y= r2, col= variable)) +
  geom_line() +
  #facet_wrap(~metric, scales='free') +
  # scale_y_log10(labels = function(x) format(x, scientific = FALSE)) +
  # scale_y_log10(limits = c(0.1,250)) +
  labs(title = 'FCRE') +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme_bw() #+
#ggplot2::scale_color_manual(values = c(biological = 'green3',
#                                       chemical = 'red',
#                                       physical = 'blue'))
