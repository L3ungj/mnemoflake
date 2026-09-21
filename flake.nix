{
  description = "Mnemosyne — zero-dependency AI memory layer (SQLite-backed)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python3;
        py = python.pkgs;

        mnemosyneSrc = pkgs.fetchFromGitHub {
          owner = "mnemosyne-oss";
          repo = "mnemosyne";
          rev = "8628fd451df7aa1a4b92868812f300334c911333";
          hash = "sha256-1vPFXPfEaQk2Mc3fGdaheKpszrO8YvnO+nTl4Vn6bf0=";
        };

        commonMeta = with pkgs.lib; {
          homepage = "https://github.com/mnemosyne-oss/mnemosyne";
          changelog = "https://github.com/mnemosyne-oss/mnemosyne/releases";
          license = licenses.mit;
          platforms = platforms.all;
        };

        mnemosyne = py.buildPythonPackage {
          pname = "mnemosyne-memory";
          version = "4.0.0b3";
          src = mnemosyneSrc;
          pyproject = true;
          nativeBuildInputs = [ py.setuptools ];
          propagatedBuildInputs = [ py.pyyaml ];
          meta = commonMeta // {
            description = "The Universal Memory Layer for Any AI Agent";
          };
        };

        withMcp = mnemosyne.overrideAttrs (old: {
          propagatedBuildInputs = old.propagatedBuildInputs ++ [ py.mcp py.anyio ];
          meta = old.meta // {
            description = "The Universal Memory Layer for Any AI Agent with MCP support";
          };
        });

        withEmbeddings = withMcp.overrideAttrs (old: {
          propagatedBuildInputs = old.propagatedBuildInputs ++ [ py.fastembed py.onnxruntime py.sqlite-vec ];
          meta = old.meta // {
            description = "The Universal Memory Layer for Any AI Agent with embeddings support";
          };
        });

        withSync = withEmbeddings.overrideAttrs (old: {
          propagatedBuildInputs = old.propagatedBuildInputs ++ [ py.cryptography ];
          meta = old.meta // {
            description = "The Universal Memory Layer for Any AI Agent with sync support";
          };
        });

        hermes = py.buildPythonPackage {
          pname = "mnemosyne-hermes";
          version = "0.7.3";
          src = mnemosyneSrc;
          sourceRoot = "source/integrations/hermes";
          pyproject = true;
          nativeBuildInputs = [ py.setuptools ];
          propagatedBuildInputs = [ withEmbeddings ];
          meta = commonMeta // {
            description = "Mnemosyne memory provider for Hermes Agent";
          };
        };
      in {
        packages = {
          default = mnemosyne;
          mnemosyne = mnemosyne;
          mnemosyneWithMcp = withMcp;
          mnemosyneWithEmbeddings = withEmbeddings;
          mnemosyneWithSync = withSync;
          mnemosyneAll = withSync;
          mnemosyneHermes = hermes;
        };
      });
}
