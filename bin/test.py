#!/usr/bin/env python3

import sys
import csv
import re
from pathlib import Path
from contextlib import contextmanager
from collections import defaultdict
from subprocess import run, PIPE
from tempfile import TemporaryDirectory

def main(name, folders):
    timeoutre = re.compile(r'ReductionTimedOut')
    results = []
    for path in (Path(f) for f in folders):
        strategy = path.name
        workfolder = path / "workfolder"

        result = defaultdict(lambda: "")

        result.update( 
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

            result["scc"] = int(final["count"])
            result["initial-scc"] = int(rows[0]["count"])
            result["bytes"] = int(final["bytes"])
            result["initial-bytes"] = int(rows[0]["bytes"])
            result["classes"] = int(final["classes"])
            result["initial-classes"] = int(rows[0]["classes"])
            result["iters"] = int(final["folder"])
            result["time"] = float(final["time"])

            for row in rows:
                if row["status"] == "1" : 
                    result["verify"] = str(row["folder"])
                    break
            else:
                result["verify"] = "success"
        
        except FileNotFoundError as e:
            result['status'] = "catastrophe"
        
       
        results.append(result)

    wr = csv.DictWriter(sys.stdout, 
            ["name", "strategy", 
                "bugs", "initial-scc", "scc", "initial-classes", "classes", 
                "initial-bytes", "bytes", 
                "iters", "time", 
                "status", "verify"]
            )
    wr.writeheader()
    for row in sorted(results, key=lambda x: (x["name"], x["strategy"])):
        wr.writerow(row)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
