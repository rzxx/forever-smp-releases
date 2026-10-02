# Pack releases

Pack releases are independent of installer releases. Version comes from `pack.toml`; notes, reviewed presets and optional features come from `release.toml`. The existing channel is `rzxx/forever-smp-releases`.

In the private local workspace, update the pack pins/presets, bump the pack version and update both languages of notes, then run from the parent directory:

```powershell
./scripts/release.ps1 pack
```

That command runs the pack export checks on your PC, builds the recipe CLI, validates the recipe, signs it with the existing local pack key and verifies its signature. Output is `modpack/dist/releases/<pack-version>`. It does not build the desktop installer, run its UI tests or release it.

Add `-Upload` to build locally and upload a draft to the pack repo; add `-Publish` to build locally and publish it as latest. Upload requires clean, committed source already pushed to this repo, including refreshed pack hashes. Bilingual notes and the three asset filenames are supplied automatically. Published versions are refused; a failed draft upload can be retried.

For an unsigned build from this public checkout, run `./scripts/build-pack-release.ps1`; the recipe CLI comes from the installer repo via its sibling checkout or `-InstallerRoot` / `-ReleaseTool`. This compiles only the CLI, not the desktop app. Signing/upload automation stays in the private workspace. No GitHub Actions runner is used for checks or builds.

The release assets are `Forever-SMP-<version>.mrpack`, `release.json` and `release.signed.json`. Preserve the stable signed feed filename, existing feature IDs, signing key and feed URL. Link the independent installer downloads instead of embedding a rebuilt installer in every pack release.

Import the candidate into a clean launcher instance and test the changed mods in game before publishing; an export check is not a gameplay test. Server changes need their own deployment/backup checks. Server upload ZIPs, keys, addresses, invitations and live data never enter the client release.
