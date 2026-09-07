"""World Bank income quintiles: take latest non-empty value over a wide API window; fall back to built-in literature values when it fails (flag for verification)"""
import urllib.request, json, pandas as pd

CC = {"CHN":"CN","IND":"IN","USA":"US","BRA":"BR","NGA":"NG"}
IND_SHARE = {"q1":"SI.DST.FRST.20","q2":"SI.DST.02ND.20","q3":"SI.DST.03RD.20",
             "q4":"SI.DST.04TH.20","q5":"SI.DST.05TH.20"}
GNI = "NY.GNP.PCAP.CD"

def wb_latest(cc, ind):
    url = (f"https://api.worldbank.org/v2/country/{cc}/indicator/{ind}"
           f"?format=json&date=2010:2024&per_page=100")
    req = urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        j = json.load(r)
    for rec in (j[1] or []):          # API returns years in descending order
        if rec["value"] is not None:
            return rec["value"], rec["date"]
    return None, None

# built-in fallback: public World Bank figures (approximate, share%), used when API fails, verify against web before submission
FALLBACK_SHARE = {
 "CHN": {"q1":6.5,"q2":10.9,"q3":15.9,"q4":23.0,"q5":43.7},   # 2021
 "IND": {"q1":8.1,"q2":11.4,"q3":15.2,"q4":21.3,"q5":44.0},   # 2022 (consumption basis)
 "USA": {"q1":5.2,"q2":10.2,"q3":15.3,"q4":22.8,"q5":46.5},   # 2022
 "BRA": {"q1":3.4,"q2":7.7,"q3":12.4,"q4":19.7,"q5":56.8},    # 2022
 "NGA": {"q1":7.5,"q2":11.5,"q3":15.5,"q4":21.5,"q5":44.0},   # 2018
}
FALLBACK_GNI = {"CHN":13400,"IND":2540,"USA":80450,"BRA":9070,"NGA":1930}  # 2023±

rows, api_ok = [], True
for iso, cc in CC.items():
    try:
        gni, gy = wb_latest(cc, GNI)
    except Exception as e:
        print(f"[API failed {iso} GNI: {e}] -> fallback"); gni, gy, api_ok = None, None, False
    if gni is None: gni, gy = FALLBACK_GNI[iso], "fallback"
    for q, ind in IND_SHARE.items():
        sh, sy = None, None
        try:
            sh, sy = wb_latest(cc, ind)
        except Exception:
            api_ok = False
        if sh is None: sh, sy = FALLBACK_SHARE[iso][q], "fallback"
        rows.append(dict(iso3=iso, quintile=q, share_pct=round(sh,1),
                         share_year=sy, gni_pc_usd=round(gni),
                         gni_year=gy,
                         income_pc_usd=round(gni*sh/100*5)))
t = pd.DataFrame(rows)
t.to_csv("params/income_quintiles_wb.csv", index=False)
print(t.to_string(index=False))
print("\nAPI status:", "all fetched online" if api_ok else "partial/all used fallback values (verify against World Bank website before submission)")
