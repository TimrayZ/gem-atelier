extends SceneTree
var app
func _initialize() -> void: call_deferred("run")
func finish(id: int, shape: int) -> void:
	app.model.reset(id,shape)
	app.toggle_fast()
	for i in range(800):
		app.run_fast_steps()
		if not app.fast_mode: break
		if i%20==0: await process_frame
	assert(app.model.stage==4 and app.exhibition.visible,"Finished pieces open the large exhibition")
	app.world.auto_rotate=false
	app.world.t=0.0
	app.world.yaw=0.42
	app.world.tilt=-1.0
	app.world.zoom=1.0

func capture(name: String) -> Image:
	app.exhibition.update_view()
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/"+name+".png"))
	return app.exhibition.viewport.get_texture().get_image()

func stats(img: Image) -> Dictionary:
	var sum:=Vector3.ZERO
	var count:=0
	var fire:=0
	var colours: Dictionary={}
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c:=img.get_pixel(x,y)
			if c.a<0.95: continue
			count+=1
			sum+=Vector3(c.r,c.g,c.b)
			colours[c.to_rgba32()]=true
			if (c.r>0.95 and c.g>0.6 and c.b<0.4) or (c.b>0.95 and c.g>0.85 and c.r<0.6): fire+=1
	return {"mean":sum/maxf(1,count),"fire":fire,"colours":colours.size(),"pixels":count}

func click(at: Vector2) -> void:
	for down in [true,false]:
		var e:=InputEventMouseButton.new()
		e.position=at
		e.global_position=at
		e.button_index=MOUSE_BUTTON_LEFT
		e.pressed=down
		Input.parse_input_event(e)
		await process_frame

func run() -> void:
	root.size=Vector2i(1120,720)
	app=load("res://main.tscn").instantiate()
	root.add_child(app)
	app.model.collection.clear()
	assert(not app.world.real_mode,"Pixel materials are the default")
	await finish(0,1)
	app.world.set_process(false)
	app.world.light_mode=0
	var day:=await capture("v10-alex-day")
	await click(Vector2(240,668))
	assert(app.world.light_mode==1)
	var warm:=await capture("v10-alex-warm")
	print("ALEX DAY ",stats(day)," WARM ",stats(warm))
	assert(stats(day).mean.y>stats(day).mean.x+0.10,"Daylight alexandrite is predominantly green")
	assert(stats(warm).mean.x>stats(warm).mean.y+0.10,"Warm-source alexandrite is predominantly red-purple")
	assert(day.get_data()!=warm.get_data(),"Same gemstone changes under the source SPD")
	app.exhibition.close()
	await finish(3,1)
	app.world.light_mode=0
	var diamond:=await capture("v10-diamond")
	print("DIAMOND ",stats(diamond))
	var down:=InputEventMouseButton.new()
	down.position=Vector2(550,370)
	down.button_index=MOUSE_BUTTON_LEFT
	down.pressed=true
	Input.parse_input_event(down)
	await process_frame
	var motion:=InputEventMouseMotion.new()
	motion.position=Vector2(594,370)
	motion.relative=Vector2(44,0)
	Input.parse_input_event(motion)
	await process_frame
	var up:=InputEventMouseButton.new()
	up.position=Vector2(1110,710)
	up.button_index=MOUSE_BUTTON_LEFT
	up.pressed=false
	Input.parse_input_event(up)
	await process_frame
	assert(app.world.yaw>0.7 and not app.exhibition.dragging,"Dragging rotates and release outside ends dragging")
	var rotated:=await capture("v10-diamond-rotated")
	print("ROTATED ",stats(rotated))
	assert(diamond.get_data()!=rotated.get_data(),"Rotation changes real ray exits")
	assert(stats(diamond).fire>10 or stats(rotated).fire>10,"Dispersed rays create visible fire regions")
	assert(stats(diamond).colours<100,"Material uses a limited palette")
	var pixel_start:=Time.get_ticks_msec()
	for i in range(20):
		app.world.yaw+=0.01
		app.exhibition.update_view()
		await process_frame
		await RenderingServer.frame_post_draw
	print("PIXEL LARGE VIEW 20 rotating frames: ",Time.get_ticks_msec()-pixel_start," ms")
	# Actual style button changes both the material and viewport quality.
	await click(Vector2(575,668))
	assert(app.world.real_mode)
	var real_image:=await capture("v10-real")
	assert(app.exhibition.viewport.size==Vector2i(1064,518))
	assert(stats(real_image).colours>stats(diamond).colours*5,"Real transport retains continuous spectral colours")
	var background: Image=root.get_texture().get_image()
	assert(background.get_pixel(40,125)==background.get_pixel(1065,610),"Real channel has a single solid background")
	# Return through the actual GUI, then reopen from the compact viewer.
	await click(Vector2(1020,668))
	assert(not app.exhibition.visible and app.model.stage==4)
	app.buttons.enlarge.emit_signal("pressed")
	assert(app.exhibition.visible)
	app.exhibition.close()
	app.sound.stop_all()
	app.queue_free()
	await process_frame
	print("PIXEL DEFAULT / ALEX SPD / ROTATION FIRE / LARGE VIEW / REAL TOGGLE / PLAIN BACKGROUND: passed")
	quit()
