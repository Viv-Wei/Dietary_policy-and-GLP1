library(ggplot2); library(dplyr); library(tidyr); library(patchwork)

ui <- read.csv("results/figure2b_arms_ui_merged.csv") %>%
  filter(scenario != "aspirational")
d2 <- read.csv("results/figure2b_arms.csv") %>%
  filter(scenario == "aspirational") %>%
  rename(med = per100) %>% mutate(lo = NA, hi = NA) %>%
  bind_rows(ui) %>%
  mutate(iso3 = factor(iso3, c("CHN","GLB","BRA","USA","IND","NGA")),
         scenario = factor(scenario,
           c("sodium30","feasible","aspirational","glp1_mediated","glp1_total"),
           c("Sodium -30%","Feasible package","Aspirational (upper bound)",
             "GLP-1 adiposity path","GLP-1 total")))
PAL2 <- c("Sodium -30%"="#91D1C2","Feasible package"="#00A087",
          "Aspirational (upper bound)"="#3C7A6A",
          "GLP-1 adiposity path"="#8491B4","GLP-1 total"="#3C5488")
p2b <- ggplot(d2, aes(scenario, med, fill = scenario)) +
  geom_col(width = .7) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .22, linewidth = .35,
                colour = "grey25", na.rm = TRUE) +
  facet_wrap(~iso3, nrow = 1) +
  scale_fill_manual(values = PAL2, name = NULL,
                    guide = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(x = NULL, y = "Averted per 100 diet-attributable IHD deaths") +
  theme_classic(base_size = 10) +
  theme(strip.background = element_blank(), strip.text = element_text(face="bold"),
        axis.text.x = element_blank(), axis.ticks.x = element_blank(),
        legend.position = "bottom", legend.text = element_text(size = 7.5))
ggsave("figures/figure2b_arms_ui.pdf", p2b, width = 11, height = 4.3, device = cairo_pdf)
ggsave("figures/figure2b_arms_ui.png", p2b, width = 11, height = 4.3, dpi = 300)

d4 <- read.csv("results/figure4_full_30yr.csv") %>%
  mutate(iso3 = factor(iso3, c("GLB","CHN","IND","USA","BRA","NGA")),
         arm = factor(arm, c("diet","glp1"),
                      c("Diet policy (feasible)","GLP-1 (20% cov., adherence-adj.)")))
a4 <- d4 %>% group_by(iso3, arm) %>% summarise(k = sum(averted_10yr)/1000, .groups="drop") %>%
  ggplot(aes(iso3, k, fill = arm)) +
  geom_col(position = position_dodge(.72), width = .62) +
  scale_fill_manual(values = c("#00A087","#3C5488"), name = NULL) +
  scale_y_continuous(trans = "sqrt", breaks = c(100,500,2000,5000,10000)) +
  labs(x = NULL, y = "Deaths averted, 30 yr (thousands, sqrt scale)", tag = "a") +
  theme_classic(base_size = 10) +
  theme(legend.position = "top", legend.text = element_text(size = 7.5))
yr <- grep("^yr[0-9]+$", names(d4), value = TRUE)
b4d <- d4 %>% filter(iso3=="CHN") %>%
  pivot_longer(all_of(yr), names_to="y", values_to="v") %>%
  mutate(t = as.integer(sub("yr","",y))) %>%
  group_by(arm, t) %>% summarise(k = sum(v)/1000, .groups="drop")
b4 <- ggplot(b4d, aes(t, k, colour = arm)) +
  geom_vline(xintercept = 9, linetype = "22", colour = "grey40") +
  annotate("text", x = 9.5, y = 15, hjust = 0, size = 2.7, colour = "grey30",
           label = "Year 9 crossover") +
  geom_line(linewidth = .9) +
  scale_colour_manual(values = c("#00A087","#3C5488"), guide = "none") +
  labs(x = "Year", y = "Annual deaths averted (thousands)",
       subtitle = "China", tag = "b") +
  theme_classic(base_size = 10) +
  theme(plot.subtitle = element_text(size = 8.5, colour = "grey30"))
t2 <- read.csv("results/t2d_incidence_arms.csv") %>%
  group_by(iso3) %>% summarise(glp1 = sum(glp1)/1e6, diet = sum(diet)/1e6) %>%
  pivot_longer(-iso3, names_to="arm", values_to="m") %>%
  mutate(iso3 = factor(iso3, c("GLB","CHN","IND","USA","BRA","NGA")),
         arm = factor(arm, c("diet","glp1"),
                      c("Diet policy (feasible)","GLP-1 (20% cov., adherence-adj.)")))
c4 <- ggplot(t2, aes(iso3, m, fill = arm)) +
  geom_col(position = position_dodge(.72), width = .62) +
  scale_fill_manual(values = c("#00A087","#3C5488"), guide = "none") +
  scale_y_continuous(trans = "sqrt", breaks = c(1,5,20,60)) +
  labs(x = NULL, y = "New T2D cases averted, 30 yr (millions, sqrt)", tag = "c") +
  theme_classic(base_size = 10)
p4 <- a4 / (b4 + c4)
ggsave("figures/figure4_final.pdf", p4, width = 11, height = 7.4, device = cairo_pdf)
ggsave("figures/figure4_final.png", p4, width = 11, height = 7.4, dpi = 300)
cat("both done\n")
