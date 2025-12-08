{
  description = "Home Manager for Pi (Arch)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";      
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, ... }:
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
          inherit self stylix repoPath;
          inputs = { inherit self stylix nixpkgs home-manager; };
        };
      };
  };
}
