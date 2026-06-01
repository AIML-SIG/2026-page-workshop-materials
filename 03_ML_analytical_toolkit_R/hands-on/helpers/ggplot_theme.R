suppressPackageStartupMessages(library(ggplot2))

# named colours
navy        <- "#0F3259"
blue        <- "#156082"
orange      <- "#E97132"
sky         <- "#0F9ED5"
green       <- "#196B24"

cluster_pal <- c("#0F9ED5", "#E97132", "#196B24", "#7E57C2", "#9CA3AF")  # up to 5 clusters
outcome_pal <- c("#0F3259", "#E97132")                                   # no event / event

# Branded ggplot2 theme; base_size scales all text.
theme_workshop <- function(base_size = 12) {
  theme_bw(base_size = base_size) +
    theme(
      panel.grid.minor    = element_blank(),
      strip.background    = element_rect(fill = "grey92", colour = NA),
      strip.text          = element_text(face = "bold"),
      plot.title          = element_text(face = "bold", colour = navy),
      plot.subtitle       = element_text(colour = "grey30"),
      legend.position     = "right"
    )
}
