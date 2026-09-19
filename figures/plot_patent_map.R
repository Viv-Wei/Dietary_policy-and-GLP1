suppressPackageStartupMessages({library(ggplot2); library(dplyr); library(rnaturalearth); library(sf)})

world <- ne_countries(scale = "medium", returnclass = "sf")

world$iso_a3[world$iso_a3 %in% c("TWN","HKG","MAC")] <- "CHN"

cm <- read.csv("params/country_map.csv") %>% filter(iso3 != "GLB")

iso3_to_iso_a3 <- c(
  CHN="CHN", IND="IND", BRA="BRA", CAN="CAN", TUR="TUR", ZAF="ZAF",
  MEX="MEX", AUS="AUS", NZL="NZL", ROU="ROU", BGR="BGR", ISR="ISR",
  NGA="NGA", EGY="EGY", BGD="BGD", USA="USA", JPN="JPN", GBR="GBR", DEU="DEU")

cm$iso_a3 <- iso3_to_iso_a3[cm$iso3]

world <- world %>%
  left_join(cm %>% select(iso_a3, tier_label), by = c("iso_a3" = "iso_a3"))

tier_labels <- c(
  "expiry_by_2027" = "Patent expiry by 2027 (n=12)",
  "never_filed"    = "No patent filed (n=3)",
  "protected"      = "Patent protected (n=4)")

world$tier_label <- factor(world$tier_label,
  levels = c("expiry_by_2027","never_filed","protected"),
  labels = tier_labels)

p <- ggplot(world) +
  geom_sf(aes(fill = tier_label), colour = "white", linewidth = 0.15) +
  scale_fill_manual(
    values = setNames(
      c("#00A087","#4DBBD5","#E64B35"),
      tier_labels),
    na.value = "#E8E8E8",
    name = "Semaglutide patent status") +
  coord_sf(crs = st_crs("+proj=robin"), expand = FALSE) +
  labs(title = "19 study countries by semaglutide patent status") +
  theme_void(base_size = 10) +
  theme(
    plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
    legend.position = "bottom",
    legend.text = element_text(size = 8),
    legend.title = element_text(size = 9, face = "bold"),
    plot.margin = margin(10, 10, 10, 10))

ggsave("figures/patent_map.pdf", p, width = 10, height = 5.5, device = cairo_pdf)
ggsave("figures/patent_map.png", p, width = 10, height = 5.5, dpi = 350)
cat("done: figures/patent_map.{pdf,png}\n")
