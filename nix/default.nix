{ fpkgs ? ./fix/nixpkgs.nix
, jreduce ? import ./fix/jreduce.nix
, jreduce-prev ? import ./fix/jreduce-prev.nix
, javaq   ? import ./fix/javaq.nix
, examples ? ../examples
}:
import fpkgs {
  overlays = [
    (self: import ./overlay.nix)
    (self: super: {
      jreduce = import jreduce { pkgs = super; };
      jreduce-prev = import jreduce-prev { pkgs = super; };
      javaq   = import javaq   { pkgs = super; };
      examples = super.callPackage examples {};
    })
  ];
}


