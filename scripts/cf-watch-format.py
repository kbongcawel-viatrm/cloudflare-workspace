#!/usr/bin/env python3
"""cf-watch-format.py — read a GraphQL httpRequestsAdaptiveGroups response
from stdin, dedupe against a seen-file, print new request lines.

Usage: printf '%s' "$RESP" | python3 cf-watch-format.py SEEN_FILE [OPTIONS]

Filters (repeatable --status, last one wins if combined oddly):
  --status PAT   edge status pattern: 200, 2xx, 4xx, 40x, 5XX (x = wildcard)
  --only-200     same as --status 200
  --no-200       hide clean 200s (non-200 status or non-allow securityAction)
"""
import json
import os
import re
import sys

positionals = []
status_pats = []
only_200 = "--only-200" in sys.argv
no_200 = "--no-200" in sys.argv
i = 1
while i < len(sys.argv):
    a = sys.argv[i]
    if a == "--status" and i + 1 < len(sys.argv):
        status_pats.append(sys.argv[i + 1])
        i += 2
    elif a.startswith("--"):
        i += 1
    else:
        positionals.append(a)
        i += 1
seen_file = positionals[0]

def status_match(st, pat):
    p = pat.strip().upper().replace("X", "x")
    rx = "^" + "".join("\\d" if c in "x*" else re.escape(c) for c in p) + "$"
    return re.match(rx, str(st)) is not None
seen = set(open(seen_file).read().splitlines()) if __import__("os").path.exists(seen_file) else set()
new = []
try:
    data = json.load(sys.stdin)
    groups = data["data"]["viewer"]["accounts"][0]["httpRequestsAdaptiveGroups"]
except Exception as e:
    print(f"# parse error: {e}", file=sys.stderr)
    sys.exit(0)
CLEAN_ACTIONS = {"", "allow", "unknown"}
for g in groups:
    d = g["dimensions"]
    st = d.get("edgeResponseStatus")
    if only_200 and str(st) != "200":
        continue
    if status_pats and not any(status_match(st, p) for p in status_pats):
        continue
    if no_200:
        st = d.get("edgeResponseStatus")
        act = d.get("securityAction") or ""
        if str(st) == "200" and act in CLEAN_ACTIONS:
            continue
    key = "|".join(str(d.get(k, "")) for k in (
        "datetime", "clientRequestHTTPHost", "clientRequestPath",
        "clientRequestHTTPMethodName", "edgeResponseStatus",
        "clientCountryName", "securityAction"))
    key += "|" + str(g.get("count", 1))
    if key in seen:
        continue
    seen.add(key)
    new.append((d, g.get("count", 1)))
with open(seen_file, "w") as f:
    for k in sorted(seen):
        f.write(k + "\n")
for d, c in new:
    dt = d.get("datetime", "")[11:19]
    m = d.get("clientRequestHTTPMethodName", "?")
    st = d.get("edgeResponseStatus", "?")
    host = d.get("clientRequestHTTPHost", "?")
    path = d.get("clientRequestPath", "?")
    cc = d.get("clientCountryName", "")
    sec = d.get("securityAction") or ""
    sec = f" WAF:{sec}" if sec and sec != "allow" else ""
    cnt = f" x{c}" if c and c > 1 else ""
    print(f"{dt}  {m:6} {st}  {host}{path}  [{cc}]{sec}{cnt}")
