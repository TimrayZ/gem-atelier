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
 subtitle.text="插画式材质研究 · 从刻面色块与高光重新着色 · 尚未接入"
 subtitle.position=Vector2(34,71)
 subtitle.add_theme_color_override("font_color",Color("8a745a"))
 overlay.add_child(subtitle)
 var cloth=ColorRect.new()
 cloth.position=Vector2(28,110)
 cloth.size=Vector2(1064,518)
 var mat=ShaderMaterial.new()
 var code="shader_type canvas_item; void fragment(){ vec2 p=floor(UV*vec2(266.0,130.0)); float v=0.5+0.5*sin(p.x*0.035+sin(p.y*0.025)); vec3 c=vec3(0.12,0.20,0.22); if(v>0.55)c=vec3(0.14,0.22,0.24); COLOR=vec4(c,1.0); }"
 var cloth_shader=Shader.new()
 cloth_shader.code=code
 mat.shader=cloth_shader
 cloth.material=mat
 overlay.add_child(cloth)
 var shadow=Polygon2D.new()
 shadow.polygon=PackedVector2Array([Vector2(342,570),Vector2(392,550),Vector2(520,542),Vector2(668,551),Vector2(762,575),Vector2(714,596),Vector2(558,607),Vector2(402,596)])
 shadow.color=Color("172d35")
 overlay.add_child(shadow)
 var shadow_core=Polygon2D.new()
 shadow_core.polygon=PackedVector2Array([Vector2(411,572),Vector2(480,557),Vector2(606,558),Vector2(685,574),Vector2(610,590),Vector2(490,590)])
 shadow_core.color=Color("12252c")
 overlay.add_child(shadow_core)
 var optical: ColorRect=app.world.optics
 var view: SubViewport=optical.get_viewport()
 view.size=Vector2i(1064,518)
 optical.size=Vector2(1064,518)
 app.world.optics_material.shader=load(ProjectSettings.globalize_path("res://../docs/prototypes/gem_illustrated.gdshader"))
 app.world.optics_material.set_shader_parameter("center",Vector2(212.5946,104.0))
 app.world.optics_material.set_shader_parameter("gem_scale",3.0)
 var display=TextureRect.new()
 display.position=Vector2(28,110)
 display.size=Vector2(1064,518)
 display.texture=view.get_texture()
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
 await snap("illustrated-diamond")
 app.world.optics_material.set_shader_parameter("material_id",2)
 app.world.optics_material.set_shader_parameter("refractive_index",app.model.GEMS[2].ri)
 app.world.optics_material.set_shader_parameter("dispersion",app.model.GEMS[2].dispersion)
 app.world.optics_material.set_shader_parameter("absorption_bands",app.model.Data.bands(2))
 app.world.optics_material.set_shader_parameter("art_dark",Vector3(0.04,0.10,0.29))
 app.world.optics_material.set_shader_parameter("art_mid",Vector3(0.15,0.34,0.77))
 app.world.optics_material.set_shader_parameter("art_light",Vector3(0.40,0.60,0.95))
 app.world.optics_material.set_shader_parameter("art_edge",Vector3(0.35,0.52,0.86))
 app.world.optics_material.set_shader_parameter("art_white",Vector3(0.84,0.94,1.0))
 caption.text="光影展台    /    同一切形的蓝宝石材质对照"
 await snap("illustrated-sapphire")
 app.sound.stop_all()
 app.queue_free()
 await process_frame
 quit()
