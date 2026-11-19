extends Control
const Solid=preload("res://scripts/solid_geometry.gd")
var host
var grid: GridContainer
var subtitle: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var bg:=ColorRect.new()
	bg.color=Color("d7dbce")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title:=Label.new()
	title.text="我的收藏室"
	title.position=Vector2(62,40)
	title.add_theme_font_size_override("font_size",30)
	title.add_theme_color_override("font_color",Color("38473f"))
	add_child(title)
	subtitle=Label.new()
	subtitle.position=Vector2(65,90)
	subtitle.add_theme_color_override("font_color",Color("718078"))
	add_child(subtitle)
	var back:=Button.new()
	back.text="回到工坊  →"
	back.position=Vector2(893,46)
	back.size=Vector2(165,43)
	back.pressed.connect(hide)
	add_child(back)
	var frame:=Panel.new()
	frame.position=Vector2(57,137)
	frame.size=Vector2(1006,518)
	var rim:=StyleBoxFlat.new()
	rim.bg_color=Color("77583f")
	rim.border_color=Color("ae8e59")
	rim.set_border_width_all(5)
	rim.set_corner_radius_all(12)
	frame.add_theme_stylebox_override("panel",rim)
	add_child(frame)
	var cloth:=ColorRect.new()
	cloth.position=Vector2(69,149)
	cloth.size=Vector2(982,494)
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://shaders/velvet.gdshader")
	cloth.material=mat
	add_child(cloth)
	var scroll:=ScrollContainer.new()
	scroll.position=Vector2(88,164)
	scroll.size=Vector2(946,461)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	grid=GridContainer.new()
	grid.columns=3
	grid.add_theme_constant_override("h_separation",18)
	grid.add_theme_constant_override("v_separation",18)
	scroll.add_child(grid)
	var hint:=Label.new()
	hint.text="点击宝石，重新拿到灯下看看。  /  Click a gem to inspect it again."
	hint.position=Vector2(66,676)
	hint.add_theme_color_override("font_color",Color("718078"))
	add_child(hint)
	hide()

func open() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	subtitle.text="%d 件亲手切出的作品 · 切形与缺角都会留下"%host.model.collection.size()
	if host.model.collection.is_empty():
		var empty:=Label.new()
		empty.text="绒布已经铺好了。\n\n加工完第一颗宝石，点击“收藏真实切工”，它就会摆在这里。"
		empty.custom_minimum_size=Vector2(900,320)
		empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color",Color("d7d5bd"))
		grid.add_child(empty)
	for i in range(host.model.collection.size()-1,-1,-1):
		add_piece(i)
	show()

func add_piece(index: int) -> void:
	var entry: Dictionary=host.model.collection[index]
	var gem_id:=int(entry.gem_id)
	var card:=Button.new()
	card.custom_minimum_size=Vector2(294,214)
	card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	card.tooltip_text="重新查看这颗宝石；不会覆盖工坊中正在加工的原石。"
	for state in ["normal","hover","pressed","focus"]:
		var style:=StyleBoxFlat.new()
		style.bg_color=Color(0.05,0.08,0.075,0.08 if state=="normal" else 0.28)
		style.border_color=Color(0.72,0.65,0.45,0.0 if state=="normal" else 0.6)
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		card.add_theme_stylebox_override(state,style)
	card.pressed.connect(func(): host.inspect_collected(index))
	grid.add_child(card)
	# One-shot spectral thumbnails use the stored boundary, including defects.
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(264,160)
	viewport.transparent_bg=true
	viewport.disable_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	card.add_child(viewport)
	var optical:=ColorRect.new()
	optical.size=Vector2(264,160)
	var material:=ShaderMaterial.new()
	var sample={"gem_id":gem_id,"GEMS":host.model.GEMS,"Data":host.model.Data}
	preload("res://scripts/gem_renderer.gd").configure(material,sample,host.model.collection_body(entry),0.35,-0.9,0,false,Vector2(264.0/160.0*207.0,207),1.6,Vector2(207.0/160.0,207.0/160.0))
	optical.material=material
	viewport.add_child(optical)
	var shadow:=Polygon2D.new()
	shadow.polygon=PackedVector2Array([Vector2(87,107),Vector2(111,101),Vector2(174,101),Vector2(207,108),Vector2(180,116),Vector2(111,115)])
	shadow.color=Color(0.025,0.045,0.04,0.48)
	card.add_child(shadow)
	var image:=TextureRect.new()
	image.position=Vector2(15,0)
	image.size=Vector2(264,160)
	image.texture=viewport.get_texture()
	image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.add_child(image)
	var caption:=Label.new()
	caption.position=Vector2(10,155)
	caption.size=Vector2(274,54)
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.text="%s · %.2f ct\n%s"%[host.model.GEMS[gem_id].name,float(entry.carats),str(entry.get("shape","早期收藏"))]
	caption.add_theme_font_size_override("font_size",13)
	caption.add_theme_color_override("font_color",Color("e5dcc1"))
	caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.add_child(caption)
