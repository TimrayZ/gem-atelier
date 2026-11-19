extends SceneTree
var app
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> Image:
 app.world._process(1.0)
 if app.exhibition.visible: app.exhibition.update_view()
 await process_frame
 await RenderingServer.frame_post_draw
 await process_frame
 await RenderingServer.frame_post_draw
 var img: Image=root.get_texture().get_image()
 img.save_png(ProjectSettings.globalize_path("res://../artifacts/launch-"+name+".png"))
 return app.exhibition.viewport.get_texture().get_image() if app.exhibition.visible else img
func complete(id: int,shape: int) -> void:
 app.model.reset(id,shape)
 app.toggle_fast()
 for i in range(800):
  app.run_fast_steps()
  if not app.fast_mode: break
  if i%20==0: await process_frame
 assert(app.model.stage==4)
 app.world.auto_rotate=false
 app.world.yaw=.42
 app.world.tilt=-1.0
 app.world.zoom=1.0
func mean(img: Image) -> Vector3:
 var sum=Vector3.ZERO;var count=0
 for y in range(img.get_height()):
  for x in range(img.get_width()):
   var c=img.get_pixel(x,y)
   if c.a>.95: sum+=Vector3(c.r,c.g,c.b);count+=1
 return sum/maxf(count,1)
func colourful(img: Image) -> int:
 var count=0
 for y in range(img.get_height()):
  for x in range(img.get_width()):
   var c=img.get_pixel(x,y)
   if c.a>.95 and maxf(c.r,maxf(c.g,c.b))>.55 and maxf(c.r,maxf(c.g,c.b))-minf(c.r,minf(c.g,c.b))>.20:count+=1
 return count
func run() -> void:
 root.size=Vector2i(1120,720)
 app=load("res://main.tscn").instantiate();root.add_child(app)
 app.model.collection.clear();app.model.save_path="user://test_launch_v011.json"
 app.set_debug(false)
 assert(app.model.GEMS.size()>=13 and app.model.SHAPES.size()>=14)
 var renderer=preload("res://scripts/gem_renderer.gd")
 var test_material=ShaderMaterial.new()
 app.model.reset(2,0)
 var base_bands=app.model.Data.bands(2)
 renderer.configure(test_material,app.model,app.model.body,0.0,0.0,0,false,Vector2(100,100),1.0,Vector2.ONE,6)
 var pixel_bands: PackedFloat32Array=test_material.get_shader_parameter("absorption_bands")
 renderer.configure(test_material,app.model,app.model.body,0.0,0.0,0,true,Vector2(100,100),1.0,Vector2.ONE,6)
 var real_bands: PackedFloat32Array=test_material.get_shader_parameter("absorption_bands")
 assert(real_bands[12]>pixel_bands[12] and is_equal_approx(pixel_bands[12],base_bands[12]),"Each style can use a different absorption strength without changing the base spectrum")
 app.model.reset(3,0)
 renderer.configure(test_material,app.model,app.model.body,0.0,0.0,0,false,Vector2(100,100),1.0,Vector2.ONE,6)
 var diamond_pixel: PackedFloat32Array=test_material.get_shader_parameter("absorption_bands")
 renderer.configure(test_material,app.model,app.model.body,0.0,0.0,0,true,Vector2(100,100),1.0,Vector2.ONE,6)
 var diamond_real: PackedFloat32Array=test_material.get_shader_parameter("absorption_bands")
 assert(is_equal_approx(diamond_pixel[12],diamond_real[12]),"Colourless diamond stays neutral in both styles")
 for id in range(app.model.GEMS.size()):
  app.exhibition.close();app.model.reset(id,0);app.refresh()
  await snap("rough-%d"%id)
 app.open_character()
 await create_timer(1.8).timeout
 await snap("panpan-greeting")
 assert(app.guide.topic_data.key=="panpan-introduction")
 app.guide.open_page();await snap("panpan-story");app.guide.cancel()
 await complete(3,1)
 app.world.set_process(false);app.world.light_mode=0
 var diamond=await snap("diamond-day")
 app.world.light_mode=1
 var warm=await snap("diamond-warm")
 print("COLOURLESS DIAMOND day=",mean(diamond)," warm=",mean(warm))
 assert(absf(mean(diamond).x-mean(diamond).z)<.12,"No fixed blue diamond palette")
 assert(mean(warm).x>mean(warm).z+.04,"Colourless material follows source colour")
 var totals=[0,0]
 for material in [3,5]:
  app.model.gem_id=material
  app.world.light_mode=0
  for yaw in [.25,.75,1.2]:
   app.world.yaw=yaw
   var img=await snap("fire-%d-%.2f"%[material,yaw])
   totals[0 if material==3 else 1]+=colourful(img)
 print("SPECTRAL FIRE same geometry diamond/moissanite: ",totals)
 assert(totals[1]>totals[0],"Higher material dispersion broadens visible spectral regions across these poses")
 app.world.max_bounces=6
 var low=await snap("moissanite-6")
 app.world.max_bounces=20
 var high=await snap("moissanite-20")
 assert(low.get_data()!=high.get_data(),"Visible reflection choice affects pixel transport")
 assert(int(app.exhibition.gem_material.get_shader_parameter("max_bounces"))==20)
 app.exhibition.controls.quality.pressed.emit()
 assert(app.world.max_bounces==3,"Reflection control exposes the simpler 3-bounce mode")
 await snap("moissanite-3")
 assert(int(app.exhibition.gem_material.get_shader_parameter("max_bounces"))==3)
 app.exhibition.controls.quality.pressed.emit()
 assert(app.world.max_bounces==6,"Reflection control returns to the default")
 for pair in [[0,1],[6,3],[7,5],[8,9],[9,8],[5,4]]:
  app.exhibition.close();await complete(pair[0],pair[1])
  app.world.light_mode=0
  await snap("finished-%d"%pair[0])
  assert(app.model.save_piece())
 app.show_collection();await snap("collection")
 app.inspect_collected(0);assert(app.exhibition.visible)
 app.exhibition.go_back();assert(app.collection_room.visible)
 DirAccess.remove_absolute(app.model.save_path)
 app.sound.stop_all();app.queue_free();await process_frame
 print("TEN BY TEN / MINERALS / PANPAN / WHITE DIAMOND / MOISSANITE / REFLECTION LIMIT / COLLECTION: passed")
 quit()
