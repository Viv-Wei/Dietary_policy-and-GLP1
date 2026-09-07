suppressPackageStartupMessages({
  library(ggplot2); library(dplyr); library(tidyr); library(patchwork); library(cowplot)
  library(ggforce)
})

d <- read.csv("results/figure5_matrix_19c.csv") %>% filter(iso3 == "GLB")
lab <- c(v01="Fruits", v02="Vegetables", v05="Legumes", v06="Nuts & seeds",
         v08="Whole grains", v09="Processed meat", v10="Red meat",
         v15="SSB", v29="Omega-6", v30="Seafood omega-3", v34="Fibre", v37="Sodium")
d$factor <- lab[d$gdd_var]

FAC_PAL <- c(
  "Whole grains"="#00A087", "Fruits"="#4DBBD5", "Nuts & seeds"="#3C5488",
  "Legumes"="#E64B35", "Vegetables"="#F39B7F", "Fibre"="#91D1C2",
  "Sodium"="#8491B4", "SSB"="#B09C85", "Omega-6"="#7E6148",
  "Seafood omega-3"="#DC0000", "Processed meat"="#868686", "Red meat"="#CCCCCC")

# ============================================================
# Panel A: Global CVD pie
# ============================================================
cvd <- d %>% filter(outcome %in% c("IHD","IschStroke")) %>%
  group_by(factor) %>% summarise(val = sum(pmax(averted_10yr, 0)), .groups="drop") %>%
  filter(val > 0) %>% mutate(share = val / sum(val)) %>% arrange(desc(share)) %>%
  mutate(rnk = row_number())

cvd$end   <- cumsum(cvd$share) * 2 * pi
cvd$start <- c(0, head(cvd$end, -1))
cvd$mid   <- (cvd$start + cvd$end) / 2
EXP <- 0.12
cvd$x0 <- ifelse(cvd$rnk <= 3, EXP * sin(cvd$mid), 0)
cvd$y0 <- ifelse(cvd$rnk <= 3, EXP * cos(cvd$mid), 0)
cvd$lbl <- ifelse(cvd$share >= 0.06,
                  paste0(cvd$factor, "\n", sprintf("%.1f%%", cvd$share * 100)), "")
LR <- 0.65
cvd$lx <- cvd$x0 + LR * sin(cvd$mid)
cvd$ly <- cvd$y0 + LR * cos(cvd$mid)

p_pie_cvd <- ggplot(cvd) +
  geom_arc_bar(aes(x0=x0, y0=y0, r0=0, r=1, start=start, end=end, fill=factor),
               colour="white", linewidth=.4) +
  geom_text(aes(x=lx, y=ly, label=lbl), size=2.4, colour="grey15", lineheight=.85) +
  scale_fill_manual(values=FAC_PAL, drop=TRUE, guide="none") +
  coord_fixed(xlim=c(-1.5,1.5), ylim=c(-1.5,1.5)) +
  labs(title="Global — CVD deaths") +
  theme_void(base_size=9) +
  theme(plot.title=element_text(face="bold", size=11, hjust=.5))

# ============================================================
# Panel B: Global T2D pie
# ============================================================
t2d <- d %>% filter(outcome == "T2D_incidence") %>%
  group_by(factor) %>% summarise(val = sum(pmax(averted_10yr, 0)), .groups="drop") %>%
  filter(val > 0) %>% mutate(share = val / sum(val)) %>% arrange(desc(share)) %>%
  mutate(rnk = row_number())

t2d$end   <- cumsum(t2d$share) * 2 * pi
t2d$start <- c(0, head(t2d$end, -1))
t2d$mid   <- (t2d$start + t2d$end) / 2
t2d$x0 <- ifelse(t2d$rnk <= 3, EXP * sin(t2d$mid), 0)
t2d$y0 <- ifelse(t2d$rnk <= 3, EXP * cos(t2d$mid), 0)
t2d$lbl <- ifelse(t2d$share >= 0.06,
                  paste0(t2d$factor, "\n", sprintf("%.1f%%", t2d$share * 100)), "")
