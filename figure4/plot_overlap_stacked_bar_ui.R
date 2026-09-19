library(ggplot2); library(dplyr); library(tidyr)

d <- read.csv("submission/tables/tableS16_overlap_sensitivity.csv", skip=3)
glb <- d %>% filter(iso3 == "GLB")

glb <- glb %>% mutate(
  coverage = factor(coverage, levels = c("20%","50%","Affordable")),
  unknown_label = paste0(unknown_overlap_pct, "%"),
  unknown_label = factor(unknown_label, levels = c("0%","25%","50%","75%","100%")),
  diet_additional_med = combo_adj_med - glp1_med,
  diet_additional_lo = combo_adj_lo - glp1_med,
  diet_additional_hi = combo_adj_hi - glp1_med
)

long <- glb %>%
  select(coverage, unknown_label, unknown_overlap_pct,
         glp1_med, diet_additional_med, combo_adj_lo, combo_adj_hi, diet_med) %>%
  pivot_longer(c(glp1_med, diet_additional_med), names_to = "component", values_to = "deaths") %>%
  mutate(component = factor(component,
    levels = c("diet_additional_med", "glp1_med"),
    labels = c("Additional benefit of dietary policy", "GLP-1 treatment alone")))

ui_data <- glb %>%
  mutate(combo_top = combo_adj_med / 1e6,
         combo_lo_m = combo_adj_lo / 1e6,
         combo_hi_m = combo_adj_hi / 1e6)

p <- ggplot(long, aes(x = unknown_label, y = deaths/1e6, fill = component)) +
  geom_col(width = 0.7, position = "stack") +
  geom_errorbar(data = ui_data,
                aes(x = unknown_label, y = combo_adj_med/1e6,
                    ymin = combo_adj_lo/1e6, ymax = combo_adj_hi/1e6,
                    fill = NULL),
                width = 0.25, linewidth = 0.4, colour = "grey30") +
  geom_hline(data = glb %>% distinct(coverage, diet_med),
             aes(yintercept = diet_med/1e6),
             linetype = "22", colour = "#00A087", linewidth = 0.5) +
  facet_wrap(~ coverage, nrow = 1, strip.position = "top") +
  scale_fill_manual(values = c(
    "GLP-1 treatment alone" = "#E64B35",
    "Additional benefit of dietary policy" = "#00A087"),
    name = NULL) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(x = "Assumed overlap of unmeasured pathways",
       y = "Deaths averted over 30 years (millions)",
       title = "Combination benefit decomposed across coverage and overlap scenarios",
       subtitle = "Error bars: 95% UI from 500 Monte Carlo samples. Green dashed line: dietary policy alone.",
       caption = "Pooled estimate across 19 study countries. Known mediator overlap captured in model; unmeasured overlap varied 0-100%.") +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        strip.text = element_text(face = "bold", size = 10),
        plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(size = 8, colour = "grey30"),
        plot.caption = element_text(size = 6, colour = "grey45", hjust = 0),
        legend.position = "top",
        legend.text = element_text(size = 8))

ggsave("figures/figS_overlap_stacked_bar_ui.pdf", p, width = 10, height = 5, device = cairo_pdf)
ggsave("figures/figS_overlap_stacked_bar_ui.png", p, width = 10, height = 5, dpi = 350)
cat("done: figS_overlap_stacked_bar_ui\n")
