#!/usr/bin/env bash
# ============================================================
# rebuild_figure5_v2.sh
# Rerun the Figure 5 single-factor matrix with the full v2 input set
#
# Usage:
#   cd /data2/han_tianshu/glp1_diet_cra
#   bash src/rebuild_figure5_v2.sh
#
# Prerequisites:
#   export LT_DP_OVERRIDE=v2_conv_fixed/results/diet_policy_arm.csv
#   export LT_FLOW_OVERRIDE=v2_conv_fixed/results/figure2_flow_v2.csv
# ============================================================
set -euo pipefail

# ---- check environment variables ----
if [[ -z "${LT_DP_OVERRIDE:-}" || -z "${LT_FLOW_OVERRIDE:-}" ]]; then
    echo "ERROR: set the v2 environment variables first:"
    echo "  export LT_DP_OVERRIDE=v2_conv_fixed/results/diet_policy_arm.csv"
    echo "  export LT_FLOW_OVERRIDE=v2_conv_fixed/results/figure2_flow_v2.csv"
    exit 1
fi
echo "✓ LT_DP_OVERRIDE=$LT_DP_OVERRIDE"
echo "✓ LT_FLOW_OVERRIDE=$LT_FLOW_OVERRIDE"

# ---- backup old version ----
BDIR="results/archive_f5_prev2"
mkdir -p "$BDIR"
for f in results/f5_single_v*.csv; do
    [[ -f "$f" ]] && cp "$f" "$BDIR/" && echo "  backed up $f -> $BDIR/"
done
[[ -f results/figure5_matrix_19c.csv ]] && \
    cp results/figure5_matrix_19c.csv "$BDIR/figure5_matrix_19c_prev2.csv" && \
    echo "  backed up figure5_matrix_19c.csv"

# ---- Step 1: rerun 12 single-factor life tables (30yr, 20% coverage, v2 definition) ----
FACTORS=(v01 v02 v05 v06 v08 v09 v10 v15 v29 v30 v34 v37)
echo ""
echo "====== Step 1: rerun 12 single-factor life tables (v2 definition) ======"
for gv in "${FACTORS[@]}"; do
    OUT="results/f5_single_${gv}.csv"
    echo -n "  [$(date +%H:%M:%S)] single_${gv} -> ${OUT} ... "
    python src/lifetable_full.py \
        --years 30 \
        --coverage 0.20 \
        --diet-scenario "single_${gv}" \
        --out "$OUT" \
        > /dev/null 2>&1
    echo "done ($(wc -l < "$OUT") rows)"
done

# ---- Step 2: aggregate into figure5_matrix_19c.csv ----
echo ""
echo "====== Step 2: aggregate matrix ======"
python3 << 'PYEOF'
import pandas as pd, numpy as np, glob, os

# Part 1: CV + CKD deaths (from life table averted_10yr = actual 30-year cumulative)
rows = []
for f in sorted(glob.glob("results/f5_single_v*.csv")):
    v = f.replace(".csv","").split("_")[-1]
    d = pd.read_csv(f)
    g = d.groupby(["iso3","outcome"]).averted_10yr.sum().reset_index()
    g["gdd_var"] = v
    rows.append(g)
t = pd.concat(rows, ignore_index=True)
assert t.averted_10yr.max() < 1e8 and t.averted_10yr.min() > -1e5, \
    f"!! out-of-range values: max={t.averted_10yr.max():.0f}, min={t.averted_10yr.min():.0f}"

# Part 2: T2D incidence (PIF x baseline annual incidence x 26 effective years)
# 26 = 30 years - 8-year ramp halved approximation (30-4=26)
cm = pd.read_csv("params/country_map.csv")
ISO = dict(zip(cm.gbd_location_name, cm.iso3))
AGE15 = [f"{a}-{a+4} years" for a in range(25,95,5)] + ["95+ years"]
inc = pd.read_csv("data/gbd/cause_totals/queryB_t2d.csv", low_memory=False)
inc = inc[(inc.measure_name=="Incidence") & (inc.metric_name=="Number")
          & (inc.year==2023) & inc.age_name.isin(AGE15)
          & inc.sex_name.isin(["Male","Female"]) & inc.location_name.isin(ISO)]
inc["iso3"] = inc.location_name.map(ISO)
bi = inc.groupby("iso3").val.sum()

# use the v2 diet_policy_arm.csv
dp_file = os.environ.get("LT_DP_OVERRIDE", "results/diet_policy_arm.csv")
dp = pd.read_csv(dp_file)
if not dp.scenario.str.startswith("single_").any():
    print(f"  WARN: {dp_file} has no single scenarios, falling back to results/diet_policy_arm.csv")
    dp = pd.read_csv("results/diet_policy_arm.csv")

dp = dp[(dp.outcome=="T2D") & dp.scenario.str.startswith("single_")]
pif = dp.groupby(["scenario","iso3"]).averted_frac_alldeaths.mean()
t2 = pd.DataFrame([
    dict(iso3=i, gdd_var=s.replace("single_",""),
         outcome="T2D_incidence",
         averted_10yr=float(bi.get(i,0)) * p * 26)
    for (s,i), p in pif.items()
])

out = pd.concat([t, t2], ignore_index=True)
out.to_csv("results/figure5_matrix_19c.csv", index=False)
print(f"\n✓ Figure 5 matrix (v2): {len(out)} rows")
print(f"  outcomes: {sorted(out.outcome.unique())}")
print(f"  countries: {out.iso3.nunique()}")
print(f"  max averted_10yr: {out.averted_10yr.max():,.0f}")

# quick QC: compare with v1
prev = "results/archive_f5_prev2/figure5_matrix_19c_prev2.csv"
if os.path.isfile(prev):
    old = pd.read_csv(prev)
    m = out.merge(old, on=["iso3","outcome","gdd_var"], suffixes=("_v2","_v1"))
    ratio = (m.averted_10yr_v2 / m.averted_10yr_v1.replace(0, np.nan))
    print(f"\n  v2/v1 ratio: median={ratio.median():.3f}, "
          f"range=[{ratio.min():.3f}, {ratio.max():.3f}]")
    big = m[abs(ratio - 1) > 0.1][["iso3","outcome","gdd_var",
                                     "averted_10yr_v1","averted_10yr_v2"]]
    if len(big):
        print(f"  rows with >10% change ({len(big)}):")
        print(big.to_string(index=False))
    else:
        print("  all rows v2/v1 change <10%")
PYEOF

echo ""
echo "====== Step 3: regenerate figures ======"
Rscript src/plot_figure5_19c.R
echo ""
echo "✓ all done. outputs:"
echo "  results/figure5_matrix_19c.csv"
echo "  figures/figure5_matrix_19c.{pdf,png}"
echo "  old backup: results/archive_f5_prev2/"
