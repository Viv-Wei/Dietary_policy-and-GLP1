import os
import pandas as pd, numpy as np
from importlib.machinery import SourceFileLoader
os.chdir("./glp1_diet_cra")
dpa = SourceFileLoader("dpa","src/diet_policy_arm.py").load_module()

RNG = np.random.default_rng(99)

def draw_normal(mean, lo, hi, n):
    return RNG.normal(mean, (hi-lo)/(2*1.96), n)

tp = pd.read_csv("params/glp1_trial_params.csv")
def par(param, trial):
    r = tp[(tp.param==param)&(tp.trial==trial)].iloc[0]
    return float(r.value), float(r.ci_lo), float(r.ci_hi)

N_CKD = 200
N_T2D = 100
N_MAX = max(N_CKD, N_T2D)

hr_m, hr_lo, hr_hi = par("mace_hr","SELECT")
HR_SELECT = np.exp(draw_normal(np.log(hr_m), np.log(hr_lo), np.log(hr_hi), N_MAX))
HR_CKD = np.exp(draw_normal(np.log(0.76), np.log(0.66), np.log(0.88), N_MAX))
t2d_m, t2d_lo, t2d_hi = par("t2d_incidence_hr","SELECT_glycemia")
HR_T2D = np.exp(draw_normal(np.log(t2d_m), np.log(t2d_lo), np.log(t2d_hi), N_MAX))
NA2SBP_draws = draw_normal(3.82/2.30, 3.08/2.30, 4.55/2.30, N_MAX)
AMP_draws = RNG.uniform(1.5, 2.2, N_MAX)

curves = pd.read_csv(os.environ.get("CRA_CURVES","params/dose_response_gbd2023_gbdexp.csv"))
cvt = pd.read_csv("params/cv_by_factor.csv")
paf_f2 = pd.read_csv(os.environ.get("CRA_F2FLOW","results/figure2_flow_v2.csv"))

paf_ckd = paf_f2[(paf_f2.outcome=="CKD")&(paf_f2.coverage==0.20)].set_index(["outcome","iso3"]).PAF_diet
paf_t2d = paf_f2[(paf_f2.outcome=="T2D")&(paf_f2.coverage==0.20)].set_index(["outcome","iso3"]).PAF_diet

expo = {s: pd.read_csv(f"data/exposure_gbd_{s}.csv") for s in ["male","female"]}
sbpf = {s: f"data/sbp_gbd2023_{s}.csv" for s in ["male","female"]}

print("====== CKD (200 draws) ======", flush=True)
ckd_rows = []
for i in range(N_CKD):
    dpa.NA2SBP = NA2SBP_draws[i]
    ckd_per = {}
    for s in ["male","female"]:
        e = expo[s]
        nb_base = dpa.sodium_paf_via_sbp(e, curves, sbpf[s], curve_id="high_sbp_ckd")
        for scen in ["sodium30","feasible","aspirational"]:
            sh = dpa.shifted_exposure(e, curves, scen)
            nb_scen = dpa.sodium_paf_via_sbp(sh, curves, sbpf[s], curve_id="high_sbp_ckd")
            for iso in nb_base:
                ckd_per.setdefault((scen, iso), []).append(nb_base[iso] - nb_scen[iso])
    for (scen, iso), vals in ckd_per.items():
        if ("CKD", iso) in paf_ckd.index and paf_ckd[("CKD", iso)] > 0:
            v = np.mean(vals) * dpa.calib("CKD", iso) / paf_ckd[("CKD", iso)] * 100
            ckd_rows.append((i, "CKD", iso, scen, v))
    pif_ckd = 0.20 * (1 - HR_CKD[i])
    for iso in paf_ckd.index.get_level_values("iso3"):
        if paf_ckd[("CKD", iso)] > 0:
            ckd_rows.append((i, "CKD", iso, "glp1_total", pif_ckd / paf_ckd[("CKD", iso)] * 100))
    if (i+1) % 50 == 0: print(f"  CKD {i+1}/{N_CKD}", flush=True)
print(f"CKD done: {len(ckd_rows)} rows", flush=True)

print("====== T2D (100 draws) ======", flush=True)
t2d_rows = []
for i in range(N_T2D):
    dpa.NA2SBP = NA2SBP_draws[i]
    cvmap = dict(zip(cvt.gdd_var, cvt.cv_between * AMP_draws[i]))
    t2d_per = {}
    for s in ["male","female"]:
        e = expo[s]
        base = dpa.combined_paf(e, curves, cvmap, outcomes=("T2D",))
        for scen in ["sodium30","feasible","aspirational"]:
            sh = dpa.shifted_exposure(e, curves, scen)
            sc = dpa.combined_paf(sh, curves, cvmap, outcomes=("T2D",))
            for (outc, iso) in base:
                t2d_per.setdefault((scen, iso), []).append(base[(outc,iso)] - sc.get((outc,iso), 0.0))
    for (scen, iso), vals in t2d_per.items():
        if ("T2D", iso) in paf_t2d.index and paf_t2d[("T2D", iso)] > 0:
            v = np.mean(vals) * dpa.calib("T2D", iso) / paf_t2d[("T2D", iso)] * 100
            t2d_rows.append((i, "T2D", iso, scen, v))
    pif_t2d = 0.20 * (1 - HR_T2D[i])
    for iso in paf_t2d.index.get_level_values("iso3"):
        if paf_t2d[("T2D", iso)] > 0:
            t2d_rows.append((i, "T2D", iso, "glp1_total", pif_t2d / paf_t2d[("T2D", iso)] * 100))
    if (i+1) % 10 == 0: print(f"  T2D {i+1}/{N_T2D}", flush=True)
print(f"T2D done: {len(t2d_rows)} rows", flush=True)

df = pd.DataFrame(ckd_rows + t2d_rows, columns=["draw","outcome","iso3","scenario","v"])

q = df.groupby(["outcome","iso3","scenario"]).v.quantile([.5,.025,.975]).unstack()
q.columns = ["med","lo","hi"]
q = q.reset_index()
q.to_csv("results/figure2b_ckd_t2d_arms_ui.csv", index=False)
print(f"\n✓ Arms UI saved: {len(q)} rows", flush=True)

ratio_rows = []
for outc in ["CKD","T2D"]:
    glp1 = df[(df.outcome==outc)&(df.scenario=="glp1_total")]
    for scen in ["sodium30","feasible","aspirational"]:
        diet = df[(df.outcome==outc)&(df.scenario==scen)]
        merged = glp1[["draw","iso3","v"]].merge(
            diet[["draw","iso3","v"]], on=["draw","iso3"], suffixes=("_g","_d"))
        merged["ratio"] = merged.v_g / merged.v_d.replace(0, np.nan)
        merged = merged.dropna(subset=["ratio"])
        if len(merged) == 0:
            continue
        for iso in merged.iso3.unique():
            sub = merged[merged.iso3==iso]
            if len(sub) < 10:
                continue
            ratio_rows.append({
                "outcome": outc, "iso3": iso, "scenario": scen,
                "med": sub.ratio.median(),
                "lo": sub.ratio.quantile(0.025),
                "hi": sub.ratio.quantile(0.975)
            })

ratios = pd.DataFrame(ratio_rows)
ratios.to_csv("results/figure2b_ckd_t2d_ratio_ui.csv", index=False)
print(f"✓ Ratio UI saved: {len(ratios)} rows", flush=True)
print(f"\nGLB ratios:", flush=True)
print(ratios[ratios.iso3=="GLB"].to_string(index=False), flush=True)
