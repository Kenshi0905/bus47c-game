# Bus 47C

A short first-person low-poly horror game about a firewatcher's ride home to Loomesville.

## Play prototype 0.6.2

On this development PC, double-click **Start Game.cmd**. To edit, double-click **Open Editor.cmd**. On a fresh Windows checkout, run `powershell -ExecutionPolicy Bypass -File tools/setup.ps1` first to download the pinned official Godot runtime and import assets. The runtime is intentionally not committed.

WASD moves, mouse looks, hold right-click to zoom, E inspects/interacts/sits, Space stands, Tab opens shift notes, Shift walks faster and Escape pauses. Read the bench note, board through the open doors, and inspect the empty driver's seat and dashboard clock. All intermediate stops depart automatically after boarding; the first passenger has no look-back prompt or required interaction. Start a **New Journey** to experience the whole expanded route; older checkpoints still load.

Six stops including the starting shelter and terminus: **Firewatch Shelter → Mill Road → Old Quarry → Pine Crossing → St Bride's → Loomesville**. Five passengers accumulate along the route. A moving deer crosses during St Bride's to Loomesville; the bus breaks down about 220 metres before the terminus. The repaired final ride lasts 36 seconds and rounds several bends. The continuation opens automatically after the impact, even if you miss the deer interaction.

The title menu slowly moves its camera through the live scene. Pause offers Main Menu and Exit to Windows; returning to the title preserves the last checkpoint. Settings include volume, sensitivity, field of view, subtitles and an optional retro picture filter. Pixel sampling, restrained palette dithering, grain, scanlines and vignette affect the world while text stays crisp. Menu design and asset editing notes are in [menu-design.txt](docs/menu-design.txt).

The longer winding route passes through a dense forest, with darker moonlight and denser ground mist. Roadside stops have shelters, benches, timetables and lights. The watcher appears through the left or right window you are looking toward, with placement checks for window pillars. Ordinary gaze never dismisses him. Hold right-click and aim a settled zoom at him for about half a second: he turns over 1.9 seconds and stares. At three seconds he begins a 0.75-second mesh dissolve, leaving drifting smoke and a faint red trace for another couple of seconds, with a positional sound. An overlooked figure can relocate only after it is far behind and offscreen. No watcher encounter gates progression.

Doors open at each bus stop. Departure waits for passengers to board, the player to return inside, a clear doorway and fully closed doors. You can step out and board again while stopped. Passengers enter out of view, walk along the aisle and sit when unobserved; their seats account for wherever you are sitting. The steering wheel responds to the road bends.

Thought subtitles are brief; sound descriptions can be enabled in Settings. Objectives appear in the top-left corner and remain available in the shift notes, rendered on fibrous paper with worn edges, stains and fold creases. Saves stay local and are excluded from Git; test runs use a separate save. A collision ramp under the visible steps supports physical boarding. The route is scripted, with multiple bends; the player is a passenger, not the driver.

After the breakdown, physically step off the bus. A stomach rumble plays once outside, followed by the persistent top-left objective "Find something to eat." Search nearby undergrowth and eat from three scattered fruit bushes; no marked trail leads directly to them. Hunger does not run down while waiting aboard. The hunger and footstep narration lines are removed. During the pursuit, a backward look reveals an empty forest. Staying still is safe; moving after that look triggers a close lunge and sound sting before failure. The fade clears to a visible retry menu; it cannot cover the buttons. Side glances do not arm it. The golden sign sits beside the path. Walking onto that path selects the route automatically and leads continuously through a gap in the village fence onto the street; pressing E at the sign is optional. Alternatively, physically reboard the bus for the final stop.

Both story branches are playable prototypes. The shortcut leads to the hostile double, three mirror interactions that remove facial features, and the daylight ticket loop. The bus route leads to the faceless intruder, a defensive knife interaction, a three-minute body-dragging/burial task, 90 seconds hiding in the closet, dawn, coffee and the newspaper accusation. The knife is on a lit entry table, reachable from the doorway. Pick it up with E; the attacker starts advancing only after it is equipped. Left-click or E defends at close range, with a visible held knife and control hint. E also interacts with tools, body, grave and wardrobe. Opening the closet before daylight fails the sequence. Both endings offer a return to the fork.

Safe checkpoints cover the forest, fork, town encounter, burial, closet and dawn. Pause and reading stop hunger, pursuit and burial/closet timers. Save data validates known checkpoints and continues to accept the earlier bus-only format.

Characters use editable mesh parts with procedural walking and separate seated poses. The new town, props and story scenes are built in `aftermath.gd`; this is an initial gameplay/art pass, not a finished release. The mirror uses a staged portrait rather than a real-time room reflection; defense is an interaction rather than a combat system, and cries are synthesized rather than voiced dialogue. This milestone has Windows rendered and automated testing; Linux CI checks headless logic/physics. Browser, mobile, macOS and graphical Linux releases remain unverified.

## Checks

Run `powershell -ExecutionPolicy Bypass -File tools/test.ps1`. Tests cover all six stops, deer timing/movement, physical boarding and breakdown exit, seats/passengers, window-side watcher placement, zoom-only disappearance, pause and save recovery, scattered fruit, empty-backward-view and movement-triggered jumpscare, the entire physical golden-path walk without E, doorway knife pickup and both attack controls, the extended final ride, both branches, physical body dragging through the back doorway, burial/closet failure and retries, and both ending documents. GitHub Actions runs the corresponding import and smoke tests on pushes and pull requests. Rendering previews are in `docs/v0.6-*.png`, `docs/v0.6.1-*.png` and `docs/v0.6.2-*.png`. The latest captures include the rendered capture menu, an activated retry, hunger timing, shelter plaque and the lingering watcher remnant.

Geometry and synthesized ambience are original project assets. Footsteps are edited from the two YouTube clips supplied by the user; see [audio sources](docs/audio-sources.md) for attribution and the unresolved public-release licence status. Godot is MIT-licensed: https://godotengine.org/license/ . Include engine and third-party notices when distributing exported builds.

## Development

Godot 4.7.2 standard edition, GDScript, Compatibility renderer. Open `game/project.godot` in Godot. Original editable character sources are in `game/assets/characters`.

## Version history

Every finished development milestone is committed and pushed. Tested playable milestones receive annotated version tags. Use a separate checkout to inspect an old version without discarding current work: `git worktree add ../bus47c-v0.1.0 v0.1.0`.

Use `git revert <commit>` on a new branch to undo a change while preserving history. Never force-push the main branch. Run the smoke tests before tagging a playable build.

The surrounding folder contains unrelated media; it is deliberately excluded from this repository.
