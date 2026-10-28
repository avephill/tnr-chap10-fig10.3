# Figure 10.3: direction of US range shifts relative to local isotherm movement,
# plus two single-species examples.

library(BioShiftR)
library(dplyr)
library(readr)
library(ggplot2)
library(rphylopic)
library(patchwork)
library(svglite)
library(ragg)
source("code/0-0-project-settings.R")

# ===== Style =====

COL_CONSISTENT <- "#1C6E75"   # shift in the direction of local isotherm movement
COL_OPPOSITE   <- "#D1584C"   # shift against it
COL_NO_SHIFT   <- "#8A8A7B"   # shift of exactly zero
COL_VELOCITY   <- "#8A8A8A"   # climate velocity
COL_INK        <- "#111111"
FONT           <- "Helvetica Neue"

# ===== Panels (a) and (b): US observations =====

# All elevational and latitudinal range-shift observations
shifts <- get_shifts()

# Study areas that overlap the US, from script 01
us_study_areas <- read_csv(file.path(intermediate_dir, "us_study_areas.csv"))

# US observations, with the median climate velocity of their study area
us <- shifts |>
  semi_join(us_study_areas, by = c("article_id", "poly_id")) |>
  add_cv(stat = "median")

# Same sign as local velocity = consistent (Lawlor et al. 2024, Fig. 2)
us <- us |>
  mutate(class = case_when(calc_rate == 0                           ~ "no_shift",
                           sign(calc_rate) == sign(cv_temp_median)  ~ "consistent",
                           TRUE                                     ~ "opposite"))

# Percent of observations in each class, one row per gradient x realm
panel_summary <- us |>
  group_by(type, eco) |>
  summarise(opposite   = 100 * mean(class == "opposite"),
            no_shift   = 100 * mean(class == "no_shift"),
            consistent = 100 * mean(class == "consistent"),
            .groups    = "drop")

# ===== Species boxes =====

# Red fir, Wright et al. 2016 (BioShifts A198): rates by range position, and
# climate velocity over the species' range in the study area
red_fir <- shifts |>
  filter(article_id == "A198", sp_name_checked == "Abies_magnifica", type == "ELE") |>
  add_cv(type = "SP", stat = "median") |>
  select(param, rate = calc_rate, cv = cv_temp_median)

# Bushy-tailed woodrat, Moritz et al. 2008 (BioShifts A047)
woodrat <- shifts |>
  filter(article_id == "A047", sp_name_checked == "Neotoma_cinerea", type == "ELE") |>
  add_cv(type = "SP", stat = "median") |>
  select(param, rate = calc_rate, cv = cv_temp_median)

# ===== Drawing =====
# Both panel types draw on a 0-100 x 0-100 canvas; positions are canvas units.

# Arrow length per percentage point, shared by the three left panels
PCT_TO_UNITS <- 34 / 61

# One left panel; r = one row of panel_summary, z = size multiplier
draw_arrow_panel <- function(r, title, z = 1) {
  y0 <- 40   # baseline
  ggplot() +
    annotate("text", x = 0, y = 99, label = title, hjust = 0, vjust = 1,
             family = FONT, fontface = "bold", size = 5.2 * z, colour = COL_INK) +
    annotate("segment", x = 18, xend = 88, y = y0, yend = y0,
             colour = "#E4E4E4", linewidth = 0.3) +
    # opposite: down arrow
    annotate("segment", x = 30, xend = 30, y = y0, yend = y0 - r$opposite * PCT_TO_UNITS,
             colour = COL_OPPOSITE, linewidth = 2.4 * z,
             arrow = arrow(length = unit(3.2 * z, "mm"), type = "closed")) +
    annotate("text", x = 26, y = y0 - r$opposite * PCT_TO_UNITS / 2, hjust = 1,
             label = sprintf("%.0f%%", r$opposite), family = FONT,
             fontface = "bold", size = 5.0 * z, colour = COL_OPPOSITE) +
    # no shift: square on the baseline
    annotate("point", x = 52, y = y0, shape = 22, size = 3.0 * z,
             fill = COL_NO_SHIFT, colour = COL_NO_SHIFT) +
    annotate("text", x = 52, y = y0 - 7, label = sprintf("%.0f%%", r$no_shift),
             hjust = 0.5, family = FONT, fontface = "bold", size = 5.0 * z,
             colour = COL_NO_SHIFT) +
    # consistent: up arrow
    annotate("segment", x = 74, xend = 74, y = y0, yend = y0 + r$consistent * PCT_TO_UNITS,
             colour = COL_CONSISTENT, linewidth = 2.4 * z,
             arrow = arrow(length = unit(3.2 * z, "mm"), type = "closed")) +
    annotate("text", x = 78, y = y0 + r$consistent * PCT_TO_UNITS / 2, hjust = 0,
             label = sprintf("%.0f%%", r$consistent), family = FONT,
             fontface = "bold", size = 5.0 * z, colour = COL_CONSISTENT) +
    coord_cartesian(xlim = c(0, 100), ylim = c(0, 100), expand = FALSE) +
    theme_void() + theme(plot.margin = margin(2, 2, 2, 2))
}

