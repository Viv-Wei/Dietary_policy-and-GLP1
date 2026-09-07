library(ggplot2); library(dplyr); library(tidyr)
args <- commandArgs(trailingOnly = TRUE)
ISO <- ifelse(length(args) >= 1, args[1], "GLB")
d <- read.csv(sprintf("results/f3_depth_mc_%s.csv", ISO))
SEGS <- c("Offset by GLP-1 (20% coverage)","Pathway open, flow insufficient",
          "Unreachable (no pathway)")
w <- d %>% mutate(seg = factor(seg, SEGS)) %>%
  group_by(factor) %>% mutate(tot = sum(med)) %>% ungroup() %>%
  mutate(factor = reorder(factor, tot, max))
p <- ggplot(w, aes(med/1000, factor, fill = seg)) +
  geom_col(width = .78, position = position_stack(reverse = TRUE)) +
  scale_fill_manual(values = c("#00A087","#A8DED4","#E64B35"), name = NULL,
                    guide = guide_legend(nrow = 3)) +
  labs(x = sprintf("Diet-attributable deaths (thousands), %s 2023",
                   ifelse(ISO == "GLB", "global", ISO)), y = NULL,
       caption = "Point estimates; 95% uncertainty intervals in Table SX.") +
  theme_classic(base_size = 11) +
  theme(legend.position = "top", legend.text = element_text(size = 7.2),
        legend.key.size = unit(8.5, "pt"), legend.justification = "left",
        axis.text.y = element_text(size = 8, face = "bold"),
        plot.caption = element_text(size = 5.2, colour = "grey40", hjust = 0))
ggsave(sprintf("figures/figure3_all/f3_foodbar_%s.png", ISO), p,
       width = 5.6, height = 4.4, dpi = 420)
ggsave(sprintf("figures/figure3_all/f3_foodbar_%s.pdf", ISO), p,
       width = 5.6, height = 4.4, device = cairo_pdf)
cat("done:", ISO, "\n")
