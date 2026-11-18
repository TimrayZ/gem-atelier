extends SceneTree
var app
var fails := 0
func _initialize() -> void: call_deferred("run")
func frame(name: String) -> Image:
	app.world._process(0.0)
	app.world.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image().get_region(Rect2i(266,162,568,414))
	img.save_png(ProjectSettings.globalize_path("res://../artifacts/"+name+".png"))
	return img
func run() -> void:
	root.size=Vector2i(1120,720)
	app=load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_debug(true)
	app.toggle_fast()
	for i in range(400):
		app.run_fast_steps()
		if not app.fast_mode: break
	app.world.set_process(false)
	app.world.auto_rotate=false
	app.world.t=0
	app.world.yaw=0.35
	app.world.tilt=-1.0
	var images: Array = []
	for mode in range(3):
		app.world.light_mode=mode
		images.append(await frame("v04-alex-%d"%mode))
	app.model.gem_id=1
	app.world.light_mode=0
	var other: Image = await frame("v04-amethyst")
	var mismatch := 0
	for x in range(568):
		for y in range(414):
			if x>130 and x<440 and y>40 and y<320: continue
			if images[0].get_pixel(x,y)!=other.get_pixel(x,y): mismatch+=1
	print("BACKGROUND material-dependent pixels: ",mismatch)
	assert(mismatch==0,"Backdrop must never inherit gemstone material color")
	app.model.gem_id=0
	app.world.yaw+=0.7
	var rotated: Image = await frame("v04-alex-rotated")
	assert(rotated.get_data()!=images[0].get_data(),"Rotating changes optical paths")
	app.sound.stop_all()
	await create_timer(0.15).timeout
	app.queue_free()
	await process_frame
	print("OPTICAL VIEW: passed")
	quit()
