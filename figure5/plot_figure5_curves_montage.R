suppressPackageStartupMessages({library(ggplot2); library(dplyr); library(tidyr); library(patchwork)})

lab <- c(v01="Fruits", v02="Vegetables", v05="Legumes", v06="Nuts & seeds",
         v08="Whole grains", v09="Processed meat", v10="Red meat",
         v15="SSB", v29="Omega-6", v30="Seafood omega-3", v34="Fibre", v37="Sodium")
FACTORS <- names(lab)
TOP_PAL <- c("#E64B35", "#00A087", "#3C5488")
yr_pat  <- "^yr\\d+$"

plots <- list()

for (gv in FACTORS) {
  f <- paste0("results/f5_single_", gv, ".csv")
  if (!file.exists(f)) next
  d <- read.csv(f)
  yr_cols <- grep(yr_pat, names(d), value = TRUE)

  # diet arm, drop GLB, aggregate yearly by country
  agg <- d %>% filter(arm == "diet", iso3 != "GLB") %>%
    group_by(iso3) %>%
    summarise(across(all_of(yr_cols), sum), .groups = "drop")

  long <- agg %>%
    pivot_longer(cols = all_of(yr_cols), names_to = "yn", values_to = "deaths") %>%
    mutate(yr = as.integer(sub("yr", "", yn))) %>%
    arrange(iso3, yr) %>%
    group_by(iso3) %>%
    mutate(cum = cumsum(deaths) / 1000) %>%
    ungroup()

  if (nrow(long) == 0 || all(long$cum == 0)) {
    # empty panel: title only
    plots[[gv]] <- ggplot() + labs(title = lab[gv]) +
      theme_void(base_size = 8) +
      theme(plot.title = element_text(face = "bold", size = 8, hjust = .5)) +
      annotate("text", x = .5, y = .5, label = "No single-factor\nbenefit",
               colour = "grey60", size = 2.4)
    next
  }

  # top3
  rank <- long %>% filter(yr == max(yr)) %>% arrange(desc(cum))
  top3 <- rank$iso3[1:min(3, nrow(rank))]

  long <- long %>%
    mutate(is_top = iso3 %in% top3,
           top_rank = match(iso3, top3))

  lbl <- long %>% filter(iso3 %in% top3, yr == max(yr))

  p <- ggplot() +
    geom_line(data = long %>% filter(!is_top),
              aes(yr, cum, group = iso3),
              colour = "grey82", linewidth = .25, alpha = .8) +
    geom_line(data = long %>% filter(is_top),
              aes(yr, cum, colour = factor(top_rank)),
              linewidth = .65) +
    geom_text(data = lbl,
              aes(yr, cum, label = iso3, colour = factor(top_rank)),
              hjust = -0.1, size = 1.9, fontface = "bold", show.legend = FALSE) +
    scale_colour_manual(values = TOP_PAL) +
    scale_x_continuous(breaks = c(1, 10, 20, 30),
                       expand = expansion(mult = c(.03, .12))) +
    scale_y_continuous(labels = function(x) ifelse(x >= 1000,
                       paste0(round(x/1000,1), "M"),
                       ifelse(x >= 1, paste0(round(x), "k"), ""))) +
    labs(x = NULL, y = NULL, title = lab[gv]) +
    theme_minimal(base_size = 7) +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major = element_line(linewidth = .2, colour = "grey92"),
          plot.title = element_text(face = "bold", size = 8, hjust = 0,
                                    margin = margin(0,0,1,0)),
          axis.text = element_text(size = 5.5),
          plot.margin = margin(3,6,3,3),
          legend.position = "none")
  plots[[gv]] <- p
}

# arrange 4 columns x 3 rows
combined <- wrap_plots(plots, ncol = 4) +
  plot_annotation(
    title    = "Single-factor 30-year trajectories (diet arm, 20% toward TMREL)",
    subtitle = "Top 3 countries highlighted; grey = remaining countries (GLB excluded)",
    caption  = "x-axis: year; y-axis: cumulative deaths averted (thousands). All CV + CKD outcomes combined.",
    theme = theme(
      plot.title    = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(size = 9, colour = "grey30"),
      plot.caption  = element_text(size = 6.5, colour = "grey45", hjust = 0)))

ggsave("figures/figure5_curves_montage.pdf", combined,
       width = 14, height = 9.5, device = cairo_pdf)
ggsave("figures/figure5_curves_montage.png", combined,
       width = 14, height = 9.5, dpi = 380)
cat("done: figure5_curves_montage\n")
