library(ggplot2); library(dplyr)
d  <- read.csv("results/figure3_offset_matrix.csv")
cm <- read.csv("params/country_map.csv", fileEncoding = "UTF-8")
TIER <- c("Global","Patent expiry \u22642027","Never filed","Protected")
d <- d %>% left_join(cm %>% select(iso3, tier), by = "iso3") %>%
  mutate(iso_lab = ifelse(iso3=="ISR","ISR*",iso3),
         tier = factor(tier, 0:3, TIER),
         outcome = factor(outcome, c("IHD","IS","ICH","SAH","T2D","CKD")))
ord <- d %>% group_by(iso3) %>% summarise(m = mean(offset_pct)) %>% arrange(m) %>% pull(iso3)
d$iso_lab <- factor(d$iso_lab, ifelse(ord=="ISR","ISR*",ord))
p <- ggplot(d, aes(outcome, iso_lab, fill = offset_pct)) +
  geom_tile(colour = "white", linewidth = .7) +
  geom_text(aes(label = sprintf("%.0f", offset_pct)), size = 2.5,
            colour = ifelse(d$offset_pct > 8, "white", "grey20")) +
  facet_grid(tier ~ ., scales = "free_y", space = "free_y") +
  scale_fill_gradient(low = "#F5FBF9", high = "#00A087",
                      name = "Offset by GLP-1\n(20% cov., %)") +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 11) +
  theme(panel.grid = element_blank(), strip.background = element_blank(),
        strip.text.y = element_text(face = "bold", angle = 0, hjust = 0, size = 7.8),
        axis.text.y = element_text(size = 7.6, face = "bold"),
        axis.text.x = element_text(size = 8, face = "bold"),
        legend.title = element_text(size = 7.2), legend.text = element_text(size = 7),
        panel.spacing.y = unit(4, "pt"))
ggsave("figures/figure3_all/f3_depth_heatmap_sample.png", p, width = 4.9, height = 5.2, dpi = 420)
ggsave("figures/figure3_all/f3_depth_heatmap_sample.pdf", p, width = 4.9, height = 5.2, device = cairo_pdf)
cat("done heatmap\n")
