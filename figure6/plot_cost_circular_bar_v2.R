suppressMessages({library(ggplot2); library(dplyr); library(tidyr); library(scales); library(patchwork)})

d <- read.csv("results/cost_for_plot.csv")
col_diet <- "#2d9b8a"
col_glp1 <- "#e85d5d"

ord <- d %>% filter(Price.scenario=="Generic $140/yr") %>%
  arrange(GLP.1.cost.death..USD.) %>% pull(Country)

d_long <- d %>%
  select(Country, Price.scenario, 
         `Dietary policy`=Diet.cost.death..USD., 
         `GLP-1 treatment`=GLP.1.cost.death..USD.) %>%
  pivot_longer(c(`Dietary policy`,`GLP-1 treatment`), 
               names_to="Arm", values_to="Cost") %>%
  mutate(Country = factor(Country, levels=ord),
         Arm = factor(Arm, c("Dietary policy","GLP-1 treatment")),
         Cost_k = Cost / 1000)

prices <- c("Branded","Generic $140/yr","Generic $28/yr")
plots <- list()

for (i in seq_along(prices)) {
  price <- prices[i]
  sub <- d_long %>% filter(Price.scenario == price)
  
  plots[[i]] <- ggplot(sub, aes(x=Country, y=sqrt(Cost_k), fill=Arm)) +
    geom_col(position=position_dodge(width=0.8), width=0.7) +
    scale_fill_manual(values=c(col_diet, col_glp1)) +
    scale_y_continuous(
      breaks=sqrt(c(0, 5, 10, 25, 50, 100, 250)),
      labels=c("$0k","$5k","$10k","$25k","$50k","$100k","$250k")
    ) +
    coord_polar(start=0) +
    labs(title=price, y=NULL, x=NULL, fill=NULL) +
    theme_minimal(base_size=9) +
    theme(
      axis.text.x = element_text(size=8, face="bold"),
      axis.text.y = element_text(size=7),
      panel.grid.major.x = element_blank(),
      plot.title = element_text(hjust=0.5, face="bold", size=12),
      legend.position = if(i==2) "bottom" else "none"
    )
}

p_sqrt <- plots[[1]] + plots[[2]] + plots[[3]] + 
  plot_layout(ncol=3, guides="collect") &
  theme(legend.position="bottom")

ggsave("figures/cost_circular_bar_sqrt.pdf", p_sqrt, width=18, height=7, device=cairo_pdf)
ggsave("figures/cost_circular_bar_sqrt.png", p_sqrt, width=18, height=7, dpi=300)
cat("✓ sqrt scale combined\n")

d_long2 <- d_long %>% filter(!Country %in% c("ZAF","NGA"))
ord2 <- ord[!ord %in% c("ZAF","NGA")]
d_long2$Country <- factor(d_long2$Country, levels=ord2)

plots2 <- list()
for (i in seq_along(prices)) {
  price <- prices[i]
  sub <- d_long2 %>% filter(Price.scenario == price)
  
  plots2[[i]] <- ggplot(sub, aes(x=Country, y=Cost_k, fill=Arm)) +
    geom_col(position=position_dodge(width=0.8), width=0.7) +
    scale_fill_manual(values=c(col_diet, col_glp1)) +
    scale_y_continuous(labels=dollar_format(suffix="k")) +
    coord_polar(start=0) +
    labs(title=price, y=NULL, x=NULL, fill=NULL) +
    theme_minimal(base_size=9) +
    theme(
      axis.text.x = element_text(size=8, face="bold"),
      axis.text.y = element_text(size=7),
      panel.grid.major.x = element_blank(),
      plot.title = element_text(hjust=0.5, face="bold", size=12),
      legend.position = if(i==2) "bottom" else "none"
    )
}

p_excl <- plots2[[1]] + plots2[[2]] + plots2[[3]] + 
  plot_layout(ncol=3, guides="collect") &
  theme(legend.position="bottom")

ggsave("figures/cost_circular_bar_excl.pdf", p_excl, width=18, height=7, device=cairo_pdf)
ggsave("figures/cost_circular_bar_excl.png", p_excl, width=18, height=7, dpi=300)
cat("✓ excluded ZAF+NGA combined\n")

d_long3 <- d_long %>%
  mutate(Cost_k_cap = pmin(Cost_k, 50),
         is_capped = Cost_k > 50)

plots3 <- list()
for (i in seq_along(prices)) {
  price <- prices[i]
  sub <- d_long3 %>% filter(Price.scenario == price)
  
  plots3[[i]] <- ggplot(sub, aes(x=Country, y=Cost_k_cap, fill=Arm)) +
    geom_col(position=position_dodge(width=0.8), width=0.7) +
    scale_fill_manual(values=c(col_diet, col_glp1)) +
    scale_y_continuous(labels=dollar_format(suffix="k"), limits=c(0,55)) +
    coord_polar(start=0) +
    labs(title=price, y=NULL, x=NULL, fill=NULL) +
    theme_minimal(base_size=9) +
    theme(
      axis.text.x = element_text(size=8, face="bold"),
      axis.text.y = element_text(size=7),
      panel.grid.major.x = element_blank(),
      plot.title = element_text(hjust=0.5, face="bold", size=12),
      legend.position = if(i==2) "bottom" else "none"
    )
}

p_cap <- plots3[[1]] + plots3[[2]] + plots3[[3]] + 
  plot_layout(ncol=3, guides="collect") &
  theme(legend.position="bottom")

ggsave("figures/cost_circular_bar_cap50k.pdf", p_cap, width=18, height=7, device=cairo_pdf)
ggsave("figures/cost_circular_bar_cap50k.png", p_cap, width=18, height=7, dpi=300)
cat("✓ capped at 50k combined\n")

cat("\nAll done!\n")
