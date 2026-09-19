suppressPackageStartupMessages({library(ggplot2); library(dplyr)})

d <- read.csv("submission/tables/tableS17_overlap_crossvalidation.csv", skip=3)
names(d) <- c("iso3","diet","glp1","combo","td_deaths","td_pct","bu_deaths","bu_pct")

highlight <- c("GLB","CHN","IND","USA","NGA","BRA")
d$label <- ifelse(d$iso3 %in% highlight, d$iso3, "")
d$highlight <- d$iso3 %in% highlight

p <- ggplot(d, aes(x = bu_pct, y = td_pct)) +
  geom_abline(slope = 1, intercept = 0, linetype = "22", colour = "grey50", linewidth = 0.4) +
  geom_point(aes(colour = highlight, size = highlight)) +
  geom_text(aes(label = label), nudge_x = 0.3, nudge_y = 0.08, size = 3, colour = "grey25") +
  scale_colour_manual(values = c("TRUE" = "#E64B35", "FALSE" = "grey60"), guide = "none") +
  scale_size_manual(values = c("TRUE" = 3, "FALSE" = 1.5), guide = "none") +
  labs(x = "Bottom-up overlap estimate (% of sum)\nfrom mediator-level offset analysis",
       y = "Top-down overlap estimate (% of sum)\nfrom life table combination arm",
       title = "Cross-validation of the independent action assumption",
       subtitle = "All points below the diagonal: life table overlap is smaller than mediator-level overlap,\nindicating the independent action assumption is conservative",
       caption = "Bottom-up: mediator-level offset (Supplementary Table 4). Top-down: diet + GLP-1 - combo (life table).") +
  coord_fixed(xlim = c(0, 7), ylim = c(0, 7)) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(size = 8, colour = "grey30"),
        plot.caption = element_text(size = 6, colour = "grey45", hjust = 0))

ggsave("figures/figS_overlap_crossvalidation.pdf", p, width = 6, height = 6, device = cairo_pdf)
ggsave("figures/figS_overlap_crossvalidation.png", p, width = 6, height = 6, dpi = 350)
cat("done: figS_overlap_crossvalidation\n")
