# Forever SMP

Pinned Minecraft modpack source and the existing signed pack release channel. Minecraft/Fabric versions are in `pack.toml`; the current pack requires Java 25 or newer.

[Download the MRPack](https://github.com/rzxx/forever-smp-releases/releases/latest) · [Installer source and downloads](https://github.com/rzxx/forever-smp-installer)

Import the `.mrpack` into Prism or another compatible launcher, or use the Windows installer. Your launcher manages Minecraft, Fabric, Java and accounts. The owner supplies server access privately.

Импортируйте `.mrpack` в Prism или используйте Windows-приложение. Minecraft, Fabric, Java и учётные записи настраивает лаунчер. Доступ на сервер получите лично у владельца.

## Iterate on the pack

Install PowerShell 7 and [packwiz](https://github.com/packwiz/packwiz). Edit the pinned `mods/*.pw.toml` recipes, maintained `config` presets or `pack.toml`, then:

```powershell
./scripts/build.ps1
```

This refreshes `index.toml`/pack hashes and exports `dist/Forever-SMP-<pack-version>.mrpack`. Import that exact archive into a separate launcher instance. Check startup and the changed mods in game; a successful export is not a gameplay test. Client/server sides and optional choices come from the recipes. The exporter makes Distant Horizons optional on clients and required on the server.

To test the pack through the current installer source, use `../installer/scripts/dev.ps1 -BuildPack`. The installer opens an isolated profile and game folder with this pack's local recipe.

```powershell
./scripts/build-pack-release.ps1   # MRPack + validated recipe in dist/releases/<version>
./scripts/test.ps1                 # export, public-file allowlist, version and DH sides
./scripts/build-server-upload.ps1  # separate server staging ZIP, no deployment
```

The recipe command needs Rust and the installer repo's `forever-release` CLI. By default it builds that CLI from a sibling `../installer` checkout. Pass `-InstallerRoot <checkout>` or `-ReleaseTool <exe>` to use another location. A plain MRPack build needs no installer checkout or Rust.

[Release steps](docs/releases.md) cover signing and publishing to this same repository. Pack changes require no installer release. Bump `pack.toml` and update `release.toml` notes for a pack release; keep optional feature IDs stable so saved player choices survive.

## Contents

| Path | Purpose |
| --- | --- |
| `pack.toml`, `index.toml`, `mods` | Versioned packwiz manifest and pinned mods |
| `config` | Reviewed client presets listed in `release.toml` |
| `release.toml` | Bilingual release notes and installer optional-feature descriptions |
| `server` | Generic server templates and [setup reference](server/README.md) |
| `scripts` | Pack export, recipe export and server staging |

`dist` is generated local output. Server worlds, account databases, whitelists, live host settings, addresses, credentials and invitations stay outside this repo. Third-party mod files are downloaded from their pinned upstream URLs and retain their own licenses.
