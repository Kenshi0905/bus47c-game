# Changelog

## 0.8.0-beta.1
- Slower journey legs and repaired final ride. Corpses appear on the side the player is viewing, fade through distant fog and stay fixed once revealed. Five distinct blood-streaked warnings replace the repeated pairs.
- The zoomed watcher turns, dashes to a real forest tree, peeks, retreats and leaves a remnant. Departing passengers hold their stare beside the front door.
- Fruit has a subtle glow. After eating, choose the footpath or collect five distinct machine parts and fit them at the bus engine. Inventory and completed repairs survive checkpoint reloads.
- A town boundary ends the forest pursuit immediately, including detours toward the mart. Footpath pursuit steps grow closer and louder. Footprints and the Forestry Way marker improve navigation.
- The mirror stays empty until E. Completed or obsolete journal entries are crossed out. Separated the vase and wall trim surfaces and reduced material shimmer.
- Distinct diner, mart, takeaway and new coffee shop use the supplied inspirations. All four have accessible interiors and optional notes.
- Original path atmosphere, tension swells, death sting, jumpscare and positional tree rush use restrained levels, fades, quiet intervals and ambience ducking. The linked commercial-preview audio is not copied.
- Reproducible Windows x86_64 beta export with controls, source information and third-party notices. More lore and final polish remain in development.

## 0.7.0
- Weathered roadside warnings on both sides of the route, an overhead message and a rebuilt woods sign. Raised blood streaks and animated falling drops remain editable procedural geometry.
- Passengers depart at varied later stops, hold a stare toward the player, walk through the door and lose their facial features inside the shelter. Seats become available again. The saved journey seed preserves the schedule across retries.
- Departed passengers remain at their shelters as the bus moves. On the following leg, matching headless bodies appear in irregular blood pools beside the road.
- Expanded Loomesville with brick houses, lit windows, street lamps, parked cars and overhead wires. Enterable Morrow's Pizza, Night Owl Diner and 47 Mart have furniture, shelves, fridges, counters and optional story notes.
- House 17 gains a covered porch, patterned wallpaper, framed pictures, wood trim, a worn runner, ceiling lights and a hallway with side rooms. The entry knife and rear burial route remain accessible.
- Added checks for random schedule persistence, the stare and facial change, stationary departed passengers, body reveals, animated drops and physical walking into and out of all three shops. Existing six-stop and both-ending checks remain required.

## 0.6.2
- Rebuilt the shelter sign as a physical transit plaque with a separate 47C badge. Removed slash and em-dash separators from game signs, notes, menus, credits and prompts.
- Watcher disappearance now dissolves the model over 0.75 seconds, with drifting smoke, a fading red remnant and a positional sound. The remnant persists after the body vanishes and clears before another appearance.
- Hunger starts only after physically leaving the broken bus. An original stomach rumble precedes a persistent top-left food objective. No hunger narration or undergrowth-footstep subtitle; fruit interactions consume food.
- Fixed capture black screen: scene fades now render below menus and are explicitly cleared on failure and menu opening. Verified the rendered retry screen and activated its retry button.
- Added regressions for staying aboard, rumble timing, persistent objectives, dissolved-body remnants, pause behavior and visible capture recovery. Both story endings remain covered.

## 0.6.1
- First passenger boards without a look-back prompt or required passenger interaction; departure follows the normal boarding and door checks.
- Smaller, correctly oriented footpath sign moved off the walking line. Fruit bushes scattered around the breakdown clearing with no direct lantern trail.
- Backward gaze shows an empty forest. A subsequent step triggers an animated close lunge and original sound sting before failure; looking alone is safe. Pause/retry preserve the encounter state correctly.
- Golden path activates on foot without pressing E and connects continuously into the village. Cleared the fence opening and lowered the blocking curb; tests physically walk the entire route.
- Visible kitchen knife on a lit table beside the doorway, reachable before danger. Attacker waits until the weapon is equipped; left-click and E both defend within reach.
- Loomesville terminus moved from 30 to 220 metres beyond the breakdown, with a 36-second repaired bus ride, extra bends and extended forest/road scenery.
- Regression checks exercise actual movement, both defense inputs, jumpscare timing and both ending branches. New rendered correction previews.

## 0.6.0
- Watcher remains visible under normal gaze. A sustained right-click zoom starts a 1.9-second turn and a stare before disappearance at three seconds. Left/right placement respects the player's view and avoids bus window pillars; missed encounters only relocate far behind and offscreen.
- Darker exterior lighting and denser drifting fog along a longer, six-stop route: Firewatch Shelter, Mill Road, Old Quarry, Pine Crossing, St Bride's and Loomesville. Five seated passenger arrivals.
- Deer crosses upright during the penultimate-to-final leg; impact and breakdown occur before Loomesville. The continuation opens without requiring a gaze interaction.
- Rebuilt boarding collision as a flush wedge after physical exit testing exposed a raised ramp edge.
- Playable forest fruit gathering, hunger, lantern paths, a warning/grace period for backward gaze, positional pursuit footsteps and the bus/walking fork.
- Walking branch: house double, defensive interaction, staged mirror portrait with disappearing facial features, forest escape and daylight ticket-loop ending.
- Bus branch: repaired final bus leg, faceless house intruder, dragging and burial with a three-minute deadline, a 90-second closet sequence, dawn, coffee and newspaper ending.
- Safe continuation checkpoints and retries. Pause/notes preserve timer and movement locks; both endings can return to the fork. Earlier save format remains readable.
- Original synthesized stall, foliage, mirror, digging, knocking, cry, pursuit, pouring and birdsong effects. New procedural scene geometry and rendered story previews.
- Expanded tests complete both branches and verify failure/retry paths, physical bus exit and body dragging through the house, zoom timing, six-stop progression and moving deer.

## 0.5.0
- Animated title camera over the live bus scene; explicit Main Menu and Exit to Windows buttons. Returning to title preserves the checkpoint.
- Winding road geometry shared with the bus, forest and roadside scenery. The cabin turns with the route, movement follows its orientation, and steering responds to bends.
- Proper Mill Road and Old Quarry shelters with platforms, benches, lamps, timetables, stop flags and bins.
- Old Quarry departs automatically after its dwell and boarding checks, without inspecting the route sign. Door and reboarding protections remain active.
- Optional retro world filter with 640×360 sampling, palette dithering, muted colour, scanlines, grain and vignette. Menus and notes retain crisp text.
- Procedural worn paper with fibrous grain, torn edges, stains, fold creases and typed note text.
- Hold right mouse to zoom, with adjusted look sensitivity and reset on pause or document inspection.
- Suited watcher encounters in the player's forward field of view during Mill Road to Old Quarry. Direct gaze dismisses him; zoomed gaze triggers a brief turn toward the player before disappearance. No encounter gates progression.
- Windows scene tests cover curved-cabin movement, both watcher reactions, zoom reset, automatic departure and title/checkpoint round trips. New rendered previews in docs/v0.5-*.png.

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
