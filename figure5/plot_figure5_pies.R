suppressPackageStartupMessages({
  library(ggplot2); library(dplyr); library(patchwork); library(cowplot)
  if (!requireNamespace("ggforce", quietly=TRUE)) install.packages("ggforce", repos="https://cloud.r-project.org")
  library(ggforce)
})

d <- read.csv("results/figure5_matrix_19c.csv") %>% filter(iso3 != "GLB")
lab <- c(v01="Fruits", v02="Vegetables", v05="Legumes", v06="Nuts & seeds",
         v08="Whole grains", v09="Processed meat", v10="Red meat",
         v15="SSB", v29="Omega-6", v30="Seafood omega-3", v34="Fibre", v37="Sodium")
d$factor <- lab[d$gdd_var]

FAC_PAL <- c(
  "Whole grains"="#00A087", "Fruits"="#4DBBD5", "Nuts & seeds"="#3C5488",
  "Legumes"="#E64B35", "Vegetables"="#F39B7F", "Fibre"="#91D1C2",
  "Sodium"="#8491B4", "SSB"="#B09C85", "Omega-6"="#7E6148",
  "Seafood omega-3"="#DC0000", "Processed meat"="#868686", "Red meat"="#CCCCCC")

mk_pies <- function(outcomes, title_str, out_stem) {
  dd <- d %>% filter(outcome %in% outcomes) %>%
    group_by(iso3, factor) %>% summarise(val = sum(pmax(averted_10yr, 0)), .groups="drop") %>%
    filter(val > 0) %>%
    group_by(iso3) %>% mutate(share = val / sum(val)) %>% ungroup()

  isos <- sort(unique(dd$iso3))
  plots <- list()

  for (iso in isos) {
    sub <- dd %>% filter(iso3 == iso) %>% arrange(desc(share)) %>%
      mutate(rnk = row_number())

    # compute arc start/end angles
    sub$end   <- cumsum(sub$share) * 2 * pi
    sub$start <- c(0, head(sub$end, -1))
    sub$mid   <- (sub$start + sub$end) / 2

    # explode top3 outward
    EXP <- 0.12
    sub$x0 <- ifelse(sub$rnk <= 3, EXP * sin(sub$mid), 0)
    sub$y0 <- ifelse(sub$rnk <= 3, EXP * cos(sub$mid), 0)

    # label position (at r=0.65)
    sub$lbl <- ifelse(sub$share >= 0.10, sprintf("%.0f%%", sub$share * 100), "")
    LR <- 0.62
    sub$lx <- sub$x0 + LR * sin(sub$mid)
    sub$ly <- sub$y0 + LR * cos(sub$mid)

    p <- ggplot(sub) +
      geom_arc_bar(aes(x0 = x0, y0 = y0, r0 = 0, r = 1,
                       start = start, end = end, fill = factor),
                   colour = "white", linewidth = .3) +
      geom_text(aes(x = lx, y = ly, label = lbl), size = 1.9, colour = "grey20") +
      scale_fill_manual(values = FAC_PAL, drop = TRUE, guide = "none") +
      coord_fixed(xlim = c(-1.3, 1.3), ylim = c(-1.3, 1.3)) +
      labs(title = iso) +
      theme_void(base_size = 7) +
      theme(plot.title = element_text(face = "bold", size = 8, hjust = .5))
    plots[[iso]] <- p
  }

  # legend
  leg_df <- data.frame(factor = factor(names(FAC_PAL), levels = names(FAC_PAL)), y = 1)
  p_leg <- ggplot(leg_df, aes(factor, y, fill = factor)) +
    geom_col() + scale_fill_manual(values = FAC_PAL, name = NULL) +
    guides(fill = guide_legend(ncol = 1)) +
    theme_void() + theme(legend.text = element_text(size = 7),
                         legend.key.size = unit(.35, "cm"))
  plots[["legend"]] <- wrap_elements(get_legend(p_leg))

  combined <- wrap_plots(plots, ncol = 5) +
    plot_annotation(title = title_str,
      subtitle = "Top 3 factors per country are offset from centre for emphasis",
      caption = "Labels shown for factors \u226510%. GLB excluded.",
      theme = theme(plot.title = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(size = 9, colour = "grey30"),
        plot.caption = element_text(size = 6.5, colour = "grey45", hjust = 0)))

  ggsave(paste0("figures/", out_stem, ".pdf"), combined, width = 12, height = 10, device = cairo_pdf)
  ggsave(paste0("figures/", out_stem, ".png"), combined, width = 12, height = 10, dpi = 350)
  cat(sprintf("done: %s\n", out_stem))
}

mk_pies(c("IHD","IschStroke"), "CVD deaths — factor shares by country", "figure5_pies_cvd")
mk_pies("T2D_incidence", "New T2D cases — factor shares by country", "figure5_pies_t2d")
