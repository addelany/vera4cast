library(tidyverse)
config <- yaml::read_yaml("challenge_configuration.yaml")

s3 <- arrow::s3_bucket(paste0(config$forecasts_bucket, "/parquet"), endpoint_override = config$endpoint, anonymous = TRUE)

bucket <- config$forecasts_bucket
inventory_df <- arrow::open_dataset(s3) |>
  mutate(reference_date = lubridate::as_date(reference_datetime),
         date = lubridate::as_date(datetime),
         pub_date = lubridate::as_date(pub_datetime)) |>
  distinct(duration, model_id, site_id, reference_date, variable, date, project_id, pub_date) |>
  collect() |>
  mutate(path = glue::glue("{bucket}/parquet/project_id={project_id}/duration={duration}/variable={variable}"),
         path_full = glue::glue("{bucket}/parquet/project_id={project_id}/duration={duration}/variable={variable}/model_id={model_id}/reference_date={reference_date}/part-0.parquet"),
         path_summaries = glue::glue("{bucket}/summaries/project_id={project_id}/duration={duration}/variable={variable}/model_id={model_id}/reference_date={reference_date}/part-0.parquet"),
         path_bundled = glue::glue("{bucket}/bundled-parquet/project_id={project_id}/duration={duration}/variable={variable}/model_id={model_id}/data_0.parquet"),
         path_bundled_summaries = glue::glue("{bucket}/bundled-summaries/project_id={project_id}/duration={duration}/variable={variable}/model_id={model_id}/data_0.parquet"),
         endpoint =config$endpoint)


sites <- readr::read_csv(config$site_table,show_col_types = FALSE) |>
  select(site_id, latitude, longitude)

inventory_df <- dplyr::left_join(inventory_df, sites, by = "site_id")

s3_inventory <- arrow::s3_bucket(config$inventory_bucket,
                                 endpoint_override = config$endpoint,
                                 access_key = Sys.getenv("OSN_KEY"),
                                 secret_key = Sys.getenv("OSN_SECRET"))

arrow::write_dataset(inventory_df, path = s3_inventory$path(glue::glue("catalog/forecasts/project_id={config$project_id}")))

s3_inventory <- arrow::s3_bucket(config$inventory_bucket,
                                 endpoint_override = config$endpoint,
                                 access_key = Sys.getenv("OSN_KEY"),
                                 secret_key = Sys.getenv("OSN_SECRET"))

inventory_df |> distinct(model_id, project_id) |>
  arrow::write_csv_arrow(s3_inventory$path("model_id/model_id-project_id-inventory.csv"))
