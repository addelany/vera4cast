submit_met_forecast <- function(model_id){

  s3 <- arrow::s3_bucket(paste0("bio230121-bucket01/flare/drivers/met/ensemble_forecast/model_id=", model_id),
                         endpoint_override = "amnh1.osn.mghpcc.org",
                         access_key = Sys.getenv("OSN_KEY"),
                         secret_key = Sys.getenv("OSN_SECRET"))

  df_dates <- arrow::open_dataset(s3) |>
    dplyr::filter(site_id == "fcre") |>
    dplyr::distinct(reference_date) |>
    dplyr::collect()

  max_reference_date <- max(df_dates$reference_date)

  filename <- paste0("drivers/", model_id, "-",max_reference_date,".csv.gz")

  df <- arrow::open_dataset(s3) |>
    dplyr::filter(reference_date == max_reference_date) |>
    dplyr::mutate(date = lubridate::as_date(datetime)) |>
    dplyr::select(-unit) |>
    dplyr::collect() |>
    tidyr::pivot_wider(names_from = variable, values_from = prediction)

  if(model_id == "ecmwf_ifs04"){
  df <- df |>  dplyr::summarize(RH_percent_mean = mean(relative_humidity_2m, na.rm = TRUE),
              Rain_mm_sum = sum(precipitation, na.rm = TRUE),
              WindSpeed_ms_mean = mean(wind_speed_10m, na.rm = TRUE),
              AirTemp_C_mean = mean(temperature_2m, na.rm = TRUE),
              BP_kPa_mean = mean(surface_pressure * 0.1, na.rm = TRUE),
              .by = c("date","ensemble"))
  }else{
    df <- df |>  dplyr::summarize(RH_percent_mean = mean(relative_humidity_2m, na.rm = TRUE),
                                  Rain_mm_sum = sum(precipitation, na.rm = TRUE),
                                  WindSpeed_ms_mean = mean(wind_speed_10m, na.rm = TRUE),
                                  AirTemp_C_mean = mean(temperature_2m, na.rm = TRUE),
                                  ShortwaveRadiationUp_Wm2_mean = mean(shortwave_radiation, na.rm = TRUE),
                                  BP_kPa_mean = mean(surface_pressure * 0.1, na.rm = TRUE),
                                  .by = c("date","ensemble"))
  }
    df |> tidyr::pivot_longer(-c(date, ensemble), names_to = "variable", values_to = "prediction") |>
    dplyr::mutate(datetime = lubridate::as_datetime(date),
           reference_datetime = lubridate::as_datetime(max_reference_date),
           site_id = "fcre",
           model_id = model_id,
           duration = "P1D",
           project_id = "vera4cast",
           depth_m = NA,
           family = "ensemble",
           ensemble = as.numeric(ensemble)) |>
    dplyr::rename(parameter = ensemble) |>
    dplyr::select(c("project_id", "site_id","model_id", "reference_datetime", "datetime","duration", "depth_m","variable", "family", "parameter", "prediction")) |>
    readr::write_csv(filename)

  vera4castHelpers::submit(filename, first_submission = FALSE)

}
