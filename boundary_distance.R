## arc lengths
library(silicate)
library(tidyr)
library(dplyr)
xsf <- readRDS("shapes/Area_48_Krill_Domain.rds")
x <- SC(xsf)

v <- pivot_longer(x$edge, -edge_, names_to = "end", values_to = "vertex_")  %>%
  dplyr::inner_join(x$vertex) %>% dplyr::select(x_, y_, edge_)
x$edge$distance <- (v %>%
  split(.$edge_))[unique(x$edge$edge_)] %>%
  purrr::map_dbl(~geosphere::distRhumb(.x[1, c("x_", "y_")], .x[2, c("x_", "y_")]))

o <- dplyr::inner_join(x$object_link_edge, x$edge) %>%
  dplyr::select(object_, edge_, distance) %>% group_by(edge_) %>%
  dplyr::filter(n() > 1)

u <- unique(o$edge_)
l <- vector("list", length(u))
for (i in seq_along(l)) {
  ed <- u[i]
  d <- o %>% dplyr::filter(edge_ == ed)

  if (!dim(d)[1] == 2) stop()
  l[[i]] <- tibble(object1 = d$object_[1],
                   object2 = d$object_[2],
                   distance = d$distance[1])
}

a <- bind_rows(l) %>% group_by(object1, object2) %>% summarize(distance = sum(distance)) %>% ungroup()
a$object1 <- match(a$object1, x$object$object_)
a$object2 <- match(a$object2, x$object$object_)

saveRDS(a, file = "shared_boundary_lengths.rds")
