extends Control
const Renderer=preload("res://scripts/gem_renderer.gd")
var host
var viewport: SubViewport
var optical: ColorRect
var gem_material: ShaderMaterial
var backdrop_material: ShaderMaterial
var display: TextureRect
var title: Label
var subtitle: Label
var controls: Dictionary={}
var dragging:=false
var cached_key: Array=[]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var bg:=ColorRect.new()
	bg.color=Color("d7dbce")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	title=Label.new()
	title.position=Vector2(30,24)
	title.add_theme_font_size_override("font_size",25)
	title.add_theme_color_override("font_color",Color("38473f"))
	add_child(title)
	subtitle=Label.new()
	subtitle.position=Vector2(31,72)
	subtitle.add_theme_color_override("font_color",Color("718078"))
	add_child(subtitle)
	var backdrop:=ColorRect.new()
	backdrop.position=Vector2(28,111)
	backdrop.size=Vector2(1064,518)
	backdrop_material=ShaderMaterial.new()
	backdrop_material.shader=load("res://shaders/exhibition_shadow.gdshader")
	backdrop.material=backdrop_material
	add_child(backdrop)
	viewport=SubViewport.new()
	viewport.transparent_bg=true
	viewport.disable_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(viewport)
	optical=ColorRect.new()
	gem_material=ShaderMaterial.new()
	optical.material=gem_material
	viewport.add_child(optical)
	display=TextureRect.new()
	display.position=backdrop.position
	display.size=backdrop.size
	display.mouse_filter=Control.MOUSE_FILTER_STOP
	display.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	display.texture=viewport.get_texture()
	add_child(display)
	make_button("day","日光 6500 K",28,136,func(): host.world.light_mode=0)
	make_button("warm","白炽灯 2850 K",174,156,func(): host.world.light_mode=1)
	make_button("neutral","中性光 4500 K",340,150,func(): host.world.light_mode=2)
	make_button("style","",500,154,toggle_style)
	make_button("spin","",664,122,func(): host.world.auto_rotate=not host.world.auto_rotate)
	make_button("save","收藏作品",796,146,func(): host.on_primary())
	make_button("back","",952,140,go_back)
	make_button("quality","",952,140,func(): host.world.max_bounces={6:12,12:20,20:6}.get(host.world.max_bounces,12))
	controls.quality.position.y=29
	controls.quality.tooltip_text="两种通道都使用此上限；6 次较快，12/20 次保留更多内部光路。"
	hide()

func make_button(id: String, text: String, x: int, width: int, callback: Callable) -> void:
	var b:=Button.new()
	b.position=Vector2(x,649)
	b.size=Vector2(width,39)
	b.text=text
	b.pressed.connect(callback)
	add_child(b)
	controls[id]=b

func open() -> void:
	if host.model.stage!=4: return
	dragging=false
	host.world.large_view_active=true
	cached_key.clear()
	show()
	update_view()

func close() -> void:
	host.world.large_view_active=false
	dragging=false
	hide()
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	if is_instance_valid(host.world.optics_display): host.world.optics_display.visible=host.world.optics.visible

func go_back() -> void:
	close()
	if host.active_workshop!=null: host.show_collection()

func toggle_style() -> void:
	host.world.real_mode=not host.world.real_mode
	cached_key.clear()
	host.refresh()

