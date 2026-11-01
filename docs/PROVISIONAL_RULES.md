# Provisional rules, prototype 0.1.0

These are reversible implementation choices, not approved final design. The source design brief remains authoritative. The current goal is to expose state transitions and AI decisions for testing.

- Three AI houses: blue prefers production, red commerce, gold ownership. Deterministic utility scoring, stable tie breaks, short trade-reversal memory. Seeded randomness currently affects the deck only. No planning council or multi-turn goal system yet.
- Ten building definitions, five initially built public buildings. Others must be constructed on unused compatible terrain. Buildings remain in the town and cycling deck regardless of ownership. Two locales vary terrain and initial market stocks.
- Four cards revealed per round; the shared deck reshuffles its discard only when exhausted. Newly built buildings enter the draw deck. Existing revealed cards stay out until round close.
- Houses alternate; opening player rotates by round. Each takes at most six non-pass actions, then must pass. Passing withdraws that house for the round. All passing closes the round. This limit bounds test duration.
- Only revealed buildings may activate, change ownership, or upgrade. A building activates once per round town-wide. Owning a building does not automatically activate it. Any house can activate it; a different owner receives one coin from the activator. Unowned buildings are public.
- Three ownership slots. Acquisition costs coins to the town bank. Divestment returns half the base price, rounded down and capped by bank funds, and makes the building public. Existing buildings persist. No direct negotiated transfers yet.
- One upgrade: 3 coins plus 1 brick raises a building from level 1 to 2. Outputs double, recipe inputs stay unchanged. Construction consumes 2 wood and 1 brick plus 2 coins, assigns ownership, and occupies one terrain slot. This cheap generic cost is a placeholder.
- Wood, grain, clay, brick, coin. Inventories are quantities, never cards. Market goods persist. Private storage holds 18 non-coin goods, market storage 30 of each good. Activation must fit after consuming recipe inputs. No production/storage ambiguity: output is a per-activation quantity; storage limits are separate.
- Raw producers create goods on activation, processors consume recipe inputs; the ledger records all creation/consumption. Raw deposits are not exhaustible in this prototype. There is no magical replenishment of market stocks; houses must sell to stock it.
- Fixed buy/sell prices are identical for now. Trades transfer existing goods and coins, with no trade spread. AI avoids reversing the same resource trade in the same round. This is test scaffolding, not a final market model.
- Bank starts with 500 coins, including the 30 assigned to houses. Work transfers 1 coin from bank as a fallback, if available. Processors transfer their coin output from bank; they do not create coins. Coin scarcity and possible bank exhaustion are observable balancing problems, not silently repaired by minting.
- Foreign trade is currently one abstract grain export offer, available every third round beginning with round 1. At most one active contract per house. On acceptance, 2 grain and the bank's 4-coin payment are escrowed. At close, grain leaves the economy and payment reaches the house. Up to three deliveries; automatically reserve the next installment only if both parties can pay. Otherwise terminate without a penalty. This proves persistence and escrow mechanics; a separate foreign-trade deck is deferred.
- No population upkeep, food consumption outside recipes/contracts, institutions, negotiation, scoring, or victory condition. A test ends after a requested round count. Wealth is a diagnostic quantity, not a victory score.

## State and debugging contracts

Snapshots include rules so edits to the live JSON cannot silently change a loaded run. RNG state is stored as a decimal string to preserve 64-bit precision through JSON. Simulation state keeps the last 64 actions as bounded AI memory; the external JSONL journal retains the complete decision history. No log retention/rotation yet, so full-state logging is intended for short investigative runs. Batch tests omit journals and retain summary metrics.

Every accepted command runs accounting and structural checks via GameProbe: nonnegative inventories/bank, storage/ownership limits, all goods and coin reconciled against source/sink ledger including escrow, terrain occupied+free totals, exactly one card per built asset. Invalid commands return an error before mutation.

The in-process API expects trusted programmatic callers and schema-valid saves from this prototype. The save loader rejects missing top-level fields and unsupported schema versions; it is not a hardened untrusted-file importer. Replay is intended for this rules-engine version; it does not promise identical results after code changes.
