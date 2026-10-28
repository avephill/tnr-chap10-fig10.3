# Figure 10.3: observed species range shifts in the US

Code for Figure 10.3, *Observed Species Range Shifts on Land and in the Ocean*,
in *The Nature Record*, Chapter 10 (Climate Change). Adapted from Lawlor et al.
(2024), Fig. 2.

- **Panels (a) and (b):** the percentage of range-shift observations from
  studies whose study area overlaps the US (land or exclusive economic zone)
  that moved in the same direction as local isotherms, the opposite direction,
  or not at all.
- **Right-hand boxes:** observed elevational shift rates for red fir (Wright et
  al. 2016) and the bushy-tailed woodrat (Moritz et al. 2008), next to climate
  velocity across each species' range.

All values come from the BioShifts database (v2), accessed through the
BioShiftR R package.

## Run

From the repository root, run each script in order:

```
code/00-BIOSHIFTS-00-download.R      downloads study-area polygons (OSF) and the US EEZ (Marine Regions) to data/source/
code/01-BIOSHIFTS-01-us-study-areas.R   writes data/intermediate/us_study_areas.csv
code/02-BIOSHIFTS-02-figure.R           writes results/fig10_3.svg and results/fig10_3.png
```

Paths are set in `code/0-0-project-settings.R`. Script 02 downloads the two
silhouettes from PhyloPic, so it needs a network connection.

## Requirements

R 4.5.2. The BioShifts data package must be pinned to the commit the figure
was built from, because its bundled data change without a version bump:

```r
remotes::install_github("Bioshifts/BioShiftR", ref = "1aa1d28001682cc418bf187c80827d9be727989b")
```

Other packages (versions used): dplyr 1.2.0, readr 2.2.0, ggplot2 4.0.2,
patchwork 1.3.2, rphylopic 1.7.0, svglite 2.2.2, ragg 1.5.0, sf 1.0.24
(GEOS 3.14.1), rnaturalearth 1.2.0, rnaturalearthdata 1.0.0.9000.

The figure uses the Helvetica Neue font, which ships with macOS. On other
systems the text will render in a substitute font.

## Data sources

- BioShifts v2 via BioShiftR (Lawlor 2026), commit `1aa1d2800168`
- BioShifts study-area polygons, https://osf.io/download/68b747593d97f9fb8567b34f/
- US exclusive economic zone, Marine Regions (VLIZ), https://www.marineregions.org
- US land, Natural Earth 1:50m admin-0 map units, via rnaturalearth
- Silhouettes, PhyloPic: *Abies magnifica* by T. Michael Keesey after MPF (CC0);
  *Peromyscus leucopus* by Edwin Price (CC BY 4.0), used as a stand-in because
  PhyloPic has no *Neotoma* silhouette

## License

Code: MIT (see `LICENSE`). Data and silhouettes keep their own licenses; the
*Peromyscus* silhouette (CC BY 4.0) must be credited wherever the figure is
published.

## References

Lawlor, J. A., et al. (2024). Mechanisms, detection and impacts of species
redistributions under climate change. *Nature Reviews Earth & Environment*,
5(5), 351–368. https://doi.org/10.1038/s43017-024-00527-z

Moritz, C., Patton, J. L., Conroy, C. J., Parra, J. L., White, G. C., &
Beissinger, S. R. (2008). Impact of a century of climate change on
small-mammal communities in Yosemite National Park, USA. *Science*, 322(5899),
261–264.

Wright, D. H., Nguyen, C. V., & Anderson, S. (2016). Upward shifts in
recruitment of high-elevation tree species in the northern Sierra Nevada,
California. *California Fish and Game*, 102(1), 17–31.
