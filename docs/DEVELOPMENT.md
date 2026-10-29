# Development guide

[Back to Bus 47C](../README.md)

## Open the project

Use **Godot 4.7.2 standard edition**, GDScript and the Compatibility renderer. Open `game/project.godot`. On this development PC, `Start Game.cmd` runs the game and `Open Editor.cmd` opens the editor.

On a fresh Windows checkout:

```powershell
powershell -ExecutionPolicy Bypass -File tools/setup.ps1
```

The setup downloads the pinned official engine and imports the project. Engine binaries, generated imports, personal saves and working files are excluded from Git.

## Find the editable pieces

| Location | Contents |
| :--- | :--- |
| `game/assets/characters` | Editable glTF character parts and seated poses |
| `game/assets/ui` | Vector logo, paper, retro filter, fog and encounter shaders |
| `game/assets/audio` | Edited and original cues with import settings |
| `game/scripts/story.gd` | Six-stop story progression |
| `game/scripts/route.gd` | Road layout and route landmarks |
| `game/scripts/bus_passengers.gd` | Boarding, seating, departures and roadside reveals |
| `game/scripts/face_loss.gd` | Staggered facial feature animation |
| `game/scripts/aftermath.gd` | Post-breakdown branches, interactions and checkpoints |
| `game/scripts/forest_events.gd` | Changing warning, search boundary and Forestry Way ending |
| `game/scripts/town_district.gd` | Shops, house details and editable signs |
| `game/scripts/town_horror.gd` | Town arrival scene and persistent blackout |
| `game/scripts/surface_atmosphere.gd` | Bus wear, glass, damp road materials and selective shadows |
| `game/scripts/story_audio.gd` | Phase-specific audio, ducking and pause behavior |
| `game/tests` | Story, traversal, regression and capture scripts |

See [gameplay notes](GAMEPLAY.md) for detailed behavior and [menu design notes](menu-design.txt) for the editable logo workflow. These documents include spoilers.

## Run checks

```powershell
powershell -ExecutionPolicy Bypass -File tools/test.ps1
```

This imports the project, validates the route and runs the full scene checks. The same checks run on GitHub Actions. Check both the exit code and the logs for script errors or failed assertions. Native rendering still needs a graphical run.

For the current lighting and material capture set:

```powershell
.\tools\godot\Godot_v4.7.2-stable_win64_console.exe --path game -- --capture12
```

Capture and smoke-test modes use a separate test save. Set `BUS47C_CAPTURE_DIR` to an absolute directory to keep captures out of the tracked preview folder.

## Export Windows

```powershell
python tools/fetch_windows_template.py
powershell -ExecutionPolicy Bypass -File tools/export_beta.ps1
```

The default export is written under ignored `work/beta-windows`. `-OutputDirectory` and `-ZipPath` choose other destinations. The package includes the executable, data pack, controls, build manifest, audio source record and engine and font notices.

Follow the [release guide](RELEASING.md) before uploading a build. A source commit by itself is not proof that its exported binary was tested.

## Preserve history

Keep playable milestones as annotated version tags. Never move a published tag, replace a release binary under the same version or force-push `main`. Inspect an old version in a separate checkout; use a new commit to correct a mistake. Keep unrelated media and temporary downloads out of the repository.
