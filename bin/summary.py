#!/usr/bin/env python3 
import csv
import json
import sys
from pathlib import Path
import subprocess

folder = Path(sys.argv[1])
output = Path(sys.argv[2])

output.mkdir(parents=True)

with open(folder / "metrics.csv") as f:
    lines = list(csv.DictReader(f))

for line in lines:
    redfolder = folder / "reduction" / line["folder"]
    inputf = redfolder / "input" / "classes"
    classes = [ f.relative_to(inputf) for f in inputf.glob("**/*.class") ]

    print(line["folder"])

    with open(output / (line["folder"] + ".txt"), "w") as of:
        try: 
            json.dump(dict(line), of, indent=2)
            print("------- 8< --------", file=of)
            print((redfolder / "stdout").read_text(), file=of)
            print("------- 8< --------", file=of)
        except FileNotFoundError:
            pass
    with open(output / (line["folder"] + ".txt"), "a") as of:
        try: 
            subprocess.run(["javap"] + classes, cwd=str(inputf), stdout=of)
        except FileNotFoundError:
            pass
