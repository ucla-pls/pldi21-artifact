# (485) PLDI'21 "Logical Input Reduction" Artifact

By Christian Kalhauge and Jens Palsberg

- Version: 1.0

The artifact have two main sections:

1. *Getting Started Guide:* This is a short introduction to the artifact and
   explanation of how setup system.

2. *Step-by-Step instruction:* Lists the findings supported by the artifact,
   and show how to reproduce the results.

## Getting Started Guide

This artifact is a different than other artifacts, because we have gone into
great lengths in making every decision we have made reproducible and
inspectable from first principles.

To make sure that everything is reproducible we use several technologies, the most
prominent is nix. Nix is a purely functional package manager which ensures that
(almost) every build is reproducible. We strongly recommend reading more about it
on [their homepage](nixos.org). You can install it on most system, however, the
derivations that we have created have been created on a NixOS machine.

### Choose an Installation of Nix

The artifact was tested on a NixOS machine and the Virtual Box, but many options exist:

```bash
$ nix --version
nix (Nix) 2.3.3

$ nixos-version
19.09.2518.8260cd5bc65 (Loris)
```

This evaluation uses Nix to make all builds reproducible. So either

1. Install [nix](https://nixos.org/download.html#nix-quick-install) on your system
   (the chache only match on a linux only).

2. Install [NixOS](https://nixos.org/download.html#nixos-iso) as an operating system.

3. Use the virtual box provided by their
   [webpage](https://nixos.org/download.html#nixos-virtualbox) the container needs atleast
   8 Gb of RAM and 50 Gb of storage.

4. Finally we have created a virtual box, from the virtual box above, where we
   are sure that everything have been setup correctly, and the cache is loaded.

   - username: demo.
   - password: demo.
   - uses 34 Gb on your disk.

### Steps Taken Produce the Virtual Box.

*NOTE:* This has already been done in the virtual box, and are only for
reference.  Build from the `NixOS 20.09.3346.4d000ee90c6e2 (x86_64-linux)` OVA,
from option 3, with RAM set to 8192 MB.

0. Open Konsole and install the tools we need:

   ```bash
   nix-env -iA nixos.vim nixos.pv nixos.git nixos.htop
   ```

1. Checkout the artifact github repository:

   ```bash
   $ git clone --recurse-submodules https://github.com/ucla-pls/pldi21-artifact.git
   $ cd pldi21-artifact
   ```

2. Download the `cache.nar.bzip2` from Google Drive. Follow the
   [link](https://drive.google.com/file/d/14Zj2E-JiNGI4zWy-0IQcyuI-SqW5h-Lo/view?usp=sharing).

3. (10 min) Load the cache into the nix-store. This makes sure that all the following steps will take
   a lot shorter, and also make sure that evaluations results are the ones we ran on our
   machines.

   ```bash
   $ pv ~/Downloads/cache.nar.bzip2 | bzip2 -c -d | sudo nix-store --option require-sigs false --import
   $ rm ~/Downloads/cache.nar.bzip2
   ```

4. (2 min) Build the evaluation framework:

   ```bash
   $ nix-shell -A all --run 'nixec list --check -v'
   ```

4. (5 s) Fetch the evaluation results from the nix-store.

   ```bash
   $ nix-shell -A rules --arg target nixecdb/rules/all.rule.nix
   /nix/store/5v6xghid3s569bwcipasynlyi6d5v2yw-all
   ```

5. (16 min) Optimize the nix-store so that the disk is smaller.

   ```bash
   $ nix-store --optimize
   ```

### Getting Into the Weeds

The artifact is structured like this:

```bash
.
├── bin
│   -- A number of python scripts used for extracting the data.
├── decompilers
│   -- The decompilers that we have bugs in.
├── examples
│   -- A list of small examples which we run J-Reduce on.
├── predicate
│   -- Contains the predicates that we used when doing reduction.
├── source
│   -- Contains the source code of J-Reduce.
├── pldi21-paper485.pdf
│   -- This is the paper
├── pldi21-paper485-supplemental_text.pdf
│   -- This is the supplemental text
├── pre-calculated
│   -- This is where we have put our results to reduce the time needed to
│   -- evaluate the artifact
├── evaluation.ipynb
│   -- A Jupyter Notebook which reproduces the evaluation.
├── figures
│   -- This is where the Jupyter Notebook puts the figures we use in the paper.
├── README.md
│   -- This file.
├── Nixecfile.hs
│   -- This file describes how we have setup the evaluation. It's written in
│   -- a DSL in haskell, but we have commented it to give an impression on
│   -- what is going on.
├── nix
│   -- This is where we have defined the versions of all dependencies of the
|   -- evaluation.
└── default.nix
    -- This is the main entry point for all our nix operations.
```



The evaluation is written in the `Nixecfile.hs`. You can change how we process the
benchmarks in this file. For example, you change the evaluation so that it only
uses the first 5 benchmarks, by changing line 38 to `fmap (take 5) .`.

```
$ nix-shell -A all --run 'nixec list --check -v'
[    INFO] Started Nixec.
[    INFO] Found Nixecfile: /vagrant/Nixecfile.hs
[    INFO] | compute db | Starting
[    INFO] | compute db | Calculating the database
[    INFO] | | build | Starting
[    INFO] | | build | Done in  1.773s
[    INFO] | | build | Starting
```

Running this the first time will take some time while it downloads the dependencies
and improving

That will recreate `nixecdb` with the new rules, but it might take some time.
Any rule in the directory should be executable with the command:

```bash
$ nix-build -A rules --arg target <path-to-rule>
```

And explorable with:

```bash
$ nix-shell -A rules --arg target <path-to-rule>
```

You can start by running the main example (See the example part of the step-by-step guide)

### Getting the Results.

With the caches loaded retrieving the full evaluation should take around 10s
(otherwise it will take approx. 500 hours)

```bash
$ nix-build -A rules --arg target nixecdb/rules/all.rule.nix
```

This should output a folder of results. If everything went well it should produce
a `result` symbolic link to `/nix/store/wmaz3ll91hb2yc6126lnaa5mp921x4qq-all`.

You should be able to inspect the result tree, each folder correspond to a "rule" in
the `nixecdb` database, and will contain a `run.sh` file. This file was run to get
the results in that folder.

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
    ...
    ├── 0022
    └── 0023

30 directories, 7 files
```

Each subfolder in `workfolder`, contains the `run.sh` file which is what was
run, and `input` which is what it was run on. `sandbox` contains the result of
the run.

You can open a shell on each rule in the `nixecdb`, and on the aggregations you
can inspect how the different python tools extract the information from
benchmarks after the runs.

```bash
$ nix-shell -A rules --arg target nixecdb/rules/full.rule.nix
```

You can also run the example from the paper: see the instructions in the Example
part of the next section.

### Trouble-shooting

-  Nix can be sensitive to filechanges, especially in the folders `examples/`,
  `bin/`, `decompilers/`, `predicates/`. To check that everything is correct the following
  command should return this:

  ```bash
  $ nix-instantiate -A rules --arg target nixecdb/rules/all.rule.nix
  warning: you did not specify '--add-root'; the result might be removed by the garbage collector
  /nix/store/9w7y56cd7xzzi5fd942ad8fd6j3770a7-all.drv
  ```

- This is a huge evaluation, so while loading the chache you might run out of memory or space.
  If there is still space left at your device and it still complains. Then you might be out of
  inodes: `sudo df -i /`. There is sadly not alot to do about except for getting a bigger disk.

## Step-by-Step instruction

This artifact support three parts of the paper:

1. A record of the code and full logical model used to do the reduction of
   real Java Bytecode.

2. The example in Section 2, and again in 4.5.

3. The evaluation in Section 5.

### The source code

The source code is located in `source` it contains two folders: The `jreduce`
folder contain the Java specific code, and the logical model.  And the `reduce`
folder contain the generals code for doing reduction. The code here is
a modification of the code from the original J-Reduce code. To see the
differences, consult the github repositories:

- `github.com/ucla-pls/reduce` from cdc9628 to 17f11b5
- `github.com/ucla-pls/jreduce` from 3ec3a6e to ff4bc47

All the code is written in Haskell.

The code for Algorithm 1, is split over two functions. The code for the
generalized binary reduction is in
`source/reduce/reduce/src/Control/Reduce.hs`, line 213 to 240.  The code for
generating the progression is listed in lines 144 - 157 for
`source/reduce/reduce-util/src/Control/Reduce/Progression.hs`

The code for generating the graph order (Supplementary Material, B.2) is on
lines 186 - 203, in the same file.

The rest of the code is in the `source/reduce` folder supports reduction.

The code to build the new version of `jreduce` is in `source/jreduce`, to
read the source start in `source/jreduce/src/JReduce.hs`. There are more strategies
available than in we use in our evaluation, but the ones we use are:

-  "classes": Handled by OverClases in (Line 109 - 115). The limited model is
   described in `source/jreduce/src/JReduce/Classes.hs`. We can see here that
   the possible items are Content or Target. Target is a folder of jars or
   classes, Content is a jar or a class or any other file. We can see that the
   Key is either a Class with some classname or a jar, metadata file or the base
   of the reduction tree.

   The reduction is calculated by using the itemR which generate
   a PartialReduction tree this explains which items depend on eachother. This
   structure is fairly well documented in
   `source/reduce/reduce-util/src/Control/Reduce/Reduction.hs`.

   The keyFun calculates all the "referential" dependencies in the graph, The interesting
   line is line 143 in which generate the dependencies from class `cls` to all classes
   that is mentioned in `cls`: `toListOf classNames cls`.

   `classNames` is a function from the [`jvmhs`](https://github.com/ucla-pls/jvmhs) library.

-  "items+logic": OverItemsLogic (Line 159 - 175 in the `JReduce.hs` file)

   This strategy uses all the bells an whistles of the reduction scheme. The interesting
   file is `source/jreduce/src/JReduce/Logic.hs`. The `data Item` describes the
   things that we can remove and `data Fact` are the variables that correspond
   to that those item still exist. The `itemR` function describes a `PartialReduction` like
   before, however its a little more complicated.

   Now for the meat of the paper: the logical expression which
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

-  "items+graph+first" and "items+graph+last": OverItemsGraph bool (Line 130 - 136 in `JReduce.hs`)
   is described in the same way as "items+logic" but instead of using the logic
   reduction approach it generates a graph (Line 575 in `Logic.hs`), where it
   uses the boolean to choose either the smallest variable "minView" or the
   largest variable "maxView" in each clause to generate edges (Line 581).

#### Running the examples with code changes

Say you have updated the source code and want to run an example again. In this case
you can use the `overrides` argument. Here we ask nix to build the example from before
with but with a version of jreduce which we have in the folder `source/jreduce`.

```bash
nix-build \
  --arg target nixecdb/rules/examples/main_example/items+logic.rule.nix \
  -A rules \
  --arg overrides '{jreduce=source/jreduce/; reduce-src=source/reduce/;}'
```

This will automatically build jreduce and run the benchmark.

### Example

To recreate the example from the paper look in the folder in
`example/main_example/`. The example is equivalent if we want to maintain the
output "Hello, Alice!", instead of a bug.

Use the following command to try to run the example yourself:

```bash
$ nix-shell -A rules --arg target nixecdb/rules/examples/main_example/items+logic.rule.nix
```

This will drop you into a temporary directory with everything setup.
We run the example, and ask J-Reduce `--dump` all debug information and also
adding that Main.main should be part of the solution:

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

You should be able to run the evaluation from section 5. Our entire evaluation
is done by a single command:

```bash
$ nix-build -A rules --arg target nixecdb/rules/all.rule.nix
...
/nix/store/5v6xghid3s569bwcipasynlyi6d5v2yw-all
```

If you have loaded the cache it should only take a couple of seconds, otherwise
it will take around 459 computing hours to build.

After this a symbolic link name `result` should point to
`/nix/store/5v6xghid3s569bwcipasynlyi6d5v2yw-all`, and should contain a file
tree of the different experiments.

```bash
$ tree result
result
├── env-vars
├── examples -> /nix/store/i91zj3vvmdy24a0hljl7v5ciydg3c6hg-examples
├── full -> /nix/store/gkm83xdlss6d8x7ppln6gwji148v8wkl-full
├── run.sh -> /nix/store/ikjh0rajsjyylkib6fsqgm9v50p2x4ji-run.sh
├── stderr
├── stdout
└── times.csv
```

In each sub folder it contain a `run.sh` file which indicate what operation
were run in that folder to generate the files you see, even in the aggregations.

A typical benchmark is split into `predicates` (`cfg`, `procyon`, and
`fernflower`) and then again into `strategies` (`jreduce`, `classes`,
`items+logic`, `items+graph+first`, and `items+graph+last`). `jreduce` refers
to the old version of `jreduce` and `items+logic` our new one as described in
the previous section.

```bash
$ tree -d -L 2 -l result/full/url0067cdd33d_goldolphin_Mi
result/full/url0067cdd33d_goldolphin_Mi
├── cfr -> /nix/store/cxlarkc5syh15725cajibrsnhgpiwrm1-cfr
│   ├── classes -> /nix/store/ny2rpiyln6qqmzypyngdbkpz764716zl-classes
│   ├── items+graph+first -> /nix/store/8jqpdjih9cxv8ijy15870n1y64nqykmb-items+graph+first
│   ├── items+graph+last -> /nix/store/p51bi0ipbikzhqxq5h572caw5l7mvbyf-items+graph+last
│   ├── items+logic -> /nix/store/9rzk6yd123j8fdnzmhcqa9fz5k3sgwkg-items+logic
│   ├── jreduce -> /nix/store/2facmcgi7x7yxgz887g593bb6hvrnh0c-jreduce
│   └── run -> /nix/store/9hrhl80fal7hwbhbkkgbbh7whbd515xy-run
├── fernflower -> /nix/store/7i8iqfw310jax86pkh2v71n4vl571yfi-fernflower
│   ├── classes -> /nix/store/ds0fnzbvma29wp7dx08kgaxjqxynd9d5-classes
│   ├── items+graph+first -> /nix/store/h9g1mxqm6zk2ag40ly3773bspf8n8z8m-items+graph+first
│   ├── items+graph+last -> /nix/store/ss3aym71jy9scf196cvs8m630gy429bq-items+graph+last
│   ├── items+logic -> /nix/store/yrgyly8i1cwdihdhc6laqpxx6dnyx958-items+logic
│   ├── jreduce -> /nix/store/314pv394kmssf0bs2l3dxprvnd1jqgh8-jreduce
│   └── run -> /nix/store/vrgs38xx2g36d3bca5hh4l6ks240sxwj-run
└── procyon -> /nix/store/s7qpsbr9f6zric170rw5b1l2shr742jh-procyon
    ├── classes -> /nix/store/0018x672b1gfxcjskrk587kydhl68b68-classes
    ├── items+graph+first -> /nix/store/ycc4s0ffk4zmw75rsss00w1b5fyn8izk-items+graph+first
    ├── items+graph+last -> /nix/store/nrw0180rian528h19vy9zbv2mlhvr27g-items+graph+last
    ├── items+logic -> /nix/store/d4lay4hjp51xc03vz2qaqlvahradx64x-items+logic
    ├── jreduce -> /nix/store/39h15lmk0y858adaxa3wkddrvi4cjwr3-jreduce
    └── run -> /nix/store/z9zcbqbyz1phzkavxl35x4fv073qlidw-run
```

You can explore the data interactively in the `evaluation.ipynb` Jupyter
Notebook. It explains how to recreate the results of the paper. You can open
jupyter using the following command:

```bash
$ nix-shell nix/jupyter.nix --run 'jupyter notebook evaluation.ipynb'
```

We have included the important results in `.csv` files in `pre-calculated`
folder, which you can use to reproduce the evaluation results. The csv files
are from another run than the one reported in the paper, so there are some
difference in time.  If you want to run the analysis on the results you created
make sure to change the folder variable in `In [2]`.

PS. We have also made a copy of our run of the Notebook in
`pre-calculated/evaluation.html`, which you should be able to open with
a normal browser


# APPENDIX

## Benchmarks removed from the data-set

Some benchmarks were removed from the dataset (as noted in the paper).

### Covariant Arrays

You can cast arrays to other arrays, this is not enforced by the java
type system.

```java
Object [] a = new Car[1];
a[0] = "I'm not a car";
```

-   url22ade473db_sureshsajja_CodingProblems, because it contains a bug in the
   compiler, which expolits Covarient Arrays.
   [here](https://github.com/sureshsajja/CodingProblems/blob/master/src/main/java/com/coderevisited/generics/CovariantArrays.java)

-  url2984a84cec_yusuke2255_relation_resolver, same problem

-  url484e914e4f_JasperZXY_TestJava, same problem

### Overloads the std-library

-  url03c33a0cf1_m_m_m_java8_backports. Reimplements many items in the stdlibrary. This
   makes it hard to figure out items which were meant by the compiler.
