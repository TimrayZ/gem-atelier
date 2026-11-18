extends Control
var host
var seen: Dictionary={}
var busy := false
var elapsed := 0.0
var topic_data: Dictionary={}
var pending := Callable()
var greeting := false
var last_character := -1
var portrait: TextureRect
var bubble: Panel
var bubble_text: Label
var overlay: ColorRect
var page: Panel
var body_text: RichTextLabel
var title_text: Label
var detail_portrait: TextureRect
var debug_check: CheckBox
var voice: AudioStreamPlayer

func label_at(text: String,pos: Vector2,size_px: int) -> Label:
	var l:=Label.new()
	l.text=text
	l.position=pos
	l.add_theme_font_size_override("font_size",size_px)
	l.add_theme_color_override("font_color",Color("503b2e"))
	return l

func panel_style() -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=Color("f4e6c6")
	s.border_color=Color("886142")
	s.set_border_width_all(3)
	s.set_corner_radius_all(3)
	s.shadow_color=Color(0.15,0.08,0.04,0.3)
	s.shadow_size=7
	return s

func image_at(pos: Vector2,dim: Vector2) -> TextureRect:
	var p:=TextureRect.new()
	p.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.position=pos
	p.size=dim
	p.texture=preload("res://art/longlong-guide.png")
	p.set_deferred("size",dim)
	p.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return p

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait=image_at(Vector2(272,388),Vector2(140,174))
	portrait.mouse_filter=Control.MOUSE_FILTER_STOP
	portrait.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	portrait.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index==MOUSE_BUTTON_LEFT:
			if greeting: open_page()
			elif not busy: host.open_notes())
	add_child(portrait)
	var caption:=label_at("珑珑的旧书角",Vector2(280,553),12)
	caption.add_theme_color_override("font_color",Color("f3e7ce"))
	add_child(caption)
	caption.name="Caption"
	bubble=Panel.new()
	bubble.position=Vector2(396,430)
	bubble.size=Vector2(370,93)
	bubble.add_theme_stylebox_override("panel",panel_style())
	add_child(bubble)
	bubble_text=label_at("",Vector2(15,12),16)
	bubble_text.size=Vector2(340,70)
	bubble_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(bubble_text)
	bubble.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index==MOUSE_BUTTON_LEFT: open_page())
	bubble.hide()
	overlay=ColorRect.new()
	overlay.color=Color(0.12,0.08,0.04,0.48)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	page=Panel.new()
	page.position=Vector2(172,158)
	page.size=Vector2(776,406)
	page.add_theme_stylebox_override("panel",panel_style())
	overlay.add_child(page)
	detail_portrait=image_at(Vector2(18,83),Vector2(185,253))
	page.add_child(detail_portrait)
	var name_tag:=label_at("珑珑",Vector2(80,343),21)
	page.add_child(name_tag)
	page.add_child(label_at("守着爷爷的旧书，一起学。",Vector2(24,375),12))
	title_text=label_at("",Vector2(27,24),22)
	page.add_child(title_text)
	page.add_child(label_at("工坊手记 · 内容较长时可上下滚动",Vector2(225,58),11))
	body_text=RichTextLabel.new()
	body_text.position=Vector2(225,83)
	body_text.size=Vector2(520,220)
	body_text.add_theme_font_size_override("normal_font_size",17)
	body_text.add_theme_color_override("default_color",Color("594334"))
	body_text.bbcode_enabled=false
	page.add_child(body_text)
	var accept_button:=Button.new()
	accept_button.text="好，我们一起试试  →"
	accept_button.position=Vector2(516,345)
	accept_button.size=Vector2(229,40)
	accept_button.pressed.connect(accept)
	page.add_child(accept_button)
	var cancel_button:=Button.new()
	cancel_button.text="先放回书签"
	cancel_button.position=Vector2(225,345)
	cancel_button.size=Vector2(130,40)
	cancel_button.pressed.connect(cancel)
	page.add_child(cancel_button)
	debug_check=CheckBox.new()
	debug_check.text="调试：跳过简介，直接加工"
	debug_check.position=Vector2(225,313)
	debug_check.add_theme_font_size_override("font_size",12)
	debug_check.toggled.connect(func(value): host.set_debug(value))
	page.add_child(debug_check)
	overlay.hide()
	voice=AudioStreamPlayer.new()
	voice.stream=preload("res://audio/longlong-blip.wav")
	voice.volume_db=-19.0
	voice.max_polyphony=3
	add_child(voice)

func present(data: Dictionary, action: Callable=Callable()) -> void:
	cancel()
	topic_data=data
	pending=action
	busy=true
	greeting=true
	elapsed=0.0
	last_character=-1
	bubble_text.text=data.greeting
	bubble_text.visible_characters=0
	bubble.show()
	portrait.show()

func open_page() -> void:
	if not busy: return
	greeting=false
	bubble.hide()
	title_text.text=topic_data.title
	body_text.text=topic_data.body
	debug_check.set_pressed_no_signal(host.debug_mode)
	overlay.show()
	voice.stop()

func accept() -> void:
	if not busy: return
	seen[topic_data.key]=true
	var action:=pending
	cancel()
	if action.is_valid(): action.call_deferred()

func cancel() -> void:
	busy=false
	greeting=false
	pending=Callable()
	if is_instance_valid(bubble): bubble.hide()
	if is_instance_valid(overlay): overlay.hide()
	if is_instance_valid(voice): voice.stop()

func _process(delta: float) -> void:
	if host==null: return
	var on_bench: bool=host.model.stage!=4 or greeting
	portrait.visible=on_bench and not overlay.visible
	get_node("Caption").visible=portrait.visible
	portrait.position.y=388+sin(Time.get_ticks_msec()*0.002)*1.5
	if not busy or not greeting: return
	elapsed+=delta
	var count:=mini(topic_data.greeting.length(),int(elapsed/0.065))
	bubble_text.visible_characters=count
	if count!=last_character and count%2==0 and count<topic_data.greeting.length():
		if not host.mute and AudioServer.get_driver_name()!="Dummy":
			voice.pitch_scale=randf_range(0.92,1.48)
			voice.play()
	last_character=count
	portrait.position.y+=sin(elapsed*19)*2.0
	if elapsed>topic_data.greeting.length()*0.065+0.6: open_page()

func _exit_tree() -> void:
	if is_instance_valid(voice):
		voice.stop()
		voice.stream=null
