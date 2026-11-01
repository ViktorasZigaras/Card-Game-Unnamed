# Prototype art

Original AI-generated raster art created for this project using the built-in image-generation tool. Style reference: the user's approved medieval-economic-game collage, combining readable classic Colonization-like sprites and detailed Anno-like buildings. No assets were extracted from either game.

- `buildings.png`: transparent 4 × 2 atlas. Hut, brick house, grain farm, lumber camp; carpenter, wooden market, chapel, caravan.
- `goods.png`: transparent 3 × 3 atlas. Wood, grain, clay; brick, furniture/chest, luxury; pop worker, influence seal, prestige medallion.
- `town_ground.png`: empty clearing, paths and forest-edge backdrop; no game objects baked into the background.

`ui/artwork.gd` calculates cell boundaries from actual image dimensions, creates AtlasTextures and uses nearest-neighbour filtering. Atlas extraction is non-destructive; source sheets retain their alpha. Production sprites can replace these sheets later without changing simulation rules.

The images are static prototype assets, with generated detail rather than a fully hand-authored uniform pixel grid. Their use does not establish a finished scale, animation system or permanent architecture style.
