{ stdenv, callPackage, nixec-builder }:
stdenv.mkDerivation {
    name = "database";
    buildInputs = [ nixec-builder ];
    phases = "buildPhase";
    buildPhase = "nixec-builder --previous ${/Users/kalhauge/Work/Phd/articles/method-reduction/_nixec/default.nix} $out";
  }


