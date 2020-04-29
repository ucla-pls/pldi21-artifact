{ haskell, artifact }: 
with haskell.packages.ghc844.override { 
  overrides = with haskell.lib; self: super: { 
    Diff = dontCheck super.Diff;
    jvmhs = dontCheck (self.callPackage ./jvmhs.nix { }); 
    jvm-binary = dontCheck (self.callPackage ./jvm-binary.nix {}); 
    reduce-util = self.callPackage ./reduce-util.nix {};
    reduce = self.callPackage ./reduce.nix {};
    megaparsec = dontCheck (self.callPackage ./megaparsec.nix {});
    # quickcheck = self.callPackage ./quickcheck.nix {};
    artifact = artifact;
  };
};
callPackage ./jreduce.nix {}


