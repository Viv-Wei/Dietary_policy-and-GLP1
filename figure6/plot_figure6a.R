library(ggplot2); library(dplyr); library(tidyr); library(patchwork)
paf <- read.csv("results/equity_paf_by_edu.csv") %>% filter(iso3!="GLB", edu %in% c(1,3))
ui  <- read.csv("results/equity_ratio_ui.csv")
ord <- ui %>% filter(outcome=="IschStroke") %>% arrange(med) %>% pull(iso3)
paf <- paf %>% mutate(iso3=factor(iso3,ord),
        edu=factor(edu,c(1,3),c("Low education","High education")),
        outcome=factor(outcome,c("IHD","IschStroke"),c("IHD","Ischaemic stroke")))
ui <- ui %>% filter(iso3 %in% ord) %>% mutate(iso3=factor(iso3,ord),
        outcome=factor(outcome,c("IHD","IschStroke"),c("IHD","Ischaemic stroke")))
pA <- ggplot(paf, aes(paf, iso3, fill=edu)) +
  geom_col(position=position_dodge(.7), width=.62) +
  facet_wrap(~outcome, nrow=1, scales="free_x") +
  scale_fill_manual(values=c("Low education"="#E64B35","High education"="#91D1C2"), name=NULL) +
  labs(x="Diet-attributable PAF (%)", y=NULL, tag="a") +
  theme_classic(base_size=10) +
  theme(strip.background=element_blank(), strip.text=element_text(face="bold",size=9),
        legend.position="top", axis.text.y=element_text(size=7,face="bold"))
pB <- ggplot(ui, aes(med, iso3, colour=outcome)) +
  geom_vline(xintercept=1, linetype=2, colour="grey55", linewidth=.4) +
  geom_linerange(aes(xmin=lo, xmax=hi), position=position_dodge(.5), linewidth=.5) +
  geom_point(position=position_dodge(.5), size=1.7) +
  scale_colour_manual(values=c("#E64B35","#4DBBD5"), name=NULL) +
  labs(x="Low/high-education PAF ratio (95% UI)", y=NULL, tag="b",
       caption=paste("MC over stratified and national exposure uncertainty (GDD 95% CIs);",
                     "dose-response curves held fixed; male exposure structure.")) +
  theme_classic(base_size=10) +
  theme(legend.position="top", axis.text.y=element_blank(), axis.ticks.y=element_blank(),
        plot.caption=element_text(size=5,colour="grey40",hjust=0))
p <- pA + pB + plot_layout(widths=c(1.9,1))
ggsave("figures/figure6a_edu_gradient.pdf", p, width=9.4, height=5.6, device=cairo_pdf)
ggsave("figures/figure6a_edu_gradient.png", p, width=9.4, height=5.6, dpi=350)
cat("done 6a final\n")
