suppressPackageStartupMessages({library(ggplot2); library(dplyr)})

r <- read.csv("results/figure2b_ckd_t2d_ratio_ui.csv")
r <- r %>% filter(iso3 != "GLB", scenario == "feasible") %>%
  mutate(outcome = factor(outcome,
    c("CKD","T2D"),
    c("CKD", "Type 2 diabetes")))

ord <- r %>% filter(outcome == "Type 2 diabetes") %>% arrange(med) %>% pull(iso3)
r$iso3 <- factor(r$iso3, levels = ord)

r <- r %>% mutate(
  hi_trunc = pmin(hi, 30),
  lo_trunc = pmax(lo, 0.5))

PAL <- c("CKD" = "#8491B4", "Type 2 diabetes" = "#00A087")

p <- ggplot(r, aes(med, iso3, colour = outcome)) +
  geom_vline(xintercept = 1, linetype = "22", colour = "grey50", linewidth = .4) +
  geom_linerange(aes(xmin = lo_trunc, xmax = hi_trunc),
                 position = position_dodge(width = .6), linewidth = .5, alpha = .6) +
  geom_point(position = position_dodge(width = .6), size = 3) +
  scale_colour_manual(values = PAL, name = NULL) +
  scale_x_log10(breaks = c(1, 2, 5, 10, 20, 30),
                limits = c(0.5, 35)) +
  labs(x = "GLP-1 treatment effect / feasible dietary package (ratio, log scale)",
       y = NULL,
       title = "GLP-1 treatment versus feasible dietary package: CKD and type 2 diabetes",
       subtitle = "Ratio > 1 indicates GLP-1 treatment averts a larger share than the feasible package",
       caption = paste("Monte Carlo: 200 draws for CKD, 100 draws for T2D.",
                       "CKD effect runs through sodium-blood pressure pathway only.",
                       "T2D compares incident cases averted. Log scale.")) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.y = element_line(linewidth = .2, colour = "grey93"),
        plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(size = 8.5, colour = "grey30"),
        plot.caption = element_text(size = 5.5, colour = "grey45", hjust = 0),
        axis.text.y = element_text(size = 8, face = "bold"),
        legend.position = "top")

ggsave("figures/figS2_ckd_t2d_ratio.pdf", p, width = 8, height = 7, device = cairo_pdf)
ggsave("figures/figS2_ckd_t2d_ratio.png", p, width = 8, height = 7, dpi = 350)
cat("done: figS2_ckd_t2d_ratio\n")
