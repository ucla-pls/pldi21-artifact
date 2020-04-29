self: super: 
{
  binary-reduction-artifact = import ./fix/fse19-artifact.nix;

  from-artifact = env: 
    super.stdenv.mkDerivation {
      inherit (env) name installPhase;  
      src = self.binary-reduction-artifact;
      buildInputs = (with self; [ unzip ]);
      unpackPhase = ''
        unzip $src ${
          super.lib.strings.concatMapStringsSep " "
          (x: "'esecfse2019-binary-reduction/" + x + "'")
          env.items
        }
        cd esecfse2019-binary-reduction
      '';
    };

  decompilers = self.from-artifact {
    name = "decompilers";
    items = ["decompilers/*"];
    installPhase = "mv decompilers $out";
  };

  benchmarks = self.from-artifact {
    name = "binary-reduction-artifact";
    items = ["data/benchmarks.tar.gz"];
    installPhase = "tar -xf data/benchmarks.tar.gz $out";
  };

  artifact-src = self.from-artifact {
    name = "jreduce-artifact-src";
    items = ["jreduce/*" "lib/*"];
    installPhase = ''
      mkdir -p $out
      mv * $out
    '';
  };

  nixec-builder = super.callPackage ./builder.nix {};

  examples = super.callPackage ../examples {};

  jreduce-old = self.callPackage ./jreduce-old { artifact = self.artifact-src; };

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
      buildInputs = (with self; [ openjdk javaq ]);
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
        CFR = "${self.decompilers}/cfr/cfr_0_132.jar";
        FERNFLOWER = "${self.decompilers}/fernflower/fernflower.jar";
        PROCYON = "${self.decompilers}/procyon/procyon-decompiler-0.5.30.jar";
      }
    );
}
