# Figure 1A/1B: channel decomposition x patent tiers - rate version final (per 100k adults >=25)
library(ggplot2); library(dplyr); library(tidyr); library(patchwork)

args <- commandArgs(trailingOnly = TRUE)
IN   <- ifelse(length(args) >= 1, args[1], "results/figure1_channel_burden.csv")
XLAB <- ifelse(length(args) >= 2, args[2],
               "Attributable deaths per 100 000 adults aged \u226525 years")
OUT  <- ifelse(length(args) >= 3, args[3], "figures/figure1_channel_burden")
SKIP_POP <- length(args) >= 4 && args[4] == "skip_pop"

d  <- read.csv(IN, fileEncoding = "UTF-8") %>% filter(!is.na(deaths))
cm <- read.csv("params/country_map.csv", fileEncoding = "UTF-8")

# ---- population (2023, Both, 25+ total) -> rate ----
pop <- read.csv("data/gbd/1-3_population.csv") %>%
  filter(year == 2023, sex_name == "Both", age_name != "All ages") %>%
  group_by(location_name) %>% summarise(pop = sum(val), .groups = "drop") %>%
  inner_join(cm %>% select(iso3, gbd_location_name),
             by = c("location_name" = "gbd_location_name"))
if (!SKIP_POP) {
d <- d %>% inner_join(pop %>% select(iso3, pop), by = "iso3") %>%
  mutate(deaths    = deaths    / pop * 1e5,
         deaths_lo = deaths_lo / pop * 1e5,
         deaths_hi = deaths_hi / pop * 1e5)
}
stopifnot(length(unique(d$iso3)) == 20)   # all 20 units must survive rate conversion

CH_LV <- c("Fully convergent-structure reachable","Highly convergent-largely reachable","Partially convergent-slightly reachable",
           "Minimally convergent-nearly unreachable","Unmediated-structure unreachable")
CH_EN <- c("Fully mediated (\u226599% via SBP/FPG/LDL)",
           "Highly mediated (50\u201399%)",
           "Partially mediated (10\u2013<50%)",
           "Minimally mediated (<10%)",
           "Unmediated (no recorded pathway)")
PAL   <- c("#00A087","#5CB8A6","#91D1C2","#F39B7F","#E64B35")
OUT_LV <- c("IHD","IschStroke","ICH","SAH","T2D","CKD")
OUT_EN <- c("IHD","IS","ICH","SAH","T2D","CKD")
TIER_EN <- c("Global","Patent expiry \u22642027","Never filed","Protected")

d <- d %>%
  left_join(cm %>% select(iso3, tier), by = "iso3") %>%
  mutate(channel = factor(glp1_channel, CH_LV, CH_EN),
         outcome = factor(outcome, OUT_LV, OUT_EN),
         tier    = factor(tier, c(0,1,2,3), TIER_EN),
         iso_lab = ifelse(iso3 == "ISR", "ISR*", iso3))
stopifnot(!any(is.na(d$channel)), !any(is.na(d$outcome)), !any(is.na(d$tier)))

ord <- d %>% filter(deaths > 0) %>%
  group_by(tier, iso_lab) %>% summarise(tot = sum(deaths), .groups = "drop") %>%
  arrange(tier, desc(tot))
d$iso_lab <- factor(d$iso_lab, levels = rev(ord$iso_lab))

pos <- d %>% filter(deaths > 0)
tot_ui <- pos %>% group_by(tier, iso_lab, outcome) %>%
  summarise(dd = sum(deaths),
            lo = dd - sqrt(sum((deaths - deaths_lo)^2)),
            hi = dd + sqrt(sum((deaths_hi - deaths)^2)), .groups = "drop")
neg <- d %>% filter(deaths < 0) %>%
  group_by(tier, iso_lab, outcome) %>%
  summarise(neg = sum(deaths), .groups = "drop") %>%
  mutate(lab = sprintf("%+.1f", neg))

CVD <- c("Ischaemic\nheart disease","Ischaemic\nstroke",
         "Intracerebral\nhaemorrhage","Subarachnoid\nhaemorrhage")
