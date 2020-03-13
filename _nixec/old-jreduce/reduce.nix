{ mkDerivation, base, containers, contravariant, directory, fgl
, filepath, generic-random, hpack, hspec-expectations-pretty-diff
, mtl, QuickCheck, random, stdenv, tasty, tasty-discover
, tasty-hspec, tasty-hunit, tasty-quickcheck, text, transformers
, vector, artifact
}:
mkDerivation {
  pname = "reduce";
  version = "0.1.0.0";
  src = "${artifact}/lib/reduce/reduce";
  libraryHaskellDepends = [
    base containers contravariant mtl transformers vector
  ];
  libraryToolDepends = [ hpack ];
  testHaskellDepends = [
    base containers contravariant directory filepath generic-random
    hspec-expectations-pretty-diff mtl QuickCheck tasty tasty-discover
    tasty-hspec tasty-hunit tasty-quickcheck text transformers vector
  ];
  testToolDepends = [ tasty-discover ];
  benchmarkHaskellDepends = [
    base containers contravariant fgl mtl random transformers vector
  ];
  prePatch = "hpack";
  homepage = "https://github.com/ucla-pls/reduce#readme";
  license = stdenv.lib.licenses.bsd3;
}
