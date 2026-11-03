# Prototype art

Original AI-generated raster art created for this project using the built-in image-generation tool. Style reference: the user's approved medieval-economic-game collage, combining readable classic Colonization-like sprites and detailed Anno-like buildings. No assets were extracted from either game.

- `buildings.png`: transparent 4 × 2 atlas. Hut, brick house, grain farm, lumber camp; carpenter, wooden market, chapel, caravan.
- `goods.png`: transparent 3 × 3 atlas. Wood, grain, clay; brick, furniture/chest, luxury; pop worker, influence seal, prestige medallion.
- `town_ground.png`: empty clearing, paths and forest-edge backdrop; no game objects baked into the background.

`ui/artwork.gd` calculates cell boundaries from actual image dimensions, creates AtlasTextures and uses nearest-neighbour filtering. Atlas extraction is non-destructive; source sheets retain their alpha. Production sprites can replace these sheets later without changing simulation rules.

The images are static prototype assets, with generated detail rather than a fully hand-authored uniform pixel grid. Their use does not establish a finished scale, animation system or permanent architecture style.

## v0.909 presentation

The saved town uses these original atlases with code-drawn foreground vegetation, decorative roads and one subtle effect per completed building. Hall uses the brick-house sprite; small sawmill uses carpenter art; kiln uses a code-drawn placeholder. These are provisional choices. `ui/town_view.gd` and `ui/town_ambience.gd` own presentation; the cosmetic clock consumes no game RNG and can be disabled. Exact unit pictures and overflow are handled by `ui/goods_view.gd`. The static `docs/images/town_layout_0_909.png` is a design study, not a Godot screenshot. See `docs/CURRENT_GAME.md` for presentation limits.
