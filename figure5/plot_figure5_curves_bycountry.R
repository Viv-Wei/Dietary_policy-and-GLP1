suppressPackageStartupMessages({library(ggplot2); library(dplyr); library(tidyr); library(patchwork)})

lab <- c(v01="Fruits", v02="Vegetables", v05="Legumes", v06="Nuts & seeds",
         v08="Whole grains", v09="Processed meat", v10="Red meat",
         v15="SSB", v29="Omega-6", v30="Seafood omega-3", v34="Fibre", v37="Sodium")
FACTORS <- names(lab)
yr_pat  <- "^yr\\d+$"

FAC_PAL <- c(
  "Whole grains"="#00A087", "Fruits"="#4DBBD5", "Nuts & seeds"="#3C5488",
  "Legumes"="#E64B35", "Vegetables"="#F39B7F", "Fibre"="#91D1C2",
  "Sodium"="#8491B4", "SSB"="#B09C85", "Omega-6"="#7E6148",
  "Seafood omega-3"="#DC0000", "Processed meat"="#868686", "Red meat"="#CCCCCC")

# faded version (for non-top3)
lighten <- function(hex, amount = 0.65) {
  r <- col2rgb(hex)
  r <- r + (255 - r) * amount
  rgb(r[1,], r[2,], r[3,], maxColorValue = 255)
}
FAC_PAL_LIGHT <- sapply(FAC_PAL, lighten)

all_data <- list()
for (gv in FACTORS) {
  f <- paste0("results/f5_single_", gv, ".csv")
  if (!file.exists(f)) next
  dd <- read.csv(f) %>% filter(arm == "diet", iso3 != "GLB")
  yr_cols <- grep(yr_pat, names(dd), value = TRUE)
  agg <- dd %>% group_by(iso3, outcome) %>%
    summarise(across(all_of(yr_cols), sum), .groups = "drop") %>%
    pivot_longer(cols = all_of(yr_cols), names_to = "yn", values_to = "deaths") %>%
    mutate(yr = as.integer(sub("yr", "", yn)), gdd_var = gv, factor = lab[gv])
  all_data[[gv]] <- agg
}
long_all <- bind_rows(all_data)

mk_curves <- function(outcomes, title_str, out_stem) {
  long <- long_all %>% filter(outcome %in% outcomes) %>%
    group_by(iso3, factor, yr) %>% summarise(deaths = sum(deaths), .groups = "drop") %>%
    arrange(iso3, factor, yr) %>%
    group_by(iso3, factor) %>% mutate(cum = cumsum(deaths) / 1000) %>% ungroup()

  isos <- sort(unique(long$iso3))
  plots <- list()

  for (iso in isos) {
    sub <- long %>% filter(iso3 == iso)
    if (nrow(sub) == 0 || all(sub$cum == 0)) {
      plots[[iso]] <- ggplot() + labs(title = iso) + theme_void(base_size = 7) +
        theme(plot.title = element_text(face="bold", size=7.5, hjust=.5)) +
        annotate("text", x=.5, y=.5, label="No benefit", colour="grey60", size=2.2)
      next
    }

    rank <- sub %>% filter(yr == max(yr)) %>% arrange(desc(cum))
    top3 <- rank$factor[1:min(3, nrow(rank))]

    sub <- sub %>% mutate(is_top = factor %in% top3)

    # colour: top3 solid, others faded
    cols <- ifelse(sub$is_top, FAC_PAL[sub$factor], FAC_PAL_LIGHT[sub$factor])

    lbl <- sub %>% filter(factor %in% top3, yr == max(yr))

    p <- ggplot() +
      # non-top3: faded thin lines
      geom_line(data = sub %>% filter(!is_top),
                aes(yr, cum, group = factor, colour = factor),
                linewidth = .25, alpha = .6) +
      # top3: solid bold lines
      geom_line(data = sub %>% filter(is_top),
                aes(yr, cum, colour = factor),
                linewidth = .65) +
      # end labels
      geom_text(data = lbl,
                aes(yr, cum, label = factor, colour = factor),
                hjust = -0.05, size = 1.4, fontface = "bold", show.legend = FALSE) +
      scale_colour_manual(values = FAC_PAL, guide = "none") +
      scale_x_continuous(breaks = c(1, 10, 20, 30),
                         expand = expansion(mult = c(.03, .28))) +
      labs(x = NULL, y = NULL, title = iso) +
      theme_minimal(base_size = 6.5) +
      theme(panel.grid.minor = element_blank(),
            panel.grid.major = element_line(linewidth = .15, colour = "grey93"),
            plot.title = element_text(face = "bold", size = 7.5, hjust = 0),
            axis.text = element_text(size = 5),
            plot.margin = margin(2, 4, 2, 2),
            legend.position = "none")
    plots[[iso]] <- p
  }

  combined <- wrap_plots(plots, ncol = 5) +
    plot_annotation(title = title_str,
      subtitle = "Top 3 factors per country in bold; others in faded colour (same palette as pie charts)",
      caption = "x-axis: year; y-axis: cumulative averted (thousands). GLB excluded.",
      theme = theme(plot.title = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(size = 9, colour = "grey30"),
        plot.caption = element_text(size = 6.5, colour = "grey45", hjust = 0)))

  ggsave(paste0("figures/", out_stem, ".pdf"), combined, width = 15, height = 11, device = cairo_pdf)
  ggsave(paste0("figures/", out_stem, ".png"), combined, width = 15, height = 11, dpi = 350)
  cat(sprintf("done: %s\n", out_stem))
}

mk_curves(c("IHD","IschStroke"), "CVD deaths — 30-year trajectories by country", "figure5_curves_cvd")
cat("\nall done\n")
