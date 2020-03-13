{ mkDerivation, async, base, bytestring, cassava, containers
, contravariant, cryptohash-sha256, data-fix, deepseq, directory
, filepath, hpack, hspec, lens, megaparsec, mtl
, optparse-applicative, process, reduce, stdenv, stm, temporary
, text, time, transformers, typed-process, unliftio
, artifact
}:
mkDerivation {
  pname = "reduce-util";
  version = "0.1.0.0";
  src = "${artifact}/lib/reduce/reduce-util";
  libraryHaskellDepends = [
    async base bytestring cassava containers contravariant
    cryptohash-sha256 data-fix deepseq directory filepath lens
    megaparsec mtl optparse-applicative process reduce stm temporary
    text time transformers typed-process unliftio
  ];
  libraryToolDepends = [ hpack ];
  testHaskellDepends = [
    async base bytestring cassava containers contravariant
    cryptohash-sha256 data-fix deepseq directory filepath hspec lens
    megaparsec mtl optparse-applicative process reduce stm temporary
    text time transformers typed-process unliftio
  ];
  prePatch = "hpack";
  homepage = "https://github.com/kalhauge/reduce#readme";
  license = stdenv.lib.licenses.bsd3;
}
