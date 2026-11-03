> **Historical document.** Retained for its original version/experiment; its recommendations and missing-feature claims may be superseded. For current v0.909 rules, decisions and next work, start with [THREAD_HANDOFF.md](THREAD_HANDOFF.md). Historical results below are not relabelled as current validation.

# Native Godot interface — v0.55

This release takes the structural proposal into native Godot Controls. Game rules are unchanged. Minimum window and base viewport: **1920 × 1080**. Larger windows expand the central area. This desktop preview does not offer the earlier web proposal's narrow-screen stacking.

## Open

Use Godot 4.5 or newer. Import `project.godot` and run the project. The new main scene is `ui/interface.tscn`. No export templates or artwork are required for editor playback.

The viewport uses `canvas_items` stretching. The window minimum is set to 1920 × 1080 in the scene script; the layout uses expanding containers rather than fixed sprite coordinates.

## Layout

| Region | Structure |
|---|---|
| Top | Version, round, actor, pass chain, recorded action, Laboratory button |
| Left | About 280 px; three houses, influence/prestige, property counts, three storage slots, finite-pop accounting, selectable assets |
| Centre | Expands; objective, reserved 2D sprite area, market construction selection, shared resource pile, four cards |
| Right | About 390 px; Selected / Caravan / Links / Journal tabs and legal-action previews |
| Bottom | Replay position, deck/discard counts, disabled live-game controls |
| Laboratory | Separate closable 1300 × 800 window with Previous / Next, scrubber, AI decision, event and state |

Four cards have a **180 × 252 px minimum**, maintaining the proposed 5:7 proportion at the baseline; container expansion may widen them. They show names, levels, ownership and available basic/enhanced recipes. Plain native controls are structural placeholders, not an art direction.

The town panel is reserved for future **Node2D sprites**. It currently shows only its name and urban/forest/field usage. No 3D content, map perspective, sprite scale or architecture has been chosen.

## Current interaction

Click a hand card or town asset to inspect recipes and legal choices. The market construction selector works before the market exists. Click a resource to inspect general lots, reservations, private holdings and access fees. Click a house to inspect its recorded state. Legal-action previews show actual exported engine inputs, outputs, influence transfers and source allocations.

The Caravan tab covers brick barter, clay-contract setup and caravan status. Links shows the contract, commitments and deliveries. Journal shows the recorded event. Laboratory exposes recorded AI alternatives and state accounting; its scrubber changes every visible panel together.

The source is the existing seed-7 manual-timber test: **83 snapshots, consisting of the initial state and 82 decisions**, finishing in round 10. This is an interface preview driven by authoritative recorded data, not a new AI run or a human-play session. The original journal remains in `experiments/marketplace/evidence/seed_7_manual/decisions.jsonl`.

Human Execute, new-game configuration, save/load buttons, automatic batch controls and a fully styled town goal/reward history are not wired in this preview. Pass and prestige conversion are visibly disabled. Some unavailable actions currently have general explanations; detailed shortages can be added when the UI connects to the live engine.

## Validation

`godot --headless --path . -- --ui-check` instantiates native controls and visits every recorded snapshot, inspector tab, building/resource/house selection and legal-action preview. It checks the largest container minimum plus outer margins against 1920 × 1080. Check logs must also be free of script errors.

The existing seed-7 journal can be replayed against the unchanged simulation with:

```sh
godot --headless --path . --script res://tests/replay.gd -- res://experiments/marketplace/evidence/seed_7_manual/decisions.jsonl
```

The available environment supports headless Godot checks but has no graphical display server; visual rendering on a desktop has not been verified here. The downloadable project opens directly in Godot for that review.

Command-line simulation options continue to dispatch to `src/laboratory.gd`; no-argument launch opens the interface. For a default headless simulation, supply an explicit option such as `-- --experiment=marketplace`.

Version sequence: 0.50 → **0.55** → 0.60. Repository upload remains pending the user's interface review.
