library(ggplot2); library(dplyr); library(tidyr); library(patchwork)
args <- commandArgs(trailingOnly = TRUE)
OUTC <- ifelse(length(args) >= 1, args[1], "IHD")
OUT  <- ifelse(length(args) >= 2, args[2], paste0("figures/figure2_ratio_", OUTC))
IN   <- Sys.getenv("F2_IN", "results/figure2b_arms_ui_19c.csv")

d  <- read.csv(IN) %>% filter(outcome == OUTC)
cm <- read.csv("params/country_map.csv", fileEncoding = "UTF-8")
SC   <- c("sodium30","feasible","aspirational")
SCL  <- c("Sodium \u221230%","Feasible package","All factors 20% toward TMREL")
TIER <- c("Global","Patent expiry \u22642027","Never filed","Protected")
TIERPAL <- c("#4DBBD5","#00A087","#3C5488","#F39B7F")

w <- read.csv(Sys.getenv("F2_RATIO","results/figure2_ratio_ui.csv")) %>%
  filter(outcome == OUTC, scenario %in% SC) %>%
  rename(ratio = med, r_lo = lo, r_hi = hi) %>%
  left_join(cm %>% select(iso3, tier), by = "iso3") %>%
  mutate(scenario = factor(scenario, SC, SCL),
         tier = factor(tier, 0:3, TIER),
         iso_lab = ifelse(iso3 == "ISR", "ISR*", iso3))

f1 <- read.csv("results/figure1_channel_burden.csv") %>%
  filter(deaths > 0) %>% group_by(iso3) %>%
  summarise(tot = sum(deaths), .groups = "drop") %>%
  left_join(cm %>% select(iso3, tier), by = "iso3") %>%
  mutate(iso_lab = ifelse(iso3 == "ISR", "ISR*", iso3),
         tier = factor(tier, 0:3, TIER)) %>%
  arrange(tier, desc(tot))
LV <- rev(f1$iso_lab)
w$iso_lab <- factor(w$iso_lab, LV)

pA <- ggplot(w, aes(ratio, iso_lab, fill = scenario, shape = scenario)) +
  geom_vline(xintercept = 1, colour = "grey25", linewidth = .9) +
  geom_linerange(aes(y = iso_lab, xmin = r_lo, xmax = r_hi),
                 linewidth = .5, colour = "grey55", inherit.aes = FALSE) +
  geom_point(size = 3.4, stroke = .9, colour = "grey20") +
  facet_grid(tier ~ scenario, scales = "free", space = "free_y") +
  scale_x_log10() +
  scale_shape_manual(values = c(21, 22, 23), guide = "none") +
  scale_fill_manual(values = c("#A8DED4","#00A087","#3C7A6A"), guide = "none") +
  labs(x = "GLP-1 total effect relative to dietary scenario (ratio, log scale)", y = NULL) +
  theme_classic(base_size = 11) +
  theme(strip.background = element_blank(),
        strip.text.x = element_text(face = "bold", size = 10),
        strip.text.y = element_blank(),
        axis.text.y = element_text(size = 9, face = "bold"),
        panel.spacing.x = unit(6, "pt"), panel.spacing.y = unit(4, "pt"),
        plot.margin = margin(2, 1, 2, 2))

bar <- ggplot(distinct(w, tier, iso_lab), aes(x = 1, y = iso_lab, fill = tier)) +
  geom_tile() +
  facet_grid(tier ~ ., scales = "free_y", space = "free_y") +
  scale_fill_manual(values = TIERPAL, guide = "none") +
  theme_void() +
  theme(strip.text = element_blank(), panel.spacing.y = unit(4, "pt"),
        plot.margin = margin(2, 2, 2, 0))

p <- pA + bar + plot_layout(widths = c(1, 0.03))
ggsave(paste0(OUT, ".pdf"), p, width = 9.2, height = 6.2, device = cairo_pdf)
ggsave(paste0(OUT, ".png"), p, width = 9.2, height = 6.2, dpi = 400)
cat("done", OUTC, "\n")
