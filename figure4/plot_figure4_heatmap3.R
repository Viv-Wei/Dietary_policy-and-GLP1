suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(patchwork)})
F <- read.csv("results/figure4_annual_flows.csv")
asp <- F %>% filter(arm=="diet_asp") %>% select(iso3, yr, asp_y=flow)
F <- read.csv("results/figure4_annual_flows.csv")
asp <- F %>% filter(arm=="diet_asp") %>% select(iso3, yr, asp_y=flow)
S <- read.csv("results/figure4_scenario_trajectories.csv") %>%
  filter(coverage %in% c("0.20","0.50","afford")) %>%
  select(iso3, coverage, arm, yr, med) %>% pivot_wider(names_from=arm, values_from=med)
w <- F %>% filter(arm!="diet_asp") %>%
  pivot_wider(names_from=arm, values_from=flow) %>%
  rename(diet_y=diet, glp1_y=glp1, combo_y=combo) %>%
  left_join(asp, by=c("iso3","yr")) %>%
  left_join(S, by=c("iso3","coverage","yr")) %>%
  arrange(iso3, coverage, yr) %>% group_by(iso3, coverage) %>%
  mutate(mask   = (diet + glp1) < 0.01*(diet[yr==30] + glp1[yr==30]),
         mask_a = (cumsum(asp_y) + glp1) < 0.01*(sum(asp_y) + glp1[yr==30]),
         r_feas = ifelse(mask,   NA, pmax(pmin(log2(diet_y/glp1_y),  2), -2)),
         r_asp  = ifelse(mask_a, NA, pmax(pmin(log2(asp_y/glp1_y),   2), -2)),
         r_comb = ifelse(mask,   NA, pmin(log2(combo_y/glp1_y), 2))) %>% ungroup()
ord <- w %>% filter(coverage=="0.20") %>% group_by(iso3) %>%
  summarise(cx = ifelse(any(diet>glp1), min(yr[diet>glp1]), 99),
            r30 = log2(diet[yr==30]/glp1[yr==30])) %>% arrange(cx, desc(r30)) %>% pull(iso3)
w <- w %>% mutate(iso3 = factor(iso3, levels=rev(ord)),
                  coverage = factor(coverage, c("0.20","0.50","afford"),
                                    c("20% coverage","50% coverage","Price-permitted ceiling")))
cx <- w %>% group_by(iso3, coverage) %>%
  summarise(cxy = ifelse(any(diet>glp1), min(yr[diet>glp1]), NA), .groups="drop") %>% filter(!is.na(cxy))
S6 <- 1.6
base <- list(scale_x_continuous(breaks=c(1,10,20,30), expand=c(0,0)),
             theme_minimal(base_size=9.5*S6),
             theme(panel.grid=element_blank(),
                   strip.text=element_text(face="bold", size=8.5*S6),
                   axis.text.y=element_text(size=6.8*S6, colour="grey15"),
                   axis.text.x=element_text(size=7*S6),
                   axis.title.x=element_blank(), plot.margin=margin(4,8,4,4)))
div <- function(nm) scale_fill_gradient2(low="#8491B4", mid="white", high="#E64B35",
        midpoint=0, limits=c(-2,2), na.value="grey92", name=nm, guide="none")
p1 <- ggplot(w, aes(yr, iso3, fill=r_feas)) + geom_tile() + facet_grid(~coverage) +
  geom_point(data=cx, aes(cxy, iso3), inherit.aes=FALSE, size=1.1*S6, colour="#333333") +
  div(NULL) + labs(x=NULL, y=NULL) + base
p2 <- ggplot(w, aes(yr, iso3, fill=r_asp)) + geom_tile() + facet_grid(~coverage) +
  div(NULL) + labs(x=NULL, y=NULL) + base + theme(strip.text=element_blank())
p3 <- ggplot(w, aes(yr, iso3, fill=r_comb)) + geom_tile() + facet_grid(~coverage) +
  scale_fill_gradient(low="white", high="#5DCAA5", limits=c(0,2), na.value="grey92", guide="none") +
  labs(x=NULL, y=NULL) + base + theme(strip.text=element_blank())
W <- 10.5*S6
ggsave("figures/figure4_heat_feas.pdf",  p1, width=W, height=4.9*S6, device=cairo_pdf)
ggsave("figures/figure4_heat_feas.png",  p1, width=W, height=4.9*S6, dpi=330)
ggsave("figures/figure4_heat_asp.pdf",   p2, width=W, height=4.6*S6, device=cairo_pdf)
ggsave("figures/figure4_heat_asp.png",   p2, width=W, height=4.6*S6, dpi=330)
ggsave("figures/figure4_heat_combo.pdf", p3, width=W, height=4.6*S6, device=cairo_pdf)
ggsave("figures/figure4_heat_combo.png", p3, width=W, height=4.6*S6, dpi=330)
mklg <- function(sc, fn, h=1.5) {
  g <- ggplot(data.frame(x=1, f=0), aes(x, x, fill=f)) + geom_tile() + sc +
    theme_void() + theme(legend.position="left",
      legend.text=element_text(size=8*S6), legend.title=element_text(size=8.5*S6),
      legend.key.height=unit(.9*S6,"cm"))
  lg <- cowplot::get_legend(g)
  ggsave(paste0("figures/", fn, ".pdf"), lg, width=3.2*S6, height=h*S6, device=cairo_pdf)
  ggsave(paste0("figures/", fn, ".png"), lg, width=3.2*S6, height=h*S6, dpi=330)
}
mklg(scale_fill_gradient2(low="#8491B4", mid="white", high="#E64B35", midpoint=0, limits=c(-2,2),
     name="log2 annual ratio\ndiet / GLP-1"), "figure4_heat_legend_div")
mklg(scale_fill_gradient(low="white", high="#5DCAA5", limits=c(0,2),
     name="log2 annual ratio\ncombination / GLP-1"), "figure4_heat_legend_combo")
cat("done montage heatmaps\n")
