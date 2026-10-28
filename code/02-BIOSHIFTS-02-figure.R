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
# Each panel is drawn on a 0-100 x 0-100 canvas. All x, y and lengths below
# are canvas units.

# Left panels: arrow length = percent x UNITS_PER_PCT, one scale for all three
# panels (a 61% arrow is 34 units long)
UNITS_PER_PCT <- 34 / 61

# r = one row of panel_summary; size_scale shrinks text and lines for the (b) panels
draw_arrow_panel <- function(r, title, size_scale = 1) {
  baseline       <- 40
  opposite_len   <- r$opposite   * UNITS_PER_PCT
  consistent_len <- r$consistent * UNITS_PER_PCT
  arrow_head     <- arrow(length = unit(3.2 * size_scale, "mm"), type = "closed")

  ggplot() +
    annotate("text", x = 0, y = 99, label = title, hjust = 0, vjust = 1,
             family = FONT, fontface = "bold", size = 5.2 * size_scale, colour = COL_INK) +
    annotate("segment", x = 18, xend = 88, y = baseline, yend = baseline,
             colour = "#E4E4E4", linewidth = 0.3) +
    # opposite: arrow down from the baseline, label beside its midpoint
    annotate("segment", x = 30, xend = 30, y = baseline, yend = baseline - opposite_len,
             colour = COL_OPPOSITE, linewidth = 2.4 * size_scale, arrow = arrow_head) +
    annotate("text", x = 26, y = baseline - opposite_len / 2, hjust = 1,
             label = sprintf("%.0f%%", r$opposite), family = FONT,
             fontface = "bold", size = 5.0 * size_scale, colour = COL_OPPOSITE) +
    # no shift: square on the baseline, label below
    annotate("point", x = 52, y = baseline, shape = 22, size = 3.0 * size_scale,
             fill = COL_NO_SHIFT, colour = COL_NO_SHIFT) +
    annotate("text", x = 52, y = baseline - 7, label = sprintf("%.0f%%", r$no_shift),
             hjust = 0.5, family = FONT, fontface = "bold", size = 5.0 * size_scale,
             colour = COL_NO_SHIFT) +
    # consistent: arrow up from the baseline, label beside its midpoint
    annotate("segment", x = 74, xend = 74, y = baseline, yend = baseline + consistent_len,
             colour = COL_CONSISTENT, linewidth = 2.4 * size_scale, arrow = arrow_head) +
    annotate("text", x = 78, y = baseline + consistent_len / 2, hjust = 0,
             label = sprintf("%.0f%%", r$consistent), family = FONT,
             fontface = "bold", size = 5.0 * size_scale, colour = COL_CONSISTENT) +
    coord_cartesian(xlim = c(0, 100), ylim = c(0, 100), expand = FALSE) +
    theme_void() + theme(plot.margin = margin(2, 2, 2, 2))
}

# Species boxes: rates and climate velocity share one scale within a box,
# set so the largest |value| in the box is BOX_MAX_ARROW units long
BOX_MAX_ARROW  <- 11
ROW_Y          <- c(LE = 62, O = 42, TE = 22)   # y of each range-position row
POSITION_LABEL <- c(LE = "Cold edge", O = "Range center", TE = "Warm edge")
fmt_signed     <- function(x) sprintf("%+.2f", x)

draw_species_box <- function(rates, cv, title, sci_name, common_name, silhouette, cite) {
  units_per_m <- BOX_MAX_ARROW / max(abs(c(rates$rate, cv)))
  cv_len      <- cv * units_per_m

  # One row per range position: y, arrow length, colour by direction
  rows <- rates |>
    mutate(y      = ROW_Y[param],
           length = rate * units_per_m,
           colour = if_else(rate > 0, COL_CONSISTENT, COL_OPPOSITE))

  ggplot() +
    # frame, titles, silhouette
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
             family = FONT, size = 3.6, colour = COL_VELOCITY) +
    # climate-velocity column (left), divider
    annotate("text", x = 15, y = 72, label = "Climate velocity", hjust = 0.5,
             family = FONT, size = 3.8, colour = COL_VELOCITY) +
    annotate("text", x = 15, y = 65.5, hjust = 0.5, label = "m/year",
             family = FONT, size = 3.6, colour = COL_VELOCITY) +
    annotate("text", x = 15, y = 58, hjust = 0.5, label = fmt_signed(cv),
             family = FONT, fontface = "bold", size = 4.6, colour = COL_VELOCITY) +
    annotate("segment", x = 7, xend = 23, y = ROW_Y[["O"]], yend = ROW_Y[["O"]],
             colour = "#DCDCDC", linewidth = 0.35) +
    annotate("segment", x = 31, xend = 31, y = 14, yend = 68,
             colour = "#EDEDED", linewidth = 0.5) +
    # velocity arrow; head shrinks on short arrows so it doesn't hide the shaft
    annotate("segment", x = 15, xend = 15, y = ROW_Y[["O"]], yend = ROW_Y[["O"]] + cv_len,
             colour = COL_VELOCITY, linewidth = 2.1,
             arrow = arrow(length = unit(min(3.0, 0.55 * abs(cv_len)), "mm"), type = "closed")) +
    # range-position rows: baseline, label, arrow, value
    annotate("segment", x = 56, xend = 74, y = ROW_Y, yend = ROW_Y,
             colour = "#DCDCDC", linewidth = 0.35) +
    annotate("text", x = 54, y = rows$y, label = POSITION_LABEL[rows$param], hjust = 1,
             family = FONT, size = 4.4, colour = COL_INK) +
    annotate("segment", x = 65, xend = 65, y = rows$y, yend = rows$y + rows$length,
             colour = rows$colour, linewidth = 2.1,
             arrow = arrow(length = unit(3.0, "mm"), type = "closed")) +
    annotate("text", x = 77, y = rows$y, label = fmt_signed(rows$rate), hjust = 0,
             family = FONT, fontface = "bold", size = 4.9, colour = rows$colour) +
    # citation
    annotate("text", x = 6, y = 3, label = cite, hjust = 0, vjust = 0,
             family = FONT, size = 3.4, colour = COL_VELOCITY) +
    coord_cartesian(xlim = c(0, 100), ylim = c(0, 100), expand = FALSE) +
    theme_void() + theme(plot.margin = margin(2, 2, 2, 2))
}

# ===== Compose and save =====

left <- draw_arrow_panel(filter(panel_summary, type == "ELE", eco == "Ter"),
                         "(a) Elevational shifts — terrestrial") /
        (draw_arrow_panel(filter(panel_summary, type == "LAT", eco == "Ter"),
                          "(b) Latitudinal — terrestrial", size_scale = 0.84) |
         draw_arrow_panel(filter(panel_summary, type == "LAT", eco == "Mar"),
                          "Latitudinal — marine", size_scale = 0.84))

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
