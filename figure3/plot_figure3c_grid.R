suppressMessages({library(dplyr); library(ggplot2); library(jsonlite)})
cm <- read.csv("params/country_map.csv"); name <- setNames(cm$gbd_location_name, cm$iso3); name["GLB"] <- "Global"
OUTS <- c(IHD="Ischaemic heart disease", IschStroke="Ischaemic stroke",
          ICH="Intracerebral haemorrhage", SAH="Subarachnoid haemorrhage")
MEDS <- c(SBP="Systolic blood pressure (mmHg)", LDL="LDL cholesterol (mmol/L)", FPG="Fasting plasma glucose (mmol/L)")
D <- bind_rows(lapply(names(OUTS), function(o) bind_rows(lapply(
  list.files("params", sprintf("figure3_depth_.*_%s\\.json", o), full.names = TRUE), function(f) {
    j <- fromJSON(f); iso <- sub(sprintf(".*depth_(.*)_%s.*", o), "\\1", f)
    bind_rows(lapply(names(MEDS), function(m) data.frame(iso3 = iso, outcome = o, mediator = m,
      diet = j$push[[m]], drug = j$glp_shift[[m]], depth = j[[m]]))) }))))
D <- D %>% filter(diet > 0) %>%
  mutate(label = name[iso3], offset = pmin(diet, drug), beyond = pmax(diet - drug, 0),
         outcome = factor(OUTS[outcome], levels = OUTS), mediator = factor(MEDS[mediator], levels = MEDS))
ord <- D %>% filter(outcome == OUTS["IHD"], mediator == MEDS["SBP"]) %>% arrange(diet) %>% pull(label)
D$label <- factor(D$label, levels = unique(c(ord, setdiff(D$label, ord))))
vl <- D %>% filter(mediator != MEDS["LDL"]) %>% distinct(outcome, mediator, drug)
p <- ggplot(D) +
  geom_col(aes(x = offset, y = label, fill = "Offset by GLP-1 at 20% coverage"), width = .62) +
  geom_segment(aes(x = offset, xend = diet, y = label, yend = label, colour = "Beyond what GLP-1 offsets"), linewidth = 3) +
  geom_vline(data = vl, aes(xintercept = drug), colour = "#00A087", linewidth = .5, linetype = "22") +
  geom_text(aes(x = diet, y = label, label = sprintf("%.2f", depth)), hjust = -.25, size = 2, colour = "grey30") +
  facet_grid(outcome ~ mediator, scales = "free_x", switch = "x") +
  scale_fill_manual(values = c("Offset by GLP-1 at 20% coverage" = "#00A087"), name = NULL) +
  scale_colour_manual(values = c("Beyond what GLP-1 offsets" = "#A8DED4"), name = NULL) +
  scale_x_continuous(expand = expansion(mult = c(0, .18))) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = NULL,
       title = "Diet pushes each mediator up; GLP-1 at 20% coverage pulls it down by a fixed amount",
       caption = "Bar length, mediator shift implied by the diet-attributable burden transmitted through that mediator. Dashed line, GLP-1 shift (LDL shift varies with national baseline and is shown only as the dark segment). Number, share offset.") +
  theme_minimal(base_size = 9) +
  theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
        strip.placement = "outside", strip.text = element_text(size = 8, face = "bold"),
        legend.position = "bottom", legend.text = element_text(size = 8),
        panel.spacing.x = unit(1.2, "lines"), axis.text.y = element_text(size = 7),
        plot.caption = element_text(size = 6.5, colour = "grey40", hjust = 0))
ggsave("figures/figure3_all/figure3c_grid_all.pdf", p, width = 11, height = 12, device = cairo_pdf)
ggsave("figures/figure3_all/figure3c_grid_all.png", p, width = 11, height = 12, dpi = 300)
cat("done grid\n")
