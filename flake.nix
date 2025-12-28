{
  description = "Home Manager for Angel-Arch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

   dms = {
     url = "github:AvengeMedia/DankMaterialShell";
     inputs.nixpkgs.follows = "nixpkgs";
   };

    stylix = {
      url = "github:nix-community/stylix";      
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, stylix, dms, ... }:
  let
    # system = builtins.currentSystem or "aarch64-linux";
    system = builtins.currentSystem or "x86_64-linux";    
    pkgs = nixpkgs.legacyPackages.${system};
    repoPath = rel: "${self}/${rel}";
  in {
    homeConfigurations.username =
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          stylix.homeManagerModules.stylix
          ./home/home.nix
        ];

        extraSpecialArgs = {
          inherit  repoPath inputs;
          inherit  (inputs) self;
        };
      };
  };
}
