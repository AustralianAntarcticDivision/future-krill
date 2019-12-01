
## from https://github.com/mdsumner/rk/blob/f92123527e8748c407af647123ab3837315b4b84/in-reverse.R

library(raadtools)
x <- readRDS("/perm_storage/home/mdsumner/Git/future-krill/shapes/Area_48_Krill_Domain.rds")


library(silicate)
arc <- ARC(x)

files <- raadfiles::altimetry_currents_polar_files()


## TEMPORARY UNTIL CACHE REBUILDS
# files0 <- fs::dir_ls("/rdsi/PRIVATE/raad/data_local/aad.gov.au/currents/polar", regex = ".*\\.grd$", recurse = TRUE)
#
#
# files <- tibble::tibble(ufullname = grep("polar_u", files0, value = TRUE), vfullname = grep("polar_v", files0, value = TRUE))
# files$date <- as.POSIXct(as.Date(stringr::str_extract(basename(files0), "[0-9]{8}"),
#                                  "%Y%m%d"),tz = "UTC")[grep("polar_u", files0)]

##


ifile <- 1

curr <- brick(raster(files$ufullname[ifile]), raster(files$vfullname[ifile]))
arc_to_sp <- function(x) {
  l <- split(x$arc_link_vertex, x$arc_link_vertex$arc_)[unique(x$arc_link_vertex$arc_)]

  for (i in seq_along(l)) {
    l[[i]] <- sp::Lines(list(sp::Line(as.matrix(dplyr::inner_join(l[[i]], arc$vertex, "vertex_") %>% dplyr::select(x_, y_)))), ID = i)
  }
  sp::SpatialLines(l, proj4string = raster::crs(x$meta$proj[1]))
}

sp <- arc_to_sp(arc)
crs <- sf::st_crs(sf::st_as_sf(sp))
sf <- sf::st_set_crs(sf::st_segmentize(sf::st_set_crs(sf::st_as_sf(sp), NA), 0.1), crs)

cells <- tabularaster::cellnumbers(curr, sf::st_transform(sf, projection(curr)))
saveRDS(cells, "cells_Polar_lines.rds")
xy <- xyFromCell(curr, cells$cell_)
l <- vector("list", nrow(files))

for (ifile in seq_along(l)) {
  curr <- try(brick(raster(files$ufullname[ifile]), raster(files$vfullname[ifile])))
  if (inherits(curr, "try-error")) next;
  l[[ifile]] <- extract(curr, cells$cell_)
  if (ifile %% 500 == 0) print(ifile)

  # plot(xy, col = colourvalues::colour_values(vfun(l[[ifile]])),
  #      pch = 19, cex = .4)
  #
}

saveRDS(l, "currents.rds")
