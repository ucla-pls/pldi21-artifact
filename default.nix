{ fpkgs ? nix/fix/nixpkgs.nix
, nixec-src ? nix/fix/nixec.nix
, db ? null
, target ? null

, examples ? ./examples/default.nix

, overrides ? {}
, fix ? import nix/fix fix // overrides
}:
import nixec-src {
  inherit db target;
  nixecfile = ./Nixecfile.hs;
  pkgs = import fpkgs {
    overlays = [
      (self: super: import nix/overlay.nix self)
      (self: super:
        let
          hpkgs = self.haskellPackages.extend (
            super.haskell.lib.packageSourceOverrides
            { inherit (fix) jreduce javaq jvmhs jvm-binary reduce reduce-util dirtree hspec-hedgehog; }
            );
        in
        { jreduce = self.haskell.lib.enableExecutableProfiling hpkgs.jreduce;
          javaq = hpkgs.javaq;
          examples = super.callPackage examples {};
          extractpy = ./bin/extract.py;
          fixpy = ./bin/fix.py;
        }
      )
    ];
  };
}

