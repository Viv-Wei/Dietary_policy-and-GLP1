suppressMessages({library(ggplot2); library(dplyr); library(tidyr)})

d <- read.csv("submission/tables/tableS_equity_twoarm.csv", skip=3)
names(d) <- c("price","iso3","edu_label","edu","paf_ratio","afford",
              "afford_frac","diet_k","glp1_k","ratio")

d$edu_label <- factor(d$edu_label, 
  levels = c("Low education","Medium education","High education"))
d$price <- factor(d$price,
  levels = c("Branded","Generic $140/yr","Generic $28/yr"))

pooled <- d %>% group_by(price, edu_label) %>%
  summarise(diet = sum(diet_k), glp1 = sum(glp1_k), 
            n_zero = sum(glp1_k == 0), n_total = n(), .groups="drop") %>%
  mutate(ratio = diet / pmax(glp1, 0.1),
         ratio_label = ifelse(glp1 > 0, sprintf("%.0fx", ratio), "Inf"),
         zero_label = sprintf("%d/%d\nzero GLP-1", n_zero, n_total))

long <- pooled %>%
  pivot_longer(c(diet, glp1), names_to = "arm", values_to = "averted_k") %>%
  mutate(arm = factor(arm, levels = c("diet","glp1"),
                       labels = c("Dietary policy","GLP-1 treatment")))

p <- ggplot(long, aes(x = edu_label, y = averted_k, fill = arm)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  facet_wrap(~ price, nrow = 1) +
  geom_text(data = pooled, 
            aes(x = edu_label, y = pmax(diet, glp1) + 120, label = ratio_label),
            inherit.aes = FALSE, size = 3.5, fontface = "bold", colour = "grey20") +
  geom_text(data = pooled %>% filter(n_zero > 0),
            aes(x = edu_label, y = -80, label = zero_label),
            inherit.aes = FALSE, size = 2.5, colour = "#E64B35", fontface = "italic") +
  scale_fill_manual(values = c("Dietary policy" = "#00A087", "GLP-1 treatment" = "#E64B35"),
                    name = NULL) +
  scale_y_continuous(expand = expansion(mult = c(0.08, 0.15))) +
  labs(x = NULL, 
       y = "Deaths averted over 30 years (thousands, 19 countries pooled)",
       title = "Dietary policy versus GLP-1 treatment by education group and drug price",
       subtitle = "At branded prices, GLP-1 treatment averts zero deaths in the lowest education group in 17 of 19 countries",
       caption = "WHO catastrophic expenditure threshold: drug cost >10% of income = unaffordable. 20% coverage within eligible overweight population.") +
  theme_minimal(base_size = 10) +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold", size = 10),
        plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(size = 8, colour = "grey30"),
        plot.caption = element_text(size = 6.5, colour = "grey45", hjust = 0),
        legend.position = "top",
        axis.text.x = element_text(size = 8, angle = 15, hjust = 0.5))

ggsave("figures/figS_equity_twoarm_v3.pdf", p, width = 11, height = 5.5, device = cairo_pdf)
ggsave("figures/figS_equity_twoarm_v3.png", p, width = 11, height = 5.5, dpi = 350)
cat("done: figS_equity_twoarm_v3\n")
