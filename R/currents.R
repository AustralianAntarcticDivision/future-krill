
## from https://github.com/mdsumner/rk/blob/f92123527e8748c407af647123ab3837315b4b84/in-reverse.R

library(raadtools)
x <- readRDS("/perm_storage/home/mdsumner/Git/future-krill/shapes/Area_48_Krill_Domain.rds")

library(silicate)
arc <- ARC(x)

files <- raadfiles::altimetry_currents_polar_files()
ifile <- 1

curr <- brick(raster(files$ufullname[ifile]), raster(files$vfullname[ifile]))
cells <- tibble::tibble(cell = cellFromXY(curr, as.matrix(reproj::reproj(arc, projection(curr))$vertex[c("x_", "y_")])),
                        vertex = arc$vertex$vertex_)

l <- vector("list", nrow(files))
for (ifile in seq_len(nrow(files))) {
  curr <- brick(raster(files$ufullname[ifile]), raster(files$vfullname[ifile]))
  l[[ifile]] <- extract(curr, cells$cell)
  if (ifile %% 500 == 0) print(ifile)
}

saveRDS(l, "currents.rds")
