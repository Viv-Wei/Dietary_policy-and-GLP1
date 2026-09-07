# Panel a reference figure: causal structure + GLP-1 dual pathway (topologically correct version)
library(ggplot2)

ell <- function(cx, cy, rx, ry, id)
  data.frame(x = cx + rx * cos(seq(0, 2*pi, len = 80)),
             y = cy + ry * sin(seq(0, 2*pi, len = 80)), id = id)

DG <- "#00A087"; LG <- "#5CB8A6"; RD <- "#E64B35"
FILLN <- "#8FD0C2"; EDGEN <- "#00695C"

nodes <- rbind(ell(50, 74, 7, 5.5, "SBP"), ell(50, 52, 7, 5.5, "FPG"),
               ell(50, 30, 7, 5.5, "LDL"), ell(24, 82, 5, 3.6, "BMI"))

seg <- function(x, y, xe, ye, col, lw = 0.9, lt = "solid")
  annotate("segment", x = x, y = y, xend = xe, yend = ye, colour = col,
           linewidth = lw, linetype = lt,
           arrow = arrow(length = unit(7, "pt"), type = "closed"))

p <- ggplot() +
  # mediator box (dashed)
  annotate("rect", xmin = 38, xmax = 62, ymin = 16, ymax = 90,
           fill = DG, alpha = 0.12, colour = DG, linetype = "dashed", linewidth = 0.5) +
  # dietary and outcome boxes
  annotate("rect", xmin = 2, xmax = 26, ymin = 40, ymax = 60,
           fill = "#DFF0EB", colour = EDGEN, linewidth = 0.6) +
  annotate("rect", xmin = 74, xmax = 98, ymin = 42, ymax = 70,
           fill = "#DFF0EB", colour = EDGEN, linewidth = 0.6) +
  geom_polygon(data = nodes, aes(x, y, group = id),
               fill = FILLN, colour = EDGEN, linewidth = 0.6) +
  # diet -> three mediators (mf)
  seg(26, 57, 42.2, 71, DG) + seg(26, 52, 41.5, 52, DG) + seg(26, 47, 42.2, 33, DG) +
  # mediator -> outcome
  seg(57.5, 72, 75, 64, DG) + seg(57.5, 52, 73.2, 55, DG) + seg(57.5, 32, 75, 47, DG) +
  # direct pathway (red arc)
  annotate("curve", x = 14, y = 38.5, xend = 88, yend = 43, curvature = 0.52,
           colour = RD, linewidth = 1.0,
           arrow = arrow(length = unit(8, "pt"), type = "closed")) +
  # GLP-1 -> BMI -> SBP/FPG (weight-mediated, light green)
  seg(13.5, 91, 19.5, 85, LG) +
  seg(28.5, 80.5, 42.4, 75.5, LG) + seg(27, 79, 41.8, 55, LG) +
  # GLP-1 -> box (weight-independent, dark green, elbow)
  seg(9, 88.5, 37.6, 58, DG, lw = 1.1) +
  # ---- text ----
  annotate("text", x = 50, y = 74, label = "SBP", fontface = "bold", size = 4.6, colour = EDGEN) +
  annotate("text", x = 50, y = 52, label = "FPG", fontface = "bold", size = 4.6, colour = EDGEN) +
  annotate("text", x = 50, y = 30, label = "LDL", fontface = "bold", size = 4.6, colour = EDGEN) +
  annotate("text", x = 24, y = 82, label = "\u2193BMI", fontface = "bold", size = 3.8, colour = EDGEN) +
  annotate("text", x = 14, y = 50, size = 3.9, fontface = "bold", colour = "grey15",
           label = "Dietary\nrisk factor\n(13 GBD dietary risks)", lineheight = .95) +
  annotate("text", x = 86, y = 56, size = 3.9, fontface = "bold", colour = "grey15",
           label = "Cardiometabolic\noutcome\nIHD, stroke subtypes,\nT2D, CKD", lineheight = .95) +
  annotate("text", x = 8, y = 94.5, label = "GLP-1 RA\n(semaglutide)",
           size = 3.6, fontface = "bold", hjust = 0, lineheight = .9) +
  annotate("text", x = 33, y = 66.5, label = "italic(mf)[1]", parse = TRUE, size = 3.6) +
  annotate("text", x = 33, y = 54.5, label = "italic(mf)[2]", parse = TRUE, size = 3.6) +
  annotate("text", x = 32, y = 42,   label = "italic(mf)[3]", parse = TRUE, size = 3.6) +
  annotate("text", x = 27, y = 40.5, label = "GBD 2023 Appendix S5", size = 2.5, colour = "grey40", hjust = 0.5) +
  annotate("text", x = 36, y = 87, hjust = 0.5, size = 3.0, colour = "#3E8E7E", fontface = "bold",
           label = "Weight-mediated pathway\n(~33% of CV benefit, SELECT*)", lineheight = .95) +
  annotate("text", x = 2, y = 70, hjust = 0, size = 2.9, colour = EDGEN, fontface = "bold",
           label = "Weight-independent (~67%*):\ndirect glycaemic (incretin),\nBP, lipid &\nanti-inflammatory effects",
           lineheight = .95) +
  annotate("text", x = 50, y = 19.5, label = "GLP-1-accessible mediators",
           size = 3.3, fontface = "bold", colour = EDGEN) +
  annotate("text", x = 50, y = 7, label = "Direct pathway (no mediation record)",
           size = 3.4, colour = RD, fontface = "bold") +
  annotate("text", x = 97, y = 4, hjust = 1, size = 2.4, colour = "grey40",
           label = "*Mediation shares from SELECT trial analysis of cardiovascular benefit (Method B; see Methods)") +
  coord_fixed(xlim = c(0, 100), ylim = c(0, 100), expand = FALSE) +
  theme_void()

ggsave("figures/schematic_panelA_reference.png", p, width = 7.4, height = 7.0, dpi = 300)
ggsave("figures/schematic_panelA_reference.pdf", p, width = 7.4, height = 7.0, device = cairo_pdf)
cat("done: figures/schematic_panelA_reference.{png,pdf}\n")
