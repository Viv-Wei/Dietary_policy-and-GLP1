suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(scatterpie)})
T <- read.csv("results/figure3_factor_split_CV4.csv")
cm <- read.csv("params/country_map.csv"); name <- setNames(cm$gbd_location_name, cm$iso3); name["GLB"] <- "Global"
SEGS <- c("Not transmitted through a GLP-1 target",
          "Transmitted through a GLP-1 target, beyond what 20% coverage offsets",
          "Transmitted through a GLP-1 target, offset by 20% coverage")
PAL <- c("#E64B35", "#A8DED4", "#00A087"); names(PAL) <- SEGS
W <- T %>% complete(iso3, factor, seg = SEGS, fill = list(pct = 0)) %>%
  select(iso3, factor, seg, pct) %>% pivot_wider(names_from = seg, values_from = pct) %>%
  mutate(country = name[iso3])
W <- W[rowSums(W[SEGS]) > 0, ]                         # leave cells with no positive attribution blank
ford <- W %>% filter(iso3 == "GLB") %>% arrange(desc(.data[[SEGS[3]]]), desc(.data[[SEGS[2]]])) %>% pull(factor)
cord <- W %>% filter(factor == "Sodium (high)", iso3 != "GLB") %>% arrange(.data[[SEGS[3]]]) %>% pull(country)
cord <- c(cord, "Global")
W <- W %>% mutate(x = match(factor, ford), y = match(country, rev(cord)))
S <- 1.6
p <- ggplot() +
  geom_scatterpie(data = W, aes(x = x, y = y, r = .47), cols = SEGS, colour = NA) +
  geom_hline(yintercept = 1.5, colour = "grey55", linewidth = .5) +
  coord_equal(clip = "off") +
  scale_x_continuous(breaks = seq_along(ford), labels = ford, position = "top", expand = expansion(add = .55)) +
  scale_y_continuous(breaks = seq_along(cord), labels = rev(cord), expand = expansion(add = .55)) +
  scale_fill_manual(values = PAL, breaks = SEGS, guide = "none") +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 11 * S) +
  theme(panel.grid = element_blank(),
        axis.text.x.top = element_text(angle = 45, hjust = 0, vjust = 0, size = 9 * S, colour = "grey15"),
        axis.text.y = element_text(size = 9.5 * S, colour = "grey15",
                                   face = ifelse(rev(cord) == "Global", "bold", "plain")),
        plot.margin = margin(4, 30 * S, 4, 4))
CELL <- 0.5; WDT <- (length(ford) + 3.6) * CELL * S; HGT <- (length(cord) + 3.2) * CELL * S
ggsave("figures/figure3_all/figureS_factor_pies.pdf", p, width = WDT, height = HGT, device = cairo_pdf)
ggsave("figures/figure3_all/figureS_factor_pies.png", p, width = WDT, height = HGT, dpi = 330)

## legend rendered separately
lg <- ggplot(data.frame(seg = factor(SEGS, levels = SEGS), v = 1), aes(x = 1, y = v, fill = seg)) +
  geom_col() +
  scale_fill_manual(values = PAL, name = NULL) +
  guides(fill = guide_legend(ncol = 1, byrow = TRUE, keywidth = unit(1.1 * S, "lines"), keyheight = unit(1.1 * S, "lines"))) +
  theme_void() + theme(legend.position = "left", legend.text = element_text(size = 10 * S, colour = "grey15"),
                       legend.spacing.y = unit(.5 * S, "lines"))
lg <- cowplot::get_legend(lg)
ggsave("figures/figure3_all/figureS_factor_pies_legend.pdf", lg, width = 5.2 * S, height = 1.6 * S, device = cairo_pdf)
ggsave("figures/figure3_all/figureS_factor_pies_legend.png", lg, width = 5.2 * S, height = 1.6 * S, dpi = 330)
cat("done pies + legend\n")
