# To try this out, it would be good to have NetCDF files (or whatever format you
# would prefer) that has the following data…
#
# Area 48 Small-Scale Management Unit, month (over time series of chlorophyll
# data), mean total chlorophyll, mean temperature, mean coverage of sea ice
# (<20%, 20-50%, 50-75%, 75-95%, >95%), surface area of water crossing the
# boundaries of the SSMUs.
#
# Ancillary data needed for the modelling will be the length of the boundaries
# between the SSMUs.
#

library(SOmap)
x <- SOmap_data$CCAMLR_SSMU
ex <- extent(spTransform(x, "+proj=longlat")) + 1
## map seawifs and modis bins to ssmu polys
library(croc)
modis_bins <- tibble::tibble(bin_num = crop_init(initbin(NUMROWS = 4320), ex))
modis_bins[c("lon", "lat")] <- croc::bin2lonlat(modis_bins$bin_num, 4320)
modis_bins$poly <- sp::over(SpatialPoints(rgdal::project(as.matrix(modis_bins[c("lon", "lat")]),
                                               projection(x)), proj4string = CRS(projection(x))), as(x, "SpatialPolygons"))
modis_bins <- dplyr::filter(modis_bins, !is.na(poly))

## group daily files by month
library(raadtools)
library(dplyr)
files <- oc_sochla_files() %>% mutate(month = format(date, "%Y-%m")) %>% group_by(month)

library(furrr)
#plan(sequential)
plan(multicore)
library(purrr)
read_modis <- function(x, ...) {
  future_map_dfr(x$date, ~read_oc_sochla(.x, bins = modis_bins, inputfiles = files)) %>% group_by(poly) %>%
    summarize(chla = mean(chla_johnson), nbins = n())
}


## takes about an hour
modis_chla <- files %>% group_split() %>% future_map(read_modis)

saveRDS(modis_chla, "modis_chla.rds")
## read months at a time, careful to map seawifs or modis bins for filter
