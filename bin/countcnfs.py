#!/usr/bin/env python3

import sys
import re
import csv
from pathlib import Path

base = Path(sys.argv[1])

fs = csv.DictWriter(sys.stdout, fieldnames=["name", "singletons", "edges", "rest", "clauses"])
fs.writeheader()
for p in base.glob("*/workfolder/cnf.txt"):
    name = p.relative_to(base).parts[0]
    with open(p) as wf:
        singletons = 0
        edges = 0
        rest = 0
        clauses = 0
        for i in wf:
            try:
                false_side, true_side = re.match(r"^(.*) ==> (.*)$", i).group(1, 2)
            except:
                print("Could not macth: " ++ i, file=sys.stderr)

            ff = false_side.split(" /\\ ")
            if ff[0] == "true" and len(ff) == 1: ff = []
            tt = true_side.split(" \\/ ")
            if tt[0] == "false" and len(tt) == 1: tt = []


            if len(ff) == 0 and len(tt) == 1:
                singletons += 1

            elif len(ff) == 1 and len(tt) == 1:
                edges += 1

            else:
                rest += 1

            clauses += 1

        fs.writerow(dict(
            name=name,
            singletons=singletons,
            edges=edges,
            rest=rest,
            clauses=clauses
        ))

