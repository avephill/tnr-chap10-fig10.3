# Data behind Figure 10.3: direction of US range shifts relative to local
# isotherm movement, and rates for two example species.

library(BioShiftR)
library(dplyr)
library(tidyr)
library(readr)
source("code/0-0-project-settings.R")

# All elevational and latitudinal range-shift observations
shifts <- get_shifts()

# ===== Panels (a) and (b) =====

# Study areas that overlap the US, from script 01
us_study_areas <- read_csv(file.path(intermediate_dir, "us_study_areas.csv"))

# US observations, with the median climate velocity of their study area
us <- shifts |>
  semi_join(us_study_areas, by = c("article_id", "poly_id")) |>
  add_cv(stat = "median")

# Same sign as local velocity = consistent (Lawlor et al. 2024, Fig. 2)
us <- us |>
  mutate(class = case_when(calc_rate == 0                           ~ "no_shift",
                           sign(calc_rate) == sign(cv_temp_median)  ~ "consistent_with_isotherms",
                           TRUE                                     ~ "opposite_to_isotherms"))

# Percent of observations in each class, one row per gradient x realm
panel_summary <- us |>
  group_by(type, eco) |>
  summarise(n_observations            = n(),
            opposite_to_isotherms     = 100 * mean(class == "opposite_to_isotherms"),
            no_shift                  = 100 * mean(class == "no_shift"),
            consistent_with_isotherms = 100 * mean(class == "consistent_with_isotherms"),
            .groups                   = "drop")

# Panel labels as printed, in figure order
panels <- tribble(
  ~type, ~eco,  ~panel,                                  ~gradient,     ~realm,
  "ELE", "Ter", "(a) Elevational shifts — terrestrial",  "elevational", "terrestrial",
  "LAT", "Ter", "(b) Latitudinal — terrestrial",         "latitudinal", "terrestrial",
  "LAT", "Mar", "(b) Latitudinal — marine",              "latitudinal", "marine")

# One row per panel x class
left_panels <- panels |>
  left_join(panel_summary, by = c("type", "eco")) |>
  pivot_longer(c(opposite_to_isotherms, no_shift, consistent_with_isotherms),
               names_to = "variable", values_to = "percent") |>
  transmute(panel          = panel,
            gradient       = gradient,
            realm          = realm,
            n_observations = n_observations,
            variable       = variable,
            percent        = round(percent, 2))

write_csv(left_panels, file.path(results_dir, "fig10_3_left_panels.csv"), quote = "all")

# ===== Species boxes =====

# The two example species and the study each comes from
examples <- tribble(
  ~article_id, ~sp_name_checked,  ~species,          ~common_name,           ~source,
  "A198",      "Abies_magnifica", "Abies magnifica", "red fir",              "Wright et al. 2016, Calif. Fish & Game",
  "A047",      "Neotoma_cinerea", "Neotoma cinerea", "bushy-tailed woodrat", "Moritz et al. 2008, Science")

# Elevational shift rate at each range position, with the median 1 km climate
# velocity over the species' range in that study area
example_shifts <- examples |>
  inner_join(filter(shifts, type == "ELE"), by = c("article_id", "sp_name_checked")) |>
  add_cv(type = "SP", stat = "median")

# One row per species x range position
rates <- example_shifts |>
  transmute(species     = species,
            common_name = common_name,
            variable    = c(LE = "cold_edge", O = "range_center", TE = "warm_edge")[param],
            rate_m_yr   = calc_rate,
            source      = source)

# One row per species: climate velocity
velocity <- example_shifts |>
  distinct(species, common_name, cv_temp_median) |>
  transmute(species     = species,
            common_name = common_name,
            variable    = "climate_velocity",
            rate_m_yr   = cv_temp_median,
            source      = "BioShifts sp_cv.rds, cv_temp_median_res1km")

# Each species' rates, then its velocity
species_boxes <- bind_rows(rates, velocity) |>
  arrange(match(species, examples$species)) |>
  mutate(rate_m_yr = round(rate_m_yr, 2))

write_csv(species_boxes, file.path(results_dir, "fig10_3_species_boxes.csv"), quote = "all")
