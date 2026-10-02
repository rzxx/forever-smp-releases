# Server templates

These are generic templates, not the live server's configuration. Read Minecraft/Fabric versions from `../pack.toml` and install a matching Fabric server launcher with Java 25 or newer. Accept the Minecraft EULA yourself.

Build the MRPack, then run `../scripts/build-server-upload.ps1` from this repository to stage the pinned server-side mods and templates. The ZIP is a deployment input: the build never uploads or starts a server. Alternatively, use `scripts/install-files.ps1 -Side server -GameDirectory <empty-test-directory>` from the repository root.

Start the Fabric runtime once in a separate test directory, stop it, and review `server.properties.recommended` and `config` templates before applying them. Choose host ports, authentication policy and the safe login spawn yourself. Keep generated databases, worlds, live settings and secrets outside this checkout. Back up the live server before any deployment; test a restore independently.

- Distant Horizons is required server-side and optional client-side. Its template serves LODs for already generated terrain; do not enable pregeneration as part of deployment.
- EasyAuth templates use offline UUIDs, disable IP login sessions and require registration/login. Set a registration secret through the server console; never commit it. Review this policy for your own server and test name impersonation, reconnects and shared-IP players before opening access.
- `add-offline-player.ps1` can add an exact offline player name to a downloaded test whitelist. Preserve existing UUIDs and world progress. It does not modify a remote host.
- Simple Voice Chat needs a reachable UDP port. Test speaking with two authenticated players and verify unauthenticated players cannot listen or transmit. Its EasyAuth packet exception needs this separate check.
- Keep BlueMap private or behind authenticated access. Review generated `core.conf`, including its resource-download terms, before enabling downloads. Do not expose map ports by default.
- Apply `world-setup.commands.txt` and `launch-permissions.commands.txt` only after reviewing them for the target server.

For a local runtime already installed in a disposable directory:

```powershell
./scripts/run-server.ps1 -ServerDirectory <test-directory> -Java <java.exe>
```

Confirm the server reaches `Done`, then test a clean client import, optional DH synchronization, recipe UI, authentication, voice and persistence through restart. Generic template tests do not validate live deployment overrides. Keep operational notes and host-specific configuration in the private workspace.
