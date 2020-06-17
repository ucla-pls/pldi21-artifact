self: 
let
  binary-reduction-artifact = import fix/fse19-artifact.nix;
  from-artifact = env: 
    self.stdenv.mkDerivation {
      inherit (env) name installPhase;  
      src = binary-reduction-artifact;
      preferLocalBuild = true;
      buildInputs = (with self; [ unzip ]);
      unpackPhase = ''
        unzip $src ${
          self.lib.strings.concatMapStringsSep " "
          (x: "'esecfse2019-binary-reduction/" + x + "'")
          env.items
        }
        cd esecfse2019-binary-reduction
      '';
    };
  decompilers = from-artifact {
    name = "decompilers";
    items = ["decompilers/*"];
    installPhase = "mv decompilers $out";
  };
  artifact-src = from-artifact {
    name = "jreduce-artifact-src";
    items = ["jreduce/*" "lib/*"];
    installPhase = ''
      mkdir -p $out
      mv * $out
    '';
  };
in 
{
  benchmarks = from-artifact {
    name = "binary-reduction-artifact";
    items = ["data/benchmarks.tar.gz"];
    installPhase = ''
      tar -xf data/benchmarks.tar.gz 
      mv benchmarks $out
    '';
  };

  jreduce-old = self.callPackage ./jreduce-old { 
    artifact = artifact-src; 
  };

  predicates =
    self.stdenv.mkDerivation {
      name = "predicates";
      src = ../predicate;
      installPhase = ''
        mkdir -p $out
        cp -r * $out
      '';
    };

  stubs =
    self.stdenv.mkDerivation {
      name = "stdlib-stubs.bin";
      buildInputs = (with self; [ openjdk javaq ]);
      phases = "installPhase";
      installPhase = ''
        javaq --fast --stdlib hierarchy+bin > $out
      '';
    };

  mkRule = attr:
    self.stdenv.mkDerivation (
      attr // {
        buildInputs = attr.buildInputs ++
          (with self; [ openjdk unzip which ]);
        CFR = "${decompilers}/cfr/cfr_0_132.jar";
        FERNFLOWER = "${decompilers}/fernflower/fernflower.jar";
        PROCYON = "${decompilers}/procyon/procyon-decompiler-0.5.30.jar";
      }
    );
}
