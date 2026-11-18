extends Control
const Data = preload("res://scripts/gem_data.gd")
var host
var selected := 0
var page: RichTextLabel
var tabs: OptionButton
var plot: Node2D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.08,0.06,0.04,0.75)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := Panel.new()
	panel.position = Vector2(115,55)
	panel.size = Vector2(890,610)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4e7c9")
	style.border_color = Color("9c8059")
	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	tabs = OptionButton.new()
	tabs.position = Vector2(140,76)
	tabs.size = Vector2(390,38)
	for gem in host.model.GEMS: tabs.add_item(gem.name)
	tabs.item_selected.connect(func(id): selected=id; update_page())
	add_child(tabs)
	var close := Button.new()
	close.text = "回到工坊  ×"
	close.position = Vector2(823,76)
	close.size = Vector2(155,38)
	close.pressed.connect(hide)
	add_child(close)
	page = RichTextLabel.new()
	page.position = Vector2(145,135)
	page.size = Vector2(830,380)
	page.bbcode_enabled = true
	page.add_theme_font_size_override("normal_font_size",15)
	page.add_theme_color_override("default_color",Color("4b3629"))
	page.meta_clicked.connect(func(url): OS.shell_open(str(url)))
	add_child(page)
	plot=Node2D.new()
	plot.draw.connect(draw_spectrum)
	add_child(plot)
	hide()

func open(id: int) -> void:
	selected = id
	tabs.select(id)
	update_page()
	show()

func update_page() -> void:
	var d: Dictionary = Data.ENTRIES[selected]
	page.text = "[b]%s · 化学与结构[/b]\n%s\n\n[b]典型原料[/b]  %s\n[b]常见成品[/b]  %s\n\n[b]物理性质[/b]\n莫氏硬度 %s（抗划伤） · %s\n解理 / 裂理：%s\n\n[b]光学性质[/b]\n折射率：%s\n%s\n\n[b]本作中的加工[/b]\n轻压通常安全；重压、过切与精细薄边叠加方向敏感性，可产生永久缺角。晶向 A/B/C 是简化坐标下的 0°/30°/60° 旋转，并非鉴定晶向。崩角仍可继续加工；过热导致的整体断裂才会报废。风险系数、温度均为游戏参数。\n\n[b]模型边界[/b]\n图中为实际渲染使用的 20 波段拟合吸收系数（游戏长度单位），不是实测吸收谱。采用标量折射率与 Cauchy 色散；未完整计算偏振、双折射、多色性。化学式是组成表达，并非天然结晶反应方程式。\n玻璃是非晶体，没有晶体解理；可以刻面，是否崩边取决于玻璃种类、角部与工艺，不能一概认定切心箭必崩。\n\n[url=https://www.handbookofmineralogy.org/pdfs/%s.pdf]矿物数据来源：Handbook of Mineralogy[/url]\n[url=https://www.gia.edu/gia-news-research/how-protect-diamond-chipping]GIA：解理、薄腰与崩角[/url] · [url=https://www.gia.edu/alexandrite-care-cleaning]GIA：变石护理与韧性[/url]\n" % [d.formula,d.structure,d.rough,d.cuts,d.hardness,d.toughness,d.cleavage,d.ri,d.spectrum,d.source]
	page.scroll_to_line(0)
	plot.queue_redraw()

func draw_spectrum() -> void:
	if not is_instance_valid(page): return
	var font = host.font
	plot.draw_string(font,Vector2(145,545),"游戏吸收模型 · 非实测谱（系数范围 0–0.10）",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("6d805c"))
	var origin := Vector2(180,618)
	plot.draw_line(origin,origin+Vector2(730,0),Color("9c8059"))
	plot.draw_line(origin,origin+Vector2(0,-60),Color("9c8059"))
	var points := PackedVector2Array()
	for band in range(20):
		points.append(origin+Vector2(730.0*band/19.0,-Data.bands(selected)[band]*600.0))
	plot.draw_polyline(points,Color("826695"),2.0,true)
	plot.draw_string(font,Vector2(180,642),"408 nm                         绿 / 黄吸收区                         693 nm",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("8a745a"))
