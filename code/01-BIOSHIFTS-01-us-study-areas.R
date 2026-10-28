# Which BioShifts study areas overlap the US (land or EEZ)?

library(sf)
library(dplyr)
library(readr)
library(rnaturalearth)
source("code/0-0-project-settings.R")

# Planar geometry: the simplified study-area polygons fail s2 validity checks
sf_use_s2(FALSE)

# ===== US region =====

# US land: Natural Earth 1:50m map units (states, PR, USVI, Guam, AS, CNMI)
us_land <- ne_countries(scale = 50, type = "map_units", returnclass = "sf") |>
  filter(sovereignt == "United States of America") |>
  st_geometry() |>
  st_make_valid()

# US exclusive economic zone
us_eez <- st_read(file.path(source_dir, "us_eez.geojson")) |>
  st_geometry() |>
  st_make_valid()

# Land and sea as one geometry
us_region <- c(us_land, us_eez) |>
  st_union()

# ===== Study areas =====

# BioShifts study-area polygons, one per article_id x poly_id
sa_polys <- readRDS(file.path(source_dir, "sa_polygons_simplified.rds")) |>
  st_make_valid()

# Keep study areas that touch the US anywhere
us_study_areas <- sa_polys |>
  st_filter(us_region) |>
  st_drop_geometry() |>
  select(article_id, poly_id)

write_csv(us_study_areas, file.path(intermediate_dir, "us_study_areas.csv"))
