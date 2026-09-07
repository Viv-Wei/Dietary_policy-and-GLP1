"""Figure 1 age-standardised version: standardised to the 2023 global 25+ population structure
Input: results/factor_burden_by_age.csv + data/gbd/1-3_population.csv
Output: results/figure1_channel_burden_agestd.csv (same structure; deaths column = standardised rate x population)
"""
import pandas as pd, numpy as np

pop = pd.read_csv("data/gbd/1-3_population.csv", low_memory=False)
pop = pop[(pop.year==2023) & (pop.age_name!="All ages")
          & pop.sex_name.isin(["Male","Female"])]
cm = pd.read_csv("params/country_map.csv")
ISO = dict(zip(cm.gbd_location_name, cm.iso3))
pop["iso3"] = pop.location_name.map(ISO)
pop = pop.dropna(subset=["iso3"])

# Standard structure: global age-sex shares
std = pop[pop.iso3=="GLB"].groupby(["sex_name","age_name"]).val.sum()
std = (std/std.sum()).rename("w")

# Country age-sex population (denominator)
den = pop.groupby(["iso3","sex_name","age_name"]).val.sum().rename("pop")

t = pd.read_csv("results/factor_burden_by_age.csv")
print("Input columns:", list(t.columns))
d = t.merge(den.reset_index(), on=["iso3","sex_name","age_name"], how="left")
d = d.merge(std.reset_index(), on=["sex_name","age_name"], how="left")
d["rate"] = d.deaths_attr / d["pop"]
d["std_contrib"] = d.rate * d.w
print("Rows missing population:", d["pop"].isna().sum(), "| rows missing weight:", d.w.isna().sum())
d.to_csv("results/figure1_agestd_detail.csv", index=False)
print("-> results/figure1_agestd_detail.csv")

# Aggregate standardised rate by country x outcome x channel, then multiply by country 25+ total population to get "comparable standardised deaths"
agg = (d.groupby(["iso3","outcome","glp1_channel"])
         .agg(std_rate=("std_contrib","sum"),
              conv_wt=("convergence","mean"))
         .reset_index())
tot_pop = den.groupby("iso3").sum()
agg["deaths"] = agg.std_rate * agg.iso3.map(tot_pop)
agg["rate_per_100k"] = agg.std_rate * 1e5

# UI standardised the same way
for col, out in [("deaths_lo","deaths_lo"), ("deaths_hi","deaths_hi")]:
    d[f"_{col}"] = d[col] / d["pop"] * d.w
    s = d.groupby(["iso3","outcome","glp1_channel"])[f"_{col}"].sum()
    agg[out] = agg.set_index(["iso3","outcome","glp1_channel"]).index.map(s) * agg.iso3.map(tot_pop)

agg[["iso3","outcome","glp1_channel","conv_wt","deaths","deaths_lo","deaths_hi","rate_per_100k"]] \
   .to_csv("results/figure1_channel_burden_agestd.csv", index=False)
print("-> results/figure1_channel_burden_agestd.csv", len(agg), "rows")

print("\n=== Crude vs standardised rate (six outcomes combined, per 100k) ===")
crude = pd.read_csv("results/figure1_channel_burden.csv").groupby("iso3").deaths.sum()
cr = (crude / den.groupby("iso3").sum() * 1e5).dropna()
st = agg.groupby("iso3").rate_per_100k.sum()
cmp_ = pd.DataFrame({"crude":cr.round(0), "age_std":st.round(0)})
cmp_["ratio"] = (cmp_.age_std/cmp_.crude).round(2)
print(cmp_.sort_values("ratio").to_string())

# Plotting input: deaths column swapped to standardised rate, UI scaled proportionally
k = agg.rate_per_100k / agg.deaths.replace(0, np.nan)
agg["deaths_lo_r"] = agg.deaths_lo * k
agg["deaths_hi_r"] = agg.deaths_hi * k
agg.assign(deaths=agg.rate_per_100k,
           deaths_lo=agg.deaths_lo_r,
           deaths_hi=agg.deaths_hi_r)[
    ["iso3","outcome","glp1_channel","conv_wt","deaths","deaths_lo","deaths_hi"]] \
   .to_csv("results/figure1_agestd_forplot.csv", index=False)
print("-> results/figure1_agestd_forplot.csv (plot input)")
