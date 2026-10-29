# Bus 47C working agreement

The user explicitly requested GitHub history and regularly pushed versions for recovery.

- Keep unrelated root media out of Git. Only stage project files intentionally.
- Commit and push each completed, verified development milestone to the configured origin. The user made the repository public; preserve that visibility.
- Run tools/test.ps1, or equivalent pinned Godot import/story/scene checks, before tagging a playable milestone.
- Add an annotated semantic version tag and update CHANGELOG.md for playable milestones.
- Preserve rollback history. Never force-push main or silently reset user changes.
- Verify the remote commit/tag after pushing. Report failed pushes honestly.
- Do not claim platform support or finished features that have not been tested.
- Keep source models editable and preserve prior versions in Git.
