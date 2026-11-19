extends SceneTree
var app
func _initialize() -> void: call_deferred("run")
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
	app.model.save_path="user://test_collection_v09.json"
	for id in range(5):
		app.model.reset(id,id)
		app.toggle_fast()
		for i in range(800):
			app.run_fast_steps()
			if not app.fast_mode: break
		assert(app.model.stage==4)
		if id==4:
			app.model.facet=app.model.tasks.size()-1
			app.model.angle=0.0
			app.model.pressure=1.8
			assert(app.model.make_edge_chip())
		assert(app.model.save_piece())
	var saved=app.model.collection.duplicate(true)
	app.model.reset(1,1)
	app.model.advance()
	app.model.advance()
	app.model.work(0.5)
	var original=app.model
	var volume: float=app.model.Solid.volume(app.model.body)
	app.show_collection()
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/v09-collection.png"))
	assert(app.collection_room.visible and not app.guide.busy)
	# Click newest gem in the actual scroll grid.
	await click(Vector2(230,265))
	assert(not app.collection_room.visible and app.active_workshop==original)
	assert(app.model.gem_id==4 and app.model.saved and app.model.stage==4)
	assert(app.model.body.any(func(f):return f.tag==-3),"Reopening preserves actual damaged planes")
	assert(absf(app.model.carats()-float(saved[4].carats))<0.011,"Reopening preserves carat weight")
	var reconstructed: Array=app.model.collection_body(saved[4])
	assert(absf(app.model.Solid.volume(reconstructed)-app.model.Solid.volume(app.model.body))<0.02)
	app.world.yaw=0.8
	app.world.light_mode=1
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/v09-collection-inspect.png"))
	await click(Vector2(1010,668))
	assert(app.collection_room.visible and app.model==original,"Back returns to collection and restores working stone")
	await click(Vector2(978,67))
	assert(not app.collection_room.visible and app.model==original)
	assert(absf(app.model.Solid.volume(app.model.body)-volume)<0.001,"Browsing never overwrites work in progress")
	var reloaded=app.Workshop.new()
	reloaded.save_path=app.model.save_path
	reloaded.load_collection()
	assert(reloaded.collection.size()==5 and reloaded.restore_piece(reloaded.collection[4]),"Works after restarting from saved collection")
	DirAccess.remove_absolute(app.model.save_path)
	app.sound.stop_all()
	app.queue_free()
	await process_frame
	print("COLLECTION / REAL THUMBNAILS / REOPEN / DAMAGE / RESTORE WORK / RELOAD: passed")
	quit()
