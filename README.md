# Bus 47C

A short first-person low-poly horror game about a firewatcher's ride home to Loomesville.

## Play prototype 0.1.0

On this development PC, double-click **Start Game.cmd**. To edit, double-click **Open Editor.cmd**. On a fresh Windows checkout, run `powershell -ExecutionPolicy Bypass -File tools/setup.ps1` first to download the pinned official Godot runtime and import assets. The runtime is intentionally not committed.

WASD moves, mouse looks, E inspects or boards, Shift walks faster, Escape pauses. Read the bench note, wait for the bus, approach its front door, inspect the empty driver's seat and the clock, then find the passenger at the rear. Expect a short 3–5 minute prototype. An end screen makes the boundary explicit.

The pause menu provides volume, mouse sensitivity, restart checkpoint and quit. No camera bob or flashing effects. Important audio events have captions. Saves stay local and are excluded from Git. Test runs use a separate save filename. Boarding currently uses an interaction transition into the bus; it is not a physically climbable doorway yet.

The deer, forest pursuit, hunger, town and branching endings are planned but not implemented. Characters are static editable models. This milestone has been tested on Windows; the CI configuration checks Linux headless logic but is not a claim of a tested Linux graphical release. Browser and mobile exports come later.

## Checks

Run `powershell -ExecutionPolicy Bypass -File tools/test.ps1`. Tests cover ordered progression, repeated interactions, timers, corrupt checkpoint validation, actual interaction range/aim, scene assets, boarding and completion. GitHub Actions runs the corresponding import and smoke tests on pushes and pull requests.

All geometry and synthesized prototype audio are original project assets. Godot is MIT-licensed: https://godotengine.org/license/ . Include engine and third-party notices when distributing exported builds.

## Development

Godot 4.7.2 standard edition, GDScript, Compatibility renderer. Open `game/project.godot` in Godot. Original editable character sources are in `game/assets/characters`.

## Version history

Every finished development milestone is committed and pushed. Tested playable milestones receive annotated version tags. Use a separate checkout to inspect an old version without discarding current work: `git worktree add ../bus47c-v0.1.0 v0.1.0`.

Use `git revert <commit>` on a new branch to undo a change while preserving history. Never force-push the main branch. Run the smoke tests before tagging a playable build.

The surrounding folder contains unrelated media; it is deliberately excluded from this repository.
