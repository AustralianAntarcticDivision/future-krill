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
dchl <- dplyr::bind_rows(d)
## oisst
d <- readRDS("R/oisst.rds")
date <- seq(as.Date("1981-12-15"), by = "1 month", length.out = length(d))
for (i in seq_along(d)) {
  if (nrow(d[[i]]) > 0) d[[i]]$date <- date[i]
}

dsst <- dplyr::bind_rows(d) %>% dplyr::rename(sst_n = n, poly = object_)

kd <- readRDS("kd_depth.rds")
oc <- ocfiles("monthly", "MODISA", varname = "KD490", type = "L3m")
for (i in seq_along(kd)) kd[[i]]$date <- as.Date(oc$date[i])
kd <- dplyr::rename(dplyr::bind_rows(kd), poly = object_, kd = depth)


saveRDS(dplyr::left_join(dplyr::left_join(dsst, dchl), kd) , "chl_sst.rds")

## ice
d <- readRDS("R/nsidc.rds")
date <- seq(as.Date("1978-10-15"), by = "1 month", length.out = length(d))
for (i in seq_along(d)) {
  if (nrow(d[[i]]) > 0) d[[i]]$date <- date[i]
}

ice <- dplyr::bind_rows(d) %>% ungroup()
## reset group values
ice$q_ice <- sprintf("ice_%s", gsub("\\]", "", unlist(lapply(strsplit(levels(ice$gice)[ice$gice], ","), "[", 2))))
saveRDS(ice %>% dplyr::transmute(poly = object_, q_ice, ice_area_km2 = area/1e6, date) %>%
          pivot_wider(names_from = q_ice, values_from = ice_area_km2), "ice_area.rds")


curr <- brick(raadfiles::altimetry_currents_polar_files()$ufullname[1])
## currents
d <- readRDS("R/currents.rds")
date <- seq(as.Date("1993-01-01"), by = "1 day", length.out = length(d))
library(raadtools)
segmentize <- function(x, d) {
  crs <- sf::st_crs(x)
  sf::st_set_crs(sf::st_segmentize(sf::st_set_crs(x, NA), d), crs)
}
xpp <- as(as(sf::st_set_crs(sf::st_transform(segmentize(readRDS("/perm_storage/home/mdsumner/Git/future-krill/shapes/Area_48_Krill_Domain.rds"), 0.1),
                                      projection(curr)), NA), "Spatial"), "SpatialPolygons")
pip <- function(x) {
  x[is.na(x)] <- 0
  sp::over(SpatialPoints(x), xpp)
}

cells <- readRDS("cells_Polar_lines.rds")
xy <- xyFromCell(curr, cells$cell_)
p <- pip(xy)
plot(xpp)
points(xy, col = c("red", "black")[is.na(p) + 1])


set_na <- function(x) {x[is.na(x)] <- 0; x}
src <- set_na(pip(xy))

flux <- vector("list", length(d))
for (i in seq_along(flux)) {
 dxy <- d[[i]] * 5e4
 tar <- set_na(pip(xy + dxy))

 exch <- cbind(src = src, tar = tar, mag = sqrt(dxy[,1] ^2 + dxy[,2]^2))
 bad <- exch[,1] == exch[,2] | exch[,1] == 0 | exch[,2] == 0
 exch[bad, 3] <- NA
 flux[[i]] <- tibble::as_tibble(exch[!is.na(exch[,3]), ]) %>% group_by(src, tar) %>% summarize(flux = sum(mag))
}
saveRDS(flux, "R/flux_.rds")
cfiles <- raadfiles::altimetry_currents_polar_files()
flux <- readRDS("R/flux_.rds")
for (i in seq_along(flux)) {
  flux[[i]]$date <- cfiles$date[i]
}

saveRDS(dplyr::bind_rows(flux), "flux_pairs.rds")
