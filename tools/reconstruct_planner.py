"""Rebuild the explicit planner from the preserved 0.905 reference policies."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
parts=['class_name PlannerAI\nextends HouseAI\n## Explicit and inspectable control flow; legacy policies are regression references.\nconst FORECAST_ROUNDS = 6\nconst MIN_BRIDGE_UNITS = 3\n']
base=(root/'src/marketplace_ai.gd').read_text();base=base[base.index('func phase'):].replace('func decide(', 'func seed_candidates(')
a=base.index('\tvar best: Dictionary = candidates[0]');b=base.index('\treturn {',a)
base=base[:a]+base[b:];base=base.replace('best.action.duplicate(true)','{}').replace('"score":best.score','"score":-1');parts.append(base)
for domain in ['contract','priority','kiln','trade','project','stockade','hall','development','expedition','financing']:
 t=(root/f'src/{domain}_ai.gd').read_text();t=t[t.index('func '):]
 name='decision' if domain in ['contract','priority','kiln','trade','project','stockade','hall'] else 'd'
 t=t.replace('func decide(simulation: TownSimulation) -> Dictionary:',f'func score_{domain}(simulation: TownSimulation, {name}: Dictionary) -> void:')
 t=re.sub(r'\tvar (decision|d) = super.decide\(sim\)\n','',t)
 t=t.replace('return decision','return').replace('return d\n','return\n')
 t=re.sub(r'\tvar best: Dictionary = (?:decision|d).candidates\[0\]\n.*?\t(?:decision|d).score = best.score\n','',t,flags=re.S)
 t=re.sub(r'\t(?:decision|d).policy_version = .*\n','',t)
 parts.append('\n# '+domain.upper()+' POLICY\n'+t)
parts.append('''
func decide(simulation: TownSimulation) -> Dictionary:
	var sim = simulation as ExpeditionSimulation
	var d = seed_candidates(sim)
	var plan = development_plan(sim)
	d.plan = {"goal":plan.objective,"land_route":plan,"alternatives":[],"budget":{},"next_action":{}}
	var groups = [
		{"name":"town and household needs","steps":[score_contract,score_priority,score_kiln,score_trade]},
		{"name":"development routes","steps":[score_project,score_stockade,score_hall,score_development]},
		{"name":"external opportunities","steps":[score_expedition]},
		{"name":"budget and exit commitments","steps":[score_financing]}]
	for c in d.candidates: c.score_trace = [{"stage":"base town needs","score":c.score}]
	for group in groups:
		for step in group.steps: step.call(sim,d)
		for c in d.candidates: c.score_trace.append({"stage":group.name,"score":c.score})
	var best: Dictionary = d.candidates[0]
	for c in d.candidates:
		if c.score > best.score: best = c
	d.chosen = best.action.duplicate(true)
	d.score = best.score
	d.policy_version = "consolidated_planner_recovery_1"
	d.plan.budget = d.financing.duplicate(true)
	d.plan.next_action = {"action":best.action.duplicate(true),"score":best.score,"reasons":best.reasons.duplicate(),"score_trace":best.score_trace.duplicate(true)}
	for c in d.candidates:
		if c.action.type in ["expedition_buy","expedition_contract","buy_route","own_route","cancel_route"]:
			d.plan.alternatives.append({"action":c.action.duplicate(true),"score":c.score,"assessment":c.get("financing",{}).duplicate(true),"priority_value":c.get("priority_value",{}).duplicate(true),"reasons":c.reasons.duplicate()})
	return d
''')
(root/'src/planner_ai.gd').write_text(''.join(parts))
