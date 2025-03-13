{
  description = "Python development environment with comprehensive tooling";

  # ============================================================================
  # INPUTS
  # External dependencies/sources for our flake
  # ============================================================================
  inputs = {
    # Nixpkgs - Main package source
    # -------------------------------------------------------------------------
    # Pinned to a specific commit/tag for reproducibility
    # Consider updating periodically for security patches
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Flake-utils - Simplifies flake output definitions for multiple systems
    # -------------------------------------------------------------------------
    # Provides useful utilities for working with flakes across platforms
    flake-utils.url = "github:numtide/flake-utils";
    
    # Nix-filter - Better filtering for Nix
    # -------------------------------------------------------------------------
    # Helps filter source files in a more convenient way
    # nix-filter - Better filtering for Nix
    # -------------------------------------------------------------------------
    # Helps filter source files in a more convenient way
    nix-filter.url = "github:numtide/nix-filter";
    
    # Poetry2nix - Helps work with Poetry Python projects
    # -------------------------------------------------------------------------
    # OPTIONAL: Uncomment if using Poetry for Python dependency management
    # poetry2nix = {
    #   url = "github:nix-community/poetry2nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    
    # Devenv - Development environments made easy
    # -------------------------------------------------------------------------
    # OPTIONAL: Uncomment if you want to use devenv for more ergonomic environments
    # devenv = {
    #   url = "github:cachix/devenv";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    
    # Devcontainer - VSCode devcontainer support
    # -------------------------------------------------------------------------
    # OPTIONAL: Uncomment for DevContainer support
    # devcontainer = {
    #   url = "github:cameronfyfe/devcontainer-flake";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  # ============================================================================
  # OUTPUTS
  # What this flake produces (packages, devShells, etc.)
  # ============================================================================
  outputs = { self, nixpkgs, flake-utils, nix-filter, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # System-specific package set
        pkgs = import nixpkgs {
          inherit system;
          # Enable non-free packages if needed
          # config.allowUnfree = true;
          
          # Add overlays if needed
          # overlays = [ ... ];
        };
        
        # Python version selection
        # -------------------------------------------------------------------------
        # Choose your Python version by changing this line
        # Common options: python3, python39, python310, python311, python312
        python = pkgs.python311;
        
        # Project name and version
        # -------------------------------------------------------------------------
        # Replace with your actual project name and version
        pname = "my-python-project";
        version = "0.1.0";
        
        # Python packages (dependencies)
        # -------------------------------------------------------------------------
        # Using uv package manager (modern alternative to pip)
        # These packages will be available in the development shell
        pythonPackages = with python.pkgs; [
          # Development tools
          pip             # Package installer
          uv              # Modern Python package manager and resolver
          setuptools      # Build system
          wheel          # Binary distribution format
          
          # Testing frameworks
          pytest          # Testing framework
          pytest-cov      # Coverage reporting
          pytest-xdist    # Parallel testing
          hypothesis      # Property-based testing
          
          # Code quality tools
          black           # Code formatter
          isort           # Import sorter
          ruff            # Fast linter (alternative to flake8/pylint)
          mypy            # Static type checking
          
          # Documentation
          sphinx          # Documentation generator
          
          # Debugging
          ipython         # Interactive shell
          ipdb            # Debugger
          
          # OPTIONAL: Common libraries (uncomment as needed)
          # numpy
          # pandas
          # matplotlib
          # requests
          # fastapi
          # sqlalchemy
          # pydantic
        ];
        
        # OPTIONAL: Poetry environment setup
        # -------------------------------------------------------------------------
        # Uncomment this block if you're using Poetry for dependency management
        
        # poetryEnv = inputs.poetry2nix.lib.mkPoetryEnv {
        #   inherit python;
        #   projectDir = ./.;
        #   overrides = inputs.poetry2nix.overrides.default;
        #   editablePackageSources = {
        #     ${pname} = ./.;
        #   };
        # };
        
        # Local Python module setup
        # -------------------------------------------------------------------------
        # This creates a package from your local Python code
        # OPTIONAL: Customize this section to fit your project structure
        pythonModule = python.pkgs.buildPythonPackage {
          inherit pname version;
          src = nix-filter.lib.filter {
            root = ./.;
            include = [
              # Include Python files and package info
              "setup.py"
              "setup.cfg"
              "pyproject.toml"
              (nix-filter.lib.matchExt "py")
              # Include your actual module directories
              # Example: "src" "my_module" "tests"
            ];
          };
          buildInputs = [ ];
          propagatedBuildInputs = with python.pkgs; [
            # Runtime dependencies (imported by your code)
            # Add packages your code needs at runtime
          ];
          nativeCheckInputs = with python.pkgs; [
            pytest
            pytest-cov
          ];
          checkPhase = ''
            runHook preCheck
            pytest
            runHook postCheck
          '';
          # Skip tests during build (change to false when ready for testing)
          doCheck = false;
        };
        
        # Development shell script helpers
        # -------------------------------------------------------------------------
        # Shell scripts for common development tasks
        shellScripts = {
          # Test runner with common flags
          pytest-run = pkgs.writeShellScriptBin "pytest-run" ''
            pytest -xvs "$@"
          '';
          
          # Coverage report generator
          coverage-report = pkgs.writeShellScriptBin "coverage-report" ''
            pytest --cov=./ --cov-report=term --cov-report=html "$@"
            echo "Coverage report generated in htmlcov/"
          '';
          
          # Code formatting
          format-code = pkgs.writeShellScriptBin "format-code" ''
            echo "Formatting imports with isort..."
            isort .
            echo "Formatting code with black..."
            black .
            echo "Checking code with ruff..."
            ruff check --fix .
          '';
          
          # Type checking
          type-check = pkgs.writeShellScriptBin "type-check" ''
            mypy .
          '';
          
          # Initialize empty project
          init-project = pkgs.writeShellScriptBin "init-project" ''
            if [ ! -f "pyproject.toml" ]; then
              echo "Creating pyproject.toml..."
              cat > pyproject.toml << EOF
            [build-system]
            requires = ["setuptools>=42.0", "wheel"]
            build-backend = "setuptools.build_meta"
            
            [tool.pytest.ini_options]
            testpaths = ["tests"]
            
            [tool.black]
            line-length = 88
            
            [tool.isort]
            profile = "black"
            
            [tool.mypy]
            python_version = "3.11"
            warn_return_any = true
            warn_unused_configs = true
            disallow_untyped_defs = true
            disallow_incomplete_defs = true
            
            [tool.ruff]
            line-length = 88
            target-version = "py311"
            select = ["E", "F", "B", "I"]
            EOF
            fi
            
            if [ ! -d "src" ]; then
              echo "Creating project structure..."
              mkdir -p src/${pname}
              mkdir -p tests
              
              # Create a simple module
              cat > src/${pname}/__init__.py << EOF
            """${pname} - Your project description here."""
            
            __version__ = "${version}"
            EOF
              
              # Create a simple test
              cat > tests/__init__.py << EOF
            """Tests for ${pname}."""
            EOF
              
              cat > tests/test_basic.py << EOF
            """Basic tests for ${pname}."""
            
            import pytest
            from ${pname} import __version__
            
            def test_version():
                """Test version is set correctly."""
                assert __version__ == "${version}"
            EOF
            fi
            
            echo "Project initialized!"
          '';
          
          # Create uv requirements files from environment
          uv-requirements = pkgs.writeShellScriptBin "uv-requirements" ''
            uv pip freeze > requirements.txt
            echo "Generated requirements.txt"
            
            # Generate requirements-dev.txt if needed
            # uv pip freeze --exclude-editable > requirements-dev.txt
            # echo "Generated requirements-dev.txt"
          '';
          
          # Create virtual environment using uv
          uv-venv = pkgs.writeShellScriptBin "uv-venv" ''
            uv venv
            echo "Created virtual environment in .venv/"
            echo "Activate with: source .venv/bin/activate"
          '';
        };
        
        # OPTIONAL: DevContainer configuration
        # -------------------------------------------------------------------------
        # Uncomment this section to enable DevContainer support
        
        # devcontainerConfig = {
        #   name = "${pname}-devcontainer";
        #   image = {
        #     # Build container with packages installed
        #     packageNames = [
        #       # System tools
        #       "git"
        #       "gnumake"
        #       # Dev tools
        #       python.name
        #     ];
        #     # Extra packages only available in devShell (not globally in container)
        #     shellPackageNames = builtins.map (p: p.name) pythonPackages;
        #   };
        #   settings = {
        #     # VS Code extensions to include
        #     extensions = [
        #       "ms-python.python"
        #       "ms-python.vscode-pylance"
        #       "matangover.mypy"
        #       "charliermarsh.ruff"
        #     ];
        #     # Default VS Code settings
        #     settings = {
        #       "python.defaultInterpreterPath" = "/usr/bin/python";
        #       "python.formatting.provider" = "black";
        #       "editor.formatOnSave" = true;
        #       "editor.codeActionsOnSave" = {
        #         "source.organizeImports" = true
        #       };
        #     };
        #   };
        # };
        
      in {
        # Development shell configurations
        # -------------------------------------------------------------------------
        devShells.default = pkgs.mkShell {
          name = "${pname}-dev-shell";
          
          # Packages available in the development shell
          packages = with pkgs; [
            # Core Nix tools
            nixpkgs-fmt     # Nix code formatter
            
            # Python packages from above
            python
            pythonPackages
            
            # Shell scripts defined above
            (builtins.attrValues shellScripts)
          ];
          
          # Environment variables and shell setup
          shellHook = ''
            # Welcome message
            echo "Welcome to the ${pname} development environment!"
            echo "Python version: $(python --version)"
            echo ""
            echo "Available commands:"
            echo "  pytest-run      - Run pytest with sensible defaults"
            echo "  coverage-report - Generate test coverage report"
            echo "  format-code     - Format code with black, isort, and ruff"
            echo "  type-check      - Run type checking with mypy"
            echo "  init-project    - Initialize a basic project structure"
            echo "  uv-requirements - Generate requirements.txt from current env"
            echo "  uv-venv         - Create a virtual environment using uv"
            echo ""
            
            # Create convenient aliases
            alias test="pytest -xvs"
            alias lint="ruff check ."
            alias format="format-code"
            
            # Create .venv directory if it doesn't exist
            if [ ! -d ".venv" ]; then
              echo "No virtual environment found, you can create one with 'uv-venv'"
            fi
            
            # Initialize project if empty directory
            if [ ! -f "pyproject.toml" ] && [ ! -d "src" ]; then
              echo "This appears to be an empty project directory."
              echo "You can initialize a basic project with 'init-project'"
            fi
            
            # PYTHONPATH setup for development
            export PYTHONPATH="$PWD:$PYTHONPATH"
            
            # Use uv as pip replacement
            export VIRTUALENV_PYTHON=$(which python)
            
            # Add any additional environment setup below
            # ----------------------------------------------
            
          '';
          
          # We'll set up aliases via the shellHook instead
        };
        
        # OPTIONAL: Enable packages to be built
        # -------------------------------------------------------------------------
        # Uncomment to make your Python module available as a package
        # packages.default = pythonModule;
        
        # OPTIONAL: DevContainer configuration
        # -------------------------------------------------------------------------
        # Uncomment to enable DevContainer support
        # packages.devcontainer = inputs.devcontainer.lib.${system}.mkDevContainer devcontainerConfig;
        
        # Default package is the Python module
        packages.default = pythonModule;
        
        # Additional useful outputs
        # -------------------------------------------------------------------------
        apps.default = {
          type = "app";
          program = "${python}/bin/python";
        };
        
        # OPTIONAL: Templates
        # -------------------------------------------------------------------------
        # Define templates for initializing new projects
        # These can be used with `nix flake init -t <flake>#{template-name}`
        templates = {
          default = {
            path = ./.;
            description = "Python development environment with comprehensive tooling";
          };
        };
      }
    );
}
