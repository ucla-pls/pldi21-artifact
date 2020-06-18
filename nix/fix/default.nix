self:
{
  dirtree     = import ./dirtree.nix;
  javaq       = import ./javaq.nix;
  jreduce     = import ./jreduce.nix;
  jvm-binary  = import ./jvm-binary.nix;
  jvmhs       = import ./jvmhs.nix;

  hspec-hedgehog = import ./hspec-hedgehog.nix;

  reduce-src  = import ./reduce.nix;
  reduce      = "${self.reduce-src}/reduce";
  reduce-util = "${self.reduce-src}/reduce-util";
}