POSITION_LABEL <- c(LE = "Cold edge", O = "Range center", TE = "Warm edge")
ROW_Y          <- c(LE = 62, O = 42, TE = 22)   # canvas y of each range position
FLAT_EPS       <- 0.15   # |rate| below this (m/yr) draws as a flat stub
MIN_CV_UNITS   <- 1.6    # shorter velocity arrows are drawn at this length, "(not to scale)"
fmt_signed     <- function(x) sprintf("%+.2f", x)

# One species box; rates and velocity share one scale, largest |value| = 11 units
draw_species_box <- function(rates, cv, title, sci_name, common_name, silhouette, cite) {
  units_per_m <- 11 / max(abs(c(rates$rate, cv)))
  d <- rates |> mutate(y   = ROW_Y[param],
                       col = case_when(abs(rate) < FLAT_EPS ~ COL_NO_SHIFT,
                                       rate > 0             ~ COL_CONSISTENT,
                                       TRUE                 ~ COL_OPPOSITE),
                       lab = fmt_signed(rate))

  # Frame, titles, silhouette, rate unit label
  g <- ggplot() +
    annotate("rect", xmin = 0, xmax = 100, ymin = 0, ymax = 100,
             fill = "white", colour = COL_INK, linewidth = 1.2) +
    annotate("text", x = 6, y = 96, label = title, hjust = 0, vjust = 1,
             family = FONT, fontface = "bold", size = 5.8, colour = COL_INK) +
    annotate("text", x = 6, y = 88, label = sci_name, hjust = 0, vjust = 1,
             family = FONT, fontface = "italic", size = 4.9, colour = COL_INK) +
    annotate("text", x = 6, y = 82, label = common_name, hjust = 0, vjust = 1,
             family = FONT, size = 4.1, colour = "#666666") +
    add_phylopic(img = silhouette, x = 83, y = 85, height = 17, fill = COL_INK) +
    annotate("text", x = 77, y = 70, label = "m/year", hjust = 0, vjust = 1,
             family = FONT, size = 3.6, colour = COL_VELOCITY)

  # Climate-velocity column, left of the divider
  g <- g +
    annotate("text", x = 15, y = 72, label = "Climate velocity", hjust = 0.5,
             family = FONT, size = 3.8, colour = COL_VELOCITY) +
    annotate("text", x = 15, y = 65.5, hjust = 0.5, label = "m/year",
             family = FONT, size = 3.6, colour = COL_VELOCITY) +
    annotate("text", x = 15, y = 58, hjust = 0.5, label = fmt_signed(cv),
             family = FONT, fontface = "bold", size = 4.6, colour = COL_VELOCITY) +
    annotate("segment", x = 7, xend = 23, y = ROW_Y[["O"]], yend = ROW_Y[["O"]],
             colour = "#DCDCDC", linewidth = 0.35) +
    annotate("segment", x = 31, xend = 31, y = 14, yend = 68,
             colour = "#EDEDED", linewidth = 0.5)

  cv_units  <- cv * units_per_m
  off_scale <- abs(cv_units) < MIN_CV_UNITS
  if (off_scale) cv_units <- sign(cv) * MIN_CV_UNITS
  g <- g + annotate("segment", x = 15, xend = 15, y = ROW_Y[["O"]],
                    yend = ROW_Y[["O"]] + cv_units, colour = COL_VELOCITY, linewidth = 2.1,
                    # head tapers on short shafts
                    arrow = arrow(length = unit(min(3.0, 0.55 * abs(cv_units)), "mm"),
                                  type = "closed"))
  if (off_scale)
    g <- g + annotate("text", x = 15, y = ROW_Y[["O"]] - 7, label = "(not to scale)",
                      hjust = 0.5, family = FONT, size = 3.0, colour = "#9A9A9A")

  # Range-position rows: baseline, label, value, arrow
  for (p in names(ROW_Y)) {
    g <- g + annotate("segment", x = 56, xend = 74, y = ROW_Y[[p]], yend = ROW_Y[[p]],
                      colour = "#DCDCDC", linewidth = 0.35)
  }
  for (i in seq_len(nrow(d))) {
    r <- d[i, ]
    g <- g +
      annotate("text", x = 54, y = r$y, label = POSITION_LABEL[[r$param]], hjust = 1,
               family = FONT, size = 4.4, colour = COL_INK) +
      annotate("text", x = 77, y = r$y, label = r$lab, hjust = 0, family = FONT,
               fontface = "bold", size = 4.9, colour = r$col)
    if (abs(r$rate) < FLAT_EPS) {
      g <- g + annotate("segment", x = 62, xend = 68, y = r$y, yend = r$y,
                        colour = COL_NO_SHIFT, linewidth = 2.1)
    } else {
      g <- g + annotate("segment", x = 65, xend = 65, y = r$y,
                        yend = r$y + r$rate * units_per_m, colour = r$col, linewidth = 2.1,
                        arrow = arrow(length = unit(3.0, "mm"), type = "closed"))
    }
  }

  g + annotate("text", x = 6, y = 3, label = cite, hjust = 0, vjust = 0,
               family = FONT, size = 3.4, colour = COL_VELOCITY) +
    coord_cartesian(xlim = c(0, 100), ylim = c(0, 100), expand = FALSE) +
    theme_void() + theme(plot.margin = margin(2, 2, 2, 2))
}

