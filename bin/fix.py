#/usr/bin/env python3

import csv
import sys
import shutil
import subprocess
from pathlib import Path 

metricfile = Path(sys.argv[1])
with open(metricfile) as f:
    headers = ["count", "classes", "bytes", "time", "setup time", "run time", "folder", "judgment"]
    out = csv.DictWriter(sys.stdout, headers)
    out.writeheader()
    for line in csv.DictReader(f):
        d = { h: line[h] for h in headers if h in line }

        d["count"] = line["scc"]
       
        output = [ s.split() for s in subprocess.check_output(
            ['du', '-aLb',  metricfile.parent / d['folder'] / "classes" ], 
            text=True).splitlines()
            ]

        d['bytes'] = sum(int(size) for size, name in output if name.endswith(".class"))
    
        sandbox = metricfile.parent / d['folder'] / "sandbox"
        if sandbox.exists():
            shutil.rmtree(sandbox)
        
        d['judgment'] = {"true": "success", "false": "failure"}[line['success']]
        
        if d['folder'] == "initial": 
            d['folder'] = "0000"
        else:
            d['folder'] = f"{int(d['folder'])+1:04d}"
        

        out.writerow(d)




