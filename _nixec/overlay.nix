self: super:
{
  nixec-builder = super.callPackage ./builder.nix {};

  examples = super.callPackage ../examples {};

	binary-reduction-artifact = 
    builtins.fetchurl {
      url = https://zenodo.org/record/3262201/files/esecfse2019-binary-reduction.zip?download=1;
      sha256 = "0ql5csmvrcc6x712wf4fbi2x7919jdqlgx0ialq36viahnddhs4g";
    };

  benchmarks = super.stdenv.mkDerivation {
    name = "binary-reduction-artifact";
    src = self.binary-reduction-artifact;
    buildInputs = (with self; [ unzip ]);
    unpackPhase = ''
      unzip $src esecfse2019-binary-reduction/data/benchmarks.tar.gz 
			tar -xf esecfse2019-binary-reduction/data/benchmarks.tar.gz benchmarks/
		'';
    installPhase = "mv benchmarks $out";
  };

  # benchmarks = binary-reduction-benchmarks;
    # super.stdenv.mkDerivation {
    #   name = "benchmarks";
    #   src = builtins.fetchurl {
    #     url = file:///home/kalhauge/Work/Evaluartion/method-reduction/data/benchmarks.tar.gz;
    #     sha256 = "0xq4nm8vvpgq0bj4nx6v0hmca3iryqlliga60x5qcqd1hal8j5pm";
    #   };
    #   unpackPhase = "tar -xf $src benchmarks/";
    #   installPhase = "mv benchmarks $out";
    # };

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
