self: super:
{
  nixec-builder = super.callPackage ./builder.nix {};

  examples = super.callPackage ../examples {};

  binary-reduction-artifact = import ../nix/fse19-artifact.nix;

  decompilers = super.stdenv.mkDerivation {
    name = "decompilers";
    src = self.binary-reduction-artifact;
    buildInputs = (with self; [ unzip ]);
    unpackPhase = ''
      unzip $src esecfse2019-binary-reduction/decompilers
     '';
    installPhase = "mv esecfse2019-binary-reduction/decompilers $out";
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

  artifact-src = super.stdenv.mkDerivation {
    name = "jreduce-artifact-src";
    src = self.binary-reduction-artifact;
    buildInputs = (with self; [ unzip ]);
    unpackPhase = ''
      unzip $src 'esecfse2019-binary-reduction/jreduce/*' 'esecfse2019-binary-reduction/lib/*'
    '';
    installPhase = ''
      mkdir -p $out
      mv esecfse2019-binary-reduction/* $out
    '';
  };
  
  jreduce-old = self.callPackage ./old-jreduce { artifact = self.artifact-src; };

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
