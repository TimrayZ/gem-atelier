extends SceneTree
var app
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/"+name+".png"))
 print("PROTOTYPE ",name)
func run() -> void:
 root.size=Vector2i(1120,720)
 app=load("res://main.tscn").instantiate()
 root.add_child(app)
 app.set_debug(false)
 app.model.collection.clear()
 app.model.reset(3,1)
 app.toggle_fast()
 for i in range(800):
  app.run_fast_steps()
  if not app.fast_mode: break
  if i%20==0: await process_frame
 app.set_process(false)
 app.world.set_process(false)
 app.world.auto_rotate=false
 app.world.yaw=0.42
 app.world.tilt=-1.0
 app.world.zoom=1.42
 app.world.t=0.0
 app.world.light_mode=0
 app.world.max_bounces=12
 app.toast_time=0.0
 app.refresh()
 app.world._process(0.0)
 await snap("style-smooth")
 var pixel=ShaderMaterial.new()
 pixel.shader=load(ProjectSettings.globalize_path("res://../docs/prototypes/pixel_present.gdshader"))
 app.world.optics_display.material=pixel
 await snap("style-pixel-2")
 pixel.set_shader_parameter("block_size",3)
 await snap("style-pixel-3")
 # Layout study only: larger observation area, neutral cloth, compact controls.
 var overlay=Control.new()
 overlay.size=Vector2(1120,720)
 app.add_child(overlay)
 var bg=ColorRect.new()
 bg.size=Vector2(1120,720)
 bg.color=Color("dfccaa")
 overlay.add_child(bg)
 var caption=Label.new()
 caption.text="光影展台    /    钻石 · 椭圆刻面 · 0.97 ct"
 caption.position=Vector2(32,29)
 caption.add_theme_font_size_override("font_size",24)
 caption.add_theme_color_override("font_color",Color("4b3629"))
 overlay.add_child(caption)
 var subtitle=Label.new()
 subtitle.text="大展台布局与像素输出研究 · 尚未接入游戏"
 subtitle.position=Vector2(34,71)
 subtitle.add_theme_color_override("font_color",Color("8a745a"))
 overlay.add_child(subtitle)
 var cloth=ColorRect.new()
 cloth.position=Vector2(28,110)
 cloth.size=Vector2(1064,518)
 var mat=ShaderMaterial.new()
 var code=FileAccess.get_file_as_string("res://shaders/velvet.gdshader")
 code=code.replace("vec2 p=UV*vec2(980.0,480.0);","vec2 p=(floor(UV*vec2(1064.0,518.0)/2.0)+vec2(0.5))*2.0;")
 var cloth_shader=Shader.new()
 cloth_shader.code=code
 mat.shader=cloth_shader
 cloth.material=mat
 overlay.add_child(cloth)
 var shadow=TextureRect.new()
 shadow.position=Vector2(320,548)
 shadow.size=Vector2(480,30)
 var gradient=Gradient.new()
 gradient.colors=PackedColorArray([Color(0,0,0,0.26),Color.TRANSPARENT])
 var shadow_texture=GradientTexture2D.new()
 shadow_texture.gradient=gradient
 shadow_texture.fill=GradientTexture2D.FILL_RADIAL
 shadow_texture.fill_from=Vector2(0.5,0.5)
 shadow_texture.fill_to=Vector2(1.0,0.5)
 shadow.texture=shadow_texture
 overlay.add_child(shadow)
 var optical: ColorRect=app.world.optics
 var view: SubViewport=optical.get_viewport()
 view.size=Vector2i(1064,518)
 optical.size=Vector2(1064,518)
 var optics_code=FileAccess.get_file_as_string("res://shaders/gem_optics.gdshader")
 optics_code=optics_code.replace("UV*vec2(284.0,207.0)","UV*vec2(425.1892,207.0)")
 var optics_shader=Shader.new()
 optics_shader.code=optics_code
 app.world.optics_material.shader=optics_shader
 app.world.optics_material.set_shader_parameter("center",Vector2(212.5946,104.0))
 app.world.optics_material.set_shader_parameter("gem_scale",3.0)
 app.world.optics_material.set_shader_parameter("pixel_footprint",Vector2(207.0/518.0,207.0/518.0))
 var display=TextureRect.new()
 display.position=Vector2(28,110)
 display.size=Vector2(1064,518)
 display.texture=view.get_texture()
 pixel.set_shader_parameter("block_size",2)
 display.material=pixel
 display.mouse_filter=Control.MOUSE_FILTER_IGNORE
 overlay.add_child(display)
 var controls=HBoxContainer.new()
 controls.position=Vector2(30,648)
 controls.add_theme_constant_override("separation",12)
 overlay.add_child(controls)
 for text in ["日光 6500 K","白炽灯 2850 K","中性光 4500 K","风格 · 像素","收藏作品","返回工坊"]:
  var button=Button.new()
  button.text=text
  button.custom_minimum_size=Vector2(160,39)
  controls.add_child(button)
 await snap("style-large-study")
 app.sound.stop_all()
 app.queue_free()
 await process_frame
 quit()
