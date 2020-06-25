#!/usr/bin/env python
"""
Extracts the reduction minute by minute.
"""

import sys
from pathlib import Path
import pandas as pd

path = Path(sys.argv[1])
outclasses = Path(sys.argv[2])
outbytes = Path(sys.argv[3])

tbytes = []
tclasses = []

maxminutes = 1440

for b in path.glob("url*/*"):
    name, predicate = b.relative_to(path).parts
    if not predicate in {"cfr", "procyon", "fernflower"}: continue

    metrics = list(b.glob("*/workfolder/metrics.csv"))
    if not metrics: continue
    for mf in metrics:
        strategy, *_ = mf.relative_to(b).parts
        m = pd.read_csv(mf)
        m.time = (m.time.floordiv(60) + 1)
        m.loc[0, "time"] = 0
        # Assume the first item is a success, even though it might not be due to flaky predicates
        m.loc[0, "judgment"] = "success"
        x = m[m.judgment == "success"]\
            .groupby("time")[["classes", "bytes"]]\
            .min()\
            .reindex(index=range(0, maxminutes+1))\
            .expanding().min()

        mbytes = { 0:  m.bytes[0]}
        mclasses = { 0 : m.classes[0] }
        try:
            for i in range(1, maxminutes+1):
                mbytes[i] = int(x.bytes[i])
                mclasses[i] = int(x.classes[i])
        except:
            print(mf)
            print(x)
            sys.exit()

        index = pd.MultiIndex.from_tuples(
            [(name, predicate, strategy)],
            names=("name", "predicate", "strategy")
            )

        tbytes.append(pd.DataFrame(mbytes, index=index))
        tclasses.append(pd.DataFrame(mclasses, index=index))

with open(outclasses, "w") as o:
    pd.concat(tclasses).to_csv(o)

with open(outbytes, "w") as o:
    pd.concat(tbytes).to_csv(o)



