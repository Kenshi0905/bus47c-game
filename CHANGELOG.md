# Changelog

## 0.4.0
- Three-spoke steering wheel and column, with steering corrections while the bus moves.
- All ten empty passenger seats support E to sit, free mouse look and Space to stand safely in the aisle. Occupied seats cannot overlap the player.
- Passengers arrive outside the camera view, walk with animated mesh limbs, wait beside a seat and switch to sitting only when unseen. Taking an empty reserved seat reroutes its approaching passenger.
- Doors open at both route stops. Departure waits for a minimum dwell, arriving passengers, the player aboard and fully closed doors. Doorway obstruction reopens the doors; stepping out and boarding again is supported.
- Soft drifting mist among bushes and trees using a Compatibility-renderer shader.
- Paper inspection notes, Tab-accessible shift notes, brief objective hints and fewer thought subtitles. Optional sound descriptions are off by default.
- One distant red-tie watcher advances through five positions only outside view, starting over 20 metres off the road.
- Expanded checks cover all seats, input/footstep suppression while sitting, unseen appearance/pose changes, stop doors, disembarking, steering and watcher visibility.

## 0.3.0
- Horror title menu based on an editable Canva layout: distressed Bus 47C vector logo, brush selection, condensed text, subtle film grain and quiet original ambience.
- Menu uses the live game scene. Removed the illustrated backdrop, location header, subtitle and menu clock line following review.
- Working controls, credits, settings, keyboard focus and Escape/back navigation; separate title camera preserves player position.
- Dense seeded forest: 3,588 trees and 9,383 bushes/grass clumps, rendered in 104 spatial batches with distance culling.
- Shelter, boarding area and stop-figure sightlines remain clear; road and windshield stay readable.
- Watcher tie emits red with restrained local spill on the shirt; source character meshes remain editable.
- Added menu navigation/camera checks alongside the existing full chapter physics/progression tests.

## 0.2.0
- Correct forward approach from 65 metres away, headlights, turning wheels and actual travel along a fixed road.
- Real doorway aperture, hinged twin doors, working collision and physical walk-on boarding.
- Transparent windshield, compact dashboard clock, overhead next-stop sign and visible roadside figures.
- Three editable seated passenger variants, introduced across Mill Road and Old Quarry.
- Extended chapter through the deer collision, with safe checkpoints at each stop.
- Transit-themed menu, separate settings screen and field-of-view control.
- Two user-supplied footstep clips trimmed into six variations each; distance-driven steps and slower walking cadence.
- Tests now walk up the entry ramp, verify bus carrying/pause behaviour and complete the extended story flow.

## 0.1.0
- First-person forest bus stop with inspectable note and arriving 47C.
- Boarding interaction, empty driver's seat, frozen clock and first passenger encounter.
- Six editable passenger variants included; grinning clerk and watcher used in the slice.
- Original synthesized forest, engine, door, footstep, chime and drone audio.
- Pause, volume, sensitivity, captions, validated checkpoints and replay.
- Windows launchers, pinned Godot setup and automated progression/scene checks.
- Scope: first playable slice; later story acts and character animation remain unimplemented.

## 0.0.0
- Established the project structure and version-history policy.
