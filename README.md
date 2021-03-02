# (485) PLDI'21 "Logic Input Reduction" Artifact

- Version: 1.0

## Getting Started Guide

## Versions

```nix
$ nix --version
nix (Nix) 2.3.3

$ nixos-version
19.09.2518.8260cd5bc65 (Loris)
```

All other versions are defined by nix-files.

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




## Step-by-Step instruction

This artifact support xx parts of the paper:

1. A record of the code and full logical model used to do the reduction of
   real Java Bytecode.

2. The example in Section 2, and again in 4.5.

3. The evaluation in Section 5.

### The source code

The source code is located in `source` it contains two folders:
The `jreduce` folder contain the Java specific code, and the logical model.
And the `reduce` folder contain the generals code for doing reduction. The code
here is a modification of the code from the original J-Reduce code. To see the
differences, consult the github repositories:

- `github.com/ucla-pls/reduce` from cdc9628 to 17f11b5
- `github.com/ucla-pls/jreduce` from 3ec3a6e to ff4bc47

All the code is written in haskell.

The code for Algorithm 1, is split over two functions. The code for the generalized binary reduction is in `source/reduce/reduce/src/Control/Reduce.hs`, line
213 to 240.
The code for generating the progression is listed in lines 144 - 157
for `source/reduce/reduce-util/src/Control/Reduce/Progression.hs`

The code for generating the graph order (Suplementary Material, B.2) is on lines 186 - 203, in the same file.

The rest of the code is in the `source/reduce` folder to support reduction.

The code to actually build the new version of `jreduce` is in `source/jreduce`, to
read the source start in `source/jreduce/src/JReduce.hs`. There are more strategies
avaiable than in our evalutation, but the interesting are

- "classes": Handeled by OverClases in (Line 109 - 115). The limited model is
  described in `source/jreduce/src/JReduce/Classes.hs`. We can see here that
  the possible items are Content or Target. Target is a folder of jars or
  classes, Content is a jar or a class or any other file. We can see that the
  Key is either a Class with some classname or a jar, metadata file or the base
  of the reduction tree.

  The reduction is calculated by using the itemR which generate
  a PartialReduction tree this explains which items depend on eachother. This structure
  is fairly well documented in `source/reduce/reduce-util/src/Control/Reduce/Reduction.hs`
  So we do not remove a jar file before removing all the contained classes.

  The keyFun calculates all the "referenctial" dependencies in the graph, The interesting
  line is line 143 in which generate the dependencies from class `cls` to all classes
  that is mentioned in `cls`: `toListOf classNames cls`.

- "items+logic": OverItemsLogic (Line 159 - 175 in the `JReduce.hs` file)

  This strategy uses all the bells an whistles of the reduction scheme. The interesting
  file is `source/jreduce/src/JReduce/Logic.hs`. The `data Item` describes the
  things that we can remove and `data Fact` are the variables that correspond
  to those item still exist. The `itemR` function describes a `PartialReduction` like
  before, however its a little more complicated.

  Now for the meat of the project the paper, and the logical expression which
  is used for doing the reduction. The function `logic` on line 621, takes a config,
  a Class Hierarchy and an Item and produces the `Fact` which correspond to the item and
  a Logical Statement with `Fact` as variables. We have tried to make the DSL self
  documenting, here is a taste:

  ```haskell
  IImplements (cls, ct) -> HasInterface (cls^.className) (ct^.simpleType)
    `withLogic` \i ->
    [ -- An Implements only depends on the interface that it implements, and
      -- its type parameters.
      i ==> requireClassNames cls ct
    , -- Given that we should keep the extends
      given keepHierarchy $ classExist cls ==> i
    ]
  ```

  So in this case the rule is if a class implements a type ct, then we require the
  class `ct` to exist. In the config we are able to require that we should not
  change the hierarchy, in which case we simply require that if the class exist then
  the class should also implement `ct`.

- "items+graph+first" and "items+graph+last": OverItemsGraph bool (Line 130 - 136 in `JReduce.hs`)
  is described in the same way as "items+logic" but instead of using the logic
  reduction approach it gennerates a graph (Line 575 in `Logic.hs`), where it
  uses the boolean to choose either the smallest variable "minView" or the
  largest variable "maxView" in each clause to generate edges (Line 581).

