# Bus 47C

A short first-person low-poly horror game about a firewatcher's ride home to Loomesville.

## Play prototype 0.4.0

On this development PC, double-click **Start Game.cmd**. To edit, double-click **Open Editor.cmd**. On a fresh Windows checkout, run `powershell -ExecutionPolicy Bypass -File tools/setup.ps1` first to download the pinned official Godot runtime and import assets. The runtime is intentionally not committed.

WASD moves, mouse looks, E inspects or sits, Space stands, Tab opens shift notes, Shift walks faster and Escape pauses. Read the bench note, watch the bus approach, then walk through its open doors. Inspect the empty driver's seat and dashboard clock. You can sit in any empty passenger seat and look around while riding. At Mill Road, inspect the new passenger; at Old Quarry, read the route sign. The chapter ends at the deer collision. Expect roughly 5–8 minutes on a first playthrough.

The horror title/pause menus use an editable vector logo, brush selection and the real game scene. They offer controls, credits, volume, sensitivity, field of view, subtitle options and checkpoint restart. The forest contains 3,584 trees plus 9,271 understory clumps, with drifting low mist. The red-tie watcher starts far from the road and approaches when you look away. Menu design and asset editing notes are in [menu-design.txt](docs/menu-design.txt).

Doors open at each bus stop. After the stop's interaction, departure waits for passengers to board, the player to return inside, a clear doorway and fully closed doors. You can step out and board again while stopped. Passengers enter out of view, walk along the aisle and sit when unobserved; their seats account for wherever you are sitting. The steering wheel turns with the bus's corrections.

Thought subtitles are brief; sound descriptions can be enabled in Settings. Objectives briefly appear and remain available in the paper shift notes. Saves stay local and are excluded from Git; test runs use a separate save. A collision ramp under the visible steps supports physical boarding. The bus carries the player along a fixed road.

Forest exploration/pursuit, hunger, town and branching endings are not implemented yet. Characters use editable mesh parts with procedural walking and separate seated poses; full skeletal animation and facial transitions remain future work. This milestone has been tested on Windows; Linux CI is a headless logic/physics check, not a graphical release certification. Browser and mobile exports come later.

## Checks

Run `powershell -ExecutionPolicy Bypass -File tools/test.ps1`. Tests cover progression, checkpoints, physical boarding, all ten seats, notes input, unseen passenger arrivals and seating, occupied seats, obstruction/reboarding, steering, watcher gaze and chapter completion. GitHub Actions runs the corresponding import and smoke tests on pushes and pull requests.

Geometry and synthesized ambience are original project assets. Footsteps are edited from the two YouTube clips supplied by the user; see [audio sources](docs/audio-sources.md) for attribution and the unresolved public-release licence status. Godot is MIT-licensed: https://godotengine.org/license/ . Include engine and third-party notices when distributing exported builds.

## Development

Godot 4.7.2 standard edition, GDScript, Compatibility renderer. Open `game/project.godot` in Godot. Original editable character sources are in `game/assets/characters`.

## Version history

Every finished development milestone is committed and pushed. Tested playable milestones receive annotated version tags. Use a separate checkout to inspect an old version without discarding current work: `git worktree add ../bus47c-v0.1.0 v0.1.0`.

Use `git revert <commit>` on a new branch to undo a change while preserving history. Never force-push the main branch. Run the smoke tests before tagging a playable build.

The surrounding folder contains unrelated media; it is deliberately excluded from this repository.
