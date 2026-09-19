suppressMessages({library(ggplot2); library(dplyr); library(tidyr); library(scales)})

d <- read.csv("results/cost_for_plot.csv")

col_diet <- "#2d9b8a"
col_glp1 <- "#e85d5d"

ord <- d %>% filter(Price.scenario=="Generic $140/yr") %>%
  arrange(desc(Ratio.GLP.1.Diet)) %>% pull(Country)
d$Country <- factor(d$Country, levels=ord)

d_long <- d %>% filter(Price.scenario=="Generic $140/yr") %>%
  select(Country, GLP1=GLP.1.cost.death..USD., Diet=Diet.cost.death..USD.) %>%
  pivot_longer(-Country, names_to="Arm", values_to="Cost")

p_dumbbell <- d %>% filter(Price.scenario=="Generic $140/yr") %>%
  ggplot() +
  geom_segment(aes(x=Diet.cost.death..USD., xend=GLP.1.cost.death..USD.,
                   y=Country, yend=Country), colour="grey70", linewidth=0.8) +
  geom_point(aes(x=Diet.cost.death..USD., y=Country), colour=col_diet, size=3) +
  geom_point(aes(x=GLP.1.cost.death..USD., y=Country), colour=col_glp1, size=3) +
  scale_x_continuous(labels=dollar_format(), trans="log10") +
  labs(x="Cost per death averted (USD, log scale)", y=NULL,
       title="Generic semaglutide $140/yr") +
  annotate("text", x=3000, y=19.5, label="Diet policy", colour=col_diet, fontface="bold", size=3.5) +
  annotate("text", x=40000, y=19.5, label="GLP-1 treatment", colour=col_glp1, fontface="bold", size=3.5) +
  theme_minimal(base_size=11) +
  theme(panel.grid.major.y=element_blank())

ggsave("figures/cost_option_A_dumbbell.pdf", p_dumbbell, width=7, height=6, device=cairo_pdf)
ggsave("figures/cost_option_A_dumbbell.png", p_dumbbell, width=7, height=6, dpi=300)
cat("✓ Option A: dumbbell\n")

d_bar <- d %>%
  select(Country, Price.scenario, GLP1=GLP.1.cost.death..USD., Diet=Diet.cost.death..USD.) %>%
  pivot_longer(c(GLP1,Diet), names_to="Arm", values_to="Cost") %>%
  mutate(Arm = factor(Arm, c("Diet","GLP1"), c("Dietary policy","GLP-1 treatment")),
         Price.scenario = factor(Price.scenario,
           c("Branded","Generic $140/yr","Generic $28/yr")))

p_bar <- ggplot(d_bar, aes(x=Country, y=Cost/1000, fill=Arm)) +
  geom_col(position="dodge", width=0.7) +
  scale_fill_manual(values=c(col_diet, col_glp1)) +
  facet_wrap(~Price.scenario, ncol=1, scales="free_y") +
  labs(x=NULL, y="Cost per death averted (thousands USD)", fill=NULL) +
  theme_minimal(base_size=10) +
  theme(axis.text.x=element_text(angle=45, hjust=1),
        legend.position="top")

ggsave("figures/cost_option_B_bars.pdf", p_bar, width=10, height=10, device=cairo_pdf)
ggsave("figures/cost_option_B_bars.png", p_bar, width=10, height=10, dpi=300)
cat("✓ Option B: paired bars\n")

p_scatter <- d %>% filter(Price.scenario=="Generic $140/yr") %>%
  ggplot(aes(x=Diet.cost.death..USD./1000, y=GLP.1.cost.death..USD./1000)) +
  geom_abline(slope=1, intercept=0, linetype="dashed", colour="grey50") +
  geom_point(size=3.5, colour=col_glp1, alpha=0.8) +
  geom_text(aes(label=Country), vjust=-0.8, size=2.8) +
  scale_x_continuous(limits=c(0,NA)) +
  scale_y_continuous(limits=c(0,NA)) +
  labs(x="Dietary policy: cost per death averted (k USD)",
       y="GLP-1 treatment: cost per death averted (k USD)",
       title="Generic semaglutide $140/yr") +
  annotate("text", x=50, y=10, label="GLP-1\ncheaper", colour=col_glp1, size=3, fontface="italic") +
  annotate("text", x=10, y=50, label="Diet\ncheaper", colour=col_diet, size=3, fontface="italic") +
  theme_minimal(base_size=11) +
  coord_equal()

ggsave("figures/cost_option_C_scatter.pdf", p_scatter, width=7, height=7, device=cairo_pdf)
ggsave("figures/cost_option_C_scatter.png", p_scatter, width=7, height=7, dpi=300)
cat("✓ Option C: scatter\n")

p_ratio <- d %>% filter(Price.scenario=="Generic $140/yr") %>%
  mutate(ratio = Ratio.GLP.1.Diet) %>%
  ggplot(aes(x=Country, y=ratio)) +
  geom_col(fill=col_glp1, alpha=0.8, width=0.6) +
  geom_hline(yintercept=1, linetype="dashed", colour="grey40") +
  annotate("text", x=0.5, y=1.1, label="Equal cost", hjust=0, size=3, colour="grey40") +
  labs(x=NULL, y="GLP-1 / Diet cost ratio\n(>1 = GLP-1 more expensive per death averted)",
       title="Generic semaglutide $140/yr vs dietary policy") +
  theme_minimal(base_size=11) +
  theme(axis.text.x=element_text(angle=45, hjust=1))

ggsave("figures/cost_option_D_ratio.pdf", p_ratio, width=8, height=5, device=cairo_pdf)
ggsave("figures/cost_option_D_ratio.png", p_ratio, width=8, height=5, dpi=300)
cat("✓ Option D: ratio bars\n")

cat("\nAll done!\n")
