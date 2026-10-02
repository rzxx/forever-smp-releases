# Pack releases

The existing channel is `rzxx/forever-smp-releases`. Version comes from `pack.toml`; notes, reviewed presets and optional features come from `release.toml`.

1. Change pins/presets, bump the pack version and update both languages of notes.
2. Run `./scripts/build-pack-release.ps1`. This exports the MRPack and validates the client recipe using the CLI owned by the installer repository. Only the CLI is built; no desktop installer is rebuilt.
3. Import the exported pack into a clean launcher instance. Check the affected mods in game; rehearse server changes on a world copy separately.
4. Sign the generated recipe with the existing private pack key:

```powershell
$version = '0.1.13' # use the actual new version
$output = "dist/releases/$version"
../installer/target/release/forever-release.exe sign "$output/release.json" ../.private/release-signing-key.txt "$output/release.signed.json"
```

5. Create a draft release in this repository with exactly `Forever-SMP-<version>.mrpack`, `release.json` and `release.signed.json`. Review/test the candidate before marking it latest.

Preserve the stable filename `release.signed.json`, existing feature IDs, signing key and feed URL. Published releases are immutable. Installer source/release changes are independent; link its downloads instead of embedding a rebuilt installer in every pack release.

`dist/releases` holds unsigned local candidates until the signing step. Keys, server addresses, invitations and deployment notes stay outside this repository. Server upload ZIPs are a separate deployment input; do not attach them to public client releases.