hl <- d %>% filter(iso3 == "GLB", outcome %in% CVD, deaths > 0) %>%
  summarise(u = sum(deaths[grepl("Minimally|Direct", channel)]) / sum(deaths) * 100) %>% pull(u)
cat(sprintf("Headline (CVD unreachable share, GLB): %.1f%%\n", hl))
HEADLINE <- sprintf(
  "%.0f%% of global diet-attributable cardiovascular burden lies beyond full GLP-1 mechanistic reach", hl)

pA <- ggplot(pos, aes(deaths, iso_lab, fill = channel)) +
  geom_col(width = .8) +
  geom_errorbarh(data = tot_ui, aes(y = iso_lab, xmin = lo, xmax = hi),
                 inherit.aes = FALSE, height = .28, linewidth = .3, colour = "grey30") +
  geom_text(data = neg, aes(x = Inf, y = iso_lab, label = lab),
            inherit.aes = FALSE, hjust = 1.02, size = 1.9, colour = "grey50") +
  facet_grid(tier ~ outcome, scales = "free", space = "free_y") +
  scale_fill_manual(values = setNames(PAL, CH_EN), name = NULL, drop = TRUE) +
  scale_x_continuous(n.breaks = 2, expand = expansion(mult = c(0, .16))) +
  labs(x = XLAB, y = NULL, tag = "a") +
  theme_classic(base_size = 10.5) +
  theme(legend.position = "none", plot.tag = element_text(size = 15, face = "bold"), plot.margin = margin(2, 2, 1, 2), strip.background = element_blank(),
        strip.text.x = element_text(face = "bold", size = 8.6),
        strip.text.y = element_blank(),
        panel.spacing.y = unit(4.5, "pt"), panel.spacing.x = unit(3.5, "pt"),
        plot.subtitle = element_text(face = "bold", size = 10.5, colour = "#B2352A"),
        axis.text.y = element_text(size = 7.6, face = "bold"),
        axis.text.x = element_text(size = 5.6))

pB <- pos %>% group_by(iso_lab, outcome) %>% mutate(share = deaths/sum(deaths)*100) %>%
  ggplot(aes(share, iso_lab, fill = channel)) +
  geom_col(width = .8) +
  facet_grid(tier ~ outcome, scales = "free_y", space = "free_y") +
  scale_fill_manual(values = setNames(PAL, CH_EN), name = NULL, drop = TRUE, guide = "none") +
  scale_x_continuous(breaks = c(0, 50, 100)) +
  labs(x = "Share of positive burden, 0 to 100% per panel", y = NULL, tag = "b",
       caption = paste0(
    "Rates are crude (not age-standardised) per 100 000 adults aged \u226525 years; an age-standardised ",
    "version is provided in the supplement. Countries grouped by semaglutide core-patent status ",
    "(MedsPaL/EPO records); within tiers ordered by total attributable rate. *Israel: expiry status pending ",
    "verification. Mediated fraction = summed mediation share via SBP/FPG/LDL, ",
    "truncated at 1; thresholds per GBD 2023 mediation factors (Appendix Table S5). The 50\u201399% category ",
    "contains no factor-outcome pairs under this rule. Red meat showed net protective attribution for ",
    "haemorrhagic stroke under the GBD 2023 J-shaped TMREL and is excluded from stacked bars (negative ",
    "rate offsets annotated at panel edges in a); shares computed over positive contributions only.")) +
  theme_classic(base_size = 10.5) +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), legend.position = "bottom", plot.tag = element_text(size = 15, face = "bold"), plot.margin = margin(1, 2, 2, 2), legend.key.size = unit(8.5, "pt"), legend.margin = margin(0, 0, 0, 0), legend.text = element_text(size = 7.8),
        strip.background = element_blank(), strip.text.x = element_blank(),
        strip.text.y = element_blank(),
        panel.spacing.y = unit(4.5, "pt"), panel.spacing.x = unit(3.5, "pt"),
        axis.text.y = element_text(size = 7.6, face = "bold"),
        plot.caption = element_text(size = 5.4, colour = "grey40", hjust = 0))

