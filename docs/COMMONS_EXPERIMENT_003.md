# Experiment 003 — flexible recipes, persistent commons, and direct paid access

2026-10-31 · prototype 0.4.0 · no visible UI.

## User's clarification implemented

- Upgraded buildings can use a lower-input recipe. In particular, an upgraded hut can consume one grain for one pop; grain plus a minor luxury produces two pops.
- Basic rural buildings produce one commodity without a pop. An upgraded rural building may still do that, or spend one pop to produce two of its commodity.
- A round is one shared-hand refresh; houses alternate actions until all pass. A house that did something during the round receives no influence on its closing pass.
- Physical goods remain in the general pile. This experiment also preserves unused pop tokens across rounds; there is no expiry, spoilage, or pool-capacity deletion.
- Each house has a protected stockpile of THREE TOTAL TOKENS. Taking one eligible token into it is an ordinary action. Hoarded stock is never available to a rival, even with influence.
- A built owned building activates at most once per round across all houses, regardless of payer. The earlier once-per-revealed-card restriction is retained for public buildings too.
- Influence is capped at ten per house. A built public chapel provides two influence to its activator. Influence spent for direct rival access transfers to that rival.
- Paid use is outright execution. There are no bids, counterbids, confiscation, or contested ownership of stockpiles.

## Temporary details needed to execute the test

1. Idle passing still ends that house's participation for this round. A completely idle house receives one influence; a house that activated, claimed, upgraded, built, took/returned a token, or performed a free paid use receives none on pass. The previous six-action cap is removed. A diagnostic watchdog would report failure rather than force passes; it did not trigger.
2. Access fee is one influence per rival building activation, plus one per rival-reserved INPUT TOKEN actually consumed. These prices were unspecified, so remain provisional. There is no fee for ordinary public goods or one's own reservations/stored goods.
3. Paid rival-building activation is a FREE ACTION: pay and activate immediately, keep the same acting house, then take a normal action or pass. It does not advance the personal normal-action reservation timer. It does mark the house as having acted for pass eligibility. Payments for rival reserved inputs are free inline access to that actual consumption; they do not make an otherwise ordinary construction or workshop action free.
4. A protected stockpile cannot be bought, consumed, or seized by rivals. Taking a token into safekeeping may use only public stock or the taker's own reserved output. One cannot buy someone else's reservation merely to hoard it. The owner can consume its own stored goods when a recipe needs them.
5. Inputs prefer own reserved lots, then public stock, then own protected stock, then rival reservations paid per unit. An operation and all its payments/consumption are atomic. The owner receives payment immediately and has no interrupt/counterbid action.
6. Existing production reservations last through the producer's next NORMAL action, then leftovers become public. Free paid activations create reservations that remain usable during the payer's immediately following normal action. All unused physical output persists; there is no round-end reset of pops.
7. Any influence gain/receipt above ten is discarded and logged as cap overflow. This also applies when a payer transfers influence to an already wealthy owner. Refusing the use because the owner is capped was not added as a rule.
8. Existing costs retained: three influence to claim any public building; construction/upgrade uses two wood, one brick, one pop. Construction creates a public asset, claimed separately later. Claims and upgrades are ordinary actions and require a revealed card; three property slots per house remain. Industry upgrade recipes retain the previous provisional processing costs; housing and rural buildings have explicit basic/enhanced recipes.
9. Same initial goods, seeds, and rural/urban capacities as experiment 002. The new chapel is an additional built urban asset and occupies the sixth urban plot. The town therefore starts with no free urban plots and three huts. This sample can test fancier huts but cannot demonstrate expansion to more homes without another land rule. The river valley has two available rural plots; woodland two forest plots, only one matching an extra defined woodlot.
10. Four shared cards are revealed each round from nine starting built buildings. All buildings activate at most once per hand; no population or resource is generated automatically. The chapel has no inputs, is claimable, and cannot be upgraded in this small test.

These are documented interpretations, especially free-action timing, the fee amount, whether public buildings also activate once, passing withdrawal, pop persistence, and the chapel's plot.

## Six-game result