### Example

To recreate the example from the paper look in the folder in
`example/main_example/`. The example is equivalent if we want to maintain the
output "Hello, Alice!", instead of the bug.

```bash
$ nix-shell -A rules --arg target nixecdb/rules/examples/main_example/items+logic.rule.nix
```

We run the example, and ask J-Reduce `--dump` all debug information and also
adding that Main.main should be part of the solution.

```bash
$ ./run.sh --dump --core 'Main.main:([Ljava/lang/String;)V!code'
[START] 2021-03-02T10:42:15 ├ JReduce
[ INFO] 2021-03-02T10:42:15 │ ├ Started JReduce.
[START] 2021-03-02T10:42:15 │ ├ Reading inputs
[  END] 2021-03-02T10:42:15 │ │ └ 0.001s
[START] 2021-03-02T10:42:15 │ ├ Calculating Initial Problem
[START] 2021-03-02T10:42:15 │ │ ├ setup
[  END] 2021-03-02T10:42:15 │ │ │ └ 0.001s
[START] 2021-03-02T10:42:15 │ │ ├ run
[  END] 2021-03-02T10:42:15 │ │ │ └ 0.076s
[DEBUG] 2021-03-02T10:42:15 │ │ ├ exitcode:   0
[DEBUG] 2021-03-02T10:42:15 │ │ ├ stdout (bytes: 00014): c4424246
[DEBUG] 2021-03-02T10:42:15 │ │ ├ stderr (bytes: 00000): e3b0c442
[  END] 2021-03-02T10:42:15 │ │ └ 0.080s
[START] 2021-03-02T10:42:15 │ ├ Initializing key function
[START] 2021-03-02T10:42:15 │ │ ├ Calculating the hierarchy
[START] 2021-03-02T10:42:15 │ │ │ ├ Load stdlib stubs
[  END] 2021-03-02T10:42:17 │ │ │ │ └ 1.341s
[START] 2021-03-02T10:42:17 │ │ │ ├ Load project stubs
[  END] 2021-03-02T10:42:17 │ │ │ │ └ 0.004s
[START] 2021-03-02T10:42:17 │ │ │ ├ Compute hierarchy
[  END] 2021-03-02T10:42:18 │ │ │ │ └ 0.939s
[  END] 2021-03-02T10:42:18 │ │ │ └ 2.286s
[ INFO] 2021-03-02T10:42:18 │ │ ├ Found 27 items.
[ INFO] 2021-03-02T10:42:18 │ │ ├ Found 27 facts.
[ INFO] 2021-03-02T10:42:18 │ │ ├ The core is 2 of them.
[  END] 2021-03-02T10:42:18 │ │ └ 2.287s
[START] 2021-03-02T10:42:18 │ ├ Compute CNF

...

[START] 2021-03-02T10:42:19 │ ├ Trying (Iteration 0011)
[DEBUG] 2021-03-02T10:42:19 │ │ ├  Metric: #16 vars, 3 classes, 0 jars, 0 other, 0 Kb
[START] 2021-03-02T10:42:19 │ │ ├ setup
[  END] 2021-03-02T10:42:19 │ │ │ └ 0.001s
[START] 2021-03-02T10:42:19 │ │ ├ run
[  END] 2021-03-02T10:42:19 │ │ │ └ 0.091s
[DEBUG] 2021-03-02T10:42:19 │ │ ├ exitcode:   0
[DEBUG] 2021-03-02T10:42:19 │ │ ├ stdout (bytes: 00014): c4424246
[DEBUG] 2021-03-02T10:42:19 │ │ ├ stderr (bytes: 00000): e3b0c442
[ INFO] 2021-03-02T10:42:19 │ │ ├ success
[  END] 2021-03-02T10:42:19 │ │ └ 0.100s
[ INFO] 2021-03-02T10:42:19 │ ├ Reduction successfull.
[START] 2021-03-02T10:42:19 │ ├ setup
[  END] 2021-03-02T10:42:19 │ │ └ 0.002s
[START] 2021-03-02T10:42:19 │ ├ run
[  END] 2021-03-02T10:42:19 │ │ └ 0.080s
[DEBUG] 2021-03-02T10:42:19 │ ├ exitcode:   0
[DEBUG] 2021-03-02T10:42:19 │ ├ stdout (bytes: 00014): c4424246
[DEBUG] 2021-03-02T10:42:19 │ ├ stderr (bytes: 00000): e3b0c442
[  END] 2021-03-02T10:42:19 │ └ 3.703s
```

