{ stdenv, callPackage, nixec-builder }:
stdenv.mkDerivation {
    name = "database";
    buildInputs = [ nixec-builder ];
    phases = "buildPhase";
    buildPhase = "nixec-builder --previous ${/home/kalhauge/Work/Evaluation/method-reduction/_nixec/default.nix} $out";
  }




