source("drivers/download_ensemble_forecast.R")
source("drivers/submit_met_forecast.R")


model_id <- "gfs_seamless"
print(model_id)
download_ensemble_forecast(model = model_id, sites = "fcre")
print('downloaded')
submit_met_forecast(model_id)
print('submitted')

model_id <- "icon_seamless"
print(model_id)
download_ensemble_forecast(model_id, forecast_horizon = 7, sites = "fcre")
submit_met_forecast(model_id)

model_id <- "gem_global"
print(model_id)
download_ensemble_forecast(model_id, forecast_horizon = 32, sites = "fcre")
submit_met_forecast(model_id)

model_id <- "ecmwf_ifs04"
print(model_id)
download_ensemble_forecast(model_id, forecast_horizon = 10, sites = "fcre")
submit_met_forecast(model_id)

model_id <- "bom_access_global_ensemble"
print(model_id)
download_ensemble_forecast(model_id, forecast_horizon = 10, sites = "fcre")
submit_met_forecast(model_id)

model_id <- "ecmwf_aifs025"
print(model_id)
download_ensemble_forecast(model_id, forecast_horizon = 10, sites = "fcre")
submit_met_forecast(model_id)

model_id <- "ukmo_global_ensemble_20km"
print(model_id)
download_ensemble_forecast(model_id, forecast_horizon = 10, sites = "fcre")
submit_met_forecast(model_id)

## Call healthcheck
#RCurl::url.exists("https://hc-ping.com/d39f878d-2dc0-4373-ab01-22fa417692f8", timeout = 5)
