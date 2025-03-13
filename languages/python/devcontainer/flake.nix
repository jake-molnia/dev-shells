{
  description = "Python development environment with DevContainer support";

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
        description = "Python env template with dev container";
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
        python = pkgs.python312;

        # Project name and version
        pname = "CHANGE-ME";
        version = "0.0.0";

        # Python packages (dependencies)
        pythonPackages = with python.pkgs; [
          # Development tools
          pip
          uv
          setuptools
          wheel

          # Testing frameworks
          pytest
          pytest-cov
          pytest-xdist

          # Code quality tools
          black
          isort
          ruff
          mypy

          # Documentation
          sphinx

          # Debugging
          ipython
          ipdb

          # OPTIONAL: Common libraries (uncomment as needed)
          # numpy
          # pandas
          # matplotlib
        ];

        # Development shell script helpers
        shellScripts = {
          # Test runner with common flags
          pytest-run = pkgs.writeShellScriptBin "pytest-run" ''
            pytest -xvs "$@"
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

          # Create uv requirements files from environment
          uv-requirements = pkgs.writeShellScriptBin "uv-requirements" ''
            uv pip freeze > requirements.txt
            echo "Generated requirements.txt"
          '';

          # Create virtual environment using uv
          uv-venv = pkgs.writeShellScriptBin "uv-venv" ''
            uv venv
            echo "Created virtual environment in .venv/"
            echo "Activate with: source .venv/bin/activate"
          '';

          # Initialize project structure
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

          # Create DevContainer configuration
          create-devcontainer = pkgs.writeShellScriptBin "create-devcontainer" ''
            # Create a .devcontainer directory with devcontainer.json
            if [ ! -d ".devcontainer" ]; then
              mkdir -p .devcontainer
              
              # Create devcontainer.json
              cat > .devcontainer/devcontainer.json << EOF
            {
              "name": "${pname}",
              "image": "mcr.microsoft.com/devcontainers/python:3.11",
              "features": {
                "ghcr.io/devcontainers/features/node:1": {}
              },
              "postCreateCommand": "pip install -r requirements.txt || pip install pytest black isort ruff mypy",
              "customizations": {
                "vscode": {
                  "extensions": [
                    "ms-python.python",
                    "ms-python.vscode-pylance",
                    "ms-python.black-formatter",
                    "charliermarsh.ruff",
                    "matangover.mypy",
                    "littlefoxteam.vscode-python-test-adapter",
                    "eamodio.gitlens",
                    "njpwerner.autodocstring"
                  ],
                  "settings": {
                    "python.formatting.provider": "black",
                    "editor.formatOnSave": true,
                    "python.linting.enabled": true,
                    "python.linting.mypyEnabled": true,
                    "python.linting.ruffEnabled": true,
                    "files.exclude": {
                      "**/__pycache__": true,
                      "**/.pytest_cache": true,
                      "**/*.pyc": true
                    }
                  }
                }
              }
            }
            EOF
              
              # Create a Dockerfile (optional - for additional customization)
              cat > .devcontainer/Dockerfile << EOF
            FROM mcr.microsoft.com/devcontainers/python:3.11
            
            # Install additional system packages if needed
            # RUN apt-get update && apt-get install -y additional-package
            
            # Set up Python environment
            WORKDIR /workspaces/${pname}
            
            # Install Python dependencies
            COPY requirements.txt* .
            RUN if [ -f "requirements.txt" ]; then pip install -r requirements.txt; else pip install pytest black isort ruff mypy; fi
            
            # Install development tools
            RUN pip install ipython ipdb
            EOF
              
              # Create a docker-compose.yml (optional)
              cat > .devcontainer/docker-compose.yml << EOF
            version: '3'
            services:
              app:
                build: 
                  context: ..
                  dockerfile: .devcontainer/Dockerfile
                volumes:
                  - ..:/workspaces/${pname}:cached
                command: sleep infinity
            EOF
              
              # Create a devcontainer.Dockerfile
              cat > .devcontainer/devcontainer.Dockerfile << EOF
            FROM mcr.microsoft.com/devcontainers/python:3.11
            
            # Install additional packages
            RUN apt-get update && apt-get install -y \\
                git \\
                make \\
                curl \\
                wget
            
            # Install pip tools wanted (uv or poetru)
            RUN pip install uv

            # Install Python tools globally
            RUN pip install black isort ruff mypy pytest
            EOF
              
              echo "DevContainer configuration created in .devcontainer/"
            else
              echo "DevContainer configuration already exists."
            fi
          '';

          # Script to launch VSCode with DevContainer
          launch-devcontainer = pkgs.writeShellScriptBin "launch-devcontainer" ''
            # First, ensure the project is initialized
            init-project
            
            # Create DevContainer configuration
            create-devcontainer
            
            # Generate requirements file if it doesn't exist
            if [ ! -f "requirements.txt" ]; then
              echo "Generating requirements.txt..."
              uv-requirements
            fi
            
            # Check if VS Code is installed
            if command -v code > /dev/null; then
              echo "Launching VS Code..."
              # First open the folder normally
              code .
              echo "To use the DevContainer, click the 'Reopen in Container' button in VS Code"
              echo "Or use the 'Remote-Containers: Reopen in Container' command from the command palette"
            else
              echo "VS Code not found. Please install VS Code or manually open this folder."
              echo "Then use the 'Remote-Containers: Reopen in Container' command."
            fi
          '';
        };

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          name = "${pname}";

          # Packages available in the development shell
          packages = with pkgs; [
            # Core Nix tools
            nixpkgs-fmt

            # Python packages
            python
            pythonPackages

            # Docker for DevContainer
            docker
            docker-compose

            # Shell scripts defined above
            (builtins.attrValues shellScripts)
          ];

          # Set up the shell environment
          shellHook = ''
            # Welcome message
            echo "Welcome to the ${pname} DevContainer environment!"
            echo "Python version: $(python --version)"
            echo ""
            echo "Available commands:"
            echo "  create-devcontainer  - Create DevContainer configuration files"
            echo "  launch-devcontainer  - Set up project and launch VS Code"
            echo "  pytest-run           - Run pytest with sensible defaults"
            echo "  format-code          - Format code with black, isort, and ruff"
            echo "  init-project         - Initialize a basic project structure"
            echo "  uv-requirements      - Generate requirements.txt from current env"
            echo "  uv-venv              - Create a virtual environment using uv"
            echo ""
            
            # Create convenient aliases
            alias test="pytest -xvs"
            alias lint="ruff check ."
            alias format="format-code"
            
            # Check if project is already initialized
            if [ ! -f "pyproject.toml" ] && [ ! -d "src" ]; then
              echo "This appears to be an empty project directory."
              echo "Initializing project structure..."
              init-project
            fi
            
            # Check if Docker is running
            if ! docker info > /dev/null 2>&1; then
              echo "⚠️  Docker is not running. DevContainer functionality requires Docker."
              echo "   Please start Docker and then run 'create-devcontainer' to set up DevContainer files."
            else
              # Ask user if they want to set up DevContainer
              read -p "Would you like to set up DevContainer configuration now? (y/n) " answer
              if [[ "$answer" =~ ^[Yy] ]]; then
                create-devcontainer
                echo ""
                read -p "Would you like to launch VS Code now? (y/n) " answer2
                if [[ "$answer2" =~ ^[Yy] ]]; then
                  launch-devcontainer
                fi
              else
                echo "You can set up DevContainer later with 'create-devcontainer'"
              fi
            fi
            
            # PYTHONPATH setup for development
            export PYTHONPATH="$PWD:$PYTHONPATH"
          '';
        };

      }
    );
}
