# v0.60 — the town becomes visible and playable

The approved Colonization–Anno pixel-art reference now appears throughout the native Godot interface: eight building/vehicle sprites, nine goods/labour/influence/prestige sprites, town ground, illustrated cards, shared pile and an earthy timber/parchment theme. The map shows actual ownership and activated buildings; improving a hut changes its sprite. A caravan appears during visits. These are presentation changes; the map does not add adjacency or transport rules.

The former recorded-only screen now supports manual actions for the current house, action review and execution, AI stepping/automatic play, exact save/load, new games with seed/link settings, live history, the original recording, six-run regression batches, logs and fullscreen. The laboratory opens closed. The inspector's repeated-text problem discovered during visual inspection is fixed.

The simulation remains authoritative. `ui/live_session.gd` projects engine state, modes, legal actions and payment plans. It sends commands through `GameProbe`; UI scripts do not change resource totals or make their own legality decisions. `GameProbe` now exposes the latest decision and result for display, without changing its saved simulation format.

The local minimum client area is 1920 × 1080. Use F11/fullscreen on a 1080p monitor so OS window decorations do not exceed the desktop. Cards remain at least 180 × 252 px. The town expands with the window. Fixed town positions are a prototype layout; sprite animation and terrain editing are later work.

## Validation

- All 83 archived snapshots inspected in the native UI across all tabs, buildings, houses, resources and legal action previews.
- Previews checked against simulation snapshot before/after: no mutation.
- A manual pass and an AI step executed through the UI/session adapter.
- Save/load reproduced the exact simulation snapshot including RNG state.
- Native layout minimum, including outer margins, fits 1920 × 1080.
- Existing regression: six complete games, 82 checks, 486 decisions, no failures.
- Actual 1080p Godot/OpenGL capture inspected; screenshot included in `docs/images/v0_60.png`.

The gameplay objective and provisional prices are unchanged. This release does not yet implement the proposed all-three-house test. No new balance claims are made from the unchanged regression.

## Testing limits

This is a Godot project for editor playback, not an exported executable. Hotseat means the tester controls the current house; AI step/play can substitute for any turns. Unavailable-action explanations are still basic; the planner and legal-action list enforce the full rules. Session history lives in memory during play; durable journals preserve complete snapshots on disk. Save/load resumes the simulation in a new journal rather than restoring the prior UI history. New-game and load controls replace the active session immediately; save first if you want to return to it.
