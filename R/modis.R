# To try this out, it would be good to have NetCDF files (or whatever format you
# would prefer) that has the following data…
#
# Area 48 Small-Scale Management Unit, month (over time series of chlorophyll
# data), mean total chlorophyll, mean temperature, mean coverage of sea ice
# (<20%, 20-50%, 50-75%, 75-95%, >95%), surface area of water crossing the
# boundaries of the SSMUs.


# Ancillary data needed for the modelling will be the length of the boundaries
# between the SSMUs.
#

library(SOmap)
library(sf)
x <- as(readRDS("/perm_storage/home/mdsumner/Git/future-krill/shapes/Area_48_Krill_Domain.rds"), "Spatial")
ex <- extent(x) + 1
## map seawifs and modis bins to ssmu polys
library(croc)
modis_bins <- tibble::tibble(bin_num = crop_init(initbin(NUMROWS = 4320), ex))
modis_bins[c("lon", "lat")] <- croc::bin2lonlat(modis_bins$bin_num, 4320)
modis_bins$poly <- sp::over(SpatialPoints(as.matrix(modis_bins[c("lon", "lat")]) ,
                                          proj4string = CRS(projection(x))), as(x, "SpatialPolygons"))
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

oc <- ocfiles("monthly", "MODISA", varname = "KD490", type = "L3m")
x <- as(readRDS("/perm_storage/home/mdsumner/Git/future-krill/shapes/Area_48_Krill_Domain.rds"), "Spatial")
cells <- tabularaster::cellnumbers(raster(oc$fullname[1]), sf::st_as_sf(x))
kd <- vector('list', nrow(oc))
for (i in seq_len(nrow(oc))) {
  r <- raster::raster(oc$fullname[i], varname = "Kd_490")
  kd[[i]] <- cells %>% dplyr::mutate(kd = extract(r, cell_)) %>% group_by(object_) %>%
    summarize(depth = mean(kd, na.rm = TRUE))

}
saveRDS(kd, "kd_depth.rds")
