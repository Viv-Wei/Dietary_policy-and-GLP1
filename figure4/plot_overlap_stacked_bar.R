library(ggplot2); library(dplyr); library(tidyr)

d <- read.csv("submission/tables/tableS16_overlap_sensitivity.csv", skip=3)
names(d) <- c("iso3","coverage","unknown_pct","diet","glp1",
              "combo_orig","combo_adj","add_over_glp1","add_over_diet")

glb <- d %>% filter(iso3 == "GLB")

glb <- glb %>% mutate(
  diet_additional = combo_adj - glp1,
  label = sprintf("%s\noverlap %s%%", coverage, unknown_pct),
  coverage = factor(coverage, levels = c("20%","50%","Affordable"))
)

long <- glb %>%
  select(coverage, unknown_pct, glp1, diet_additional) %>%
  pivot_longer(c(glp1, diet_additional), names_to = "component", values_to = "deaths") %>%
  mutate(
    component = factor(component,
      levels = c("diet_additional", "glp1"),
      labels = c("Additional benefit of dietary policy", "GLP-1 treatment alone")),
    unknown_label = paste0(unknown_pct, "%"),
    unknown_label = factor(unknown_label, levels = c("0%","25%","50%","75%","100%"))
  )

p <- ggplot(long, aes(x = unknown_label, y = deaths/1e6, fill = component)) +
  geom_col(width = 0.7, position = "stack") +
  facet_wrap(~ coverage, nrow = 1, strip.position = "top") +
  geom_hline(data = glb %>% distinct(coverage, diet),
             aes(yintercept = diet/1e6),
             linetype = "22", colour = "#00A087", linewidth = 0.5) +
  scale_fill_manual(values = c(
    "GLP-1 treatment alone" = "#E64B35",
    "Additional benefit of dietary policy" = "#00A087"),
    name = NULL) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(x = "Assumed overlap of unmeasured pathways",
       y = "Deaths averted over 30 years (millions)",
       title = "Combination benefit decomposed: GLP-1 alone vs additional dietary policy contribution",
       subtitle = "Green dashed line: dietary policy alone. At all scenarios, combination exceeds either single arm.",
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

ggsave("figures/figS_overlap_stacked_bar.pdf", p, width = 10, height = 5, device = cairo_pdf)
ggsave("figures/figS_overlap_stacked_bar.png", p, width = 10, height = 5, dpi = 350)
cat("done: figS_overlap_stacked_bar\n")
