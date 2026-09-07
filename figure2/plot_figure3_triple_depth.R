library(ggplot2); library(dplyr); library(ggalluvial)
args <- commandArgs(trailingOnly = TRUE)
ISO <- args[1]
d <- read.csv(sprintf("results/figure3_triple_depth_%s.csv", ISO))
thresh <- 0.012 * sum(d$deaths)
d <- d %>%
  group_by(factor) %>% mutate(ft = sum(deaths)) %>% ungroup() %>%
  mutate(factor = ifelse(ft < thresh, "Other (minor)", factor),
         mediator = factor(mediator, c("SBP","FPG","LDL","Direct")),
         outcome = dplyr::recode(outcome, "Ischaemic stroke"="IS", "Type 2 diabetes"="T2D"),
         outcome = factor(outcome, c("IHD","IS","ICH","SAH","T2D","CKD")),
         seg = factor(seg, c("Offset by GLP-1 (20% coverage)",
                             "Pathway open, flow insufficient",
                             "Unreachable (no pathway)"))) %>%
  count(factor, mediator, outcome, seg, wt = deaths, name = "deaths") %>%
  mutate(factor = reorder(factor, deaths, sum))
PAL <- c("Offset by GLP-1 (20% coverage)"="#00A087",
         "Pathway open, flow insufficient"="#A8DED4",
         "Unreachable (no pathway)"="#E64B35")
p <- ggplot(d, aes(axis1 = factor, axis2 = mediator, axis3 = outcome, y = deaths/1000)) +
  geom_alluvium(aes(fill = seg), width = 1/9, alpha = .85) +
  geom_stratum(width = 1/9, fill = "grey96", colour = "grey50", linewidth = .22) +
  geom_text(stat = "stratum", aes(label = after_stat(stratum)),
            size = 2.4, fontface = "bold") +
  scale_x_discrete(limits = c("Dietary risk factor","Mediator","Outcome"),
                   expand = c(.14, .04)) +
  scale_fill_manual(values = PAL, name = NULL, drop = FALSE,
                    guide = guide_legend(nrow = 1)) +
  labs(y = sprintf("Diet-attributable deaths (thousands), %s 2023",
                   ifelse(ISO == "GLB", "global", ISO)),
       caption = paste("Dark green: flow offset by GLP-1 at 20% coverage (on-treatment,",
                       "mediator-shift depth per country-outcome; params/glp1_depth_params.csv).",
                       "Light green: pathway open, drug flow insufficient. Red: no mediated pathway.",
                       "IS=ischaemic stroke.")) +
  theme_minimal(base_size = 11) +
  theme(axis.text.y = element_blank(), panel.grid = element_blank(),
        axis.title.x = element_blank(), legend.position = "top",
        legend.text = element_text(size = 7.4), legend.key.size = unit(9, "pt"),
        legend.margin = margin(0, 0, 0, 0),
        plot.caption = element_text(size = 5.0, colour = "grey40", hjust = 0))
out <- sprintf("figures/figure3_all/figure3_triple_depth_%s", ISO)
ggsave(paste0(out, ".pdf"), p, width = 5.6, height = 4.4, device = cairo_pdf)
ggsave(paste0(out, ".png"), p, width = 5.6, height = 4.4, dpi = 420)
cat("done:", out, "\n")
