# Download the two spatial inputs that are not bundled in BioShiftR.

source("code/0-0-project-settings.R")

# ===== BioShifts study-area polygons =====

# Same OSF file that BioShiftR::download_polygons(type = "SA") fetches
download.file("https://osf.io/download/68b747593d97f9fb8567b34f/",
              file.path(source_dir, "sa_polygons_simplified.rds"),
              mode = "wb")

# ===== US exclusive economic zone =====

# Marine Regions EEZ features whose sovereign is the United States
eez_url <- "https://geo.vliz.be/geoserver/MarineRegions/wfs?service=wfs&version=2.0.0&request=GetFeature&typeName=MarineRegions:eez&cql_filter=sovereign1%3D%27United%20States%27&outputFormat=application/json"
download.file(eez_url,
              file.path(source_dir, "us_eez.geojson"),
              mode = "wb")