# ===== Compose and save =====

left <- draw_arrow_panel(filter(panel_summary, type == "ELE", eco == "Ter"),
                         "(a) Elevational shifts — terrestrial") /
        (draw_arrow_panel(filter(panel_summary, type == "LAT", eco == "Ter"),
                          "(b) Latitudinal — terrestrial", z = 0.84) |
         draw_arrow_panel(filter(panel_summary, type == "LAT", eco == "Mar"),
                          "Latitudinal — marine", z = 0.84))

# PhyloPic silhouettes: Abies magnifica (CC0); Peromyscus leucopus as a stand-in
# for Neotoma (CC BY 4.0, Edwin Price; credit required)
right <- draw_species_box(red_fir, red_fir$cv[1], "Upslope shift",
                          "Abies magnifica", "red fir",
                          get_phylopic("e2d75b78-b616-4a0a-9db6-58011e0109ed"),
                          "Wright et al. 2016, Calif. Fish & Game") /
         draw_species_box(woodrat, woodrat$cv[1], "Range collapse",
                          "Neotoma cinerea", "bushy-tailed woodrat",
                          get_phylopic("78d30905-8878-41ee-a612-700c1bf09ae9"),
                          "Moritz et al. 2008, Science")

fig <- wrap_plots(left, right, ncol = 2, widths = c(1.18, 1))

ggsave(file.path(results_dir, "fig10_3.svg"), fig, device = svglite,
       width = 14.5, height = 7.2)
ggsave(file.path(results_dir, "fig10_3.png"), fig, device = agg_png,
       width = 14.5, height = 7.2, dpi = 320, bg = "white")
