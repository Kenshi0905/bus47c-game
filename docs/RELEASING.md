# Releases and rollback

[Releases on GitHub](https://github.com/Kenshi0905/bus47c-game/releases) · [Changelog](../CHANGELOG.md)

## Version names

Playable beta tags use `vMAJOR.MINOR.PATCH-beta.NUMBER`, for example `v0.9.0-beta.1`. Use a new patch or beta number for a changed playable build. Documentation-only updates can be ordinary commits without a new game version.

Create annotated tags at the **tested game commit**. A published tag and its assets are permanent rollback points. Keep historical source tags even when they have no packaged build.

## Prepare a release

1. Update the in-game version, project description, export version, packaging version, beta notes and changelog together.
2. Run the [source checks](DEVELOPMENT.md), then export and test the actual Windows package. Review native captures for changed scenes.
3. Commit and push the verified milestone. Confirm the remote commit and its GitHub checks.
4. Create an annotated version tag at that commit and push it. Do not retag an older build.
5. Export from a clean checkout so `BUILD_INFO.txt` identifies the matching revision. Package the executable and data pack with the notices.
6. Verify the ZIP contents and CRC, then create `SHA256SUMS.txt` with the ZIP's SHA-256 hash and exact filename.
7. Create a **draft GitHub release** using the existing tag. Add notes and upload the Windows ZIP and checksum file. Verify the uploaded sizes and digests before publishing.
8. Publish unfinished builds with **Set as a pre-release** enabled. Link the current beta explicitly from the README because it is a prerelease, not a stable release.
9. Verify the release page and assets, then update the README's current-build and previous-build links.

## Release notes

Use a title such as **Bus 47C 0.9.0 Beta 1**. Include a short summary, the Windows ZIP name, extraction instructions, important additions and fixes, actual validation, meaningful beta limitations and the source revision. Keep ending spoilers in a collapsed section where useful.

The repository's release-note configuration groups future pull requests into fixes, gameplay and documentation. Review generated notes before publishing; they do not replace playtest notes.

## Download and verify

Download the **Windows ZIP** under release Assets. GitHub's automatic Source code archives contain the editable project, not the standalone game.

Compare this output with the matching line in `SHA256SUMS.txt`:

```powershell
Get-FileHash .\Bus47C-Beta-0.9.0-Windows.zip -Algorithm SHA256
```

Extract the whole archive. Keep `Bus47C.exe` and `Bus47C.pck` together. Extract different versions into separate folders. Use **New Journey** when testing changed story sequences; checkpoints are stored locally and shared by the game's application identity.

Releases follow the repository's access permissions. Publishing a release here does not change repository visibility.
