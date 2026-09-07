#!/usr/bin/env python3
"""Rebuild GLP-1 substitutability classification from the GBD 2021 mediation matrix

Why rewrite
-----------
The old question was "does this dietary factor act through BMI as a mediator?".
In GBD 2019, SSB->BMI->T2D exists, so that question was barely usable. But in
GBD 2021 no dietary factor is mediated by BMI; BMI appears only as a distal
factor. Asking the old question would classify every factor as non-substitutable,
a false negative.

New logic: mediation convergence
--------------------------------
GLP-1 lowers BMI, and BMI affects outcomes via FPG/SBP/LDL.
Dietary factors also affect the same outcomes through these mediators.
The portion where both converge on the same mediator is the burden that
GLP-1 can structurally reach.

    convergence(D, C) = max{ MF(D, M, C) : M with MF(BMI, M, C) > 0 }

Take max rather than sum: MF is a pairwise attribution coefficient, not an
additive pathway share.

*** This is a structural upper bound, not an effect size ***
High convergence only says "the burden flows through mediators GLP-1 can move";
it does not say how much GLP-1 can lower it.
The latter requires BMI change x mediator dose-response, a separate calculation.
"""
import argparse
from pathlib import Path

import numpy as np
import pandas as pd

# GBD 2021 calls it "High body-mass index in adults", changed to "High body-mass index" in 2023
BMI_ALIASES = ("High body-mass index in adults", "High body-mass index",
               "High body mass index in adults", "High body mass index")

MEDIATOR_SHORT = {
    "High fasting plasma glucose": "FPG",
    "High systolic blood pressure": "SBP",
    "High LDL cholesterol": "LDL",
    "High body-mass index in adults": "BMI",
}
CAUSE2OUTCOME = {
    "Ischemic heart disease": "IHD",
    "Ischaemic heart disease": "IHD",          # GBD 2023 uses British spelling
    "Ischaemic stroke": "IschStroke",
    "Intracerebral haemorrhage": "ICH",
    "Subarachnoid haemorrhage": "SAH",
    "Ischemic stroke": "IschStroke",
    "Diabetes mellitus type 2": "T2D",
    "Intracerebral hemorrhage": "ICH",
    "Subarachnoid hemorrhage": "SAH",
    "Chronic kidney disease": "CKD",
}
RISK2FACTOR = {
    "Diet low in fruits": "fruits",
    "Diet low in vegetables": "vegetables",
    "Diet low in whole grains": "wholegrains",
    "Diet low in nuts and seeds": "nutsseeds",
    "Diet low in legumes": "legumes",
    "Diet low in fibre": "fiber",
    "Diet low in milk": "milk",
    "Diet low in seafood omega-3 fatty acids": "seafood_omega3",
    "Diet low in polyunsaturated fatty acids": "omega6",
    "Diet low in omega-6 polyunsaturated fatty acids": "omega6",   # renamed in GBD 2023
    "Diet high in red meat": "redmeat",
    "Diet high in processed meat": "procmeat",
    "Diet high in sugar-sweetened beverages": "ssb",
    "Diet high in trans fatty acids": "transfat",
    "Diet high in sodium": "sodium",
}


def classify(conv, has_any_mediation):
    if not has_any_mediation:
        return "Unmediated-structure unreachable"
    if conv >= 0.99:
        return "Fully convergent-structure reachable"
    if conv >= 0.50:
        return "Highly convergent-largely reachable"
    if conv >= 0.10:
        return "Partially convergent-slightly reachable"
    return "Minimally convergent-nearly unreachable"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mediation", required=True)
    ap.add_argument("--out", default="params/glp1_channels_gbd2021.csv")
    ap.add_argument("--outcomes", default="IHD,IschStroke,T2D")
    a = ap.parse_args()

    want = [x.strip() for x in a.outcomes.split(",")]
    md = pd.read_csv(a.mediation)
    md["med"] = md.mediator.map(MEDIATOR_SHORT)
    md["out"] = md.cause.map(CAUSE2OUTCOME)
    md = md.dropna(subset=["med", "out"])

    bmi = md[md.risk_factor.isin(BMI_ALIASES)]
    if bmi.empty:
        raise SystemExit(f"BMI not found in mediation matrix (tried {BMI_ALIASES}), "
                         f"actual distal risks: {sorted(md.risk_factor.unique())}")
    bmi_prof = {o: dict(zip(g.med, g.mf)) for o, g in bmi.groupby("out")}
    print("=== BMI mediation profile (GLP-1 action reference) ===")
    for o in want:
        p = bmi_prof.get(o, {})
        print(f"  {o:11s} " + ("  ".join(f"{m}={v:.3f}" for m, v in sorted(p.items()))
                               if p else "no record"))

    md["factor"] = md.risk_factor.map(RISK2FACTOR)
    diet = md.dropna(subset=["factor"])

    rows = []
    for fac in sorted(set(RISK2FACTOR.values())):
        for o in want:
            sub = diet[(diet.factor == fac) & (diet["out"] == o)]
            bp = bmi_prof.get(o, {})
            prof = dict(zip(sub.med, sub.mf))
            shared = {m: v for m, v in prof.items() if bp.get(m, 0) > 0}
            conv = min(1.0, sum(shared.values())) if shared else 0.0  # reachable mediator share, truncated to 1 (accommodates pairwise overlap)
            via = "+".join(sorted(shared, key=shared.get, reverse=True)) if shared else None
            rows.append(dict(
                factor=fac, outcome=o,
                mf_FPG=prof.get("FPG"), mf_SBP=prof.get("SBP"), mf_LDL=prof.get("LDL"),
                bmi_FPG=bp.get("FPG"), bmi_SBP=bp.get("SBP"), bmi_LDL=bp.get("LDL"),
                convergence=round(conv, 4), via_mediator=via,
                n_mediation_rows=len(sub),
                glp1_channel=classify(conv, len(sub) > 0)))

    res = pd.DataFrame(rows)
    CKD_PAIRED = {"fruits","vegetables","wholegrains","redmeat","procmeat","ssb","sodium"}  # S3 official pairing
    res = res[~((res.outcome == "CKD") & (~res.factor.isin(CKD_PAIRED)))].reset_index(drop=True)
    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    res.to_csv(a.out, index=False)
    print(f"\nWrote {len(res)} rows -> {a.out}")

    print("\n=== Convergence table (structural upper bound, not effect size) ===")
    for o in want:
        g = res[res.outcome == o].sort_values("convergence", ascending=False)
        print(f"\n--- {o} ---")
        for _, r in g.iterrows():
            via = f"via {r.via_mediator}" if r.via_mediator else "  - "
            print(f"  {r.factor:16s} conv={r.convergence:5.3f} {via:6s} "
                  f"[{r.glp1_channel}]"
                  + ("" if r.n_mediation_rows else "   (S6 no record = pure direct effect)"))

    print("\n=== Tier summary ===")
    print(res.pivot_table(index="glp1_channel", columns="outcome",
                          values="factor", aggfunc="count", fill_value=0).to_string())

    print("\n=== Three points that must be written into Methods ===")
    print("  1. Convergence is a structural upper bound. It indicates whether the burden")
    print("     flows through mediators GLP-1 can move; it does not say how much GLP-1")
    print("     can lower it. The latter needs BMI change x mediator dose-response.")
    print("  2. Take max rather than sum. MF is a pairwise attribution coefficient,")
    print("     not an additive pathway share.")
    print("  3. Triplets absent from S6 = GBD treats as pure direct effect, not missing data.")


if __name__ == "__main__":
    main()
