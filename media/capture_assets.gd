extends SceneTree
var app
var out: String
func _initialize() -> void: call_deferred("run")
func render_save(name: String) -> void:
 app.world._process(0.0)
 if app.exhibition.visible:app.exhibition.update_view()
 await process_frame
 await RenderingServer.frame_post_draw
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
 if app.exhibition.visible:app.exhibition.viewport.get_texture().get_image().save_png(out.path_join(name+"-gem.png"))
func complete(id: int,shape: int) -> void:
 app.model.reset(id,shape);app.toggle_fast()
 for i in range(800):
  app.run_fast_steps()
  if not app.fast_mode:break
  if i%20==0:await process_frame
 assert(app.model.stage==4)
 app.world.auto_rotate=false;app.world.yaw=.42;app.world.tilt=-1.0;app.world.zoom=1.0
func run() -> void:
 root.size=Vector2i(1120,720)
 out=ProjectSettings.globalize_path("res://../artifacts/media-assets")
 DirAccess.make_dir_recursive_absolute(out)
 app=load("res://main.tscn").instantiate();root.add_child(app)
 app.model.collection.clear();app.model.save_path="user://media_assets_temp.json"
 app.set_debug(false)
 for id in range(10):
  app.exhibition.close();app.model.reset(id,0);app.refresh()
  var view=SubViewport.new();view.size=Vector2i(284,207);view.transparent_bg=true;view.disable_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
  var raw=load(ProjectSettings.globalize_path("res://../media/rough_portrait.gd")).new()
  raw.model=app.model;raw.yaw=.4;raw.tilt=-.38;raw.displayed_color=app.model.GEMS[id].day
  view.add_child(raw)
  await process_frame;await RenderingServer.frame_post_draw
  await process_frame;await RenderingServer.frame_post_draw
  view.get_texture().get_image().save_png(out.path_join("raw-%d.png"%id))
  view.queue_free();await process_frame
 await render_save("workshop")
 for pair in [[3,1],[5,4],[0,1],[6,3],[7,5],[8,9],[9,8]]:
  app.exhibition.close();await complete(pair[0],pair[1]);app.world.light_mode=0
  await render_save("gem-%d"%pair[0])
  if pair[0]==0:
   app.world.light_mode=1;await render_save("alex-warm");app.world.light_mode=0
  assert(app.model.save_piece())
 app.show_collection();await render_save("collection")
 app.collection_room.hide();app.model.reset(0);app.refresh();app.open_character()
 await create_timer(1.6).timeout;await render_save("intro")
 app.guide.open_page();await render_save("story");app.guide.cancel()
 DirAccess.remove_absolute(app.model.save_path)
 app.sound.stop_all();app.queue_free();await process_frame
 print("MEDIA ASSETS: 10 raw minerals, 7 real cut gems, alex light pair, intro, story, collection")
 quit()
