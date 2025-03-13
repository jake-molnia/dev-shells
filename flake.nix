{
  description = "Collection of Nix flake templates for different development environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    {
      # Define templates that can be used with `nix flake init -t`
      templates = {
        # Standard Python development environment
        python = {
          path = ./languages/python;
          description = "Standard Python development environment with comprehensive tooling";
        };

        # Python with DevContainer support
        python-devcontainer = {
          path = ./languages/python/devcontainer;
          description = "Python development environment with DevContainer support";
        };

        # Default template points to standard Python
        default = self.templates.python;
      };
    };
}
