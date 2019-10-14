
f <- "C:/Users/michae_sum/Downloads/Area 48 Krill Domain.map"
lyr <- "Area48_Krill_polygons"
dwg <- manifoldr::Drawing(f, lyr)

saveRDS(sf::st_set_crs(dwg, 4326), "Area_48_Krill_Domain.rds")
