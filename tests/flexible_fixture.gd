extends RefCounted
func fund(s: FlexibleContractSimulation,r: String,n: int) -> void:
	s._add_lot(r,n,"","fixture",0)
	if r == "planks": s.state.houseworks.planks_made += n
	if r == "stone": s.state.project_metrics.stone_bought += n
	if r == "brick": s.state.capacity.kiln_bricks += n
func expose(s: FlexibleContractSimulation,id: String) -> void:
	for pile in [s.state.deck,s.state.discard,s.state.revealed]:
		while id in pile: pile.erase(id)
	s.state.revealed.append(id)
	s.state.used.erase(id)
func act(s: FlexibleContractSimulation,a: Dictionary,actor: int = 0) -> Dictionary:
	s.state.actor = actor
	return s.apply(a)
func build(s: FlexibleContractSimulation,id: String) -> void:
	var actor = 1 if id == "hall_red" else 2 if id == "hall_gold" else 0
	s._gain_influence(s.state.houses[actor].id,3,"fixture",[])
	for r in s.site_cost(id): fund(s,r,int(s.site_cost(id)[r]))
	var replacement = "marketplace" if id == "hall_red" and s.state.terrain_free.urban == 0 else ""
	if replacement != "": s._prestige("red",s.clear_price(replacement),"fixture",[])
	assert(act(s,{"type":"claim_site","building":id,"replace":replacement},actor).ok)
	expose(s,id)
	assert(act(s,{"type":"supply_site","building":id,"bundle":s.site_cost(id)},actor).ok)
func home(s: FlexibleContractSimulation,actor: int) -> void:
	var h: Dictionary = s.state.houses[actor]
	var id = "hut_%d" % (actor+1)
	s._gain_influence(h.id,3,"fixture",[])
	expose(s,id)
	assert(act(s,{"type":"claim","building":id},actor).ok)
	for r in s.rules.housing_upgrade_cost: fund(s,r,int(s.rules.housing_upgrade_cost[r]))
	expose(s,id)
	assert(act(s,{"type":"upgrade","building":id},actor).ok)
func wallet(s: FlexibleContractSimulation,cash: int,prestige: int) -> void:
	var h = s.house("blue")
	var delta = cash-int(h.inventory.gold)
	h.inventory.gold = cash
	s.state.trade.gold_minted += delta
	delta = prestige-int(h.inventory.prestige)
	if delta > 0: s._prestige("blue",delta,"fixture",[])
	elif delta < 0:
		h.inventory.prestige += delta
		s.state.ledger.prestige.consumed -= delta
func fixture(seed_value: int,bridge: bool,blue_home: bool = true) -> FlexibleContractSimulation:
	var s = FlexibleContractSimulation.new()
	s.batch = 3
	s.rules.town_wood_sweep = false
	s.start(seed_value)
	build(s,"marketplace")
	build(s,"hall_blue")
	if blue_home: home(s,0)
	if not bridge:
		home(s,1)
		home(s,2)
	s._gain_influence("blue",3,"fixture",[])
	expose(s,"lumber_camp")
	assert(act(s,{"type":"claim","building":"lumber_camp"}).ok)
	s.unlock_recipe("blue","brick")
	fund(s,"pop",3)
	wallet(s,5 if bridge else 3,8 if bridge else 12)
	assert(act(s,{"type":"launch_expedition"}).ok)
	for i in 6: s.apply({"type":"pass"})
	var t = s.trip_for("blue")
	assert(t.status == "trading")
	t.buy = [{"resource":"clay","price":1,"left":2,"contracted":false},{"resource":"stone","price":1,"left":2,"contracted":false}]
	t.sell = [{"resource":"wood","price":1,"left":0},{"resource":"grain","price":1,"left":0}]
	s.state.actor = 0
	assert(s.violations().is_empty(),str(s.violations()))
	return s
