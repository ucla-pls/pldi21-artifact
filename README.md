# PLDI'21 "Logic Input Reduction" Artifact

## Versions

```nix
$ nix --version
nix (Nix) 2.3.3

$ nixos-version
19.09.2518.8260cd5bc65 (Loris)
```

## Building the run database

We can build the rule database, like this:

```
$ nix-shell -A all --run 'nixec list --check'
```

We can build all runs, by running

```bash
$ nix-build -A rules --arg target nixecdb/rules/all.rule.nix
```

This should output a folder of results. If everything went well it should produce
a `result` symbolic link to `/nix/store/wmaz3ll91hb2yc6126lnaa5mp921x4qq-all`.
It can however take a long time to run, so you might
want to you run a single item:

```bash
$ nix-build -A rules --arg target nixecdb/rules/full/url0067cdd33d_goldolphin_Mi/cfr/items+logic.rule.nix
```

### Running the tool yourself

If instead of building the results you want to run it yourself you can run the `nix-shell` command on the same rule:

```bash
$ nix-shell -A rules --arg target nixecdb/rules/full/url0067cdd33d_goldolphin_Mi/cfr/items+logic.rule.nix
```

You will now be dropped into a nice shell in which you can run the command. Either you'll have to run the code manually or you can run the `run.sh` file. Like this:

```bash
$ ./run.sh
```

You can also add extra arguments to `./run.sh` which will be passed onto `jreduce` in the
`$@` command. Try `--keep-folders` to save more information during the runs. After running you should see a folder containing all the reductions tried:

```
$ tree workfolder/ -L 2
workfolder/
├── final
│   ├── input
│   ├── run.sh
│   ├── sandbox
│   ├── stderr
│   └── stdout
├── initial
│   ├── input
│   ├── run.sh
│   ├── sandbox
│   ├── stderr
│   └── stdout
├── metrics.csv
└── reduction
    ├── 0000
    ├── 0002
    ├── 0003
    ├── 0004
    ├── 0005
    ├── 0006
    ├── 0007
    ├── 0008
    ├── 0009
    ├── 0010
    ├── 0011
    ├── 0012
    ├── 0013
    ├── 0014
    ├── 0015
    ├── 0016
    ├── 0017
    ├── 0018
    ├── 0019
    ├── 0020
    ├── 0021
    ├── 0022
    └── 0023

30 directories, 7 files
```

Each subfolder contains the `run.sh` file which is what was run, and `input` which is
what it was run on. `sandbox` contains the run of the code.

## Running the examples with code changes

Say you have updated the source code and want to run an example again. In this case
you can use the `overrides` argument. Here we ask nix to build the example from before
with but with a version of jreduce which we have in the folder `~/Develop/projects/jreduce`.

```bash
nix-build \
  --arg target nixecdb/rules/full/url0067cdd33d_goldolphin_Mi/cfr/items+logic.rule.nix \
  -A rules \
  --arg overrides '{jreduce=~/Develop/projects/jreduce}'
```