Seeds 1, 7, 42 in river valley and northern woodland. Forty rounds each: 240 rounds, 1,485 recorded decisions including free uses. No economic or policy changes between games.

| Locale / seed | First upgraded hut round: Blue / Red / Gold | All three achieved by round | Economic activity in round 40 |
|---|---|---:|---|
| River valley / 1 | 7 / 7 / 3 | 7 | Yes |
| River valley / 7 | 4 / 4 / 5 | 5 | Yes |
| River valley / 42 | 3 / 4 / 8 | 8 | Yes |
| Woodland / 1 | 7 / 9 / 3 | 9 | Yes |
| Woodland / 7 | 4 / 4 / 5 | 5 | Yes |
| Woodland / 42 | 3 / 4 / 7 | 7 | Yes |

All eighteen house cases achieved one upgraded hut. None of the six towns exhibited the previous permanent grain/luxury bootstrap failure. Shared grain ended at four to six tokens, with one additional protected grain per house. Shared pops ended at one to three, with one protected pop per house. These are a small sample of a heuristic policy, not a success probability estimate.

The policy also built rural capacity: river-valley towns added a farm and a woodlot; woodland towns added a woodlot. Industry claims and upgrades followed the housing goal. The chapel/starting town consumed urban space, so every game retained exactly the three starting huts, all upgraded.

## Mechanisms observed

- 194 paid rival-building uses; every such use was a logged free action.
- 22 rival-reserved input units bought and immediately consumed.
- 216 influence transferred for those direct uses, before recipient-cap overflow.
- 126 ordinary actions moved a token into safekeeping. Houses prepared wood/bricks for upgrades, then tended to keep grain, luxury and a pop as a small reserve.
- Four grain-only activations of upgraded huts occurred. Most upgraded-hut activations could use luxury, but the basic recipe was present and was actually exercised.
- 164 rural activations used the no-pop basic recipe. No upgraded rural fallback was selected by this policy in these six games; focused fixtures verify it works.
- 228 pops supplied; 200 spent and 28 retained. There was no pop expiry. Eighteen retained pops were in protected stores, ten in general stock.
- 310 fully idle passes qualified for the one-influence reward; 410 passes after acting generated no reward. Capped receipts are not all credited: the cap discarded 178 influence across all gains and transfers. Ninety-two chapel uses generated two influence each before capping.

## Assessment and limits

The fallback and no-pop rural recipe remove the two circular restart requirements from the preceding experiment. This run shows a stable small domestic production loop through round forty, with upgrade preparation, protected reserves, and circulation of influence for access.

Ownership now has an observable access-payment benefit in addition to controlling upgrades. Paying for a rival building also preserves the payer's normal turn under this interpretation, giving influence a concrete timing use. It remains a political/access resource; no domestic general-purpose money was added.

Stockpiles protected tokens without creating an auction or seizure contest. Resource payments occur only as part of actual use, and stockpiles never enter the payment planner's rival-access path.

The influence cap prevented unlimited balances, but large overflow and frequent maximum balances suggest the current toy town eventually has fewer useful influence sinks than supply. This is recorded for later discussion rather than silently changed.

Several changes were introduced together, as requested. The six runs do not isolate how much stability came from fallback recipes, no-pop rural supply, persistent pops, protected caches, or better access. Also, success on one upgraded hut cannot establish how extra urban development would behave, because the chapel occupied the remaining urban plot.

## Verification

69 checks passed; zero failures. This includes 33 focused assertions and six games with save/load, exact next-decision/state continuation, full journal replay and post-action invariant checks. Checks cover basic/enhanced input choices, no-pop rural production, grain/pop restart, persistent resources, stockpile capacity and protection, immediate paid consumption, transfer/cap accounting, free paid turn retention, once-per-round owned activation, and idle-only influence rewards. No corrective game reruns were required.

Evidence: `experiments/commons/results.json`, complete per-game journals/checkpoints/saves/summaries under `experiments/commons/evidence/`, and `verification.txt`. Default execution is `--experiment=commons`. Historical modes remain available. `python tools/run_checks.py --godot /path/to/Godot` reproduces the six games.
