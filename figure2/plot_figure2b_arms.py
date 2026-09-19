import pandas as pd, numpy as np

dp = pd.read_csv("results/diet_policy_arm.csv")
dp = dp.groupby(["scenario","iso3"])[["paf_base","averted_frac_alldeaths"]].mean()
dp["per100"] = dp.averted_frac_alldeaths / dp.paf_base * 100
diet = dp.reset_index()[["scenario","iso3","per100"]]

g = pd.read_csv("results/figure2_flow_v2.csv")
g = g[(g.outcome=="IHD") & (g.coverage==0.20)]
glp = pd.concat([
    pd.DataFrame(dict(scenario="glp1_mediated", iso3=g.iso3,
                      per100=g.averted_med_samebase*100)),
    pd.DataFrame(dict(scenario="glp1_total", iso3=g.iso3,
                      per100=(g.averted_med_samebase+g.averted_resid_samebase)*100)),
])
t = pd.concat([diet, glp], ignore_index=True)
t.to_csv("results/figure2b_arms.csv", index=False)

w = t.pivot(index="iso3", columns="scenario", values="per100")
w = w[["sodium30","feasible","aspirational","glp1_mediated","glp1_total"]]
print("=== Avertable deaths per 100 diet-attributable IHD deaths ===")
print(w.round(1).to_string())
