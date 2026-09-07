library(ggplot2); library(patchwork)
CH <- c("Fully mediated (\u226599% via SBP/FPG/LDL)","Highly mediated (50\u201399%)",
        "Partially mediated (10\u2013<50%)","Minimally mediated (<10%)","Unmediated (no recorded pathway)")
PAL <- c("#00A087","#5CB8A6","#91D1C2","#F39B7F","#E64B35")
TI <- c("Global","Patent expiry \u22642027","Never filed","Protected")
TIP <- c("#F1EFE8","#D3D1C7","#B4B2A9","#888780")
RU <- c("Primary","Weighted by mediated fraction","Strict")
RUP <- c("#0F6E56","#1D9E75","#9FE1CB")
mk <- function(lv, pal, ttl, shp = NULL) {
  d <- data.frame(x = 1, y = 1, g = factor(lv, lv))
  p <- ggplot(d, aes(x, y, fill = g))
  p <- if (is.null(shp)) p + geom_tile() +
        scale_fill_manual(values = setNames(pal, lv), name = ttl,
          guide = guide_legend(ncol = 1, override.aes = list(shape = NA)))
   else p + geom_point(aes(shape = g), size = 3) +
        scale_shape_manual(values = shp, name = ttl) +
        scale_fill_manual(values = setNames(pal, lv), name = ttl)
  p + theme_void(base_size = 9) +
    theme(legend.key.size = unit(9, "pt"), legend.title = element_text(face = "bold", size = 8.5),
          legend.text = element_text(size = 8))
}
g <- function(p) cowplot::get_legend(p)
library(cowplot)
L <- plot_grid(g(mk(TI, TIP, "Patent status")), g(mk(CH, PAL, "Mediated fraction")),
               g(mk(RU, RUP, "Accounting rule", c(21,22,23))), nrow = 1, rel_widths = c(1,1.5,1.2))
ggsave("figures/figure1_legend.pdf", L, width = 7.5, height = 1.5, device = cairo_pdf)
ggsave("figures/figure1_legend.png", L, width = 7.5, height = 1.5, dpi = 400)
cat("done legend\n")
