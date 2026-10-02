# Working on the pack

This repository owns the pinned packwiz source, client presets and generic server templates. Rust installer source and the recipe tool live in `rzxx/forever-smp-installer`, usually checked out beside this repo as `../installer`.

- After changing `mods`, `config` or pack versions, run `./scripts/build.ps1`. It refreshes packwiz hashes and exports `dist/Forever-SMP-<version>.mrpack`.
- Run `./scripts/test.ps1` to verify the archive contains only reviewed public presets, the expected version and correct DH side requirements. Commit refreshed pack hashes.
- To validate/export the installer recipe too, run `./scripts/build-pack-release.ps1`. Use `-InstallerRoot` or `-ReleaseTool` when the installer checkout is elsewhere.
- Import the current MRPack into a separate launcher instance for gameplay checks. Exporting successfully does not prove the game boots or mods work together.
- `./scripts/build-server-upload.ps1` stages pinned server mods and generic templates. It never reads a live server directory or deploys.
- Pack changes do not require an installer version bump or installer release. Keep optional feature IDs stable so saved choices survive.
- Live host configs, addresses, credentials, invitations, player/account databases and world data belong outside this repository. Server templates must use placeholders.
- Do not add old audits, deployment diaries or alternate client installers. Keep current instructions in README and server/README.
