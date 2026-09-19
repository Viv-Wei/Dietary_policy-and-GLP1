suppressMessages({library(ggplot2); library(dplyr); library(tidyr); library(patchwork)})

d <- read.csv("submission/tables/tableS_equity_twoarm.csv", skip=3)
names(d) <- c("price","iso3","edu_label","edu","paf_ratio","afford",
              "afford_frac","diet_k","glp1_k","ratio")

d$edu_label <- factor(d$edu_label, 
  levels = c("Low education","Medium education","High education"))
d$price <- factor(d$price,
  levels = c("Branded","Generic $140/yr","Generic $28/yr"))
d$iso_lab <- ifelse(d$iso3 %in% c("CHN","IND","USA","NGA","BGD","BRA","DEU","EGY"), d$iso3, "")

th <- theme_minimal(base_size = 8) +
  theme(panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold", size = 8),
        plot.title = element_text(face = "bold", size = 9),
        plot.subtitle = element_text(size = 6.5, colour = "grey30"),
        legend.text = element_text(size = 7),
        legend.key.size = unit(6, "pt"),
        axis.text = element_text(size = 7),
        plot.margin = margin(4,4,4,4))

pooled <- d %>% group_by(price, edu_label) %>%
  summarise(diet = sum(diet_k), glp1 = sum(glp1_k),
            n_zero = sum(glp1_k == 0), n_total = n(), .groups="drop") %>%
  mutate(ratio_label = ifelse(glp1 > 0, sprintf("%.0fx", diet/glp1), ">100x"),
         zero_label = sprintf("%d/%d", n_zero, n_total))

long <- pooled %>%
  pivot_longer(c(diet, glp1), names_to = "arm", values_to = "averted_k") %>%
  mutate(arm = factor(arm, levels = c("diet","glp1"),
                       labels = c("Diet","GLP-1")))

pa <- ggplot(long, aes(x = edu_label, y = averted_k, fill = arm)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  facet_wrap(~ price, nrow = 1) +
  geom_text(data = pooled,
            aes(x = edu_label, y = pmax(diet, glp1) + 100, label = ratio_label),
            inherit.aes = FALSE, size = 2.8, fontface = "bold", colour = "grey20") +
  geom_text(data = pooled %>% filter(n_zero > 0),
            aes(x = edu_label, y = -50, label = paste0(zero_label, "\nzero")),
            inherit.aes = FALSE, size = 2, colour = "#E64B35") +
  scale_fill_manual(values = c("Diet" = "#00A087", "GLP-1" = "#E64B35"), name = NULL) +
  scale_y_continuous(expand = expansion(mult = c(0.06, 0.12))) +
  labs(x = NULL, y = "Deaths averted (k)", title = "a  Pooled (19 countries)") +
  th + theme(legend.position = "top",
             axis.text.x = element_text(size = 6.5, angle = 20, hjust = 0.5))

pb <- ggplot(d, aes(x = diet_k, y = glp1_k)) +
  geom_abline(slope = 1, intercept = 0, linetype = "22", colour = "grey50", linewidth = 0.3) +
  geom_point(aes(colour = edu_label), size = 1.2, alpha = 0.8) +
  geom_text(aes(label = iso_lab), size = 1.6, nudge_y = 4, colour = "grey30") +
  facet_grid(price ~ edu_label, scales = "free") +
  scale_colour_manual(values = c("Low education" = "#E64B35",
                                  "Medium education" = "#F39B7F",
                                  "High education" = "#00A087"), guide = "none") +
  labs(x = "Diet averted (k)", y = "GLP-1 averted (k)",
       title = "b  Country-level") +
  th + theme(panel.spacing = unit(4, "pt"))

d_ratio <- d %>%
  mutate(ratio_num = ifelse(glp1_k > 0, diet_k / glp1_k, 20),
         ratio_num = pmin(ratio_num, 20))

ord <- d_ratio %>% filter(price == "Branded", edu == 1) %>%
  arrange(ratio_num) %>% pull(iso3)
d_ratio$iso3 <- factor(d_ratio$iso3, levels = ord)

pc <- ggplot(d_ratio, aes(x = ratio_num, y = iso3, colour = edu_label)) +
  geom_vline(xintercept = 1, linetype = "22", colour = "grey50") +
  geom_point(size = 1.5, position = position_dodge(width = 0.5), alpha = 0.8) +
  facet_wrap(~ price, nrow = 1) +
  scale_colour_manual(values = c("Low education" = "#E64B35",
                                  "Medium education" = "#F39B7F",
                                  "High education" = "#00A087"), name = NULL) +
  scale_x_continuous(breaks = c(1, 2, 5, 10, 20),
                     labels = c("1x","2x","5x","10x","20x+"),
                     trans = "log10") +
  labs(x = "Diet / GLP-1 ratio (log)", y = NULL,
       title = "c  Diet-to-GLP-1 ratio") +
  th + theme(legend.position = "top",
             axis.text.y = element_text(size = 6, face = "bold"),
             panel.spacing = unit(6, "pt"))

layout <- "
AAAA
BBCC
BBCC
"

combined <- pa + pb + pc + plot_layout(design = layout) +
  plot_annotation(
    title = "Equity analysis: dietary policy versus GLP-1 treatment by education and drug price",
    subtitle = "WHO catastrophic expenditure threshold (>10% of income = unaffordable). Diet coverage: population-wide. GLP-1: 20% of eligible overweight.",
    theme = theme(
      plot.title = element_text(face = "bold", size = 11),
      plot.subtitle = element_text(size = 7, colour = "grey30")))

ggsave("figures/figS_equity_montage.pdf", combined, width = 12, height = 10, device = cairo_pdf)
ggsave("figures/figS_equity_montage.png", combined, width = 12, height = 10, dpi = 400)
cat("done: figS_equity_montage\n")