func handle_event(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE: go_back()
			KEY_R: toggle_style()
			KEY_1,KEY_2,KEY_3: host.world.light_mode=event.keycode-KEY_1
			KEY_H,KEY_J:
				host.world.auto_rotate=false
				host.world.yaw=0.0
				host.world.tilt=-PI/2 if event.keycode==KEY_H else PI/2
		host.get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			if not event.pressed: dragging=false
			elif Rect2(display.position,display.size).has_point(event.position):
				dragging=true
				host.world.auto_rotate=false
		if event.pressed and Rect2(display.position,display.size).has_point(event.position) and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			host.world.zoom=clampf(host.world.zoom+(0.08 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -0.08),0.7,1.65)
	if event is InputEventMouseMotion and dragging:
		host.world.yaw+=event.relative.x*0.008
		host.world.tilt=clampf(host.world.tilt+event.relative.y*0.006,-1.5,1.5)

func _process(_delta: float) -> void:
	if visible: update_view()

func update_view() -> void:
	var m=host.model
	var w=host.world
	title.text="%s  /  %s · %.2f ct"%[m.GEMS[m.gem_id].name,m.cut_name(),m.carats()]
	subtitle.text="%s · 拖动旋转 · 滚轮缩放 · 1/2/3 换光 · R 换风格 · 缺角 %d"%[["日光","白炽灯","中性光"][w.light_mode],m.chips.size()]
	for i in range(3): controls[["day","warm","neutral"][i]].modulate=Color.WHITE if w.light_mode==i else Color("baaa8b")
	controls.quality.visible=true
	controls.quality.text="反射上限 · %d"%w.max_bounces
	controls.style.text="风格 · "+("真实" if w.real_mode else "像素")
	controls.spin.text="旋转 · "+("开" if w.auto_rotate else "关")
	controls.save.text="已收藏 ✓" if m.saved else "收藏作品"
	controls.save.disabled=m.saved
	controls.back.text="返回收藏室" if host.active_workshop!=null else "返回工坊"
	var key: Array=[m.generation,m.gem_id,m.revision,w.yaw,w.tilt,w.light_mode,w.real_mode,w.zoom,w.max_bounces,w.inclusion_enabled,m.thermal_damage]
	if key==cached_key: return
	cached_key=key
	var bounding_radius := 0.0
	var rotated_planes := PackedVector4Array()
	for face in m.body:
		var normal: Vector3 = face.n.rotated(Vector3.UP,w.yaw).rotated(Vector3.RIGHT,w.tilt)
		rotated_planes.append(Vector4(normal.x,normal.y,normal.z,face.d))
		for vertex in face.v:
			bounding_radius=maxf(bounding_radius,vertex.length())
	# A rotation-independent bound keeps the gem's centre and scale stable.
	var perspective_radius: float = bounding_radius*220.0/sqrt(maxf(10000.0,220.0*220.0-bounding_radius*bounding_radius))
	var scale: float = minf(2.8*w.zoom,88.0/maxf(perspective_radius,1.0))
	var floor_y: float = 0.91
	backdrop_material.set_shader_parameter("rotation_angle",w.yaw)
	backdrop_material.set_shader_parameter("floor_y",floor_y)
	backdrop_material.set_shader_parameter("floor_width",clampf(perspective_radius*scale/425.0,0.08,0.4))
	backdrop_material.set_shader_parameter("receiver_y",bounding_radius+24.0/maxf(scale,0.01))
	backdrop_material.set_shader_parameter("illuminant",w.light_mode)
	var tint: Color = m.GEMS[m.gem_id][["day","warm","neutral"][w.light_mode]]
	if m.gem_id in [3,5]: tint=Color.WHITE
	backdrop_material.set_shader_parameter("material_tint",Vector3(tint.r,tint.g,tint.b))
	backdrop_material.set_shader_parameter("pixel_style",not w.real_mode)
	backdrop_material.set_shader_parameter("plane_count",mini(rotated_planes.size(),256))
	rotated_planes.resize(256)
	backdrop_material.set_shader_parameter("planes",rotated_planes)
	viewport.size=Vector2i(1064,518) if w.real_mode else Vector2i(532,259)
	optical.size=Vector2(viewport.size)
	var logical:=Vector2(1064.0/518.0*207.0,207)
	Renderer.configure(gem_material,m,m.body,w.yaw,w.tilt,w.light_mode,w.real_mode,logical,scale,logical/Vector2(viewport.size),w.max_bounces)
	gem_material.set_shader_parameter("center",Vector2(logical.x*0.5,logical.y*0.44))
	if w.real_mode:
		var inclusions:=PackedVector4Array()
		for point in [Vector3(-6,-4,8),Vector3(9,8,-6),Vector3(-11,12,4)]:
			var v: Vector3=point.rotated(Vector3.UP,w.yaw).rotated(Vector3.RIGHT,w.tilt)
			inclusions.append(Vector4(v.x,v.y,v.z,0.55 if m.gem_id==3 else 1.2))
		gem_material.set_shader_parameter("inclusions",inclusions)
		gem_material.set_shader_parameter("inclusion_count",(1 if m.gem_id==3 else 3) if w.inclusion_enabled else 0)
		gem_material.set_shader_parameter("scattering_strength",0.00003+m.thermal_damage*0.00002)
		gem_material.set_shader_parameter("surface_roughness",0.004+minf(0.06,m.thermal_damage*0.0015))
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
