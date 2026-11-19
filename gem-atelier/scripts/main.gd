extends Control

const Workshop = preload("res://scripts/workshop.gd")
const PixelWorld = preload("res://scripts/pixel_world.gd")
const BG := Color("e3d3b0")
const PANEL := Color("f4e7c9")
const LINE := Color("b29873")
const WHITE := Color("4b3629")
const MUTED := Color("8a745a")
const MINT := Color("6d805c")
const GOLD := Color("9c663a")
const STAGE_NAMES = ["挑选原石", "装夹定位", "刻面切割", "细磨抛光", "光影展台"]
const STAGE_EN = ["THE ROUGH", "THE SETUP", "THE CUT", "THE POLISH", "THE REVEAL"]

const Dialogue=preload("res://dialogue/longlong.gd")
var guide
var debug_mode := false
var debug_checkbox: CheckBox
var sound
var fast_mode := false
var bgm_enabled := true
var model = Workshop.new()
var world
var encyclopedia
var collection_room
var exhibition
var cut_dialog: FileDialog
var active_workshop
var font: SystemFont
var font_bold: SystemFont
var buttons: Dictionary = {}
var depth_slider: HSlider
var angle_slider: HSlider
var hold_button: Button
var primary: Button
var scene_texture: TextureRect
var toast: String = "爷爷去旅行了。这阵子，你和潘潘一起照看工坊。"
var toast_time: float = 5.0
var holding := false
var facet_latched := false
var dragging := false
var last_stage: int = -1
var t: float = 0.0
var mute := false
var audio_player: AudioStreamPlayer
var audio_playback: AudioStreamGeneratorPlayback
var audio_phase: float = 0.0

func _ready() -> void:
	get_window().title = "石间 · Gem Atelier 0.12.1 · 石间小铺"
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans CJK SC", "PingFang SC", "sans-serif"])
	font_bold = SystemFont.new()
	font_bold.font_names = font.font_names
	font_bold.font_weight = 700
	model.load_collection()
	build_theme()
	build_world()
	build_controls()
	build_audio()
	guide=preload("res://scripts/shop_guide.gd").new()
	guide.host=self
	add_child(guide)
	var config:=ConfigFile.new()
	if config.load("user://preferences.cfg")==OK: set_debug(bool(config.get_value("play","debug",false)))
	encyclopedia = preload("res://scripts/encyclopedia.gd").new()
	encyclopedia.host = self
	add_child(encyclopedia)
	collection_room=preload("res://scripts/collection_room.gd").new()
	collection_room.host=self
	add_child(collection_room)
	exhibition=preload("res://scripts/exhibition.gd").new()
	exhibition.host=self
	add_child(exhibition)
	refresh()

func build_theme() -> void:
	var skin := Theme.new()
	skin.default_font = font
	skin.default_font_size = 14
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("ebd9b4")
		style.border_color = LINE
		style.set_border_width_all(2)
		style.set_corner_radius_all(2)
		style.content_margin_left = 8
		style.content_margin_right = 8
		if state == "hover":
			style.bg_color = Color("f6e7c7")
			style.border_color = MINT
		if state == "pressed":
			style.bg_color = Color("ddbd89")
		if state == "disabled":
			style.bg_color = Color("dfd2b7")
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = GOLD
		skin.set_stylebox(state, "Button", style)
	skin.set_color("font_color", "Button", WHITE)
	skin.set_color("font_hover_color", "Button", WHITE)
	skin.set_color("font_disabled_color", "Button", Color("a09075"))
	skin.set_color("font_color","CheckBox",WHITE)
	skin.set_color("font_pressed_color","CheckBox",WHITE)
	skin.set_color("font_hover_pressed_color","CheckBox",WHITE)
	skin.set_color("font_hover_color","CheckBox",GOLD)
	theme = skin

func build_world() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(284, 207)
	viewport.disable_3d = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	world = PixelWorld.new()
	world.model = model
	viewport.add_child(world)
	scene_texture = TextureRect.new()
	scene_texture.position = Vector2(266, 162)
	scene_texture.size = Vector2(568, 414)
	scene_texture.texture = viewport.get_texture()
	scene_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene_texture.mouse_filter = Control.MOUSE_FILTER_STOP
	scene_texture.gui_input.connect(on_scene_input)
	add_child(scene_texture)
	# Optical pass at native panel resolution; keep the workshop art pixelated.
	var optical_view := SubViewport.new()
	optical_view.size = Vector2i(568,414)
	optical_view.transparent_bg = true
	optical_view.disable_3d = true
	optical_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(optical_view)
	world.remove_child(world.optics)
	optical_view.add_child(world.optics)
	world.optics.size = Vector2(568,414)
	world.optics_material.set_shader_parameter("pixel_footprint",Vector2(0.5,0.5))
	var display := TextureRect.new()
	display.position = scene_texture.position
	display.size = scene_texture.size
	display.texture = optical_view.get_texture()
	display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.visible = false
	add_child(display)
	world.optics_display = display

