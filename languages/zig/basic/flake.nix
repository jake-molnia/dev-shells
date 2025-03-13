{
  description = "basic zig flake";

  # ============================================================================
  # INPUTS
  # External dependencies/sources for our flake
  # ============================================================================
  inputs = {
    # Nixpkgs - Main package source
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Flake-utils - Simplifies flake output definitions for multiple systems
    flake-utils.url = "github:numtide/flake-utils";
  };

  # ============================================================================
  # OUTPUTS
  # What this flake produces (packages, devShells, etc.)
  # ============================================================================
  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    # Define top-level template for direct initialization
    {
      templates.default = {
        path = ./.;
        description = "basic zig flake";
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        # System-specific package set
        pkgs = import nixpkgs {
          inherit system;
          # Enable non-free packages if needed
          config.allowUnfree = true;
        };

        # Python version selection
        # Choose your Python version by changing this line
        zig = pkgs.zig_0_13;

        # Project name and version
        pname = "CHANGE-ME";
        version = "0.0.0";

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          name = "${pname}";

          # Packages available in the development shell
          packages = with pkgs; [
            # Core Nix tools
            nixpkgs-fmt

            # Zig language
            zig

          ];

          # Set up the shell environment
          shellHook = ''
            # Welcome message
            echo "Welcome to the ${pname} environment!"
            echo "Python version: $(zig --version)"
            echo ""
            
          '';
        };

      }
    );
}
