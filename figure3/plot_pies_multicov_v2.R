suppressMessages({library(dplyr); library(tidyr); library(ggplot2); library(scatterpie)})

args <- commandArgs(trailingOnly = TRUE)
COV_LABEL <- ifelse(length(args) >= 1, args[1], "20%")
cov_tag <- gsub("%","pct", COV_LABEL)

T <- read.csv(sprintf("results/figure3_factor_split_CV4_%s.csv", cov_tag))
cm <- read.csv("params/country_map.csv")
name <- setNames(cm$gbd_location_name, cm$iso3); name["GLB"] <- "Pooled"

all_segs <- sort(unique(T$seg))
SEG_NONE <- all_segs[grepl("Not transmitted", all_segs)]
SEG_BEYOND <- all_segs[grepl("beyond", all_segs)]
SEG_OFFSET <- all_segs[grepl("offset by", all_segs)]
SEGS <- c(SEG_NONE, SEG_BEYOND, SEG_OFFSET)

PAL <- c("#E64B35", "#A8DED4", "#00A087"); names(PAL) <- SEGS

W <- T %>% complete(iso3, factor, seg = SEGS, fill = list(pct = 0)) %>%
  select(iso3, factor, seg, pct) %>%
  pivot_wider(names_from = seg, values_from = pct, values_fill = 0) %>%
  mutate(country = name[iso3])
W <- W[rowSums(W[SEGS], na.rm = TRUE) > 0, ]

ford <- W %>% filter(iso3 == "GLB") %>%
  arrange(desc(.data[[SEG_OFFSET]]), desc(.data[[SEG_BEYOND]])) %>% pull(factor)
sod_data <- W %>% filter(factor == "Sodium (high)", iso3 != "GLB")
if (nrow(sod_data) > 0) {
  cord <- sod_data %>% arrange(.data[[SEG_OFFSET]]) %>% pull(country)
} else {
  cord <- unique(W$country[W$iso3 != "GLB"])
}
cord <- c(cord, "Pooled")

W <- W %>% mutate(x = match(factor, ford), y = match(country, rev(cord))) %>%
  filter(!is.na(x), !is.na(y))

S <- 1.6
p <- ggplot() +
  geom_scatterpie(data = W, aes(x = x, y = y, r = .47), cols = SEGS, colour = NA) +
  geom_hline(yintercept = 1.5, colour = "grey55", linewidth = .5) +
  coord_equal(clip = "off") +
  scale_x_continuous(breaks = seq_along(ford), labels = ford, position = "top",
                     expand = expansion(add = .55)) +
  scale_y_continuous(breaks = seq_along(cord), labels = rev(cord),
                     expand = expansion(add = .55)) +
  scale_fill_manual(values = PAL, breaks = SEGS, guide = "none") +
  labs(x = NULL, y = NULL, title = sprintf("GLP-1 coverage: %s", COV_LABEL)) +
  theme_minimal(base_size = 11 * S) +
  theme(panel.grid = element_blank(),
        axis.text.x.top = element_text(angle = 45, hjust = 0, vjust = 0, size = 9 * S, colour = "grey15"),
        axis.text.y = element_text(size = 9.5 * S, colour = "grey15",
                                   face = ifelse(rev(cord) == "Pooled", "bold", "plain")),
        plot.title = element_text(size = 12 * S, face = "bold"),
        plot.margin = margin(4, 30 * S, 4, 4))

CELL <- 0.5; WDT <- (length(ford) + 3.6) * CELL * S; HGT <- (length(cord) + 3.2) * CELL * S
ggsave(sprintf("figures/figure3_all/pies/pies_%s.pdf", cov_tag), p, width = WDT, height = HGT, device = cairo_pdf)
ggsave(sprintf("figures/figure3_all/pies/pies_%s.png", cov_tag), p, width = WDT, height = HGT, dpi = 330)
cat("done pies:", cov_tag, "\n")
