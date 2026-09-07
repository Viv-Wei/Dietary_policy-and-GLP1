"""Split Figure 3 flows into three segments by depth (batch version, cardiovascular outcomes only)"""
import pandas as pd, json, glob, os, sys
OUTCOMES = {"IHD","IschStroke","ICH","SAH"}
SEG_NONE = "Not transmitted through a GLP-1 target"
SEG_OPEN = "Transmitted through a GLP-1 target, beyond what 20% coverage offsets"
SEG_FULL = "Transmitted through a GLP-1 target, offset by 20% coverage"
summary = []
for fp in sorted(glob.glob("params/figure3_depth_*_*.json")):
    iso, out = os.path.basename(fp)[len("figure3_depth_"):-5].rsplit("_",1)
    if out not in OUTCOMES: continue
    depth = json.load(open(fp))
    d = pd.read_csv(f"results/figure3_flows_{iso}_{out}.csv")
    rows = []
    for _, r in d.iterrows():
        if r.mediator == "Direct":
            rows.append(dict(factor=r.factor, mediator="Direct", seg=SEG_NONE, deaths=r.deaths)); continue
        dp = float(depth.get(r.mediator, -1.0))
        if dp < 0:
            if r.deaths > 0:
                print(f"[warning] {iso} {out} {r.factor}->{r.mediator} has flow {r.deaths:.0f} but depth undefined, assigned to '{SEG_OPEN}'", file=sys.stderr)
            dp = 0.0
        if dp > 0:
            rows.append(dict(factor=r.factor, mediator=r.mediator, seg=SEG_FULL, deaths=r.deaths*dp))
        if dp < 1:
            rows.append(dict(factor=r.factor, mediator=r.mediator, seg=SEG_OPEN, deaths=r.deaths*(1-dp)))
    t = pd.DataFrame(rows)
    s = t.groupby("seg").deaths.sum(); s = s/s.sum()*100          # summary: untrimmed, conserving
    small = t.deaths <= 0.02*t.deaths.sum()                          # plotting: trace rows merged into Other, not dropped
    t.loc[small, "factor"] = "Other factors"
    t = t.groupby(["factor","mediator","seg"], as_index=False).deaths.sum()
    t.to_csv(f"results/figure3_flows_{iso}_{out}_depth.csv", index=False)
    summary.append(dict(iso3=iso, outcome=out, **{k: round(s.get(k,0),1) for k in [SEG_NONE,SEG_OPEN,SEG_FULL]}))
S = pd.DataFrame(summary); S.to_csv("results/figure3_depth_summary.csv", index=False)
print(S[S.outcome=="IHD"].to_string(index=False))
