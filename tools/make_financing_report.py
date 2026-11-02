from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
r=json.loads((root/'experiments/financing/results.json').read_text())
d=json.loads((root/'experiments/financing_directed/results.json').read_text())
assert len(r)==12 and all(x['replay']['ok'] and x['save_exact'] and not x['failure'] for x in r)
assert len(d)==6 and all(x['replay']['ok'] and not x['failure'] for x in d)
def totals(mode):
 a=[x for x in r if x['funded_policy']==mode]
 return {'decisions':sum(int(x['metrics']['decisions'])for x in a),'halls':sum(len(x['houseworks']['hall_rounds'])for x in a),'trips':sum(len(x['exploration']['trips'])for x in a),'returned':sum(sum(t['status']=='home'for t in x['exploration']['trips'])for x in a),'routes':sum(len(x['exploration']['routes'])for x in a),'delivered':sum(sum(z['delivered']for z in x['exploration']['routes'])for x in a),'missed':sum(sum(z['misses']for z in x['exploration']['routes'])for x in a),'imports':sum(sum(x['exploration']['imports'].values())for x in a),'cargo':sum(sum(sum(t['cargo'].values())for t in x['exploration']['trips'])for x in a),'earned':sum(x['exploration']['gold_earned']for x in a),'spent':sum(x['exploration']['gold_spent']for x in a)}
b,n=totals(False),totals(True)
rows=[]
for seed in [1,7,42]:
 for linked in [False,True]:
  x=next(t for t in r if t['seed']==seed and t['linked']==linked and not t['funded_policy'])
  y=next(t for t in r if t['seed']==seed and t['linked']==linked and t['funded_policy'])
  imports=lambda t:int(sum(t['exploration']['imports'].values()))
  missed=lambda t:int(sum(z['misses']for z in t['exploration']['routes']))
  rows.append(f"| {seed} | {'linked' if linked else 'manual'} | {imports(x)} / {imports(y)} | {missed(x)} / {missed(y)} | {len(y['houseworks']['hall_rounds'])}/3 |")
