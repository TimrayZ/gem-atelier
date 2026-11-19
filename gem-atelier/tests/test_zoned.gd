extends SceneTree

func _initialize() -> void: call_deferred("run")

func frame(app) -> Image:
	app.exhibition.cached_key=[]
	app.exhibition.update_view()
	app.exhibition.viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	return app.exhibition.viewport.get_texture().get_image()

func run() -> void:
	root.size=Vector2i(1120,720)
	var app=load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.world.set_process(false)
	app.model.collection.clear()
	app.model.save_path="user://test_zoned_collection.json"
	app.world.light_mode=1
	app.world.advance_light(0.2)
	assert(app.world.light_weights.x>0.0 and app.world.light_weights.y>0.0,"Light switch passes smoothly through intermediate spectra")
	var mid: Vector3=app.world.light_weights
	app.world.light_mode=2
	app.world.advance_light(0.0)
	assert(app.world.light_weights.distance_to(mid)<0.0001,"Interrupting a transition does not jump")
	app.world.advance_light(1.0)
	assert(app.world.light_weights.distance_to(Vector3(0,0,1))<0.0001)
	app.world.light_mode=0
	app.world.advance_light(1.0)
	app.model.reset(3,4)
	assert(app.model.cut_difficulty()==4,"Hearts-and-arrows experiment is a four-star cut")
	for spec in [[10,13],[11,3],[12,3]]:
		app.exhibition.close()
		app.model.reset(spec[0],spec[1])
		assert(app.model.Data.bands(spec[0])!=app.model.Data.alternate_bands(spec[0]),"Zoned materials have two different absorption spectra")
		app.toggle_fast()
		for i in range(1000):
			app.run_fast_steps()
			if not app.fast_mode: break
		assert(app.model.stage==4 and not app.model.failed,"Zoned material finishes its recommended cut")
		for mode in [false,true]:
			app.world.real_mode=mode
			app.world.yaw=0.35
			app.world.tilt=-1.0
			var zoned_img=await frame(app)
			app.exhibition.gem_material.set_shader_parameter("zoned",false)
			app.exhibition.viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
			await process_frame
			await RenderingServer.frame_post_draw
			var unzoned_img: Image=app.exhibition.viewport.get_texture().get_image()
			assert(zoned_img.get_data()!=unzoned_img.get_data(),"Colour zones affect the actual image in each renderer")
		assert(app.model.save_piece(),"Zoned piece is collectible")
		var restored=load("res://scripts/workshop.gd").new()
		assert(restored.restore_piece(app.model.collection.back()) and restored.gem_id==spec[0],"Collection preserves zoned material identity")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(app.model.save_path))
	app.sound.stop_all()
	app.queue_free()
	await process_frame
	print("SMOOTH LIGHTS / ZONED MATERIALS / FOUR-STAR / COLLECTION: passed")
	quit()
