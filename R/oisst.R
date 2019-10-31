library(SOmap)
library(sf)
x <- readRDS("/perm_storage/home/mdsumner/Git/future-krill/shapes/Area_48_Krill_Domain.rds")
files <- raadfiles::oisst_monthly_files()
r <- raster::setExtent(raster::raster(files$fullname[1]), raster::extent(-360, 0, -90, 90))
oisst_pix <- tabularaster::cellnumbers(r, x)
library(dplyr)
fun <- function(file) {
  oisst_pix %>% mutate(sst = raster::extract(raster::raster(file, varname = "sst"), oisst_pix$cell_)) %>%
    group_by(object_) %>% summarize(sst = mean(sst, na.rm = TRUE), n = n())
}
library(furrr)
plan(multicore)
system.time(res <- future_map(files$fullname, fun))

saveRDS(res, "oisst.rds")
