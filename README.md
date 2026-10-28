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

## Data sources

- BioShifts v2 via BioShiftR (Lawlor 2026), commit `1aa1d2800168`
- BioShifts study-area polygons, https://osf.io/download/68b747593d97f9fb8567b34f/
- US exclusive economic zone, Marine Regions (VLIZ), https://www.marineregions.org
- US land, Natural Earth 1:50m Admin 0 – Details: Map Units (`ne_50m_admin_0_map_units`), via rnaturalearth
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
