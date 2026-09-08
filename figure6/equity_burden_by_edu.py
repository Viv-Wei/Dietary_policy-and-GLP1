"""Figure 6a final table: education-tier attributable deaths = tier PAF x tier population share x total deaths
   Approximation: mortality rates identical across tiers (no stratified mortality data); differences all come from PAF and population structure"""
import pandas as pd, numpy as np

EDU_MAP = {  # Wittgenstein 11 tiers -> GDD 3 tiers
 "No Education":1,"Incomplete Primary":1,"Primary":1,
 "Lower Secondary":2,"Upper Secondary":2,
 "Post Secondary":3,"Short Post Secondary":3,"Bachelor":3,"Master and higher":3}
import pandas as _cmpd
_cm = _cmpd.read_csv("params/country_map.csv")
AREA = dict(zip(_cm.gbd_location_name, _cm.iso3))
AREA["Turkey"] = "TUR"
AREA["United Kingdom of Great Britain and Northern Ireland"] = "GBR"

w = pd.read_csv("data/wittgenstein/wcde_clean.csv")
w = w[w.Area.isin(AREA) & w.Education.isin(EDU_MAP)].copy()
w["iso3"] = w.Area.map(AREA); w["edu"] = w.Education.map(EDU_MAP)
# 25+ population (Age format "25--29")
def age_lo(a):
    try: return int(str(a).split("--")[0].replace("+",""))
    except: return -1
w = w[w.Age.map(age_lo) >= 25]
share = w.groupby(["iso3","edu"]).Population.sum()
share = share / share.groupby("iso3").transform("sum")

paf = pd.read_csv("results/equity_paf_by_edu.csv")
paf = paf.set_index(["outcome","iso3","edu"]).paf

# total dietary-attributable deaths for the outcome (figure1 data, positive attribution only)
f1 = pd.read_csv("results/figure1_channel_burden.csv")
f1 = f1[f1.deaths > 0]
tot = f1.groupby(["outcome","iso3"]).deaths.sum()
OUTMAP = {"IHD":"IHD","IschStroke":"IschStroke"}

rows = []
for (outc, iso, e), p in paf.items():
    if iso == "GLB" or outc not in OUTMAP: continue
    sh = float(share.get((iso,e), np.nan))
    T = float(tot.get((OUTMAP[outc],iso), np.nan))
    # tier attributable deaths = total attributable deaths x [tier PAF x tier population] / sum over tiers[PAF x population]
    rows.append(dict(outcome=outc, iso3=iso, edu=e, paf=p, pop_share=sh,
                     w_paf=p*sh))
t = pd.DataFrame(rows)
t["attr_share"] = t.w_paf / t.groupby(["outcome","iso3"]).w_paf.transform("sum")
t = t.merge(tot.rename("total_attr").reset_index(), on=["outcome","iso3"])
t["attr_deaths_k"] = (t.attr_share * t.total_attr / 1000).round(1)
t.to_csv("results/equity_burden_by_edu.csv", index=False)

piv = t.pivot_table(index=["outcome","iso3"], columns="edu",
                    values=["pop_share","attr_deaths_k"])
print(piv.round(2).to_string())
print("\n=== Low-education-tier share of attributable deaths vs population share ===")
q = t[t.edu==1].set_index(["outcome","iso3"])
print((q.attr_share*100).round(1).astype(str).str.cat(
      (q.pop_share*100).round(1).astype(str), sep="% vs ").to_string())
