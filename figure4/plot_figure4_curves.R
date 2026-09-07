suppressMessages({library(dplyr); library(tidyr); library(ggplot2)})
S <- read.csv("results/figure4_scenario_trajectories.csv") %>% filter(coverage=="0.20" | arm=="diet_asp")
PICK <- c(CHN="China", ROU="Romania", IND="India", DEU="Germany")
ARMS <- c(diet="Feasible dietary package", diet_asp="Aspirational diet (ceiling)", glp1="GLP-1 treatment", combo="Combination")
PAL  <- c("Feasible dietary package"="#00A087", "Aspirational diet (ceiling)"="#00A087",
          "GLP-1 treatment"="#E64B35", "Combination"="#7E6148")
LTY  <- c("Feasible dietary package"="solid", "Aspirational diet (ceiling)"="22",
          "GLP-1 treatment"="solid", "Combination"="solid")
d <- S %>% filter(iso3 %in% names(PICK)) %>%
  mutate(panel = factor(PICK[iso3], levels=PICK), arm = factor(ARMS[arm], levels=ARMS))
cr <- d %>% filter(arm!="Combination") %>% select(panel, arm, yr, med) %>%
  pivot_wider(names_from=arm, values_from=med) %>% group_by(panel) %>%
  filter(`Feasible dietary package` > `GLP-1 treatment`) %>% summarise(cx=min(yr)) %>% filter(cx>1)
p <- ggplot(d, aes(yr, med/1000, colour=arm, fill=arm)) +
  geom_ribbon(aes(ymin=lo/1000, ymax=hi/1000), alpha=.16, colour=NA) +
  geom_line(aes(linetype=arm), linewidth=.8) +
  scale_linetype_manual(values=LTY, name=NULL) +
  geom_vline(data=cr, aes(xintercept=cx), linetype="22", colour="grey40", linewidth=.45) +
  geom_text(data=cr, aes(x=cx, y=Inf, label=paste0("year ", cx)), inherit.aes=FALSE,
            vjust=1.4, hjust=-.08, size=2.8, colour="grey30") +
  facet_wrap(~panel, ncol=2, scales="free_y") +
  scale_colour_manual(values=PAL, name=NULL) + scale_fill_manual(values=PAL, name=NULL) +
  scale_x_continuous(breaks=c(1,10,20,30)) +
  labs(x="Year", y="Cumulative deaths averted (thousands)") +
  theme_minimal(base_size=11) +
  theme(panel.grid.minor=element_blank(), legend.position="top",
        strip.text=element_text(face="bold", size=10))
ggsave("figures/figure4_curves_representative.pdf", p, width=9, height=7, device=cairo_pdf)
ggsave("figures/figure4_curves_representative.png", p, width=9, height=7, dpi=330)
cat("done curves\n")
