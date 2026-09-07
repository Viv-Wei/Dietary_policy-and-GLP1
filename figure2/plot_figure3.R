# Figure 3 sankey: parameterised version
# Usage: Rscript plot_figure3.R [iso3] [outcome] [mode: plain|depth]
library(ggplot2); library(dplyr); library(ggalluvial)

args <- commandArgs(trailingOnly = TRUE)
ISO  <- ifelse(length(args) >= 1, args[1], "GLB")
OUTC <- ifelse(length(args) >= 2, args[2], "IHD")
MODE <- ifelse(length(args) >= 3, args[3], "plain")

OUT_TITLE <- c(IHD="ischaemic heart disease", IschStroke="ischaemic stroke",
               ICH="intracerebral haemorrhage", SAH="subarachnoid haemorrhage",
               T2D="type 2 diabetes", CKD="chronic kidney disease")[OUTC]

if (MODE == "depth") {
  d <- read.csv(sprintf("results/figure3_flows_%s_%s_depth.csv", ISO, OUTC))
  FILLVAR <- "seg"
  PAL <- c("Transmitted through a GLP-1 target, offset by 20% coverage"="#00A087",
           "Transmitted through a GLP-1 target, beyond what 20% coverage offsets"="#A8DED4",
           "Not transmitted through a GLP-1 target"="#B0B0B0")
} else {
  d <- read.csv(sprintf("results/figure3_flows_%s_%s.csv", ISO, OUTC))
  # colouring: mediator flows by channel syntax green, direct flow red
  d$seg <- ifelse(d$mediator == "Direct", "Direct (unreachable)",
                  paste0("Via ", d$mediator, " (reachable)"))
  FILLVAR <- "seg"
  PAL <- c("Via SBP (reachable)"="#00A087", "Via FPG (reachable)"="#4DBBD5",
           "Via LDL (reachable)"="#91D1C2", "Direct (unreachable)"="#E64B35")
}

d <- subset(d, deaths > 0)
thresh <- 0.015 * sum(d$deaths)
d <- d %>%
  group_by(factor) %>% mutate(fac_tot = sum(deaths)) %>% ungroup() %>%
  mutate(factor = ifelse(fac_tot < thresh, "Other (minor factors)", factor),
         mediator = factor(mediator, c("SBP","FPG","LDL","Direct"))) %>%
  count(factor, mediator, seg, wt = deaths, name = "deaths") %>%
  mutate(factor = reorder(factor, deaths, sum))

p <- ggplot(d, aes(axis1 = factor, axis2 = mediator, y = deaths/1000)) +
  geom_alluvium(aes(fill = seg), width = 1/8, alpha = .85) +
  geom_stratum(width = 1/8, fill = "grey96", colour = "grey55", linewidth = .25) +
  geom_text(stat = "stratum", aes(label = after_stat(stratum)), size = 2.4) +
  scale_x_discrete(limits = c("Dietary risk factor","Mediator pathway"),
                   expand = c(.12, .05)) +
  scale_fill_manual(values = PAL, name = NULL) +
  labs(y = sprintf("Diet-attributable %s deaths (thousands), %s 2023",
                   OUT_TITLE, ifelse(ISO=="GLB","global",ISO)),
       caption = paste("Flow widths: GBD 2023 attributable deaths split by official",
                       "mediation factors (Appendix Table S5). Flows from factors",
                       "below 1.5% of total burden pooled as minor.")) +
  theme_minimal(base_size = 10) +
  theme(axis.text.y = element_blank(), panel.grid = element_blank(),
        axis.title.x = element_blank(), legend.position = "top",
        legend.text = element_text(size = 7.5),
        plot.caption = element_text(size = 6.5, colour = "grey40", hjust = 0))

out <- sprintf("figures/figure3_all/figure3_%s_%s_%s", ISO, OUTC, MODE)
ggsave(paste0(out, ".pdf"), p, width = 8, height = 6.5, device = cairo_pdf)
ggsave(paste0(out, ".png"), p, width = 8, height = 6.5, dpi = 300)
cat("done:", out, "\n")