full=b['decisions']+n['decisions'];directed=sum(int(x['steps'])for x in d)
text=f'''# Route financing — experiment 015, v0.905

**2 November 2026 · local source version 0.905 · schema 16**

## Outcome and scope

The financing policy imported **{int(n['imports'])} units versus {int(b['imports'])}** in the six matched ordinary towns. It chose no standing routes in those ordinary games, so route misses fell from **{int(b['missed'])} to zero** by avoiding the obligations, not by manufacturing missing gold. All eighteen houses in each group completed Halls. Home/industry milestone timing and chapel completion were unchanged across the matched pairs.

That result alone could conceal a blanket contract veto. Six controlled cases separately checked whether the AI could accept and operate a genuinely funded, limited route. All three funded cases imported four clay, missed no shipments, paid the eight-prestige exit bill and released transport. All three finite-cargo cases bought two clay without binding transport; they also used a remaining coin for a useful stone cargo. These are deliberately funded/controlled fixtures, not naturally earned wealth or random discoveries.

The change affects AI choices and explanations. No import/export price, delivery cadence, transport capacity, crew cost, cancellation fee, offer quota or legal contract permission was altered. The save schema adds acquisition observations so the policy can reconstruct its budget after loading; those observations do not reserve funds or restrict human actions.

## The economic ceiling that motivated the policy

The cheapest standing route spends one gold every round. The current caravan buys only one brick for one gold every three rounds, shared by the whole town. Once a Hall's single transport capacity is bound to a route, that house cannot keep generating additional expedition sale offers with the same capacity. Goods sold before binding provide a finite starting treasury, not recurring income.

Even a house that captured every caravan order could obtain at most two gold over six future rounds, against at least six gold of route operation. That optimistic ceiling does not even charge the production inputs needed for its export bricks. Shared orders are uncertain competition, not guaranteed private revenue. Town rewards for a new clay route are prestige, which cannot pay gold upkeep.

Consequently, better action selection alone cannot make an indefinitely operating route sustainably funded under this restricted economy. A finite prefunded contract can still be useful for a specific material need. Future foreign-trade channels could change this calculation; none were invented to rescue the current result.

## Implemented decision process

1. Estimate a bounded material need from unfinished homes, known working buffers, physical supply and cargo already returning. The clay buffer is a provisional two units; it is an AI target, not a new public demand rule. Stone accounts for chapel/Hall requirements; wood/grain use small supply targets.
2. Compare that need with the finite units still offered. If finite cargo covers it, do not pay to bind transport merely for recurring rights or a one-time prestige reward.
3. Consider a limited standing contract only when at least three useful deliveries are wanted beyond what the finite offer can supply, up to a six-round planning cap.
4. Require actual cash for setup plus every planned delivery. Record the upper bound from shared caravan opportunities, but count zero guaranteed recurring gold. Unsold goods and other houses' wallets are not booked as secured funding.
5. Require the real social exit budget as well. At the initial route price, cancellation costs eight prestige. A genuinely still-available town clay reward is counted only as prestige; it is not assumed to repeat or turn into cash.
6. Once committed, protect the remaining operating gold from discretionary prestige/stone/cargo purchases and protect the exit prestige from title purchases or demolition. This is policy earmarking, not a new currency lock imposed on a human.
7. Reconstruct the original bounded goal and remaining deliveries from the saved acquisition observation. On reaching that goal, or when the next shipment is unfunded, favour paying for exit before repeated misses if cancellation is actually affordable.
8. Re-evaluate departure after financing vetoes, so a rejected trade does not by itself keep an expedition waiting abroad. Other worthwhile legal work can still outrank immediate departure, and the existing trade-window limit remains.

Human players can still take an underfunded contract, buy other things with that gold, or retain a route longer. The interface provides an advisory funding note when previewing a contract; it does not change legality.

## Persistent observations, rather than hidden AI memory

`FinancingSimulation` inherits expedition mechanics and adds an acquisition record when a route is established or bought out: owner, cash after the transaction, current delivery count, round, outstanding-home count and physical/cargo observations. `FinancingAI` derives its target and budget from that record. Save/load and journal replay therefore preserve the evidence the policy uses without an unrecorded agent-memory object.

This is a specific multi-turn funding assessment. The player is still a rule-based policy with bounded demand estimates, not a general search engine, opponent modeller or learned financial strategist. Historical v0.904 saves are not automatically migrated to the new schema; their source version remains available separately.

## Twelve ordinary matched games

Seeds 1, 7 and 42 × manual/preset lumber × old expedition policy/new financing policy. Both variants use the same schema-16 simulator, all expeditions enabled, the same prices and the same development rules. Each runs eighty playable rounds and snapshots at the refresh into round 81. Changed actions alter the shared RNG's later card/offer draws; these are descriptive matched comparisons, not identical future hands or a statistical proof of superior play.

| Seed | Lumber | Actual imports: old / financed | Missed route shipments: old / financed | Financed Halls |
|---|---|---:|---:|---:|
'''+ '\n'.join(rows)+f'''

| Total across six towns | Old policy | Financing policy |
|---|---:|---:|
| Actual imported units | {int(b['imports'])} | {int(n['imports'])} |
| Standing routes established | {b['routes']} | {n['routes']} |
| Route-delivered units | {int(b['delivered'])} | {int(n['delivered'])} |
| Missed route shipments | {int(b['missed'])} | {int(n['missed'])} |
| Expedition launches | {b['trips']} | {n['trips']} |
| Expeditions home by cutoff | {b['returned']} | {n['returned']} |
| Purchased units still in cargo | {int(b['cargo'])} | {int(n['cargo'])} |
| Gold earned from expedition sales | {int(b['earned'])} | {int(n['earned'])} |
| Expedition purchase/setup/upkeep gold | {int(b['spent'])} | {int(n['spent'])} |
| Completed Halls | {b['halls']} | {n['halls']} |

The new policy's two units still in cargo explain why paid purchases exceed goods already imported at cutoff. Those parties remain saved and can return later. More imported units and zero rejected obligations are not a victory condition; the experiment does not establish that every trade was optimal or useful to the same degree.

## Six directed cases

For each seed, a real Hall, market, improved home and owned industry were constructed in the fixture. A ready expedition received a controlled clay/stone offer and a stated initial treasury.

- **Finite case:** all homes already improved; two clay cover the policy's working target. The AI purchases the finite cargo, also buys one useful stone with its remaining coin, returns and has no standing obligation.
- **Limited-contract case:** two homes remain unimproved, giving a four-clay target including the working buffer. The owner begins with five gold and eight prestige. One setup gold leaves four prepaid deliveries. The one-time clay reward offsets the setup's prestige charge; the real eight-prestige cancellation budget is preserved. The AI imports four clay, pays to cancel and recovers its transport with no missed shipment.

Other houses pass during these directed cases. They test budgeting, continuation and exit, not opposition strength or the natural likelihood of discovering the deal. All six cases finish, save/load exactly and replay exactly: **{directed} decisions**. The policy is not simply forbidden from making contracts.

## Verification and limits

- All twelve ordinary games passed invariants, exact saves and exact journal replay: **{full:,} decisions**.
- All six directed cases passed exact saves/replay: **{directed} decisions**, for **{full+directed:,}** across both sets.
- **52 financing checks** cover funding/exit shortfalls, nonrepeatable rewards, no invented recurring income, cargo-aware demand, advisory-only vetoes, protected money, cancellation, saved budgets and the six directed flows.
- The earlier expedition/Hall/stockade/project/trade/priority suites pass 93/56/47/31/22/47 checks.
- A nineteen-command expedition UI fixture passes preview immutability and exact save/load, minimum 1515 × 1028. A forty-round live UI game passes, minimum 1525 × 1028. All 83 archived UI states and existing controls pass.

A focused departure assertion initially inspected the next house after a forced sponsor action. Packaged checks caught this fixture error; the fixture now explicitly selects the sponsor before checking its departure choice. The assertion tests that departure is available after rejected/exhausted trades, without requiring it to outrank every useful civic action. No gameplay rule or price was changed to make the check pass.

The cash forecast is intentionally conservative; the demand model does not exhaustively price rights, rival responses or future institutional needs. Its clay target is anchored to acquisition observations rather than general adaptive goal replanning. The six-round cap and working buffers are policy assumptions. Long-lived import funding remains an economic design boundary until actual repeatable earning channels are introduced or trade rules evolve through an explicit test.

## Reproduce

`tests/financing_experiment.gd` runs the twelve ordinary comparisons. `tests/financing_checks.gd` runs the focused suite and regenerates the six directed journals. Compact results are in `experiments/financing/results.json` and `experiments/financing_directed/results.json`; full journals are regenerable and excluded from the ZIP.
'''
(root/'docs/ROUTE_FINANCING_TEST_015.md').write_text(text)
print({'main_decisions':full,'directed_decisions':directed,'total_replayed':full+directed,'new_imports':int(n['imports']),'old_imports':int(b['imports'])})
