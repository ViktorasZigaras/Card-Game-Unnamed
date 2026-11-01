# Art generation record

Built-in image generation was used with the approved collage as a style reference; no external API/CLI fallback was used.

## Building atlas prompt

Create a production sprite atlas on true transparent background for an original medieval economic game, consistent Colonization–Anno-inspired crisp pixel art, isometric elevated three-quarter view. Exactly four columns by two rows of equal cells, landscape. One complete centred isolated building/vehicle per cell with a small ground footprint and upper-left light. No labels, text, grid, UI or background scene. Transparent padding; no sprite crosses its cell. Top: humble thatched hut, upgraded brick dwelling with tiled roof, grain farm with wheat plot, lumber camp with logs. Bottom: open carpenter workshop with chest, wooden market stalls, small chapel, horse-drawn covered caravan. Match warm wood, thatch, cream plaster, clay reds, muted foliage and readable pixel clusters. Readable at about 150 px; no photographic/smooth 3D surfaces; actual alpha.

## Goods atlas prompt

Create one square production sprite atlas, exactly three columns by three rows of equal cells, each containing one centred isolated inventory sprite with transparent padding. No labels or UI. Match the reference's warm pixel-art materials, elevated three-quarter view and upper-left light. Top: timber logs, grain sack and sheaf, clay pile. Middle: brick stack, wooden furniture chest, minor-luxury cloth with ceramic cup. Bottom: plain worker with a tool representing pop, rolled parchment with wax seal representing influence, heraldic medallion representing prestige. No money coins. Readable at 48 px; no sprite crosses its cell; no blur; actual alpha.

## Town-ground prompt

Create a wide empty town-ground backdrop in the same classic historical pixel-art style. Elevated three-quarter overhead view; packed-earth paths connect broad empty grass-and-earth building areas. Small forest edge at left/upper-left, undeveloped meadow at right, entrance lane at bottom, hedgerow at top. Keep the centre open to receive separately rendered building sprites. No buildings, people, wagons, labels, UI or objects in the central clearing. Muted warm colours and deliberate pixel clusters; not a floating island or 3D render.

These are normalized prompt records; the original generation requests additionally repeated padding, transparency and readability constraints. The approved collage itself remains a reference image, not a sprite texture used by the game.