func button(id: String, caption: String, rect: Rect2, callback: Callable, hint: String = "") -> Button:
	var b := Button.new()
	b.text = caption
	b.position = rect.position
	b.size = rect.size
	b.tooltip_text = hint
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(callback)
	add_child(b)
	buttons[id] = b
	return b

func build_controls() -> void:
	button("encyclopedia", "百科", Rect2(174,173,60,25), open_encyclopedia)
	button("pressure", "力度 · 轻", Rect2(866,280,102,29), func(): model.pressure = 1.0 if model.pressure>1.1 else 1.8; refresh(), "轻压适合精细切削；重压更快，但脆性材料与解理方向更容易崩角。")
	button("axis", "晶向 · A", Rect2(974,280,102,29), func(): model.crystal_orientation = (model.crystal_orientation+1)%3; refresh(), "相对加工轴旋转晶体方向（简化模型）；影响解理风险，不改变已切出的表面。")
	button("bounces", "光路 · 12 次", Rect2(866,352,210,30), func(): world.max_bounces = {6:12,12:20,20:6}[world.max_bounces]; refresh(), "6 次更快；12 / 20 次保留更多内部反射。减少次数可能损失光能，不能代替抗锯齿。")
	button("notes", "爷爷的手记  ?", Rect2(570,32,124,38), open_notes)
	debug_checkbox=CheckBox.new()
	debug_checkbox.text="调试：跳过简介"
	debug_checkbox.position=Vector2(306,69)
	debug_checkbox.size=Vector2(204,28)
	debug_checkbox.add_theme_font_size_override("font_size",12)
	debug_checkbox.add_theme_color_override("font_color",WHITE)
	debug_checkbox.toggled.connect(func(value): set_debug(value,true))
	add_child(debug_checkbox)
	button("fast", "F8  快速加工 · 约 30 倍", Rect2(570, 73, 260, 24), toggle_fast, "自动完成后续工序；再次按 F8 停止。保留已切出的错误，过热仍会报废。")
	button("bgm", "音乐 · 开", Rect2(704,32,102,38), func(): bgm_enabled = not bgm_enabled; refresh())
	button("collection", "收藏室  /  %02d" % model.collection.size(), Rect2(930, 32, 162, 38), show_collection)
	button("mute", "声音 · 开", Rect2(816, 32, 102, 38), func(): mute = not mute; refresh())
	for i in range(model.GEMS.size()):
		var id := i
		var b := button("gem%d" % i, "", Rect2(44, 214 + i * 51, 190, 46), func(): select_gem(id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_constant_override("outline_size", 0)
	var gem_scroll=ScrollContainer.new()
	gem_scroll.position=Vector2(44,214)
	gem_scroll.size=Vector2(190,265)
	gem_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(gem_scroll)
	gem_scroll.name="GemScroll"
	var gem_list=VBoxContainer.new()
	gem_list.custom_minimum_size=Vector2(174,0)
	gem_scroll.add_child(gem_list)
	for i in range(model.GEMS.size()):
		var gem_button: Button=buttons["gem%d"%i]
		remove_child(gem_button)
		gem_button.custom_minimum_size=Vector2(174,46)
		gem_button.add_theme_font_size_override("font_size",13)
		gem_list.add_child(gem_button)
	button("coarse", "01  切面 · 600#", Rect2(866, 212, 210, 29), func(): model.wheel = 0; refresh())
	button("fine", "02  一次抛光 · 3000#", Rect2(866, 246, 210, 29), func(): model.wheel = 1; refresh())
	button("finish", "03  终抛 · 材料适配盘", Rect2(866, 280, 210, 29), func(): model.wheel = 2; refresh())
	for i in range(model.SHAPES.size()):
		var selected := i
		button("shape%d"%i,model.SHAPES[i],Rect2(866,216+i*38,210,31),func(): model.reset(model.gem_id,selected); refresh())
	var shape_scroll=ScrollContainer.new()
	shape_scroll.position=Vector2(866,216)
	shape_scroll.size=Vector2(210,176)
	shape_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	shape_scroll.name="ShapeScroll"
	add_child(shape_scroll)
	var shape_list=VBoxContainer.new()
	shape_list.custom_minimum_size=Vector2(192,0)
	shape_scroll.add_child(shape_list)
	for i in range(model.SHAPES.size()):
		var b: Button=buttons["shape%d"%i]
		remove_child(b)
		b.custom_minimum_size=Vector2(192,31)
		b.add_theme_font_size_override("font_size",13)
		shape_list.add_child(b)
	button("crust", "原石外皮   有", Rect2(44, 491, 190, 33), func(): model.crust = not model.crust; refresh())
	button("inclusions", "内含物对照 · 关", Rect2(866,73,210,24), func(): world.inclusion_enabled = not world.inclusion_enabled; refresh())
	button("import_cut","导入切工 .asc / .gcs",Rect2(866,401,210,29),open_cut_import)
	cut_dialog=FileDialog.new()
	cut_dialog.title="导入 GemCAD ASC / Gem Cut Studio GCS"
	cut_dialog.access=FileDialog.ACCESS_FILESYSTEM
	cut_dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE
	cut_dialog.filters=PackedStringArray(["*.asc ; GemCAD 文本切工","*.gcs ; Gem Cut Studio"])
	cut_dialog.file_selected.connect(func(path):
		var design=preload("res://scripts/cut_import.gd").read_file(path)
		if not design.get("ok",false): notify("导入失败："+str(design.error))
		elif model.apply_cut(design): notify("已导入："+str(design.name)+"；将实际按这些平面加工。")
		refresh())
	add_child(cut_dialog)
	button("rough", "原料形态", Rect2(866,481,210,30), func(): model.rough_kind = 1-model.rough_kind; model.reset(model.gem_id); refresh())
	button("inspect", "抬起观察 / 拖动旋转", Rect2(44, 523, 190, 32), func(): stop_work(); world.inspection = not world.inspection; refresh())
	button("enlarge", "放大展台  ↗", Rect2(626,533,190,28), func(): exhibition.open())
	button("style", "风格 · 像素", Rect2(866,354,210,28), func(): world.real_mode=not world.real_mode; refresh())
	button("optics", "光学追踪  /  刻面对照", Rect2(866, 485, 210, 28), func(): world.optical_enabled = not world.optical_enabled; refresh())
	depth_slider = HSlider.new()
	depth_slider.position = Vector2(872, 381)
	depth_slider.size = Vector2(198, 16)
	depth_slider.min_value = -8.0
	depth_slider.max_value = 12.0
	depth_slider.step = 0.5
	depth_slider.value_changed.connect(func(value): model.depth_offset = value; queue_redraw())
	depth_slider.tooltip_text = "正值进给更深，负值留下更多原石。首触后锁定，不会恢复已磨掉的材料。"
	add_child(depth_slider)
	angle_slider = HSlider.new()
	angle_slider.position = Vector2(872, 344)
	angle_slider.size = Vector2(198, 20)
	angle_slider.min_value = 0.0
	angle_slider.max_value = 90.0
	angle_slider.step = 0.5
	angle_slider.value_changed.connect(func(value): model.angle = value; queue_redraw())
	angle_slider.tooltip_text = "刻面与腰平面的夹角。错误角度也能切，会永久留下错误形状；粘杆与磨盘夹角是其余角。"
	add_child(angle_slider)
	button("prev", "‹", Rect2(866, 400, 40, 34), func(): model.next_facet(-1); refresh())
	button("next", "›", Rect2(1036, 400, 40, 34), func(): model.next_facet(); refresh())
	button("water", "滴水冷却   开启", Rect2(866, 452, 210, 33), func(): model.set_water(not model.water); refresh())
	hold_button = button("work", "按住 · 切磨", Rect2(866, 509, 210, 48), func(): pass, "按住鼠标或空格；每完成一组后松开，再加工下一组")
	hold_button.button_down.connect(start_work)
	hold_button.button_up.connect(stop_work)
	primary = button("primary", "", Rect2(850, 620, 226, 48), on_primary)
	var accent := StyleBoxFlat.new()
	accent.bg_color = MINT
	accent.set_corner_radius_all(4)
	primary.add_theme_stylebox_override("normal", accent)
	var hover := accent.duplicate()
	hover.bg_color = Color("83936b")
	primary.add_theme_stylebox_override("hover", hover)
	primary.add_theme_color_override("font_color", Color("fff3d4"))
	primary.add_theme_color_override("font_hover_color", Color("fff3d4"))
	primary.add_theme_font_override("font", font_bold)
	for i in range(3):
		var mode := i
		button("light%d" % i, ["日光 · 6500 K", "白炽灯 · 2850 K", "中性光 · 4500 K"][i], Rect2(866, 216 + i * 46, 210, 36), func(): world.light_mode = mode; refresh())
	button("spin", "自动旋转   关闭", Rect2(866, 402, 210, 34), func(): world.auto_rotate = not world.auto_rotate; refresh())
	button("reset_view", "重置观赏角度", Rect2(866, 444, 210, 34), func(): world.yaw = 0.35; world.tilt = -0.52; world.zoom = 1.0; refresh())
	button("new", "再加工一颗  →", Rect2(44, 513, 190, 38), func(): model.reset(model.gem_id); world.auto_rotate = false; world.inspection = false; world.zoom = 1.0; refresh())

func build_audio() -> void:
	sound = preload("res://scripts/workshop_audio.gd").new()
	add_child(sound)
	audio_player = sound.impact

func feed_audio() -> void:
	sound.set_muted(mute, not bgm_enabled)
	if is_instance_valid(guide) and guide.busy and not mute and bgm_enabled: sound.music.volume_db=-32.0
	sound.tick(holding and not facet_latched and model.last_error.is_empty(), get_process_delta_time())

func _exit_tree() -> void:
	if is_instance_valid(sound): sound.stop_all()

func toggle_fast() -> void:
	stop_work()
	if is_instance_valid(guide): guide.cancel()
	fast_mode = not fast_mode if not model.failed and model.stage != 4 else false
	refresh()

func run_fast_steps() -> void:
	# Small simulation steps preserve geometry and existing mistakes; no ideal mesh swap.
	for step in range(14):
		if not fast_mode: return
		if model.failed or model.stage == 4:
			fast_mode = false
			refresh()
			return
		if model.stage in [0,1]:
			on_primary()
			continue
		var values: Array[float] = model.cut if model.stage == 2 else model.polish
		if model.section_done(values):
			on_primary()
			continue
		if values[model.facet] >= 1.0: model.next_facet(); continue
		model.wheel = 0 if model.stage == 2 else 1
		if model.stage == 3: model.angle = model.cut_angles[model.facet]
		var result: int = model.work(0.04)
		world.working = result == 0
		if result == 1:
			sound.play_impact()
			model.next_facet()
			refresh()
		elif result < 0:
			fast_mode = false
			notify(model.failure_reason if model.failed else model.last_error)
			refresh()
			return

func _process(delta: float) -> void:
	t += delta
	if fast_mode: run_fast_steps()
	toast_time = maxf(0.0, toast_time - delta)
	if holding and not facet_latched:
		var result: int = model.work(delta)
		world.working = result >= 0
		if result == 1:
			sound.play_impact()
			facet_latched = true
			world.working = false
			notify("第 %02d 面完成。松开，转到下一刻面。" % (model.facet + 1))
			refresh()
		elif result == -2:
			stop_work()
			notify(model.failure_reason + "。这一颗已损失，请重新领料。")
			refresh()
		elif result == -1 and not model.last_error.is_empty():
			toast = model.last_error
			toast_time = 2.0
			model.cool(delta)
	else:
		model.cool(delta)
	feed_audio()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		stop_work()
		dragging = false

func _input(event: InputEvent) -> void:
	if is_instance_valid(cut_dialog) and cut_dialog.visible: return
	if is_instance_valid(exhibition) and exhibition.visible:
		exhibition.handle_event(event)
		return
	if is_instance_valid(collection_room) and collection_room.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			collection_room.hide()
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(encyclopedia) and encyclopedia.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			encyclopedia.hide()
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(guide) and guide.busy and event is InputEventKey and event.pressed:
		if event.keycode==KEY_F8: toggle_fast()
		elif event.keycode==KEY_ESCAPE: guide.cancel()
		elif event.keycode in [KEY_ENTER,KEY_SPACE]:
			if guide.greeting: guide.open_page()
			else: guide.accept()
		get_viewport().set_input_as_handled()
		return
	# Release outside a button or a viewport must still end machining.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if holding:
			stop_work()
		dragging = false
	if event is InputEventKey and not event.echo and not collection_room.visible:
		if event.pressed and event.keycode == KEY_F8:
			toggle_fast()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_SPACE and model.stage in [2, 3]:
			if event.pressed:
				start_work()
			else:
				stop_work()
			get_viewport().set_input_as_handled()
		if event.pressed and event.keycode in [KEY_LEFT, KEY_RIGHT] and model.stage in [2, 3]:
			model.next_facet(-1 if event.keycode == KEY_LEFT else 1)
			refresh()
		if event.pressed and model.stage == 4 and event.keycode in [KEY_1, KEY_2, KEY_3]:
			world.light_mode = event.keycode - KEY_1
			refresh()
		if event.pressed and model.stage == 4 and event.keycode in [KEY_H,KEY_J]:
			world.auto_rotate = false
			world.yaw = 0.0
			world.tilt = -PI/2.0 if event.keycode == KEY_H else PI/2.0
			notify("冠部正视：观察刻面反射对称性" if event.keycode == KEY_H else "亭部正视：观察刻面反射对称性")
			refresh()

func on_scene_input(event: InputEvent) -> void:
	if holding or (model.stage in [2, 3] and not world.inspection):
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			if dragging:
				world.auto_rotate = false
				refresh()
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			world.zoom = clampf(world.zoom + (0.08 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -0.08), 0.7, 1.4)
	if event is InputEventMouseMotion and dragging:
		world.yaw += event.relative.x * 0.012
		world.tilt = clampf(world.tilt + event.relative.y * 0.009, -1.3, 1.1)
		queue_redraw()
	if event is InputEventScreenTouch:
		dragging = event.pressed
		world.auto_rotate = false
	if event is InputEventScreenDrag:
		world.yaw += event.relative.x * 0.012
		world.tilt = clampf(world.tilt + event.relative.y * 0.009, -1.3, 1.1)

func start_work() -> void:
	if model.stage not in [2, 3] or model.failed or fast_mode or collection_room.visible or (is_instance_valid(guide) and guide.busy):
		return
	world.inspection = false
	holding = true
	refresh()

func stop_work() -> void:
	holding = false
	if world != null: world.working = false
	var finished_stroke := facet_latched
	facet_latched = false
	if finished_stroke and not model.failed:
		var values: Array[float] = model.cut if model.stage == 2 else model.polish
		for i in range(model.active_ids().size()):
			model.next_facet()
			if values[model.facet] < 1.0: break
	if not buttons.is_empty(): refresh()

func select_gem(id: int) -> void:
	model.reset(id)
	notify("已挑选 " + model.GEMS[id].name + "。先看看原石，再开始加工。")
	refresh()

func on_primary() -> void:
	if active_workshop != null:
		show_collection()
		return
	stop_work()
	if is_instance_valid(guide): guide.cancel()
	if debug_mode and model.stage==0: model.advance()
	if model.failed:
		model.reset(model.gem_id)
		world.inspection = false
		notify("重新领料。损失的原石不能恢复。")
	elif model.stage == 4:
		if model.save_piece(): notify("已收藏实际切出的几何体与光路诊断。")
		else: notify("收藏未写入，请检查本机用户目录权限。")
	elif model.advance():
		if model.awaiting_transfer: notify("亭部与腰围已抛光。用转接夹具将亭部粘到锥形杆，再加工冠部。")
		elif model.stage == 1: notify("粘杆固定原石，八角分度手柄支承在升降托台上。")
		elif model.stage == 2: notify("角度和进给都会改变真实形状；已磨掉的材料不会恢复。")
		elif model.stage == 3: notify("每个刻面只需抛光一次，完成后直接进入下一工序。")
		elif model.stage == 4:
			exhibition.open()
			sound.play_complete()
			world.auto_rotate = true
			world.inspection = false
			world.yaw = 0.35
			world.tilt = -0.85
			notify("展台使用刚才切出的实体追踪光线，形状误差会保留。")
	refresh()

func notify(message: String) -> void:
	toast = message
	toast_time = 6.0

func refresh() -> void:
	if buttons.is_empty(): return
	var s: int = model.stage
	var machining: bool = s in [2,3] and not model.failed
	get_node("GemScroll").visible=s==0
	get_node("ShapeScroll").visible=s==0
	buttons.import_cut.visible=s==0
	for i in range(model.GEMS.size()):
		buttons["gem%d"%i].visible = s == 0
		var gem = model.GEMS[i]
		buttons["gem%d"%i].text = ("●  " if i == model.gem_id else "○  ")+gem.name+"\n     %.2f ct / 原石"%gem.rough
	for i in range(3):
		buttons["light%d"%i].visible = s == 4
		buttons["light%d"%i].modulate = Color.WHITE if world.light_mode == i else Color("b5a17c")
	for i in range(model.SHAPES.size()):
		buttons["shape%d"%i].visible = s == 0
		buttons["shape%d"%i].text = ("●  " if model.shape_id == i else "○  ")+model.SHAPES[i]
	for id in ["coarse","fine","finish","prev","next","water","work","inspect"]:
		buttons[id].visible = machining
	for pair in [["coarse",0],["fine",1],["finish",2]]:
		buttons[pair[0]].modulate = Color.WHITE if model.wheel == pair[1] else Color("b5a17c")
	buttons.finish.text = "03  终抛 · "+("氧化铈盘" if model.gem_id == 1 else "金刚石抛光盘")
	buttons.finish.visible = false
	buttons.pressure.visible = machining
	buttons.axis.visible = machining or s == 0
	buttons.axis.position.y = 441 if s == 0 else 280
	buttons.axis.disabled = holding
	buttons.pressure.text = "力度 · " + ("重" if model.pressure>1.1 else "轻")
	buttons.axis.text = "晶向 · " + ["A","B","C"][model.crystal_orientation]
	buttons.bounces.visible = s == 4
	buttons.bounces.position=Vector2(626,499)
	buttons.bounces.size=Vector2(190,28)
	buttons.style.visible = s == 4
	buttons.style.text = "风格 · "+("真实" if world.real_mode else "像素")
	buttons.enlarge.visible = s == 4
	buttons.bounces.text = "光路 · %d 次" % world.max_bounces
	buttons.fast.text = "F8  停止快速加工" if fast_mode else "F8  快速加工 · 约 30 倍"
	buttons.fast.disabled = model.failed or s == 4
	buttons.bgm.text = "音乐 · " + ("开" if bgm_enabled else "关")
	angle_slider.visible = machining
	angle_slider.editable = not holding and (model.cut[model.facet] == 0.0 or s == 3)
	angle_slider.set_value_no_signal(model.angle)
	depth_slider.visible = machining
	depth_slider.editable = not holding and model.cut[model.facet] == 0.0 and s == 2
	depth_slider.set_value_no_signal(model.depth_offset)
	buttons.water.text = "滴水冷却   "+("开启" if model.water else "关闭")
	buttons.work.text = "按住 · "+("磨去材料" if s == 2 else "抛光当前面")
	buttons.spin.visible = s == 4
	buttons.reset_view.visible = s == 4
	buttons.optics.visible = s == 4
	buttons.new.visible = s == 4
	buttons.crust.visible = s == 0
	buttons.inclusions.visible = s == 4
	buttons.inclusions.text = "内含物对照 · " + ("开" if world.inclusion_enabled else "关")
	buttons.rough.visible = s == 0
	buttons.rough.text = "原料 · "+("原生晶体" if model.rough_kind==0 else "冲积磨圆料")
	buttons.crust.text = "原皮 / 附着物   "+("有" if model.crust else "无")
	buttons.spin.text = "自动旋转   "+("开启" if world.auto_rotate else "关闭")
	buttons.collection.text = "收藏室  /  %02d"%model.collection.size()
	buttons.mute.text = "声音 · "+("关" if mute else "开")
	primary.disabled = false
	match s:
		0: primary.text = "开始加工   →"
		1: primary.text = "转接翻面 · 粘锥形杆 →" if model.awaiting_transfer else "粘杆装夹 · 开始亭部 →"
		2:
			primary.text = "切面完成 · 进入抛光 →"
			primary.disabled = not model.section_done(model.cut)
		3:
			primary.text = "亭部完成 · 转接翻面 →" if model.section == 0 else "送入光影展台   →"
			primary.disabled = not model.section_done(model.polish)
		4:
			primary.text = "已收入收藏柜  ✓" if model.saved else "收藏真实切工   +"
			primary.disabled = model.saved
	if active_workshop != null:
		primary.text = "返回收藏室   →"
		primary.disabled = false
		buttons.new.visible = false
	if model.failed:
		primary.text = "原石报废 · 重新领料"
		primary.disabled = false
	if last_stage != s:
		last_stage = s
		world.zoom = 1.0
	queue_redraw()

func show_collection() -> void:
	exhibition.close()
	stop_work()
	fast_mode=false
	dragging=false
	guide.cancel()
	if active_workshop != null:
		model=active_workshop
		active_workshop=null
		world.model=model
		world.seen_generation=-1
	collection_room.open()
	refresh()

func inspect_collected(index: int) -> void:
	var original=model
	var viewer=Workshop.new()
	if not viewer.restore_piece(original.collection[index]):
		notify("这件早期收藏缺少有效几何数据，暂时无法重新查看。")
		return
	viewer.collection=original.collection
	active_workshop=original
	model=viewer
	world.model=model
	world.seen_generation=-1
	world.yaw=0.35
	world.tilt=-0.9
	world.zoom=1.0
	world.auto_rotate=false
	collection_room.hide()
	exhibition.open()
	refresh()

func text_at(caption: String, x: float, y: float, size_px: int = 14, color: Color = WHITE, bold: bool = false) -> void:
	draw_string(font_bold if bold else font, Vector2(x, y), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func line(x: float, y: float, width: float) -> void:
	draw_line(Vector2(x, y), Vector2(x + width, y), LINE, 1.0)

func box(rect: Rect2, color: Color = PANEL) -> void:
	draw_style_box(panel_style(color), rect)

func panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = LINE
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.shadow_color=Color(0.28,0.17,0.09,0.14)
	style.shadow_size=4
	return style

func _draw() -> void:
	if font == null:
		return
	draw_rect(Rect2(0, 0, 1120, 720), BG)
	draw_rect(Rect2(0,0,1120,6),Color("806044"))
	draw_rect(Rect2(0,694,1120,26),Color("6f513b"))
	for i in range(75):
		var x: float=posmod(i*163,1110)
		var y: float=posmod(i*97,680)+9
		draw_line(Vector2(x,y),Vector2(x+8+i%7,y),Color(0.48,0.34,0.20,0.055),1.0)
	# The little mark is a code-drawn, original pixel diamond.
	draw_colored_polygon(PackedVector2Array([Vector2(29, 41), Vector2(38, 30), Vector2(56, 30), Vector2(65, 41), Vector2(47, 62)]), MINT)
	draw_polyline(PackedVector2Array([Vector2(29, 41), Vector2(65, 41), Vector2(47, 62), Vector2(38, 30), Vector2(56, 30), Vector2(47, 62)]), Color("244b42"), 1.0)
	text_at("石间小铺", 80, 51, 24, WHITE, true)
	text_at("GEM ATELIER", 190, 49, 15, MINT)
	text_at("选择原料与琢型，开始加工。", 29, 83, 13, MUTED)
	text_at("宝石加工工坊", 310, 49, 12, MUTED)
	line(28, 100, 1064)
	for i in range(5):
		var x := 30 + i * 218
		var active: bool = model.stage == i
		var done: bool = model.stage > i
		text_at("%02d" % (i + 1), x, 135, 13, MINT if active or done else MUTED)
		text_at(STAGE_NAMES[i], x + 31, 135, 15, WHITE if active else MUTED, active)
		if active:
			draw_rect(Rect2(x, 148, 174, 2), MINT)
		if i < 4:
			text_at("/", x + 191, 134, 14, LINE)
	box(Rect2(28, 162, 222, 414))
	box(Rect2(850, 162, 242, 414))
	draw_rect(Rect2(261,157,578,424),Color("896644"))
	draw_rect(Rect2(264,160,572,418),Color("e9d4a6"))
	draw_left()
	draw_right()
	draw_bottom()
	text_at("石间小铺  /  潘潘和你的宝石工坊 0.12.1", 28, 710, 10, Color("e7d6ae"))
	text_at("F8 快速加工 · 点击潘潘查看说明", 862, 710, 10, Color("e7d6ae"))

func draw_left() -> void:
	var gem = model.GEMS[model.gem_id]
	text_at("原石匣" if model.stage == 0 else "加工记录",44,193,17,WHITE,true)
	line(44,204,190)
	if model.stage == 0:
		line(44,478,190)
		text_at(model.Stock.NAMES[model.gem_id] if model.rough_kind==0 else "冲积磨圆料（示例）",44,548,12,GOLD)
		return
	draw_circle(Vector2(136,255),30,Color("d4bf96"))
	draw_circle(Vector2(136,255),20,world.displayed_color.darkened(0.3))
	text_at(gem.name,44,310,19,WHITE,true)
	text_at(gem.en,44,332,10,MINT)
	text_at(model.cut_name(),44,348,10,GOLD)
	text_at(gem.origin,44,366,10,MUTED)
	line(44,372,190)
	text_at("原石重量",44,397,12,MUTED)
	text_at("%.2f ct"%gem.rough,165,397,13)
	text_at("当前余重",44,423,12,MUTED)
	text_at("%.2f ct"%model.carats(),165,423,13,GOLD)
	text_at("切工记录" if debug_mode else "加工状态",44,449,12,MUTED)
	text_at("%d / 100"%int(model.quality) if debug_mode else ("完成啦" if model.stage==4 else "慢慢来"),163,449,13,MINT)
	line(44,466,190)
	if model.failed:
		text_at("贯穿裂纹 · 原石损失",44,494,14,Color("ed9e87"),true)
		text_at("无法抛光、展示或收藏",44,522,12,MUTED)
	elif model.stage == 4:
		text_at("轴向回光抽样  %.0f%%"%(model.optical_return*100) if debug_mode else "成品已完成",44,493,12,GOLD)
		text_at("仅对照同组测试光路" if debug_mode else "详细笔记在「爷爷的手记」",44,566,10,MUTED)
	else:
		text_at("亭部先抛 → 转接 → 冠部",44,491,12,GOLD)
		text_at("%s · %d 面"%[model.cut_name(),model.tasks.size()],44,514,11,MUTED)

func draw_right() -> void:
	var s: int = model.stage
	text_at("光源实验室" if s == 4 else ("琢型选择" if s == 0 else "切磨控制"),866,193,17,WHITE,true)
	line(866,204,210)
	if model.failed:
		text_at("原石已报废",866,249,21,Color("ed9e87"),true)
		text_at("裂纹贯穿剩余晶体。",866,284,13,MUTED)
		text_at("冷却不能愈合已经形成的裂口。",866,315,11,MUTED)
		text_at("本次重量与工序全部损失。",866,344,12,MUTED)
		return
	if s == 0:
		text_at("%d 个加工面"%model.tasks.size(),866,457,13,GOLD)
		text_at("心箭试验型尚未验证图样。" if model.shape_id==4 else "按 F8 快速加工并比较光彩。",866,525,11,MINT)
	elif s == 1:
		text_at("翻到爷爷画工具的那一页。",866,255,14,GOLD)
		text_at("保持粘杆与原石的轴线。",866,292,12,MUTED)
		text_at("准备好了，就继续吧。",866,329,12,MUTED)
	elif s in [2,3]:
		text_at("崩角风险："+("较高 · 可继续" if model.chip_risk()>1.0 else "较低")+" / 缺角 %d"%model.chips.size(),866,319,10,GOLD)
		text_at("刻面角 %.1f° / 目标 %.1f°"%[model.angle,model.target_angle()],866,332,12,GOLD)
		text_at("进给偏置 %+0.1f · 正值切深"%model.depth_offset,866,378,11,MUTED)
		text_at("%02d / %02d"%[model.active_ids().find(model.facet)+1,model.active_ids().size()],930,423,15,MINT,true)
		text_at(("温度 %.0f°C / 应力 %.0f"%[model.temperature,model.thermal_damage]) if debug_mode else ("温度偏高，先歇一会儿。" if model.thermal_damage>0 else "滴水开着，慢慢磨。"),866,500,10,GOLD if model.thermal_damage>0 else MUTED)
		text_at("%s / 八方 %d"%[model.tasks[model.facet].name,int(model.tasks[model.facet].index/12)+1],958,445,10,MUTED)
	elif s == 4:
		text_at("折射率 %.3f"%model.GEMS[model.gem_id].ri if debug_mode else "慢慢转一转，看看里面。",866,340,12,MUTED)
		text_at("实际切形" if debug_mode else "",1025,340,12,MINT)
		line(866,390,210)
		text_at("拖动 / 缩放 / 1·2·3 切光 / H·J 正视",866,535,10,GOLD)
		text_at("光源改变呈色 · 转动寻找闪光",866,557,10,MUTED)

func draw_bottom() -> void:
	box(Rect2(28,592,1064,98),Color("f0dfba"))
	var s: int = model.stage
	text_at(STAGE_EN[s],46,617,9,MINT)
	var titles := ["选择原料","翻个面，再试一次" if model.awaiting_transfer else "把它稳稳放好","慢慢磨，别着急","这一面，快要亮起来了","成品展示"]
	text_at("这颗原石已损失" if model.failed else titles[s],46,646,21,WHITE,true)
	if s in [2,3] and not model.failed:
		var values: Array[float] = model.cut if s == 2 else model.polish
		var ids: Array = model.active_ids()
		text_at("%s · %s · %02d / %02d"%["亭部+腰围" if model.section==0 else "冠部+台面","切面" if s==2 else "抛光",model.count_complete(values),ids.size()],397,619,11,MUTED)
		for i in range(ids.size()):
			var bar_width: float = minf(25.0,400.0/ids.size())
			var x: float = 398+i*bar_width
			draw_rect(Rect2(x,634,bar_width-3,10),Color("d3bd97"))
			draw_rect(Rect2(x,634,(bar_width-3)*values[ids[i]],10),MINT)
			if ids[i] == model.facet: draw_rect(Rect2(x,651,bar_width-3,2),GOLD)
	else:
		text_at("%.2f ct · 今天的工坊手账"%model.carats(),397,640,12,MUTED)
	var status: String = toast if toast_time>0 else ("材料一旦移除不可恢复；抛光不会修正切歪的形状。" if s in [2,3] else "拖动中央可观察原石；先加工几何体，再看光如何走。")
	text_at(model.failure_reason if model.failed else status,46,674,11,GOLD)

func set_debug(value: bool, persist: bool=false) -> void:
	debug_mode=value
	if is_instance_valid(debug_checkbox): debug_checkbox.set_pressed_no_signal(value)
	if value and is_instance_valid(guide): guide.accept()
	if value and is_instance_valid(guide): guide.seen["welcome"]=true
	if persist:
		var config:=ConfigFile.new()
		config.set_value("play","debug",value)
		config.save("user://preferences.cfg")
	refresh()

func open_notes() -> void:
	stop_work()
	fast_mode=false
	guide.present(Dialogue.topic(model,true))

func open_encyclopedia() -> void:
	stop_work()
	fast_mode = false
	dragging = false
	guide.cancel()
	encyclopedia.open(model.gem_id)
	refresh()

func open_character() -> void:
	stop_work()
	fast_mode=false
	guide.present(Dialogue.introduction())

func open_cut_import() -> void:
	var samples=OS.get_executable_path().get_base_dir().path_join("示例切工")
	if not DirAccess.dir_exists_absolute(samples): samples=ProjectSettings.globalize_path("res://cuts")
	if DirAccess.dir_exists_absolute(samples): cut_dialog.current_dir=samples
	cut_dialog.popup_centered_ratio(0.75)
