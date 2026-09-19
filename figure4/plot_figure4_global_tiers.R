suppressMessages({library(dplyr); library(tidyr); library(ggplot2)})
d <- read.csv("results/figure4_global_tiers.csv") %>%
  mutate(tier = factor(tier, c("0.20","0.50","afford"),
                       c("20% coverage","50% coverage","Price-permitted ceiling")),
         series = factor(series, c("glp1","combo","diet_feasible","diet_aspirational"),
                         c("GLP-1 treatment","Combination","Feasible dietary package","Aspirational diet (ceiling)")))
PAL <- c("GLP-1 treatment"="#E64B35","Combination"="#7E6148",
         "Feasible dietary package"="#00A087","Aspirational diet (ceiling)"="#00A087")
LTY <- c("GLP-1 treatment"="solid","Combination"="solid",
         "Feasible dietary package"="solid","Aspirational diet (ceiling)"="22")
p <- ggplot(d, aes(yr, med/1e6, colour=series, linetype=series, fill=series)) +
  geom_ribbon(aes(ymin=lo/1e6, ymax=hi/1e6), alpha=.13, colour=NA, show.legend=FALSE) +
  geom_line(linewidth=.85) +
  facet_wrap(~tier, ncol=3) +
  scale_colour_manual(values=PAL, name=NULL) +
  scale_linetype_manual(values=LTY, name=NULL) +
  scale_fill_manual(values=PAL, name=NULL) +
  scale_x_continuous(breaks=c(1,10,20,30)) +
  labs(x="Year", y="Cumulative deaths averted, global (millions)") +
  theme_minimal(base_size=10.5) +
  theme(panel.grid.minor=element_blank(), legend.position="top",
        strip.text=element_text(face="bold"))
ggsave("figures/figure4_global_tiers.pdf", p, width=11, height=4.6, device=cairo_pdf)
ggsave("figures/figure4_global_tiers.png", p, width=11, height=4.6, dpi=330)
cat("done tiers\n")
