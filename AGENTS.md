# Working on the pack

Work from this directory with ordinary Git commands. This repo owns the packwiz source, client presets and generic server templates; the recipe CLI comes from the sibling `../installer` repository.

- Check/export: `./scripts/test.ps1` refreshes hashes, exports the MRPack and checks its contents, version and mod sides. Commit refreshed pack hashes.
- Playtest: import that MRPack into a separate launcher instance. Export checks do not prove the game boots or mods work together.
- Package: `./scripts/build-pack-release.ps1` also exports the installer recipe. Owner signing/upload uses `../scripts/release.ps1 pack`; see [release steps](docs/releases.md).

Run locally; do not add automatic GitHub Actions. Pack version is in `pack.toml`, notes in `release.toml`; pack releases are independent of installer releases. Keep optional feature IDs stable.

Keep live host settings, addresses, credentials, invitations and player/world data outside this repo. Server templates use placeholders; `build-server-upload.ps1` only stages files and never deploys.