CVD4 <- c("IHD","IS","ICH","SAH")
acc <- pos %>% filter(outcome %in% CVD4) %>%
  group_by(tier, iso_lab) %>%
  summarise(primary  = sum(deaths[channel %in% CH_EN[4:5]]) / sum(deaths) * 100,
            weighted = (1 - sum(deaths * conv_wt) / sum(deaths)) * 100,
            strict   = sum(deaths[channel %in% CH_EN[3:5]]) / sum(deaths) * 100,
            .groups = "drop") %>%
  pivot_longer(c(primary, weighted, strict), names_to = "rule", values_to = "pct") %>%
  mutate(rule = factor(rule, c("primary","weighted","strict"),
                       c("Primary","Weighted by mediated fraction","Strict")))
seg <- acc %>% group_by(tier, iso_lab) %>%
  summarise(lo = min(pct, na.rm = TRUE), hi = max(pct, na.rm = TRUE), .groups = "drop") %>%
  filter(is.finite(lo), is.finite(hi))
pC <- ggplot(acc, aes(pct, iso_lab)) +
  geom_segment(data = seg, aes(x = lo, xend = hi, y = iso_lab, yend = iso_lab),
               colour = "#888780", linewidth = 0.55, inherit.aes = FALSE) +
  geom_point(aes(fill = rule, shape = rule, size = rule), colour = "#0F6E56", stroke = 0.5) +
  scale_shape_manual(values = c(21, 22, 23), guide = "none") +
  facet_grid(tier ~ ., scales = "free_y", space = "free_y") +
  scale_fill_manual(values = c("Primary" = "#0F6E56",
                               "Weighted by mediated fraction" = "#1D9E75",
                               "Strict" = "#9FE1CB"), name = NULL, guide = "none") +
  scale_size_manual(values = c(5.0, 4.6, 4.6), guide = "none") +
  scale_x_continuous(limits = c(20, 100), breaks = seq(20, 100, 20)) +
  labs(x = "Share of diet-attributable cardiovascular burden outside GLP-1 pathways (%)",
       y = NULL, tag = "c") +
  theme_classic(base_size = 10.5) +
  theme(legend.position = "bottom", plot.tag = element_text(size = 15, face = "bold"),
        plot.margin = margin(1, 2, 2, 2), legend.key.size = unit(8.5, "pt"),
        legend.text = element_text(size = 7.8), legend.margin = margin(0, 0, 0, 0),
        strip.background = element_blank(),
        strip.text.y = element_blank(),
        panel.spacing.y = unit(4.5, "pt"),
        axis.text.y = element_text(face = "bold", size = 8.2),
        panel.grid.major.x = element_line(colour = "grey92", linewidth = 0.3))

TIERPAL <- c("#4DBBD5","#00A087","#3C5488","#F39B7F")
mkbar <- function(df) ggplot(df, aes(x = 1, y = iso_lab, fill = tier)) +
  geom_tile() +
  facet_grid(tier ~ ., scales = "free_y", space = "free_y") +
  scale_fill_manual(values = TIERPAL, guide = "none", drop = FALSE) +
  theme_void() +
  theme(strip.text = element_blank(), panel.spacing.y = unit(4.5, "pt"))
bar1 <- mkbar(distinct(pos, tier, iso_lab))
bar2 <- mkbar(distinct(acc, tier, iso_lab))
pB <- pB + theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())
p <- ((pA | pB | bar1) + plot_layout(widths = c(1, 1, 0.035))) /
     ((pC | bar2) + plot_layout(widths = c(1, 0.018))) +
     plot_layout(heights = c(1, 0.85))
ggsave(paste0(OUT, ".pdf"), p, width = 7.5, height = 9.2, device = cairo_pdf)
ggsave(paste0(OUT, ".png"), p, width = 7.5, height = 9.2, dpi = 400)
cat("done:", OUT, "\n")
