# Paths used by every script. Run scripts from the repository root.

source_dir       <- "data/source"        # downloaded inputs, never written after download
intermediate_dir <- "data/intermediate"  # derived tables
results_dir      <- "results"            # the figure

dir.create(source_dir,       recursive = TRUE, showWarnings = FALSE)
dir.create(intermediate_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(results_dir,      recursive = TRUE, showWarnings = FALSE)
