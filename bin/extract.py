#!/usr/bin/env python3

import sys
import csv
import re
import itertools
from pathlib import Path
from contextlib import contextmanager
from collections import defaultdict
from subprocess import run, PIPE
from tempfile import TemporaryDirectory

def main(name, predicate, folders):
    timeoutre = re.compile(r'ReductionTimedOut')
    results = []
    for path in (Path(f) for f in folders):
        strategy = path.name
        workfolder = path / "workfolder"

        result = defaultdict(lambda: "")

        result.update( 
            predicate=predicate,
            name=name,
            strategy=strategy,
        )

        with open(str(path / "stderr")) as log:
            status = "success"
            for line in log:
                match = timeoutre.findall(line)
                if match: 
                    status = "timeout"
                    break
            result['status'] = status
        try:
            with open(str(workfolder / "metrics.csv")) as p:
                rows = list(csv.DictReader(p))

            for final in reversed(rows):
                if final['judgment'] == 'success': break
            else:
                result['status'] = "bad"

            result["scc"] = int(final["count"])
            result["initial-scc"] = int(rows[0]["count"])
            result["bytes"] = int(final["bytes"])
            result["initial-bytes"] = int(rows[0]["bytes"])
            result["classes"] = int(final["classes"])
            result["initial-classes"] = int(rows[0]["classes"])
            result["iters"] = int(final["folder"])
            result["setup-time"] = float(rows[0]["time"])
            result["flaky"] = rows[0]["judgment"] != "success"
           
            hits = set()
            for x in rows:
                hits.add(int(x["count"]))

            for i in itertools.count():
                if not i in hits: break
            result["searches"] = i - 1

            result["time"] = float(final["time"]) + float(final["run time"]) + float(final["setup time"])

            bugs = list((workfolder / "initial" / "stdout").read_text().splitlines())
            result["bugs"] = len(bugs)
            bugs = set(bugs)
           
            result["verify"] = "success"
            for path in sorted(workfolder.glob("*/*/stdout")):
                found_bugs = set(path.read_text().splitlines())
                if bugs < found_bugs:
                    result["verify"] = str(path.parent.name)
                    break
        
        except FileNotFoundError as e:
            result['status'] = "catastrophe"
        
       
        results.append(result)

    wr = csv.DictWriter(sys.stdout, 
            ["name", "predicate", "strategy", 
                "bugs", "initial-scc", "scc", "initial-classes", "classes", 
                "initial-bytes", "bytes", 
                "iters", "searches", "setup-time", "time", 
                "status", "verify", "flaky"]
            )
    wr.writeheader()
    for row in sorted(results, key=lambda x: (x["predicate"], x["name"], x["strategy"])):
        wr.writerow(row)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3:])
