suppressPackageStartupMessages({library(ggplot2); library(dplyr); library(patchwork)})

d <- read.csv("results/figure5_matrix_19c.csv")
lab <- c(v01="Fruits", v02="Vegetables", v05="Legumes", v06="Nuts & seeds",
         v08="Whole grains", v09="Processed meat", v10="Red meat",
         v15="SSB", v29="Omega-6", v30="Seafood omega-3", v34="Fibre", v37="Sodium")
d$factor <- lab[d$gdd_var]

FAC_PAL <- c(
  "Whole grains"="#00A087", "Fruits"="#4DBBD5", "Nuts & seeds"="#3C5488",
  "Legumes"="#E64B35", "Vegetables"="#F39B7F", "Fibre"="#91D1C2",
  "Sodium"="#8491B4", "SSB"="#B09C85", "Omega-6"="#7E6148",
  "Seafood omega-3"="#DC0000", "Processed meat"="#868686", "Red meat"="#CCCCCC")

glb_ord <- d %>% filter(iso3=="GLB", outcome %in% c("IHD","IschStroke")) %>%
  group_by(factor) %>% summarise(val = sum(pmax(averted_10yr,0)), .groups="drop") %>%
  arrange(desc(val)) %>% pull(factor)

mk_radial <- function(outcomes, title_str, out_stem) {
  dd <- d %>% filter(outcome %in% outcomes) %>%
    group_by(iso3, factor) %>% summarise(val = sum(pmax(averted_10yr, 0)), .groups="drop") %>%
    group_by(iso3) %>% mutate(share = val / sum(val) * 100) %>% ungroup()

  all_combos <- expand.grid(iso3 = unique(dd$iso3), factor = names(FAC_PAL), stringsAsFactors = FALSE)
  dd <- dd %>% right_join(all_combos, by = c("iso3","factor")) %>%
    mutate(val = ifelse(is.na(val), 0, val),
           share = ifelse(is.na(share), 0, share))

  fac_order <- if (all(outcomes %in% c("IHD","IschStroke"))) glb_ord else {
    dd %>% filter(iso3=="GLB") %>% arrange(desc(share)) %>% pull(factor)
  }
  dd$factor <- factor(dd$factor, levels = fac_order)

  isos <- c(sort(setdiff(unique(dd$iso3), "GLB")), "GLB")
  plots <- list()

  for (iso in isos) {
    sub <- dd %>% filter(iso3 == iso) %>% arrange(factor)
    sub$lbl <- ifelse(sub$share >= 10, sprintf("%.0f", sub$share), "")

    p <- ggplot(sub, aes(x = factor, y = share, fill = factor)) +
      geom_col(width = 0.85) +
      geom_text(aes(y = share + 1, label = lbl), size = 1.5, colour = "grey25") +
      scale_fill_manual(values = FAC_PAL, guide = "none") +
      coord_polar(start = 0) +
      ylim(-5, max(sub$share) * 1.4) +
      labs(title = iso) +
      theme_void(base_size = 7) +
      theme(plot.title = element_text(face = "bold", size = 7.5, hjust = 0.5),
            axis.text.x = element_text(size = 3.5, colour = "grey40"))
    plots[[iso]] <- p
  }

  leg_df <- data.frame(factor = factor(names(FAC_PAL), levels = fac_order), y = 1)
  p_leg <- ggplot(leg_df, aes(factor, y, fill = factor)) +
    geom_col() + scale_fill_manual(values = FAC_PAL, name = NULL) +
    guides(fill = guide_legend(ncol = 2)) +
    theme_void() + theme(legend.text = element_text(size = 7),
                          legend.key.size = unit(.35, "cm"))
  plots[["legend"]] <- wrap_elements(cowplot::get_legend(p_leg))

  combined <- wrap_plots(plots, ncol = 5) +
    plot_annotation(
      title = title_str,
      subtitle = "Bar height = share (%) of single-factor benefit. Factor order fixed by global ranking.",
      caption = "Labels shown for factors \u226510%. All 12 factors shown; zero-benefit factors have no bar.",
      theme = theme(
        plot.title = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(size = 9, colour = "grey30"),
        plot.caption = element_text(size = 6.5, colour = "grey45", hjust = 0)))

  ggsave(paste0("figures/", out_stem, ".pdf"), combined,
         width = 14, height = 12, device = cairo_pdf)
  ggsave(paste0("figures/", out_stem, ".png"), combined,
         width = 14, height = 12, dpi = 350)
  cat(sprintf("done: %s\n", out_stem))
}

mk_radial(c("IHD","IschStroke"), "CVD deaths — factor shares by country",
           "figure5_radial_cvd")
mk_radial("T2D_incidence", "New T2D cases — factor shares by country",
           "figure5_radial_t2d")
