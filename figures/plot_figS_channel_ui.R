library(ggplot2); library(dplyr)
d <- read.csv("results/figure1_channel_burden.csv", fileEncoding="UTF-8") %>%
  filter(outcome=="IHD", deaths > 0) %>%
  mutate(iso3 = factor(iso3, rev(c("GLB","CHN","IND","USA","BRA","NGA"))),
         ch = factor(glp1_channel,
           c("Full convergence - structurally reachable","Partial convergence - partly reachable",
             "Minimal convergence - largely unreachable","Direct effect only - structurally unreachable"),
           c("Fully convergent","Partially convergent",
             "Minimally convergent","Direct effect")))
PAL <- c("#00A087","#4DBBD5","#F39B7F","#E64B35")

p1 <- ggplot(d, aes(deaths/1000, iso3, colour = ch)) +
  geom_pointrange(aes(xmin = pmax(deaths_lo,0)/1000, xmax = deaths_hi/1000),
                  position = position_dodge(width = .65), size = .3) +
  scale_colour_manual(values = PAL, name = NULL) +
  scale_x_sqrt(breaks = c(10,50,200,500,1000,2000)) +
  labs(x = "Diet-attributable IHD deaths (thousands, square-root scale)",
       y = NULL, subtitle = "Version 1: sqrt scale, single panel") +
  theme_classic(base_size = 10) + theme(legend.position = "top")
ggsave("figures/figS_channel_ui_v1sqrt.png", p1, width = 7, height = 4.5, dpi = 300)

p2 <- ggplot(d, aes(deaths/1000, ch, colour = ch)) +
  geom_pointrange(aes(xmin = deaths_lo/1000, xmax = deaths_hi/1000), size = .3) +
  geom_vline(xintercept = 0, linetype = "22", colour = "grey60", linewidth = .3) +
  facet_wrap(~iso3, scales = "free_x", nrow = 2) +
  scale_colour_manual(values = PAL, guide = "none") +
  labs(x = "Diet-attributable IHD deaths (thousands)",
       y = NULL, subtitle = "Version 2: linear scale, faceted by country") +
  theme_classic(base_size = 9.5) +
  theme(strip.background = element_blank(),
        strip.text = element_text(face = "bold"))
ggsave("figures/figS_channel_ui_v2linear.png", p2, width = 9, height = 4.8, dpi = 300)
cat("both done\n")
