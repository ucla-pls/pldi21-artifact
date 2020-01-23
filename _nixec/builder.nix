{ stdenv, ghc }:
stdenv.mkDerivation {
  name = "nixec-builder";
  src = ../Nixecfile.hs;
  buildInputs = [
    ( ghc.withPackages
      (p: with p; [ nixec text ])
    )
  ];
  phases = "buildPhase";
  buildPhase = ''
    mkdir -p $out/bin
    ghc --make $src -rtsopts -threaded -with-rtsopts=-I0 \
      -XOverloadedStrings \
      -outputdir=$out/bin/ -o $out/bin/nixec-builder
  '';
}
