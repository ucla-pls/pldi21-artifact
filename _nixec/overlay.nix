self: super:
{
  nixec-builder = super.callPackage ./builder.nix {};

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

  benchmark-small = 
    super.stdenv.mkDerivation {
      name = "benchmarks";
      src = builtins.fetchurl {
        url = file:///Users/kalhauge/Develop/projects/2019/nixec/example/benchmarks.tar.gz;
        sha256 = "0xq4nm8vvpgq0bj4nx6v0hmca3iryqlliga60x5qcqd1hal8j5pm";
      };
      unpackPhase = ''
      tar -xf $src \
        benchmarks/urlde8e6ba918_Michael_Heinzelmann_IT_Consulting_dog4sql_tgz-pJ8 \
        benchmarks/urle018949e15_DzenanaMahmutspahic_SI2013Tim8_tgz-pJ8 \
        benchmarks/urle1e37fc2b4_mksource_DataStructure_tgz-pJ8 \
        benchmarks/urle3c114971e_ShawnZhong_Java_tgz-pJ8 \
        benchmarks/urle65252f83f_bocchino_AppleCore_tgz-pJ8 \
        benchmarks/urle9a5be5560_lyjberserker_LeetCode_tgz-pJ8 \
        benchmarks/urlf244d20be0_rjwut_ArtClientLib_tgz-pJ8 \
        benchmarks/urlfb1c607a9c_harshiet_RallyExport_tgz-pJ8 \
        benchmarks/urlfc5806b04b_wlu_mstr_leveldb_java_tgz-pJ8 \
        benchmarks/urlfd310dd96e_nomoonx_LeetCodeOJ_tgz-pJ8 \
      '';
      installPhase = "mv benchmarks $out";
    };

  benchmark-one = 
    super.stdenv.mkDerivation {
      name = "benchmarks";
      src = builtins.fetchurl {
        url = file:///Users/kalhauge/Develop/projects/2019/nixec/example/benchmarks.tar.gz;
        sha256 = "0xq4nm8vvpgq0bj4nx6v0hmca3iryqlliga60x5qcqd1hal8j5pm";
      };
      unpackPhase = ''
      tar -xf $src benchmarks/urlfc5806b04b_wlu_mstr_leveldb_java
      '';
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
