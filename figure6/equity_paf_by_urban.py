"""Urban/rural stratified PAF (gradient transfer method, reusing the edu-version logic)"""
import pandas as pd, numpy as np, glob
from importlib.machinery import SourceFileLoader
dpa = SourceFileLoader("dpa","src/diet_policy_arm.py").load_module()

_g = pd.read_csv("data/exposure_19country.csv", low_memory=False)
_g = _g[_g.age >= 22.5]
ratios = {}
for gv, d in _g.groupby("gdd_var"):
    nat = d[d.stratum_type=="age_marginal"].groupby("iso3").intake_median.mean()
    cr = d[d.stratum_type=="cross"]
    for u in [0,1]:   # 0=rural, 1=urban
        st = cr[cr.urban==u].groupby("iso3").intake_median.mean()
        for iso in nat.index:
            if nat[iso] > 0 and np.isfinite(st.get(iso, np.nan)):
                ratios[(gv,iso,u)] = float(st[iso]/nat[iso])
print(f"urban/rural gradient ratios: {len(ratios)}")

curves = pd.read_csv("params/dose_response_gbd2023_gbdexp.csv")
cvt = pd.read_csv("params/cv_by_factor.csv")
cvmap = dict(zip(cvt.gdd_var, cvt.cv_between*1.8))
rows = []
for sex in ["male","female"]:
    e23 = pd.read_csv(f"data/exposure_gbd_{sex}.csv")
    e23 = e23[e23.year==2023]
    for u in [0,1]:
        et = e23.copy()
        et["intake_median"] = et.apply(
            lambda r: r.intake_median*ratios.get((r.gdd_var,r.iso3,u),1.0), axis=1)
        paf = dpa.combined_paf(et, curves, cvmap, outcomes=("IHD","IschStroke"))
        nb = {"IHD": dpa.sodium_paf_via_sbp(et, curves, f"data/sbp_gbd2023_{sex}.csv"),
              "IschStroke": dpa.sodium_paf_via_sbp(et, curves,
                    f"data/sbp_gbd2023_{sex}.csv", curve_id="high_sbp_s")}
        for (outc,iso), v in paf.items():
            rows.append(dict(sex=sex, urban=u, outcome=outc, iso3=iso,
                paf=1-(1-v)*(1-nb[outc][iso])))
t = pd.DataFrame(rows)
out = t.groupby(["outcome","iso3","urban"]).paf.mean().mul(100).round(2)
out.to_csv("results/equity_paf_by_urban.csv")
print(out.unstack("urban").rename(columns={0:"rural",1:"urban"}).to_string())
print("\nRural/urban PAF ratio (>1 means burden pressed toward rural):")
w = out.unstack("urban")
print((w[0]/w[1]).round(2).unstack(0).to_string())
