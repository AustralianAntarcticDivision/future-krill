# for a MEASO area, get worm plots as per last week soki meeting

# Summary of MEASO Sectors

## total organic CARBON!!!
#
## complete cases, fill NAs for full time series back to ice 1978
## simple flux over boundary, just magnitude
#
# uploading data to http://soki.aq/display/Projectd/Krill+habitat+time+series+-+data
library(dplyr)
## chlorophyll
d <- readRDS("R/modis_chla.rds")
date <- seq(as.Date("2002-07-15"), by = "1 month", length.out = length(d))
for (i in seq_along(d)) {
  if (nrow(d[[i]]) > 0) d[[i]]$date <- date[i]
}
dchl <- dplyr::bind_rows(d) %>% rename(chla_n = nbins)


## oisst
d <- readRDS("R/oisst.rds")
date <- seq(as.Date("1981-12-15"), by = "1 month", length.out = length(d))
for (i in seq_along(d)) {
  if (nrow(d[[i]]) > 0) d[[i]]$date <- date[i]
}
dsst <- dplyr::bind_rows(d) %>% dplyr::rename(sst_n = n, poly = object_)
saveRDS(dplyr::left_join(dsst, dchl), "chl_sst.rds")

## ice
d <- readRDS("R/nsidc.rds")
date <- seq(as.Date("1978-10-15"), by = "1 month", length.out = length(d))
for (i in seq_along(d)) {
  if (nrow(d[[i]]) > 0) d[[i]]$date <- date[i]
}
saveRDS(dplyr::bind_rows(d) %>% dplyr::rename(poly = object_, quant_ice = gice, ice_area = area) %>%
  mutate(ice_area_km2 = ice_area/1e6, ice_area = NULL), "ice_area.rds")


## currents
d <- readRDS("R/currents.rds")
date <- seq(as.Date("1993-01-01"), by = "1 day", length.out = length(d))
