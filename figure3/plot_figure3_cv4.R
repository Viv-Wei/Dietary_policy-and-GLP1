suppressMessages({library(dplyr); library(ggplot2); library(ggalluvial)})
args <- commandArgs(trailingOnly = TRUE); ISO <- args[1]
OUTS <- c(IHD="Ischaemic heart disease", IschStroke="Ischaemic stroke",
          ICH="Intracerebral haemorrhage", SAH="Subarachnoid haemorrhage")
SEGS <- c("Not transmitted through a GLP-1 target",
          "Transmitted through a GLP-1 target, beyond what 20% coverage offsets",
          "Transmitted through a GLP-1 target, offset by 20% coverage")
PAL  <- c("#E64B35", "#A8DED4", "#00A087"); names(PAL) <- SEGS
d <- bind_rows(lapply(names(OUTS), function(o)
  read.csv(sprintf("results/figure3_flows_%s_%s_depth.csv", ISO, o)) %>%
    mutate(outcome = OUTS[[o]])))
d <- d %>% count(factor, mediator, outcome, seg, wt = deaths, name = "deaths") %>%
  mutate(seg = factor(seg, levels = SEGS),
         mediator = factor(mediator, levels = c("Direct","SBP","LDL","FPG")),
         outcome = factor(outcome, levels = OUTS))
fo <- d %>% count(factor, wt = deaths) %>% arrange(n) %>% pull(factor)
fo <- c("Other factors", setdiff(fo, "Other factors"))
d$factor <- factor(d$factor, levels = fo)
d <- d %>% arrange(seg, mediator, outcome, factor)
pct <- d %>% count(seg, wt = deaths) %>% mutate(p = round(100*n/sum(n), 1))
p <- ggplot(d, aes(axis1 = factor, axis2 = mediator, axis3 = outcome, y = deaths)) +
  geom_alluvium(aes(fill = seg), width = 1/9, alpha = .85, knot.pos = .4,
                aes.bind = "alluvia", lode.guidance = "frontback") +
  geom_stratum(width = 1/9, fill = "white", colour = "grey30", linewidth = .3) +
  ggrepel::geom_text_repel(stat = "stratum", aes(label = after_stat(stratum)), size = 2.4,
            direction = "y", box.padding = .1, segment.size = .2, min.segment.length = 0) +
  scale_x_discrete(limits = c("Dietary factor", "Mediator", "Outcome"),
                   expand = c(.12, .05)) +
  scale_fill_manual(values = PAL, name = NULL,
                    labels = sprintf("%s (%s%%)", pct$seg, pct$p)) +
  scale_y_continuous(labels = function(x) x/1000, name = "Deaths (thousands)") +
  labs(title = sprintf("%s, four cardiovascular outcomes, 2023", ISO),
       caption = "Flows below 2% of each outcome pooled as Other factors.") +
  theme_minimal(base_size = 10) +
  theme(panel.grid = element_blank(), plot.margin = margin(6, 10, 6, 14), axis.title.x = element_blank(),
        legend.position = "top", legend.text = element_text(size = 7.5),
        plot.caption = element_text(size = 6.5, colour = "grey40", hjust = 0))
out <- sprintf("figures/figure3_all/figure3_%s_CV4", ISO)
ggsave(paste0(out, ".pdf"), p, width = 8.5, height = 7, device = cairo_pdf)
ggsave(paste0(out, ".png"), p, width = 8.5, height = 7, dpi = 300)
cat("done:", out, "\n")
