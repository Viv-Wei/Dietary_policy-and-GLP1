suppressPackageStartupMessages({library(ggplot2); library(dplyr)})

ui <- read.csv("results/equity_ratio_ui.csv") %>%
  filter(iso3 != "GLB", outcome != "CKD") %>%
  mutate(outcome = factor(outcome,
    c("IHD","IschStroke","T2D"),
    c("IHD", "Ischaemic stroke", "Type 2 diabetes")))

ord <- ui %>% filter(outcome == "Ischaemic stroke") %>% arrange(med) %>% pull(iso3)
ui$iso3 <- factor(ui$iso3, levels = ord)

ui <- ui %>% mutate(
  hi_trunc = pmin(hi, 3.0),
  lo_trunc = pmax(lo, 0.5),
  arrow_hi = hi > 3.0,
  arrow_lo = lo < 0.5)

PAL <- c("IHD" = "#E64B35", "Ischaemic stroke" = "#4DBBD5",
         "Type 2 diabetes" = "#00A087")

p <- ggplot(ui, aes(med, iso3, colour = outcome)) +
  geom_vline(xintercept = 1, linetype = "22", colour = "grey50", linewidth = .4) +
  geom_linerange(aes(xmin = lo_trunc, xmax = hi_trunc),
                 position = position_dodge(width = .65), linewidth = .5, alpha = .6) +
  geom_point(position = position_dodge(width = .65), size = 3.2) +
  geom_text(data = ui %>% filter(arrow_hi),
            aes(x = hi_trunc, label = "\u2192"),
            position = position_dodge(width = .65),
            size = 2.5, show.legend = FALSE, hjust = -0.2) +
  geom_text(data = ui %>% filter(arrow_lo),
            aes(x = lo_trunc, label = "\u2190"),
            position = position_dodge(width = .65),
            size = 2.5, show.legend = FALSE, hjust = 1.2) +
  scale_colour_manual(values = PAL, name = NULL) +
  scale_x_continuous(breaks = c(0.5, 0.75, 1, 1.25, 1.5, 2.0, 2.5, 3.0),
                     limits = c(0.5, 3.2)) +
  labs(x = "Low / high education PAF ratio (95% UI)",
       y = NULL,
       title = "Educational gradient in diet-attributable disease burden",
       subtitle = "Ratio > 1 indicates higher burden in the low-education group",
       caption = paste("IHD, ischaemic stroke, and type 2 diabetes shown.",
                       "CKD excluded: attributable burden runs through sodium alone,",
                       "educational gradient inconsistent.\n",
                       "Monte Carlo (200 draws) over stratified and national exposure",
                       "uncertainty (GDD 95% CIs); dose\u2013response curves held fixed.",
                       "Arrows: UI truncated for display.")) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.y = element_line(linewidth = .2, colour = "grey93"),
        plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(size = 8.5, colour = "grey30"),
        plot.caption = element_text(size = 5.5, colour = "grey45", hjust = 0),
        axis.text.y = element_text(size = 8, face = "bold"),
        legend.position = "top")

ggsave("figures/figure6a_ratio_forest.pdf", p, width = 8, height = 7, device = cairo_pdf)
ggsave("figures/figure6a_ratio_forest.png", p, width = 8, height = 7, dpi = 350)
cat("done: figure6a (3 outcomes, no CKD)\n")
