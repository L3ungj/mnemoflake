# Mnemosyne Nix Flake

Nix packaging for [Mnemosyne](https://github.com/mnemosyne-oss/mnemosyne) — a zero-dependency AI memory layer with SQLite-backed storage.

## Packages

| Package | Description | Features |
|---------|-------------|----------|
| `mnemosyne` (default) | Core memory layer | PyYAML only, FTS5 search |
| `mnemosyneWithMcp` | + MCP server | MCP SDK + anyio |
| `mnemosyneWithEmbeddings` | + Vector search | + fastembed, onnxruntime, sqlite-vec |
| `mnemosyneWithSync` | + Sync encryption | + cryptography |
| `mnemosyneAll` | All features | Embeddings + MCP + sync |
| `hermesPlugin` | Hermes Agent provider | Mnemosyne for Hermes Agent |

## Binaries

- `mnemosyne` — main CLI (store, recall, mcp, export, import)
- `mnemosyne-install` — install for agent frameworks
- `mnemosyne-uninstall` — remove agent integrations
- `mnemosyne-browser` — memory browser UI
- `mnemosyne-auto-save` — OpenWebUI integration

## NixOS Configuration

Add to your flake input:

```nix
mnemoflake = {
  url = "github:L3ungj/mnemoflake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then add to system packages, or home.packages:

```nix
environment.systemPackages = [
  inputs.mnemoflake.packages.x86_64-linux.mnemosyneAll
];
```
## Integration with Hermes

Wrap hermes to add Mnemosyne to PYTHONPATH:
```nix
hermes-mnemo = let
  llmAgentsPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  mnemoPkgs = inputs.mnemoflake.packages.${pkgs.stdenv.hostPlatform.system};
in pkgs.writeShellApplication {
  name = "hermes";
  runtimeInputs = [llmAgentsPkgs.hermes-agent]; # or your hermes-agent package
  text = ''
    export PYTHONPATH=${lib.concatStringsSep ":" [
      "${mnemoPkgs.mnemosyneAll}/lib/python3.14/site-packages"
      "${mnemoPkgs.mnemosyneHermes}/lib/python3.14/site-packages"
    ]}

    exec hermes "$@"
  '';
};
```

Symlink the plugin into the hermes plugins directory:
```nix
home.file.".hermes/plugins/mnemosyne" = {
  source = config.lib.file.mkOutOfStoreSymlink "${mnemoPkgs.mnemosyneHermes}/lib/python3.14/site-packages/mnemosyne_hermes";
  recursive = true;
};
```

Then run:
```bash
hermes config set memory.provider mnemosyne
```