{ stdenv, openjdk}:
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
        [ -e "$src/resources" ] && cp -r $src/resources $out/classes
        ln -s $src $out/src
      '';
    };
in { 
  main_example = mkExample "main_example" ./main_example; 
  field = mkExample "field" ./field;
  throws = mkExample "throws" ./throws;
  inner = mkExample "inner" ./inner;
  lambda = mkExample "lambda" ./lambda;
  defaultmethod = mkExample "defaultmethod" ./defaultmethod;
  metadata = mkExample "metadata" ./metadata;
}
