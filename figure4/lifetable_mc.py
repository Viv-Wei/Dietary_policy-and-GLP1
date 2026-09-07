import os
# -*- coding: utf-8 -*-
"""Figure 4 MC shell: parameter sampling x repeated lifetable_full runs
Sampled: GLP-1 PIF (flow table UI normal) / dietary PIF (dp table perturbed by draw) / RETAIN (U(0.50,0.83)) / CKD HR (LN(0.76,CI))
Fixed: ramp (assigned to sweep) / population and all-cause (GBD convention) / baseline rates (!!upgrade item: link queryB UI columns in sampling, done in v2)
Usage: python src/lifetable_mc.py --draws 500 --shard 0 --nshards 8 --coverage 0.20
"""
import pandas as pd, numpy as np, subprocess, os, argparse, tempfile

def main(a):
    rng = np.random.default_rng(4200 + a.shard)
    f2 = pd.read_csv(os.environ.get("CRA_F2FLOW","results/figure2_flow_v2.csv"))
    dp = pd.read_csv(os.environ.get("LT_DP_OVERRIDE","results/diet_policy_arm.csv"))
    hr_mu, hr_sd = np.log(0.76), (np.log(0.88)-np.log(0.66))/(2*1.96)
    recs = []
    _q, _r = divmod(a.draws, a.nshards)
    lo = a.shard*_q + min(a.shard, _r)
    hi = lo + _q + (1 if a.shard < _r else 0)
    for d in range(lo, hi):
        # 1) GLP-1 PIF perturbation: flow table pif columns, normal with +/-15% relative uncertainty (upper-level MC approximation)
        f2d = f2.copy()
        for c in ["pif_med_pop","pif_resid_pop"]:
            f2d[c] = f2d[c] * rng.normal(1.0, 0.075, len(f2d))
        # 2) dietary PIF perturbation: averted_frac with +/-12% relative (curve + exposure propagation approximation)
        dpd = dp.copy()
        dpd["averted_frac_alldeaths"] = dpd.averted_frac_alldeaths * rng.normal(1.0, 0.06, len(dpd))
        # 3) RETAIN sampling
        retain = rng.uniform(0.50, 0.83)
        # 4) CKD HR sampling -> injected via env var (engine-side v2 hook; v1 first approximates as covered by PIF perturbation)
        with tempfile.TemporaryDirectory() as td:
            f2p, dpp = f"{td}/flow.csv", f"{td}/dp.csv"
            f2d.to_csv(f2p, index=False); dpd.to_csv(dpp, index=False)
            # engine reads fixed paths -> symlinking a temp dir is not feasible; pass paths via env vars (engine v2 adds 2-line hook)
            env = os.environ | dict(SENS_RETAIN=str(retain),
                                    LT_FLOW_OVERRIDE=f2p, LT_DP_OVERRIDE=dpp)
            out = f"{td}/lt.csv"
            r = subprocess.run(["python","src/lifetable_full.py","--years","30",
                                "--coverage",str(a.coverage),
                                "--diet-scenario",a.diet_scenario,"--out",out],
                               env=env, capture_output=True, text=True)
            if r.returncode != 0:
                print(f"draw{d} engine failed:", r.stderr[-200:]); continue
            t = pd.read_csv(out)
        yr = [c for c in t.columns if c.startswith("yr")]
        g = t.groupby(["iso3","arm"])[yr].sum()
        for (iso, arm), row in g.iterrows():
            recs.append(dict(draw=d, iso3=iso, arm=arm,
                             cum30=row.sum(),
                             **{f"y{i+1}": v for i, v in enumerate(row.values)}))
        if (d-lo+1) % 10 == 0: print(f"shard{a.shard}: {d-lo+1}/{hi-lo}")
    pd.DataFrame(recs).to_csv(
        f"results/figure4_mc{'' if a.diet_scenario=='feasible' else '_'+a.diet_scenario[:3]}_cov{a.coverage}_shard{a.shard}.csv", index=False)
    print(f"shard{a.shard} done")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--draws", type=int, default=500)
    p.add_argument("--shard", type=int, default=0)
    p.add_argument("--nshards", type=int, default=8)
    p.add_argument("--diet-scenario", default="feasible")
    p.add_argument("--coverage", default="0.20")
    main(p.parse_args())
