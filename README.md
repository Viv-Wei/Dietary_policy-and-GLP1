# Overview 

***Dietary policy versus Glucagon-like peptide-1 receptor agonists for cardiometabolic mortality: a 19-country comparative risk assessment***

---

## analysis/
-  `build_glp1_channels.py`  Rebuilds the GLP-1 substitutability classification from the GBD 2023 mediation matrix: factor x outcome convergence tiers and structural upper bounds; writes `params/glp1_channels_gbd2023.csv`.
-  `build_figure1_data.py`  Builds the Figure 1 base data: age-weighted attributable burden by country x outcome x channel (official PAF definition); writes `results/factor_burden_by_age.csv` and `results/figure1_channel_burden.csv`.
-  `build_figure1_agestd.py`  Age-standardised version of Figure 1: converts attributable deaths to comparable standardised rates using the 2023 global 25+ population structure; writes `results/figure1_channel_burden_agestd.csv` and `results/figure1_agestd_forplot.csv`.
-  `build_figure2_data.py`  Builds the Figure 2 flow-layer data: IHD and ischaemic stroke flows, T2D control, ICH/SAH placeholders (three policy scenarios at 20% coverage); writes `results/figure2_flow_v2.csv`.
-  `diet_policy_arm.py`  Dietary policy arm PIF engine: three policy scenarios plus per-factor single scenarios (sodium via the two-step SBP chain); writes `results/diet_policy_arm.csv`.
-  `glp1_arm.py`  GLP-1 arm PIF: coverage x retention shifts population SBP/FPG and mediator dose-response curves give the RR changes; writes `results/glp1_arm_pif.csv`.
-  `calc_depth.py`  Computes the per-country GLP-1@20% offset depth on SBP/FPG/LDL by inverting mediator curves; writes `params/figure3_depth_{iso3}_{outcome}.json`.
-  `calc_depth_050.py`  Same offset-depth calculation at 50% coverage; writes `params/figure3_depth_{iso3}_{outcome}.json`.
-  `calc_depth_afford.py`  Computes GLP-1 offset depth at per-country affordable coverage caps; writes `params/depth_afford/figure3_depth_*.json`.

## figure1/
-  `plot_figure1.R`  Plots Figure 1A/1B/1C: channel decomposition x patent-tier stacked bars, shares and accounting-rule comparison (rate per 100 000 adults); writes `figures/figure1_channel_burden.pdf/png`.
-  `plot_figure1_legend.R`  Renders the Figure 1 legend separately (patent status, mediated fraction, accounting rule); writes `figures/figure1_legend.pdf/png`.

## figure3/
-  `plot_sankey_multicov.R`  Sankey/alluvial diagram (dietary factor -> mediator -> direct flow) by GLP-1 offset segment for one country and coverage; writes `figures/figure3_all/sankey_{cov}_{ISO}.pdf/png`.
-  `plot_pies_multicov_v2.R`  Scatterpie grid of factor x country GLP-1 offset shares for a given coverage; writes `figures/figure3_all/pies/pies_{cov}.pdf/png`.
-  `plot_foodbar_multicov.R`  Horizontal stacked bar of diet-attributable deaths per factor split by GLP-1 offset segment for one country/coverage; writes `figures/figure3_all/foodbar_{cov}_{ISO}.pdf/png`.
-  `plot_figureS_factor_pies.R`  Supplementary factor-pie matrix at 20% coverage plus a separate legend; writes `figures/figure3_all/figureS_factor_pies.pdf/png` and `_legend.pdf/png`.

## figure2/
-  `plot_figure2b_arms.py`  Rebuilds the Figure 2b two-arm comparison (dietary policy vs GLP-1) as avertable deaths per 100 diet-attributable IHD deaths; writes `results/figure2b_arms.csv`.
-  `plot_figure2.R`  Figure 2 ratio dot plot (log scale) of the GLP-1 total effect relative to dietary scenarios, faceted by patent tier; writes `figures/figure2_ratio_{OUTC}.pdf/png`.
-  `plot_figS2_ckd_t2d_ratio.R`  Figure S2 point-range plot comparing GLP-1 treatment with the feasible dietary package for CKD and T2D; writes `figures/figS2_ckd_t2d_ratio.pdf/png`.
-  `plot_fig2b_fig4_final.R`  Figure 2b two-arm bars with uncertainty intervals and the Figure 4 three-panel 30-year projection (cumulative, China crossover, T2D incidence); writes `figures/figure2b_arms_ui.pdf/png` and `figures/figure4_final.pdf/png`.
-  `mc_figure2b_ckd_t2d_fast_v2.py`  CKD/T2D arm and ratio Monte Carlo (trial HRs, Na-SBP conversion, CV scaling); writes `results/figure2b_ckd_t2d_arms_ui.csv` and `results/figure2b_ckd_t2d_ratio_ui.csv`.
-  `mc_figure2b.py`  Sharded Monte Carlo producing the Figure 2b two-arm uncertainty intervals for IHD/ischaemic stroke; writes `results/figure2b_arms_ui_19c_shard*.csv` and `results/f2b_draws_shard*.csv`.

