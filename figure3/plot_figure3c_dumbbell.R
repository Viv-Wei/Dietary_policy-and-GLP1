suppressMessages({library(dplyr); library(ggplot2); library(jsonlite)})
cm <- read.csv("params/country_map.csv"); name <- setNames(cm$gbd_location_name, cm$iso3); name["GLB"] <- "Global"
fs <- list.files("params", "figure3_depth_.*_IHD\\.json", full.names = TRUE)
D <- bind_rows(lapply(fs, function(f) { j <- fromJSON(f); iso <- sub(".*depth_(.*)_IHD.*", "\\1", f)
  data.frame(iso3 = iso, diet = j$push$SBP, drug = j$glp_shift$SBP, depth = j$SBP) }))
D <- D %>% mutate(label = name[iso3], offset = pmin(diet, drug), beyond = pmax(diet - drug, 0))
T <- read.csv("results/figure3_factor_split_CV4.csv")
cord <- T %>% filter(factor == "Sodium (high)", seg == "Transmitted through a GLP-1 target, offset by 20% coverage", iso3 != "GLB") %>%
  arrange(pct) %>% pull(iso3)
D$label <- factor(D$label, levels = rev(c(name[cord], "Global")))   # same order as the pie matrix
drug <- D$drug[1]
S <- 1.6; drug <- D$drug[1]
p <- ggplot(D) +
  geom_col(aes(x = offset, y = label, fill = "Offset by GLP-1 at 20% coverage"), width = .62) +
  geom_segment(aes(x = offset, xend = diet, y = label, yend = label, colour = "Beyond what GLP-1 offsets"), linewidth = 4.4 * S) +
  geom_vline(xintercept = drug, colour = "#00A087", linewidth = .7, linetype = "22") +
  geom_text(aes(x = diet, y = label, label = sprintf("%.2f", depth)), hjust = -.3, size = 2.6 * S, colour = "grey30") +
  scale_fill_manual(values = c("Offset by GLP-1 at 20% coverage" = "#00A087"), name = NULL, guide = "none") +
  scale_colour_manual(values = c("Beyond what GLP-1 offsets" = "#A8DED4"), name = NULL, guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0, .1))) +
  coord_cartesian(clip = "off") +
  labs(x = "Diet-induced systolic blood pressure shift (mmHg)", y = NULL) +
  theme_minimal(base_size = 11 * S) +
  theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
        axis.text.y = element_text(size = 9.5 * S, colour = "grey15", face = ifelse(levels(D$label) == "Global", "bold", "plain")),
        axis.text.x = element_text(size = 9 * S), axis.title.x = element_text(size = 9.5 * S),
        plot.margin = margin(4, 30 * S, 4, 4))
ggsave("figures/figure3_all/figure3c_sbp_IHD.pdf", p, width = 6.5 * S, height = 9.3 * S, device = cairo_pdf)
ggsave("figures/figure3_all/figure3c_sbp_IHD.png", p, width = 6.5 * S, height = 9.3 * S, dpi = 330)
lg <- ggplot(data.frame(k = factor(c("Offset by GLP-1 at 20% coverage", "Beyond what GLP-1 offsets", "GLP-1 shift, 1.02 mmHg (5.10 mmHg × 20% coverage)"),
                                   levels = c("Offset by GLP-1 at 20% coverage", "Beyond what GLP-1 offsets", "GLP-1 shift, 1.02 mmHg (5.10 mmHg × 20% coverage)")), v = 1),
             aes(x = 1, y = v, fill = k)) + geom_col() +
  scale_fill_manual(values = c("#00A087", "#A8DED4", "white"), name = NULL) +
  guides(fill = guide_legend(ncol = 1, keywidth = unit(1.1 * S, "lines"), keyheight = unit(1.1 * S, "lines"))) +
  theme_void() + theme(legend.position = "left", legend.text = element_text(size = 10 * S, colour = "grey15"))
lg <- cowplot::get_legend(lg)
ggsave("figures/figure3_all/figure3c_legend.pdf", lg, width = 5 * S, height = 1.5 * S, device = cairo_pdf)
ggsave("figures/figure3_all/figure3c_legend.png", lg, width = 5 * S, height = 1.5 * S, dpi = 330)
cat("done c\n")
