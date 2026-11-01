# Suggested next test: a decent house for every house

Proposal only; not implemented or run in v0.60.

Change one condition: keep the current economy, trade terms, buildings and prices, but finish only when **Blue, Red and Gold each own at least one upgraded brick home**, with the clay import still established and having delivered.

The current test ends as soon as one home improves. It can therefore hide problems that appear when everyone must obtain bricks, find labour and accumulate influence while the first successful house continues acting. This test would exercise the existing systems before adding more goods or contract types.

Run six games: seeds 1, 7 and 42, each with manual timber and with the preset lumber link. Use a 40-round diagnostic limit, record any incomplete towns, and keep those failures in the report rather than silently rerunning or correcting them. The paired deck-access difference remains part of the lumber-link intervention.

Record first/second/third home-improvement rounds, completion gaps between houses, import pauses, unavailable-labour opportunities, carpenter/card access, influence transfers and overrides, chapel use, prestige distribution, and a short explanation of each unfinished house's blocking dependency.

The temporary AI would need to recognise the revised town objective and decide what a house with an upgraded home should do next. Keep that explicit: first use the current policy with only the necessary objective/terminal changes, inspect its decisions, and distinguish a coordination-policy failure from a physical supply deadlock.

The first question after those runs: **does the last house have a reasonable route to a decent home, or does the first success consume opportunities without contributing anything useful afterwards?**

Do not add a kiln, specialist, new commodity or a new contract at the same time. The observed bottleneck should determine which development is useful next.
