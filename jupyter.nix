let
  x = import ./default.nix {};
  python = x.pkgs.python3.withPackages (pkgs: with pkgs;
  [ numpy matplotlib scipy pygraphviz pandas ipython notebook ]
  );
in x.pkgs.mkShell {
  buildInputs = [ python ];
}
