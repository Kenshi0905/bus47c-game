# Bus 47C

A short first-person low-poly horror game about a firewatcher's ride home to Loomesville.

## Play prototype 0.2.0

On this development PC, double-click **Start Game.cmd**. To edit, double-click **Open Editor.cmd**. On a fresh Windows checkout, run `powershell -ExecutionPolicy Bypass -File tools/setup.ps1` first to download the pinned official Godot runtime and import assets. The runtime is intentionally not committed.

WASD moves, mouse looks, E inspects, Shift walks faster, Escape pauses. Read the bench note, watch the bus approach from down the road, then physically walk up the steps and through its open doors. Inspect the empty driver's seat and the small dashboard clock. The bus drives to Mill Road and Old Quarry, with seated passengers and figures visible outside. The chapter ends at the deer collision. Expect roughly 5–8 minutes on a first playthrough.

The redesigned title/pause menus offer settings for volume, sensitivity and field of view, plus checkpoint restart. Important audio events have captions. Saves stay local and are excluded from Git. Test runs use a separate save filename. Door leaves rotate on hinges, and collision opens only when the doorway is clear. A smooth collision ramp under the visible steps allows boarding without jumping or teleportation. The bus carries the player along a fixed road; passing scenery is no longer moved independently of the bus.

Forest exploration/pursuit, hunger, town and branching endings are not implemented yet. Characters have editable static seated meshes; skeletal animation and facial transitions remain future work. This milestone has been tested on Windows; Linux CI is a headless logic/physics check, not a graphical release certification. Browser and mobile exports come later.

## Checks

Run `powershell -ExecutionPolicy Bypass -File tools/test.ps1`. Tests cover ordered progression, repeated interactions, timers, corrupt checkpoint validation, actual interaction range/aim, scene assets, boarding and completion. GitHub Actions runs the corresponding import and smoke tests on pushes and pull requests.

Geometry and synthesized ambience are original project assets. Footsteps are edited from the two YouTube clips supplied by the user; see [audio sources](docs/audio-sources.md) for attribution and the unresolved public-release licence status. Godot is MIT-licensed: https://godotengine.org/license/ . Include engine and third-party notices when distributing exported builds.

## Development

Godot 4.7.2 standard edition, GDScript, Compatibility renderer. Open `game/project.godot` in Godot. Original editable character sources are in `game/assets/characters`.

## Version history

Every finished development milestone is committed and pushed. Tested playable milestones receive annotated version tags. Use a separate checkout to inspect an old version without discarding current work: `git worktree add ../bus47c-v0.1.0 v0.1.0`.

Use `git revert <commit>` on a new branch to undo a change while preserving history. Never force-push the main branch. Run the smoke tests before tagging a playable build.

The surrounding folder contains unrelated media; it is deliberately excluded from this repository.
