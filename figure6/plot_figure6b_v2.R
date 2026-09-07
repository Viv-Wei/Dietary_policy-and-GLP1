# Figure 6b v2: affordability tile matrix (country x quintile x price scenario, five-level colour bands)
suppressPackageStartupMessages({library(ggplot2); library(dplyr); library(tidyr)})
d <- read.csv("results/affordability_matrix.csv")
long <- d %>%
  select(iso3, quintile, Branded = afford_brand_pct,
         Generic = afford_generic_hi_pct) %>%
  pivot_longer(c(Branded, Generic), names_to = "scenario", values_to = "pct") %>%
  mutate(
    scenario = factor(scenario, levels = c("Branded", "Generic"),
                      labels = c("Branded price (2024\u201325)",
                                 "Generic price, upper bound ($140/yr)")),
    band = cut(pct, breaks = c(-Inf, 5, 10, 50, 100, Inf),
               labels = c("\u22645%",
                          ">5\u201310%",
                          ">10\u201350%",
                          ">50\u2013100%",
                          ">100% (exceeds annual income)")),
    lab = ifelse(pct >= 100, sprintf("%.1f\u00d7", pct/100),
          ifelse(pct >= 10,  sprintf("%.0f%%", pct), sprintf("%.1f%%", pct))),
    dark = band %in% c(">50\u2013100%", ">100% (exceeds annual income)"))
# countries ordered by brand-price Q1
ord <- d %>% filter(quintile == "Q1") %>% arrange(afford_brand_pct) %>% pull(iso3)
long$iso3 <- factor(long$iso3, levels = ord)
pal <- c("\u22645%"                             = "#00A087",
         ">5\u201310%"                          = "#91D1C2",
         ">10\u201350%"                         = "#F39B7F",
         ">50\u2013100%"                        = "#E64B35",
         ">100% (exceeds annual income)"        = "#8B0000")
pb <- ggplot(long, aes(quintile, iso3, fill = band)) +
  geom_tile(colour = "white", linewidth = 1.2) +
  geom_text(aes(label = lab, colour = dark), size = 1.9, show.legend = FALSE) +
  scale_colour_manual(values = c(`FALSE` = "grey15", `TRUE` = "white")) +
  scale_fill_manual(values = pal, name = "Annual cost as share of\nper-capita income") +
  facet_wrap(~scenario) +
  labs(x = "Income quintile (Q1 = poorest)", y = NULL,
       caption = paste0("Income: World Bank quintile shares (2022\u20132024) \u00d7 GNI per capita (Atlas, 2025).\n",
                        "Generic bound: Levi et al. Obesity 2026. Cells >100% shown as multiples of annual income.\n",
                        "IND/NGA quintiles from consumption surveys; Q1\u2013Q2 affordability conservatively overestimated.")) +
  theme_minimal(base_size = 10) +
  theme(panel.grid = element_blank(),
        strip.text = element_text(face = "bold", size = 9.5),
        legend.position = "right",
        legend.text = element_text(size = 7.5),
        legend.title = element_text(size = 8),
        axis.text.y = element_text(face = "bold"),
        plot.caption = element_text(size = 6.3, colour = "grey40", hjust = 0))
ggsave("figures/figure6b_affordability_v2.pdf", pb, width = 9.6, height = 7.4, device = cairo_pdf)
ggsave("figures/figure6b_affordability_v2.png", pb, width = 9.6, height = 7.4, dpi = 300)
cat("done: figure6b_affordability_v2\n")
