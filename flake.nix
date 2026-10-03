{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      naersk,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        naersk-lib = pkgs.callPackage naersk { };
      in
      {
        packages.default = naersk-lib.buildPackage {
          src = ./.;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            self.formatter.${system}
            cargo
            rustc
            clippy
            rustfmt
            rust-analyzer
            nixd
            statix
            deadnix
          ];
          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
        };

        formatter = pkgs.nixfmt;
      }
    );
}