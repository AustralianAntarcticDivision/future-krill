library(SOmap)
library(sf)
x <- readRDS("/perm_storage/home/mdsumner/Git/future-krill/shapes/Area_48_Krill_Domain.rds")
files <- raadfiles::nsidc_south_monthly_files()
r <- setValues(raadtools::readice_monthly(files$date[1]), 1)
pts <- spTransform(as(r, "SpatialPoints"), projection(x))
library(dplyr)
nsidc_pix <- tibble::tibble(object_ = over(pts, as(as(x, "Spatial"), "SpatialPolygons"))) %>%
  mutate(cell_ = row_number()) %>% filter(!is.na(object_))


r_ice <- function(date) {
  x <- raadtools::readice_monthly(date)[[1]]
  x[is.na(x)] <- 0
  x
}
fun <- function(date) {
  nsidc_pix %>% mutate(ice = raster::extract(r_ice(date), nsidc_pix$cell_)) %>%
    filter(!is.na(ice)) %>%
    mutate(gice = cut(ice, c(0, 0.2, 0.5, 0.75, 0.95, 1) * 100, include.lowest = TRUE)) %>% group_by(object_, gice) %>%
    summarize(area = n() * 25000 * 25000)
}
library(furrr)
plan(multicore)
system.time(res <- future_map(files$date, fun))

saveRDS(res, "R/nsidc.rds")
