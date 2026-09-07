"""Figure 3 flow table: attributable deaths split by official mediation factor"""
import pandas as pd, argparse

RISK2FAC = {"Diet low in whole grains":"wholegrains","Diet low in fruits":"fruits",
 "Diet low in vegetables":"vegetables","Diet low in fibre":"fiber",
 "Diet low in legumes":"legumes","Diet low in nuts and seeds":"nutsseeds",
 "Diet low in seafood omega-3 fatty acids":"seafood_omega3",
 "Diet low in omega-6 polyunsaturated fatty acids":"omega6",
 "Diet high in red meat":"redmeat","Diet high in processed meat":"procmeat",
 "Diet high in sugar-sweetened beverages":"ssb","Diet high in sodium":"sodium",
 "Diet high in trans fatty acids":"transfat"}
MEDMAP = {"High systolic blood pressure":"SBP","High fasting plasma glucose":"FPG",
          "High LDL cholesterol":"LDL"}
LABEL = {"wholegrains":"Whole grains (low)","fruits":"Fruits (low)",
 "vegetables":"Vegetables (low)","fiber":"Fibre (low)","legumes":"Legumes (low)",
 "nutsseeds":"Nuts & seeds (low)","seafood_omega3":"Seafood omega-3 (low)",
 "omega6":"Omega-6 PUFA (low)","redmeat":"Red meat (high)",
 "procmeat":"Processed meat (high)","ssb":"SSB (high)","sodium":"Sodium (high)",
 "transfat":"Trans fat (high)"}

def main(a):
    fb = pd.read_csv("results/factor_burden_by_age.csv")
    q = fb[(fb.iso3==a.iso3) & (fb.outcome==a.outcome)]
    burden = q.groupby("factor").deaths_attr.sum()
    burden = burden[burden > 0]

    md = pd.read_csv("params/mediation_gbd2023_5outcomes.csv")
    md = md[md.outcome==a.outcome].copy()
    md["factor"] = md.risk.map(RISK2FAC)
    md["med"] = md.mediator.map(MEDMAP)
    md = md.dropna(subset=["factor","med"])

    rows = []
    for fac, d in burden.items():
        mfs = md[md.factor==fac].set_index("med").mf.to_dict()
        s = sum(mfs.values())
        for m, v in mfs.items():
            rows.append(dict(factor=LABEL[fac], mediator=m, deaths=d*v))
        rows.append(dict(factor=LABEL[fac], mediator="Direct",
                         deaths=d*max(1-s, 0)))
    t = pd.DataFrame(rows)
    t.to_csv(f"results/figure3_flows_{a.iso3}_{a.outcome}.csv", index=False)
    print(f"{a.iso3}: {len(t)} flows, total {t.deaths.sum()/1000:.0f}k")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--iso3", required=True)
    p.add_argument("--outcome", default="IHD")
    main(p.parse_args())
