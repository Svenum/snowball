{
  description = "Snowball lib test";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    snowball.url = "path:../";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.snowball.lib.mkFlake {
      inherit inputs;
      root = ./.;

      example.modules = with inputs; [ disko.nixosModules.disko ];
    };
}
