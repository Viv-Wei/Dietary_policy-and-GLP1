suppressMessages({library(ggplot2); library(dplyr); library(tidyr); library(patchwork)})

d <- read.csv("submission/tables/tableS_equity_twoarm.csv", skip=3)
names(d) <- c("price","iso3","edu_label","edu","paf_ratio","afford",
              "afford_frac","diet_k","glp1_k","ratio")

d$edu_label <- factor(d$edu_label, 
  levels = c("Low education","Medium education","High education"))
d$price <- factor(d$price,
  levels = c("Branded","Generic $140/yr","Generic $28/yr"))

d$iso_lab <- ifelse(d$iso3 %in% c("CHN","IND","USA","NGA","BGD","BRA","DEU","EGY"), d$iso3, "")

p_scatter <- ggplot(d, aes(x = diet_k, y = glp1_k)) +
  geom_abline(slope = 1, intercept = 0, linetype = "22", colour = "grey50", linewidth = 0.4) +
  geom_point(aes(colour = edu_label), size = 2, alpha = 0.8) +
  geom_text(aes(label = iso_lab), size = 2, nudge_y = 5, colour = "grey30") +
  facet_grid(price ~ edu_label, scales = "free") +
  scale_colour_manual(values = c("Low education" = "#E64B35",
                                  "Medium education" = "#F39B7F",
                                  "High education" = "#00A087"), guide = "none") +
  labs(x = "Deaths averted by dietary policy (thousands)",
       y = "Deaths averted by GLP-1 (thousands)",
       title = "Country-level comparison by education group and drug price",
       subtitle = "Points below diagonal: dietary policy averts more. Points at y=0: GLP-1 unaffordable.") +
  theme_minimal(base_size = 9) +
  theme(strip.text = element_text(face = "bold", size = 9),
        plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(size = 7.5, colour = "grey30"),
        panel.spacing = unit(8, "pt"))

ggsave("figures/figS_equity_scatter_v3.pdf", p_scatter, width = 10, height = 9, device = cairo_pdf)
ggsave("figures/figS_equity_scatter_v3.png", p_scatter, width = 10, height = 9, dpi = 350)
cat("done: scatter\n")

d_ratio <- d %>%
  mutate(ratio_num = ifelse(glp1_k > 0, diet_k / glp1_k, 20),
         ratio_num = pmin(ratio_num, 20))

ord <- d_ratio %>% filter(price == "Branded", edu == 1) %>% 
  arrange(ratio_num) %>% pull(iso3)
d_ratio$iso3 <- factor(d_ratio$iso3, levels = ord)

p_dumbbell <- ggplot(d_ratio, aes(x = ratio_num, y = iso3, colour = edu_label)) +
  geom_vline(xintercept = 1, linetype = "22", colour = "grey50") +
  geom_point(size = 2, position = position_dodge(width = 0.5), alpha = 0.8) +
  facet_wrap(~ price, nrow = 1) +
  scale_colour_manual(values = c("Low education" = "#E64B35",
                                  "Medium education" = "#F39B7F",
                                  "High education" = "#00A087"),
                      name = NULL) +
  scale_x_continuous(breaks = c(1, 2, 5, 10, 20),
                     labels = c("1x","2x","5x","10x","20x+"),
                     trans = "log10") +
  labs(x = "Diet / GLP-1 ratio (log scale)", y = NULL,
       title = "Diet-to-GLP-1 ratio by education, country, and drug price",
       subtitle = "Values >1: dietary policy averts more. Capped at 20x. At branded prices, most low-education ratios hit the cap.") +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold", size = 10),
        plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(size = 7.5, colour = "grey30"),
        legend.position = "top",
        axis.text.y = element_text(size = 7, face = "bold"),
        panel.spacing = unit(10, "pt"))

ggsave("figures/figS_equity_dumbbell_v3.pdf", p_dumbbell, width = 12, height = 7, device = cairo_pdf)
ggsave("figures/figS_equity_dumbbell_v3.png", p_dumbbell, width = 12, height = 7, dpi = 350)
cat("done: dumbbell\n")

cat("all done\n")
