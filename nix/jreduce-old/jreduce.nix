{ mkDerivation, base, bytestring, cassava, containers, deepseq
, filepath, hpack, jvmhs, lens, lens-action, mtl
, optparse-applicative, reduce, reduce-util, stdenv, text, time
, unliftio, unordered-containers, zip-archive
, artifact
}:
mkDerivation {
  pname = "jreduce";
  version = "0.0.1";
  src = "${artifact}/jreduce";
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    base bytestring cassava containers deepseq filepath jvmhs lens
    lens-action mtl optparse-applicative reduce reduce-util text time
    unliftio unordered-containers zip-archive
  ];
  libraryToolDepends = [ hpack ];
  executableHaskellDepends = [
    base bytestring cassava containers deepseq filepath jvmhs lens
    lens-action mtl optparse-applicative reduce reduce-util text time
    unliftio unordered-containers zip-archive
  ];
  prePatch = "hpack";
  homepage = "https://github.com/ucla-pls/jvmhs#readme";
  description = "A tool for reducing Java Bytecode files";
  license = stdenv.lib.licenses.bsd3;
}
