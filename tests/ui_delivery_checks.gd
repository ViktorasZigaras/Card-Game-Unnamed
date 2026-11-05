extends SceneTree
var ui
var checks := 0
var failures: Array = []
var fx = preload('res://tests/flexible_fixture.gd').new()
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures.append(label)
func _initialize(): call_deferred('run')
func settle():
 for i in 6: await process_frame
func refresh():
 ui.session.frames = [ui.session.project()];ui.cursor=0;ui._draw()
func execute(action: Dictionary):
 var sim=ui.session.sim
 sim.state.actor=0;refresh()
 check(action in sim.legal_actions(),'fixture action legal '+str(action))
 ui._choose(ui.session.preview(action))
 check(ui.session.probe.failure=='','UI action keeps invariants')
func run():
 root.size=Vector2i(1920,1080)
 ui=load('res://ui/interface.tscn').instantiate();root.add_child(ui)
 ui.safe_actions=false
 await settle()
 check(root.get_visible_rect().encloses(ui.action_footer.get_global_rect()),'footer visible after layout settles')
 var s=ui.session.sim
 s.rules.town_wood_sweep=false
 fx.fund(s,'wood',8);fx.fund(s,'pop',5);fx.fund(s,'brick',1);fx.fund(s,'stone',2)
 s._gain_influence('blue',6,'fixture',[])
 fx.expose(s,'hut_1');execute({'type':'claim','building':'hut_1'})
 fx.expose(s,'hut_1');execute({'type':'contribute_upgrade','building':'hut_1','bundle':{'wood':1}})
 ui._select('building','hut_1');await settle()
 check(s.state.buildings.hut_1.level==1 and s.progress('hut_1').paid.wood==1,'partial upgrade retains old function')
 check(ui.town_view.project_costs.hut_1==s.cost_for('hut_1'),'map costs come from rules')
 check(s.remaining('hut_1').wood==1,'partial contribution paid once')
 fx.expose(s,'hut_1');execute({'type':'upgrade','building':'hut_1'})
 check(s.state.buildings.hut_1.level==2,'UI completes upgrade')
 for i in 6: execute({'type':'supply_wood'})
 ui._select('plot','stockade');await settle()
 check(s.state.town.wall_complete and ui.detail.get_parsed_text().contains('Complete:'),'completed stockade inspectable')
 check(not ui.detail.get_parsed_text().contains('{'),'normal feedback is readable')
 # Cost confirmation includes legal rival access and continuing obligations.
 var example={'action':{'type':'secure_contract','resource':'furniture'},'inputs':{'wood':2},'outputs':{},'plan':{'payments':{'red':2}},'commitments':{'pop':1},'recurring':{'upkeep':{'wood':1},'cadence':'round'}}
 var terms=ui._confirmation_text(example)
 check(terms.contains('2 influence to Red') and terms.contains('Held') and terms.contains('Ongoing upkeep'),'confirmation includes all cost categories')
 var snapshot=TownSimulation.canonical(s.snapshot())
 var invalid={'type':'claim_site','building':'marketplace','replace':'','plot':'N1'}
 check(not ui.session.step(invalid).ok and ui.session.probe.failure=='','invalid site rejected before probe')
 check(snapshot==TownSimulation.canonical(s.snapshot()),'rejected site leaves state and RNG unchanged')
 # Build catalogue explanations report the actual gate.
 s.state.actor=0;s.house('blue').inventory.influence=0;refresh()
 check(ui._build_blocked('marketplace').contains('influence'),'specific missing influence reason')
 # Exact overflow can be expanded without changing the economy.
 var visual=s.state.duplicate(true)
 visual.lots=[{'resource':'wood','amount':30,'reserved_for':'','released':false},{'resource':'wood','amount':2,'reserved_for':'red','released':false},{'resource':'grain','amount':1,'reserved_for':'blue','released':true}]
 for h in visual.houses:
  for r in h.stockpile: h.stockpile[r]=0
 visual.houses[0].stockpile.clay=3
 ui.goods_view.set_state(visual)
 check(ui.goods_view.represented_units==36,'public private reserved released quantities exact')
 var groups=preload('res://ui/goods_view.gd').groups(visual)
 check(groups.any(func(g): return g.resource=='grain' and g.holder==''),'released reservation becomes public')
 ui.goods_view.expanded_groups['Public supply:wood']=true;ui.goods_view.set_state(visual)
 check(ui.goods_view.displayed_units==36,'expanded goods show every unit')
 var strip=preload('res://ui/token_strip.gd').new();root.add_child(strip)
 strip.show_bundle({'wood':15},{'wood':4},'Committed')
 check(strip.exact_total==15,'cost overflow retains exact total')
 strip.expanded=true;strip.show_bundle({'wood':15},{'wood':4},'Committed')
 check(strip.get_child_count()==15,'expanded cost shows all silhouettes')
 # A pending confirmation cannot survive new-game/load navigation.
 ui.safe_actions=true;ui._review_type('pass')
 ui._new_game()
 check(ui.confirmation_entry.is_empty() and not ui.confirm_dialog.visible,'new game clears pending confirmation')
 var next=ui.session.sim.state.sequence
 ui.confirm_dialog.confirmed.emit()
 check(ui.session.sim.state.sequence==next,'stale confirmation cannot spend in a new game')
 # All archive screens remain inspectable after the new presentation.
 ui.safe_actions=false
 for frame in [0,9,40,82]:
  ui.archive=true;ui.cursor=frame;ui._draw();await settle()
  check(root.get_visible_rect().encloses(ui.action_footer.get_global_rect()),'archive footer fits '+str(frame))
 ui.archive=false;ui.cursor=ui.session.frames.size()-1;ui._draw()
 # Exercise broad live UI coverage across actual AI states; no policy edits.
 for i in 80:
  ui._ai_step()
  if i%10==0:
   for category in ['Build','Upgrade','Contracts','Trade']:
    ui._category(category);await settle()
    check(root.get_visible_rect().encloses(ui.action_footer.get_global_rect()),'live footer fits '+str(i)+' '+category)
 check(ui.session.probe.failure=='','80 live AI actions preserve invariants')
 var out={'checks':checks,'failures':failures}
 DirAccess.make_dir_recursive_absolute('res://experiments/ui_delivery')
 FileAccess.open('res://experiments/ui_delivery/results.json',FileAccess.WRITE).store_string(JSON.stringify(out,'\t'))
 print(JSON.stringify(out));quit(0 if failures.is_empty() else 1)