And now we can see that the solution is found in only 11 iterations. We can
see that the solution is correct by using `javap` on the reduced solution. Except
for the constructors which are always added by `javap`.

```bash
$ javap reduced/*
public class A implements I {
  public A();
  public java.lang.String m();
}
public interface I {
  public abstract java.lang.String m();
}
public class Main {
  public Main();
  public java.lang.String x(I);
  public static void main(java.lang.String[]);
}
```

In the `workfolder` folder there is a folder for the initial and final
reduction, and all other iterations tried. You can inspect each of them if you want to
witness the full the process.

```bash
$ tree workfolder/reduction/0001/
workfolder/reduction/0001/
├── input
│   └── classes
│       ├── A.class
│       ├── I.class
│       └── Main.class
├── run.sh
├── sandbox
├── stderr
└── stdout
```

- All the metrics for each run is saved in the `workfolder/metrics.csv` file.

- The items are listed in `items.txt`, there are 20 items, if we filter out the
  meta (top variable) and the constructors.

- The `cnf.txt` contains the CNF that we generated in Figure 2, if we filter out the
  constructors and the meta variable. There should be 16 (Syntactic) + 10
  (Referential) + 5 (Non-Referential) = 31 dependencies after filtering,
  a required variable `true  ==> ...`, and finally a single superfluous constraint
  from `Main.main!code ==> I`. The extra constraint produced in line 853
  in the logic file: `c ==> requireClassNamesOf cls (codeByteCode.folded) code`. There we
  require all classes that mentioned in the bytecode of a class: it is not
  strictly necessary, but it is nice extra safety precaution.

- The `variable-graph.txt` contains the graph from Figure 9 (B2.1) and
  `variableorder.txt` contains the variable order in the same section
  (filtering out constructors and meta-variables)

### Evaluation

You should be able to run the evaluation by running the following steps.

Because this is obviously way to long to evaluate the results, we have included the
results of running the code in different stages

1. You can build everything from scratch (**NOTE:** It will take around 459 hours to compute)
  ```bash
  $ nix-build -A rules --arg target nixecdb/rules/all.rule.nix
  ...
  /nix/store/5v6xghid3s569bwcipasynlyi6d5v2yw-all
  ```

  Now `result` should point to `/nix/store/5v6xghid3s569bwcipasynlyi6d5v2yw-all`, and
  should contain a file tree of the different experiments run. Each folder contain a
  `run.sh` file which indicate what operation where run in that folder to genererate the
  files you see.

2. You can use the nix cache that we have included in `pre-caluclated`:
  ```bash
  $ bzip2 -d pre-calculated/cache.nar.bzip2 | nix-store --import
  ```
  This might take some time but after that running the script from before should
  take 10-20 s, as it is only finding the files from before.

  ```bash
  $ nix-build -A rules --arg target nixecdb/rules/all.rule.nix
  /nix/store/5v6xghid3s569bwcipasynlyi6d5v2yw-all
  ```

  Now you should be ready to explore the filetree.

3. We have included the important results in `.csv` files in `pre-calculated`, which you
  can use to reproduce the evaluation results. The csv files are from another run than the
  one reported in the paper, so there are some difference in time.

  You can explore the data interactively in the `evaluation.ipynb` Jupyter
  Notebook. It explains how to recreate the results of the paper. You can open
  jupyter using the following command:

  ```bash
  $ nix-shell nix/jupyter.nix --run 'jupyter notebook'
  ```

  If you want to run the analysis on the results you created make sure to change the folder variable
  in `In [2]`.

4. We have also made a copy of our run of the Notebook in `pre-calculated/evaluation.html`.


