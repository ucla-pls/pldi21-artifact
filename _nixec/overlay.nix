self: super:
{
  nixec-builder = super.callPackage ./builder.nix {};

  examples = super.callPackage ../examples {};

  benchmarks = 
    super.stdenv.mkDerivation {
      name = "benchmarks";
      src = builtins.fetchurl {
        url = file:///Users/kalhauge/Develop/projects/2019/nixec/example/benchmarks.tar.gz;
        sha256 = "0xq4nm8vvpgq0bj4nx6v0hmca3iryqlliga60x5qcqd1hal8j5pm";
      };
      unpackPhase = "tar -xf $src benchmarks/";
      installPhase = "mv benchmarks $out";
    };
  
  predicates = 
    super.stdenv.mkDerivation {
      name = "predicates";
      src = ../predicate;
      installPhase = ''
        mkdir -p $out
        cp -r * $out 
      '';
    };

  stubs = 
    super.stdenv.mkDerivation {
      name = "stdlib-stubs.bin";
      buildInputs = (with self; [ openjdk haskellPackages.javaq ]);
      phases = "installPhase";
      installPhase = ''
        javaq --fast --stdlib hierarchy+bin > $out
      '';
    };


  mkRule = attr:
    super.stdenv.mkDerivation (
      attr // { 
        buildInputs = attr.buildInputs ++ 
          (with self; [ openjdk unzip which ]);
        CFR = ../decompilers/cfr/cfr_0_132.jar;
        FERNFLOWER = ../decompilers/fernflower/fernflower.jar;
        PROCYON = ../decompilers/procyon/procyon-decompiler-0.5.30.jar;
      }
    );
}
