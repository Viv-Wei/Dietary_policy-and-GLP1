# Overview 

***Dietary policy versus Glucagon-like peptide-1 receptor agonists for cardiometabolic mortality: a 19-country comparative risk assessment***

---

## analysis/
-  `build_figure1_data.py`    Builds the Figure 1 base data: age-weighted attributable burden by country x outcome x channel (official PAF definition); writes the channel-burden table. 
-  `build_figure1_agestd.py`  Age-standardised version of Figure 1: converts attributable deaths to comparable standardised rates using the 2023 global 25+ population structure.
-  `build_glp1_channels.py`   Rebuilds the GLP-1 substitutability channel classification from the GBD mediation matrix (convergence tiers; structural upper bound). 

## figure1/
-  `plot_figure1.R`  Plots Figure 1A/1B: channel decomposition x patent-tier stacked bars (per 100 000 adults rate version).
-  `plot_figure1_legend.R`  Renders the Figure 1 legend separately (patent status, mediated fraction, accounting rule). 

## figure2/
- `plot_figure3.R`  Parameterised Sankey diagram (dietary factor -> mediator -> direct flow; plain/depth modes). 
-  `plot_figure3_triple.R`  Three-axis Sankey: factor -> mediator -> outcome. 
-  `plot_figure3_triple_depth.R`  Sankey with depth segments (offset by 20% coverage / pathway open but flow insufficient / unreachable). 
-  `plot_f3_foodbar_final.R`  Stacked bar chart of food factors segmented by the degree of GLP-1 offset. 
-  `plot_f3_heatmap.R`  Depth heatmap of GLP-1 offset (%) by country x outcome. 
-  `plot_schematic_panelA.R`  Draws the Panel A schematic: causal structure + GLP-1 dual pathway (weight-mediated and weight-independent). 

## figure3/

-  `build_figure3_flows.py`  Builds the Figure 3 flow table: splits attributable deaths by official mediation factor. 
-  `calc_depth.py`  Computes the offset depth of GLP-1@20% coverage on each mediator (SBP/FPG/LDL). 
-  `add_figure3_depth.py`  Splits flows into three segments by depth (unreachable / reachable but beyond offset / offset), batched output. 
-  `plot_figure3c_dumbbell.R`  Figure 3c dumbbell chart: SBP shift (dietary push vs GLP-1 offset). 
-  `plot_figure3c_grid.R`  Dumbbell grid across outcomes x mediators. 
-  `plot_figure3_cv4.R`  Depth Sankey combining the four cardiovascular outcomes. 
-  `plot_figureS_factor_pies.R`  Supplementary factor-pie matrix: segment shares by factor. 

## figure4/
-  `lifetable_full.py`  Figure 4 full three-state (Well -> Diseased -> Dead) life-table engine (by arm, outcome, country). 
-  `lifetable_mc.py`  Monte Carlo shell: samples GLP-1/dietary PIFs, RETAIN and CKD HR, then runs the life table repeatedly. 
-  `plot_figure4_curves.R`  30-year cumulative avertable-death curves for representative countries (by arm, with UI). 
-  `plot_figure4_global_tiers.R`  Global avertable-death curves across coverage scenarios (20% / 50% / price-permitted ceiling). 
-  `plot_figure4_heatmap3.R`  Heatmap montage of log2 annual diet/GLP-1 flow ratios plus legends. 

## figure5/
-  `rebuild_figure5_v2.sh`  One-shot rerun of the Figure 5 single-factor matrix: 12 factor life tables -> aggregation -> plots. 
-  `plot_figure5_19c.R`  Heatmap of single-factor contribution shares across 19 countries (CV+CKD deaths and new T2D cases). 
-  `plot_figure5_global.R`  Global single-factor analysis composite: CVD/T2D pies + 30-year trajectory curves. 
-  `plot_figure5_curves_bycountry.R`  30-year cumulative curves faceted by factor with top-3 countries highlighted. 
-  `plot_figure5_curves_montage.R`  Montage of 30-year cumulative curves per single factor by country.
-  `plot_figure5_heatmaps.R`  Factor contribution-share heatmaps for 4 outcomes (2x2 panels). 
-  `plot_figure5_pies.R`  Factor contribution-share pies per country. 

## figure6/
-  `fetch_income_quintiles.py`  Fetches World Bank income-quintile shares and GNI (with built-in fallback values). 
-  `affordability_model.py`  Affordability model: annual drug cost as % of quintile per-capita income (brand / generic upper $140 / generic lower $28). 
-  `equity_paf_by_edu.py`  Education three-tier stratified dietary-attributable PAF (gradient transfer method). 
-  `equity_paf_by_urban.py`  Urban/rural stratified dietary-attributable PAF.
-  `equity_burden_by_edu.py`  Final table of education-tier attributable deaths (tier PAF x tier population share x total deaths). 
-  `equity_mc.py`  Monte Carlo uncertainty of the education-gradient PAF ratio (median + 95% UI). 
-  `plot_figure6a.R`  Plots Figure 6a: education-gradient PAF bars + ratio forest plot.
-  `plot_figure6a_v2.R`  Figure 6a v2: low/high-education PAF ratio forest plot for three outcomes (IHD / ischaemic stroke / T2D).
-  `plot_figure6b_v2.R`  Plots Figure 6b: affordability tile matrix (country x quintile x price scenario). 
