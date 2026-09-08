library(ggplot2); library(dplyr); library(patchwork)
d <- read.csv("results/figure5_matrix_19c.csv")
lab <- c(v01="Fruits",v02="Vegetables",v05="Legumes",v06="Nuts & seeds",
         v08="Whole grains",v09="Processed meat",v10="Red meat",
         v15="SSB",v29="Omega-6",v30="Seafood omega-3",v34="Fibre",v37="Sodium")
t <- d %>% mutate(metric = ifelse(outcome=="T2D_incidence",
                  "New T2D cases","CV+CKD deaths"), factor = lab[gdd_var]) %>%
  group_by(metric, iso3, factor) %>% summarise(a = sum(averted_10yr), .groups="drop") %>%
  group_by(metric, iso3) %>% mutate(share = a / sum(pmax(a,0)) * 100) %>% ungroup()
ordf <- t %>% filter(iso3=="GLB", metric=="CV+CKD deaths") %>% arrange(share) %>% pull(factor)
t <- t %>% mutate(factor = factor(factor, ordf))
mk <- function(mm) ggplot(t %>% filter(metric==mm), aes(iso3, factor, fill = pmax(share,0))) +
  geom_tile(colour="white", linewidth=.4) +
  geom_text(aes(label = ifelse(share >= 8, sprintf("%.0f", share), "")), size=2.0) +
    scale_fill_gradient(low="white", high="#00584A",
                      name="Share of country's\nsingle-factor benefit (%)") +
  labs(x=NULL, y=NULL,
       caption=paste("Within-country shares: each factor's contribution to the country's total",
                     "single-factor (20% toward TMREL) benefit. Labels shown for cells \u22658%.")) +
  theme_minimal(base_size=10) +
  theme(panel.grid=element_blank(), strip.text=element_text(face="bold",size=9),
        axis.text.x=element_text(size=6.4,face="bold",angle=45,hjust=1),
        axis.text.y=element_text(size=7.4,face="bold"),
        legend.title=element_text(size=7), legend.text=element_text(size=6.4),
        plot.caption=element_text(size=5.2,colour="grey40",hjust=0))
p <- mk("CV+CKD deaths") + ggtitle("CV+CKD deaths") + (mk("New T2D cases") + ggtitle("New T2D cases"))
ggsave("figures/figure5_matrix_19c.pdf", p, width=10.8, height=4.6, device=cairo_pdf)
ggsave("figures/figure5_matrix_19c.png", p, width=10.8, height=4.6, dpi=380)
cat("done F5 share\n")