t2d$lx <- t2d$x0 + LR * sin(t2d$mid)
t2d$ly <- t2d$y0 + LR * cos(t2d$mid)

p_pie_t2d <- ggplot(t2d) +
  geom_arc_bar(aes(x0=x0, y0=y0, r0=0, r=1, start=start, end=end, fill=factor),
               colour="white", linewidth=.4) +
  geom_text(aes(x=lx, y=ly, label=lbl), size=2.4, colour="grey15", lineheight=.85) +
  scale_fill_manual(values=FAC_PAL, drop=TRUE, guide="none") +
  coord_fixed(xlim=c(-1.5,1.5), ylim=c(-1.5,1.5)) +
  labs(title="Global — New T2D cases") +
  theme_void(base_size=9) +
  theme(plot.title=element_text(face="bold", size=11, hjust=.5))

# ============================================================
# Panel C: Global CVD curves (12 factors over 30yr)
# ============================================================
yr_pat <- "^yr\\d+$"
all_data <- list()
for (gv in names(lab)) {
  f <- paste0("results/f5_single_", gv, ".csv")
  if (!file.exists(f)) next
  dd <- read.csv(f) %>% filter(arm == "diet", iso3 == "GLB",
                                 outcome %in% c("IHD","IschStroke"))
  yr_cols <- grep(yr_pat, names(dd), value = TRUE)
  agg <- dd %>% group_by(iso3) %>%
    summarise(across(all_of(yr_cols), sum), .groups = "drop") %>%
    pivot_longer(cols = all_of(yr_cols), names_to = "yn", values_to = "deaths") %>%
    mutate(yr = as.integer(sub("yr", "", yn)), factor = lab[gv]) %>%
    arrange(yr) %>% mutate(cum = cumsum(deaths) / 1000)
  all_data[[gv]] <- agg
}
long <- bind_rows(all_data)

rank <- long %>% filter(yr == max(yr)) %>% arrange(desc(cum))
top3 <- rank$factor[1:3]
long <- long %>% mutate(is_top = factor %in% top3)
lbl <- long %>% filter(factor %in% top3, yr == max(yr))

p_curve <- ggplot() +
  geom_line(data = long %>% filter(!is_top),
            aes(yr, cum, group = factor, colour = factor),
            linewidth = .4, alpha = .5) +
  geom_line(data = long %>% filter(is_top),
            aes(yr, cum, colour = factor), linewidth = .9) +
  geom_text(data = lbl,
            aes(yr, cum, label = factor, colour = factor),
            hjust = -0.05, size = 2.8, fontface = "bold", show.legend = FALSE) +
  scale_colour_manual(values = FAC_PAL, guide = "none") +
  scale_x_continuous(breaks = c(1, 5, 10, 15, 20, 25, 30),
                     expand = expansion(mult = c(.02, .18))) +
  labs(x = "Year", y = "Cumulative CVD deaths averted (thousands)",
       title = "Global — 30-year trajectories by factor") +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 11))

# ============================================================
# Shared legend
# ============================================================
leg_df <- data.frame(factor = factor(names(FAC_PAL), levels = names(FAC_PAL)), y = 1)
p_leg <- ggplot(leg_df, aes(factor, y, fill = factor)) +
  geom_col() + scale_fill_manual(values = FAC_PAL, name = NULL) +
  guides(fill = guide_legend(ncol = 2)) +
  theme_void() + theme(legend.text = element_text(size = 8),
                        legend.key.size = unit(.4, "cm"))
leg_grob <- get_legend(p_leg)

# ============================================================
# Compose: pies on top, curve below, legend right
# ============================================================
top_row <- p_pie_cvd + p_pie_t2d
full <- (top_row / p_curve) | wrap_elements(leg_grob)
full <- full + plot_layout(widths = c(4, 1)) +
  plot_annotation(
    title = "Global single-factor analysis (20% toward TMREL, 30-year)",
    theme = theme(plot.title = element_text(face = "bold", size = 13)))

ggsave("figures/figure5_global.pdf", full, width = 13, height = 9, device = cairo_pdf)
ggsave("figures/figure5_global.png", full, width = 13, height = 9, dpi = 350)
cat("done: figure5_global\n")
