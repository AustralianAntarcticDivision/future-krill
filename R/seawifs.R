library(SOmap)
#x <- SOmap_data$CCAMLR_SSMU
library(sf)
x <- as(readRDS("/perm_storage/home/mdsumner/Git/future-krill/shapes/Area_48_Krill_Domain.rds"), "Spatial")
ex <- extent(x) + 1
## map seawifs and modis bins to ssmu polys
library(croc)
n_bins <- 2160
theprod <- "SeaWiFS"
sw_bins <- tibble::tibble(bin_num = crop_init(initbin(NUMROWS = n_bins), ex))
sw_bins[c("lon", "lat")] <- croc::bin2lonlat(sw_bins$bin_num, n_bins)
sw_bins$poly <- sp::over(SpatialPoints(as.matrix(sw_bins[c("lon", "lat")]),
                                                       proj4string = CRS(projection(x))), as(x, "SpatialPolygons"))

sw_bins <- dplyr::filter(sw_bins, !is.na(poly))

## group daily files by month
library(raadtools)
library(dplyr)
files <- oc_sochla_files(product = theprod) %>% mutate(month = format(date, "%Y-%m")) %>% group_by(month)

library(furrr)
#plan(sequential)
plan(multicore)
library(purrr)
read_sw <- function(x, ...) {
  future_map_dfr(x$date, ~read_oc_sochla(.x, bins = sw_bins, inputfiles = files, product = theprod)) %>% group_by(poly) %>%
    summarize(chla = mean(chla_johnson), nbins = n())
}


## takes about an hour for MODISA
sw_chla <- files %>% group_split() %>% future_map(read_sw)

saveRDS(sw_chla, "sw_chla.rds")

