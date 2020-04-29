{ fpkgs ? ./fix/nixpkgs.nix 
, jreduce ? import ./fix/jreduce.nix
, javaq   ? import ./fix/javaq.nix
, examples ? ../examples
}:
import fpkgs { 
  overlays = [ 
    (import ./overlay.nix)
    (self: super: {
      jreduce = import jreduce { pkgs = super; };
      javaq   = import javaq   { pkgs = super; };
      examples = super.callPackage examples {};
    })
  ]; 
}


