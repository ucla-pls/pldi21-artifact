{ stdenv, openjdk }:
let 
  mkExample = name: folder:
    stdenv.mkDerivation {
      name = name;
      buildInputs = [ openjdk ];
      src = folder;
      buildPhase = ''
        mkdir classes
        javac -sourcepath $src -d classes $(find "$src" -name "*.java") 
      '';
      installPhase = ''
        mkdir -p $out/lib
        mv classes $out
        ln -s $src $out/src
      '';
    };
in { 
  main_example = mkExample "main_example" ./main_example; 
  field = mkExample "field" ./field;
  throws = mkExample "throws" ./throws;
  inner = mkExample "inner" ./inner;
  defaultmethod = mkExample "defaultmethod" ./defaultmethod;
}
