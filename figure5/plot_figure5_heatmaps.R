suppressPackageStartupMessages({library(ggplot2); library(dplyr); library(tidyr); library(patchwork)})

d <- read.csv("results/figure5_matrix_19c.csv")
lab <- c(v01="Fruits", v02="Vegetables", v05="Legumes", v06="Nuts & seeds",
         v08="Whole grains", v09="Processed meat", v10="Red meat",
         v15="SSB", v29="Omega-6", v30="Seafood omega-3", v34="Fibre", v37="Sodium")
d$factor <- lab[d$gdd_var]

# normalise share separately within each outcome
d <- d %>% group_by(outcome, iso3) %>%
  mutate(share = averted_10yr / sum(pmax(averted_10yr, 0)) * 100) %>% ungroup()

# factor ordering: by total contribution across all outcomes in GLB
ordf <- d %>% filter(iso3=="GLB") %>% group_by(factor) %>%
  summarise(tot = sum(pmax(share,0)), .groups="drop") %>% arrange(tot) %>% pull(factor)
d$factor <- factor(d$factor, levels = ordf)

OUTMAP <- c(IHD = "IHD", IschStroke = "Ischaemic stroke",
            CKD = "CKD", T2D_incidence = "New T2D cases")

mk_heat <- function(oc, ttl) {
  dd <- d %>% filter(outcome == oc) %>%
    mutate(share_clip = pmax(share, 0),
           lbl = ifelse(is.na(share) | abs(averted_10yr) < 1, "\u00d7",
                 ifelse(share >= 8, sprintf("%.0f", share), "")),
           is_x = lbl == "\u00d7")

  ggplot(dd, aes(iso3, factor, fill = share_clip)) +
    geom_tile(colour = "white", linewidth = .5) +
    geom_text(aes(label = lbl, colour = is_x), size = 2.0, show.legend = FALSE) +
    scale_colour_manual(values = c("FALSE" = "grey20", "TRUE" = "#B0B0B0")) +
    scale_fill_gradient(low = "white", high = "#00A087",
                        na.value = "grey95", name = "Share (%)") +
    labs(x = NULL, y = NULL, title = ttl) +
    theme_minimal(base_size = 9) +
    theme(panel.grid = element_blank(),
          plot.title = element_text(face = "bold", size = 10),
          axis.text.x = element_text(size = 6, face = "bold", angle = 45, hjust = 1),
          axis.text.y = element_text(size = 7, face = "bold"),
          legend.key.height = unit(.35, "cm"),
          legend.key.width  = unit(.6, "cm"),
          legend.title = element_text(size = 7),
          legend.text  = element_text(size = 6),
          legend.position = "right")
}

p1 <- mk_heat("IHD", "IHD")
p2 <- mk_heat("IschStroke", "Ischaemic stroke")
p3 <- mk_heat("CKD", "CKD")
p4 <- mk_heat("T2D_incidence", "New T2D cases")

# combine into 2x2
ptop <- p1 + p2 + plot_layout(guides = "collect") & theme(legend.position = "right")
pbot <- p3 + p4 + plot_layout(guides = "collect") & theme(legend.position = "right")
pfull <- ptop / pbot +
  plot_annotation(
    caption = paste("Within-country shares: each factor's contribution to the country's total",
                    "single-factor (20% toward TMREL, 30-year) benefit.",
                    "Labels shown for cells \u22658%. \u00d7 = no GBD pairing or intake within TMREL range."),
    theme = theme(plot.caption = element_text(size = 6, colour = "grey40", hjust = 0)))

ggsave("figures/figure5_heatmaps_4panel.pdf", pfull, width = 12, height = 9, device = cairo_pdf)
ggsave("figures/figure5_heatmaps_4panel.png", pfull, width = 12, height = 9, dpi = 350)
cat("done: figure5_heatmaps_4panel\n")
