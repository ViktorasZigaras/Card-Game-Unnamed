extends SceneTree
var ui
var fx = preload('res://tests/flexible_fixture.gd').new()
func _initialize(): call_deferred('run')
func shot(path):
 for i in 6: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
func refresh():
 ui.session.frames=[ui.session.project()];ui.cursor=0;ui._draw()
func act(a):
 ui.session.sim.state.actor=0;refresh();ui._choose(ui.session.preview(a))
func run():
 root.size=Vector2i(1920,1080)
 ui=load('res://ui/interface.tscn').instantiate();root.add_child(ui)
 ui.safe_actions=false
 await shot('res://docs/images/ui_0_910_opening.png')
 var s=ui.session.sim;s.rules.town_wood_sweep=false
 s._gain_influence('blue',6,'fixture',[])
 fx.fund(s,'pop',5);fx.fund(s,'wood',10);refresh()
 ui._category('Build');ui.catalogue_building='marketplace';ui._draw_detail()
 var entry=ui._m().legal.filter(func(e): return e.action.type=='claim_site' and e.action.building=='marketplace' and e.action.replace=='')[0]
 ui._choose(entry)
 await shot('res://docs/images/ui_0_910_build.png')
 ui._map_choice('plot',ui.town_view.eligible_plots[-1])
 fx.expose(s,'marketplace');act({'type':'supply_site','building':'marketplace','bundle':{'wood':1}})
 ui._select('building','marketplace')
 await shot('res://docs/images/ui_0_910_progress.png')
 fx.expose(s,'marketplace');act({'type':'supply_site','building':'marketplace','bundle':s.site_remaining('marketplace')})
 for i in 6: act({'type':'supply_wood'})
 # Advance to the actual scheduled caravan; fixture money permits real offers.
 fx.wallet(s,4,4)
 for i in 3: s.apply({'type':'pass'})
 s.state.actor=0;refresh();ui._category('Trade')
 await shot('res://docs/images/ui_0_910_trade.png')
 ui._select('building','carpenter')
 DirAccess.make_dir_recursive_absolute('res://build/motion')
 var before=TownSimulation.canonical(s.snapshot())
 for i in 16:
  await create_timer(.125).timeout
  await shot('res://build/motion/frame_%02d.png'%i)
 assert(before==TownSimulation.canonical(s.snapshot()),'Rendered animation must not change simulation RNG')
 print('Captured 4 gameplay screens and 16 motion frames; motion leaves simulation unchanged.')
 quit()
