{ mkDerivation, aeson, attoparsec, base, bytestring, containers
, deepseq, directory, fgl, fgl-visualize, filepath, generic-random
, hashable, hpack, hspec-expectations-pretty-diff, jvm-binary, lens
, lens-action, mtl, process, QuickCheck, stdenv, tasty
, tasty-discover, tasty-hspec, tasty-hunit, tasty-quickcheck, text
, transformers, unordered-containers, vector, zip-archive
, artifact
}:
mkDerivation {
  pname = "jvmhs";
  version = "0.0.1";
  src = "${artifact}/lib/jvmhs/jvmhs";
  libraryHaskellDepends = [
    aeson attoparsec base bytestring containers deepseq directory fgl
    fgl-visualize filepath hashable jvm-binary lens lens-action mtl
    process text transformers unordered-containers vector zip-archive
  ];
  libraryToolDepends = [ hpack ];
  testHaskellDepends = [
    aeson attoparsec base bytestring containers deepseq directory fgl
    fgl-visualize filepath generic-random hashable
    hspec-expectations-pretty-diff jvm-binary lens lens-action mtl
    process QuickCheck tasty tasty-discover tasty-hspec tasty-hunit
    tasty-quickcheck text transformers unordered-containers vector
    zip-archive
  ];
  testToolDepends = [ tasty-discover ];
  prePatch = "hpack";
  homepage = "https://github.com/ucla-pls/jvmhs#readme";
  description = "A library for reading Java class-files";
  license = stdenv.lib.licenses.bsd3;
}
