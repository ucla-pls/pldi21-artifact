{ python3, stdenv }:
stdenv.mkDerivation {
  name = "summary";
  src = ./summary.py;
  buildInputs = [ python3 ];
  unpackPhase = "true";
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/summary.py
    chmod +x $out/bin/summary.py
  '';

}

