extends SceneTree
var app
func _initialize() -> void: call_deferred("run")
func frame(name: String) -> Image:
	app.refresh()
	app.world._process(0.0)
	app.world.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img:=root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://../artifacts/v06-"+name+".png"))
	return img
func run() -> void:
	root.size=Vector2i(1120,720)
	app=load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_debug(true)
	app.world.set_process(false)
	app.world.auto_rotate=false
	app.world.t=0
	var signatures: Array=[]
	for id in range(5):
		app.model.rough_kind=0
		app.model.reset(id)
		assert(not app.model.crust,"Primary crystals do not all have a rind")
		assert(app.model.body.all(func(f):return f.tag==-1),"Natural faces are not processed facets")
		signatures.append(app.model.body.size())
		await frame("raw-%d"%id)
	assert(signatures[3]==8,"Diamond rough is octahedral")
	assert(signatures[1]!=signatures[2],"Quartz prism differs from corundum barrel")
	app.model.rough_kind=1
	app.model.reset(2)
	assert(app.model.crust,"Weathered example can carry rind")
	await frame("worn-sapphire")
	app.model.rough_kind=0
	app.model.reset(1,1)
	app.toggle_fast()
	for i in range(600):
		app.run_fast_steps()
		if not app.fast_mode: break
	assert(app.model.stage==4)
	app.world.auto_rotate=false
	app.world.yaw=0.35
	app.world.tilt=-0.65
	app.world.inclusion_enabled=false
	var clean: Image=await frame("perspective-clean")
	app.world.inclusion_enabled=true
	var included: Image=await frame("perspective-inclusions")
	assert(clean.get_data()!=included.get_data(),"Spatial inclusion segments affect transmitted rays")
	app.world.yaw+=0.4
	await frame("perspective-rotated")
	app.sound.stop_all()
	await create_timer(0.15).timeout
	app.queue_free()
	await process_frame
	print("NATURAL STOCK / PERSPECTIVE / SPATIAL INCLUSIONS: passed")
	quit()