## figure4/
-  `lifetable_full.py`  Figure 4 three-state life-table engine simulating GLP-1, diet and combo arms; writes `results/figure4_full.csv`.
-  `lifetable_mc.py`  MC wrapper sampling GLP-1/diet PIFs and retention, re-running the life-table engine; writes `results/figure4_mc*_shard*.csv`.
-  `sensitivity_sweep.py`  Sensitivity sweep over policy maintenance, wholegrain discount, GLP-1 retention and diet ramp; writes `results/sensitivity_sweep_19c.csv`.
-  `plot_figure4_global_tiers.R`  Faceted global cumulative avertable-death curves by coverage tier; writes `figures/figure4_global_tiers.pdf/png`.
-  `plot_figure4_heatmap3.R`  Three log2 ratio heatmaps (diet/asp/combo vs GLP-1) plus legends; writes `figures/figure4_heat_*.pdf/png`.
-  `plot_overlap_crossvalidation.R`  Plots top-down vs bottom-up overlap cross-validation; writes `figures/figS_overlap_crossvalidation.pdf/png`.
-  `plot_overlap_stacked_bar.R`  Stacked-bar decomposition of the combo benefit into GLP-1 and added diet across overlap scenarios; writes `figures/figS_overlap_stacked_bar.pdf/png`.
-  `plot_overlap_stacked_bar_ui.R`  Same decomposition with 95% UI error bars; writes `figures/figS_overlap_stacked_bar_ui.pdf/png`.

## figure5/
-  `rebuild_figure5_v2.sh`  One-shot rerun of the Figure 5 single-factor matrix: 12 factor life tables -> aggregation -> plots.
-  `plot_figure5_19c.R`  Two-panel country x factor heatmap of benefit shares (CV+CKD deaths and new T2D cases); writes `figures/figure5_matrix_19c.pdf/png`.
-  `plot_figure5_curves_bycountry.R`  Per-country 30-year CVD curves with top-3 factors highlighted; writes `figures/figure5_curves_cvd.pdf/png`.
-  `plot_figure5_curves_montage.R`  4x3 montage of single-factor 30-year curves (diet arm) with top-3 countries highlighted; writes `figures/figure5_curves_montage.pdf/png`.
-  `plot_figure5_global.R`  Global composite: CVD/T2D pies plus 30-year trajectory curves; writes `figures/figure5_global.pdf/png`.
-  `plot_figure5_heatmaps.R`  2x2 heatmaps of within-country factor shares for IHD, ischaemic stroke, CKD and T2D; writes `figures/figure5_heatmaps_4panel.pdf/png`.
-  `plot_figure5_pies.R`  Per-country pie charts of factor shares for CVD deaths and new T2D; writes `figures/figure5_pies_cvd.pdf/png` and `figure5_pies_t2d.pdf/png`.
-  `plot_figure5_radial.R`  Radial bar panels of per-country factor shares for CVD and new T2D; writes `figures/figure5_radial_cvd.pdf/png` and `figure5_radial_t2d.pdf/png`.

## figure6/
-  `fetch_income_quintiles.py`  Fetches World Bank income-quintile shares and GNI per capita (with built-in fallback values); writes `params/income_quintiles_wb.csv`.
-  `affordability_model.py`  Affordability model: annual drug cost as % of quintile per-capita income (branded / generic upper $140 / generic lower $28); writes `results/affordability_matrix.csv`.
-  `equity_paf_by_edu.py`  Education three-tier stratified dietary-attributable PAF (GDD gradient transplantation); writes `results/equity_paf_by_edu.csv`.
-  `equity_paf_by_urban.py`  Urban/rural stratified dietary-attributable PAF using the same gradient-transplant method; writes `results/equity_paf_by_urban.csv`.
-  `equity_burden_by_edu.py`  Final table of education-tier attributable deaths (tier PAF x tier population share x total deaths); writes `results/equity_burden_by_edu.csv`.
-  `equity_mc.py`  Monte Carlo uncertainty of the education-gradient PAF ratio (median + 95% UI); writes `results/equity_ratio_ui.csv`.
-  `plot_figure6a.R`  Plots Figure 6a: education-gradient PAF bars plus ratio forest plot; writes `figures/figure6a_edu_gradient.pdf/png`.
-  `plot_figure6a_v2.R`  Figure 6a v2: low/high-education PAF ratio forest plot for IHD, ischaemic stroke and T2D; writes `figures/figure6a_ratio_forest.pdf/png`.
-  `plot_figure6b_v2.R`  Plots Figure 6b: affordability tile matrix (country x quintile x price scenario); writes `figures/figure6b_affordability_v2.pdf/png`.
-  `plot_cost_options.R`  Four cost-per-death-averted plots (dumbbell, paired bars, scatter, ratio) comparing dietary policy with GLP-1; writes `figures/cost_option_A-D.pdf/png`.
-  `plot_cost_circular_bar_v2.R`  Circular bars of diet vs GLP-1 cost per death averted by country and price; writes `figures/cost_circular_bar_*.pdf/png`.
-  `plot_equity_twoarm_v3.R`  Pooled bars of deaths averted by education tier and price for both arms; writes `figures/figS_equity_twoarm_v3.pdf/png`.
-  `plot_equity_full_v3.R`  Scatter (price x education) and dumbbell ratio plots of diet vs GLP-1 deaths averted; writes `figures/figS_equity_scatter_v3.pdf/png` and `figS_equity_dumbbell_v3.pdf/png`.
-  `plot_equity_montage.R`  Equity montage (pooled bars, scatter, dumbbells) by education and price; writes `figures/figS_equity_montage.pdf/png`.

## figures/
-  `plot_patent_map.R`  Robinson-projection world map of the 19 study countries coloured by semaglutide patent tier; writes `figures/patent_map.pdf/png`.
-  `plot_figS_channel_ui.R`  Supplementary channel-burden plots for IHD (sqrt-scale single panel and linear faceted by country); writes `figures/figS_channel_ui_v*.png`.
