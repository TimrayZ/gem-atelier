extends RefCounted
const Solid = preload("res://scripts/solid_geometry.gd")
const Data = preload("res://scripts/gem_data.gd")
const Stock = preload("res://scripts/rough_stock.gd")
var rough_kind := 0
var imported_cut: Dictionary = {}
enum Stage { RAW, MOUNT, CUT, POLISH, SHOWCASE }
# Representative optical constants; heat limits are game values, not mineral data.
const GEMS = [
	{"name": "亚历山大变石", "en": "ALEXANDRITE", "origin": "金绿宝石 · 变色品种", "rough": 7.84, "angle": 42.0, "crown": 37.0, "ri": 1.746, "dispersion": 0.012, "heat": 115.0, "toughness": 1.3, "day": Color("56c7a1"), "warm": Color("cb597d"), "neutral": Color("7daeb5")},
	{"name": "紫水晶", "en": "AMETHYST", "origin": "石英 · 紫色品种", "rough": 10.26, "angle": 43.0, "crown": 42.0, "ri": 1.544, "dispersion": 0.008, "heat": 75.0, "toughness": 0.8, "day": Color("a58cde"), "warm": Color("bc83c4"), "neutral": Color("a399e7")},
	{"name": "蓝宝石", "en": "SAPPHIRE", "origin": "刚玉 · 蓝色品种", "rough": 6.52, "angle": 40.0, "crown": 38.0, "ri": 1.765, "dispersion": 0.018, "heat": 135.0, "toughness": 1.5, "day": Color("4f95dc"), "warm": Color("686fc0"), "neutral": Color("659ce8")},
	{"name":"钻石","en":"DIAMOND","origin":"金刚石 · 无色透明","rough":5.8,"angle":40.75,"crown":34.5,"ri":2.417,"dispersion":0.044,"heat":180.0,"toughness":1.1,"day":Color("dce9ef"),"warm":Color("eadfce"),"neutral":Color("e5e8ee")},
	{"name":"透明正长石","en":"ORTHOCLASE","origin":"长石族 · 透明品种","rough":9.2,"angle":43.0,"crown":40.0,"ri":1.522,"dispersion":0.012,"heat":70.0,"toughness":0.7,"day":Color("e7d7a8"),"warm":Color("ead7b1"),"neutral":Color("e1d5b7")},
 {"name":"莫桑石","en":"MOISSANITE","origin":"实验室合成 · 碳化硅","rough":6.8,"angle":41.0,"crown":34.0,"ri":2.648,"dispersion":0.104,"heat":180.0,"toughness":1.2,"day":Color("e7e9e1"),"warm":Color("efe2cc"),"neutral":Color("e7e7df")},
 {"name":"祖母绿","en":"EMERALD","origin":"绿柱石 · 绿色品种","rough":8.7,"angle":43.0,"crown":36.0,"ri":1.580,"dispersion":0.014,"heat":80.0,"toughness":0.65,"day":Color("42b67f"),"warm":Color("63a270"),"neutral":Color("60b58d")},
 {"name":"粉色尖晶石","en":"SPINEL","origin":"尖晶石族 · 粉色品种","rough":6.9,"angle":42.0,"crown":36.0,"ri":1.719,"dispersion":0.020,"heat":130.0,"toughness":1.3,"day":Color("df7299"),"warm":Color("e48993"),"neutral":Color("db82b0")},
 {"name":"金色托帕石","en":"TOPAZ","origin":"黄玉 · 金色品种","rough":9.4,"angle":43.0,"crown":38.0,"ri":1.620,"dispersion":0.014,"heat":95.0,"toughness":0.75,"day":Color("e9b96d"),"warm":Color("e5ac58"),"neutral":Color("e6c18b")},
 {"name":"红宝石","en":"RUBY","origin":"刚玉 · 红色品种","rough":6.7,"angle":40.0,"crown":38.0,"ri":1.765,"dispersion":0.018,"heat":135.0,"toughness":1.5,"day":Color("d94c72"),"warm":Color("e65b55"),"neutral":Color("d9618a")},
 {"name":"白绿翡翠","en":"ZONED JADEITE","origin":"翡翠 · 白绿分色","rough":12.0,"angle":42.0,"crown":38.0,"ri":1.66,"dispersion":0.013,"heat":90.0,"toughness":1.5,"day":Color("a7d5b8"),"warm":Color("c7d9ad"),"neutral":Color("b2d7bb")},
 {"name":"紫黄晶","en":"AMETRINE","origin":"石英 · 紫黄分色","rough":10.0,"angle":43.0,"crown":40.0,"ri":1.544,"dispersion":0.008,"heat":75.0,"toughness":0.8,"day":Color("c2a3cd"),"warm":Color("d3ad99"),"neutral":Color("c6a6c4")},
 {"name":"双色碧玺","en":"BICOLOR TOURMALINE","origin":"电气石 · 粉绿分色","rough":9.0,"angle":42.0,"crown":38.0,"ri":1.624,"dispersion":0.017,"heat":85.0,"toughness":0.8,"day":Color("99c8ad"),"warm":Color("c5ada0"),"neutral":Color("a9c1ae")}

]
const SHAPES = ["八角单翻", "椭圆刻面", "八重对称刻面", "长方阶梯式", "圆形明亮（心箭试验）", "枕形刻面", "梨形刻面", "马眼刻面", "切角三角形", "六边阶梯式", "八面体（8面）", "简易方形（13面）", "简易长阶梯（17面）", "蛋面（多面近似）"]
# Fictional relative prices for selecting rough, not real-world valuations.
const ROUGH_PRICES = [1200, 90, 850, 2200, 140, 60, 1000, 260, 180, 1500, 900, 300, 500]
var shape_id := 0
var stage: int = Stage.RAW
var gem_id := 0
var facet := 0
var section := 0
var awaiting_transfer := false
var angle := 42.0
var depth_offset := 0.0
var wheel := 0
var water := true
var pressure := 1.0
var temperature := 20.0
var thermal_damage := 0.0
var quality := 100.0
var failed := false
var failure_reason := ""
var crust := true
var saved := false
var collection: Array = []
var last_error := ""
var save_path := "user://collection.json"
var body: Array = []
var inner_body: Array = []
var tasks: Array = []
var cut: Array[float] = []
var polish: Array[float] = []
var prepolish: Array[float] = []
var starts: Array[float] = []
var cut_angles: Array[float] = []
var cut_depths: Array[float] = []
var initial_volume := 1.0
var revision := 0
var generation := 0
var removal_events: Array = []
var chip_sources: Dictionary = {}
var optical_return := 0.0
var crystal_orientation := 0
var chips: Array = []
var chipped_tasks: Dictionary = {}
var facet_scores: Array[int] = []
var facet_grades: Array[String] = []
var repair_checkpoint: Dictionary = {}

func _init() -> void: reset(0)

func reset(id: int, selected_shape: int = -1) -> void:
	if selected_shape >= 0:
		shape_id = clampi(selected_shape,0,SHAPES.size()-1)
		imported_cut.clear()
	gem_id = clampi(id, 0, GEMS.size()-1)
	stage = Stage.RAW
	section = 0
	awaiting_transfer = false
	facet = 0
	angle = GEMS[gem_id].angle
	depth_offset = 0.0
	wheel = 0
	water = true
	pressure = 1.0
	temperature = 20.0
	thermal_damage = 0.0
	quality = 100.0
	optical_return = 0.0
	failed = false
	failure_reason = ""
	saved = false
	last_error = ""
	removal_events.clear()
	chip_sources.clear()
	chips.clear()
	chipped_tasks.clear()
	facet_scores.clear()
	facet_grades.clear()
	repair_checkpoint.clear()
	body = Stock.make(gem_id,rough_kind)
	inner_body = Stock.core(body)
	crust = rough_kind==1 and gem_id in [0,2]
	initial_volume = Solid.volume(body)
	tasks.clear()
	build_recipe()
	for values in [cut, polish, prepolish, starts, cut_angles, cut_depths]: values.clear()
	for task in tasks:
		cut.append(0.0)
		polish.append(0.0)
		prepolish.append(0.0)
		starts.append(INF)
		cut_angles.append(task.angle)
		cut_depths.append(0.0)
		facet_scores.append(-1)
		facet_grades.append("")
	revision += 1
	generation += 1

func active_ids() -> Array:
	var ids: Array = []
	for i in range(tasks.size()):
		if tasks[i].section == section: ids.append(i)
	return ids

func add_ring(count: int, tier: int, a: float, r: float, y: float, offset: float, label: String) -> void:
	for i in range(count):
		var az := TAU*i/count+offset
		var radius := r
		if shape_id == 3 and offset == 0.0:
			# Rectangle with clipped corners, with independent side/end distances.
			radius *= (19.0/30.0 if i%2==1 else 1.0) if count==4 else 1.0
		if shape_id==5:
			radius*=pow(pow(absf(cos(az))*1.02,4.0/3.0)+pow(absf(sin(az))*0.95,4.0/3.0),0.75)
		elif shape_id in [6,7]:
			var outline: Array=[Vector2(0,38),Vector2(17,13),Vector2(26,-8),Vector2(21,-26),Vector2(0,-32),Vector2(-21,-26),Vector2(-26,-8),Vector2(-17,13)] if shape_id==6 else [Vector2(0,38),Vector2(17,22),Vector2(22,0),Vector2(17,-22),Vector2(0,-38),Vector2(-17,-22),Vector2(-22,0),Vector2(-17,22)]
			var extent=0.0
			for point in outline: extent=maxf(extent,point.dot(Vector2(cos(az),sin(az))))
			radius*=extent/30.0
		var n := Vector3(sin(deg_to_rad(a))*cos(az), (1.0 if tier<2 else -1.0)*cos(deg_to_rad(a)), sin(deg_to_rad(a))*sin(az))
		var d: float = sin(deg_to_rad(a))*radius+cos(deg_to_rad(a))*absf(y)
		if shape_id == 1:
			n = Vector3(n.x/1.24,n.y,n.z/0.82)
			d /= n.length()
			n = n.normalized()
		var actual_angle := rad_to_deg(atan2(Vector2(n.x,n.z).length(),absf(n.y)))
		tasks.append({"tier":tier,"section":0 if tier<2 else 1,"index":posmod(int(round(az*96.0/TAU)),96),"azimuth":atan2(n.z,n.x),"angle":actual_angle,"d":d,"name":label})

func cut_name() -> String: return str(imported_cut.get("name",SHAPES[shape_id]))

func apply_cut(design: Dictionary) -> bool:
	if stage!=Stage.RAW or not design.get("ok",false): return false
	imported_cut=design.duplicate(true)
	reset(gem_id)
	return true

func build_recipe() -> void:
	if not imported_cut.is_empty():
		tasks=imported_cut.tasks.duplicate(true)
		return
	var pa: float = GEMS[gem_id].angle
	var ca: float = GEMS[gem_id].crown
	if shape_id == 13:
		add_ring(1,0,0.0,0.0,8.0,0.0,"蛋面平底")
		add_ring(8,1,90.0,25.0,0.0,0.0,"蛋面腰围")
		for a in [70.0,45.0,20.0]:
			add_ring(8,2,a,25.0*sin(deg_to_rad(a)),-25.0*cos(deg_to_rad(a)),0.0,"蛋面弧顶")
	elif shape_id == 10:
		add_ring(4,0,45.0,25.0,0.0,PI/4.0,"八面体亭面")
		add_ring(4,2,45.0,25.0,0.0,PI/4.0,"八面体冠面")
	elif shape_id == 11:
		add_ring(4,0,pa,30.0,2.0,0.0,"方形亭面")
		add_ring(4,1,90.0,30.0,0.0,0.0,"方形腰围")
		add_ring(4,2,ca,30.0,-2.0,0.0,"方形冠面")
	elif shape_id == 12:
		add_ring(4,0,pa,24.0,8.0,0.0,"长阶梯内亭")
		add_ring(4,0,pa+10.0,30.0,2.0,0.0,"长阶梯外亭")
		add_ring(4,1,90.0,30.0,0.0,0.0,"长阶梯腰围")
		add_ring(4,2,ca,30.0,-2.0,0.0,"长阶梯冠面")
	elif shape_id==8:
		add_ring(3,0,pa,20,2,0,"三角亭主面")
		add_ring(3,1,90,20,0,0,"三角腰围")
		add_ring(3,1,90,32,0,PI/3,"护角")
		add_ring(3,2,ca,20,-2,0,"三角冠面")
	elif shape_id==9:
		for band in range(3): add_ring(6,0,pa+band*9.0,[20.0,26.0,30.0][band],[12.0,6.0,2.0][band],0,"六边亭阶梯")
		add_ring(6,1,90,30,0,0,"六边腰围")
		for band in range(2): add_ring(6,2,ca-band*10.0,[30.0,22.0][band],[-2.0,-9.0][band],0,"六边冠阶梯")
	elif shape_id == 3:
		for band in range(3):
			add_ring(4,0,pa+band*12.0,[21.0,27.0,30.0][band],[12.0,6.6,2.0][band],0.0,"亭部阶梯%d"%(band+1))
		add_ring(4,1,90.0,30.0,0.0,0.0,"腰围长短边")
		add_ring(4,1,90.0,30.4,0.0,PI/4.0,"腰围切角")
		for band in range(3):
			add_ring(4,2,ca-band*10.0,[30.0,24.0,15.0][band],[-2.0,-7.0,-12.0][band],0.0,"冠部阶梯%d"%(band+1))
	else:
		var count := 16 if shape_id in [1,5,6,7] else 8
		add_ring(count,0,pa,30.0,2.0,0.0,"亭部主面")
		if shape_id==2: add_ring(8,0,pa+4.0,30.0,2.0,PI/8.0,"亭部腰下刻面")
		if shape_id==4: add_ring(16,0,pa+2.0,30.0,2.0,PI/16.0,"下腰刻面")
		add_ring(16 if shape_id==4 else count,1,90.0,30.0,0.0,0.0,"腰围")
		add_ring(count,2,ca,30.0,-2.0,0.0,"冠部主面")
		if shape_id in [2,4]:
			add_ring(16,2,ca+9.0,30.0,-2.0,PI/16.0,"上腰刻面")
			var d: float = sin(deg_to_rad(ca))*30.0+cos(deg_to_rad(ca))*2.0
			var table_radius: float = (d-cos(deg_to_rad(ca))*15.0)/sin(deg_to_rad(ca))
			add_ring(8,2,ca-15.0,table_radius*0.90,-15.0,PI/8.0,"八星刻面")
	if shape_id != 10: add_ring(1,3,0.0,0.0,-25.0 if shape_id==13 else -15.0,0.0,"蛋面顶点" if shape_id==13 else "台面")

func cut_difficulty() -> int:
	return 4 if shape_id==4 and imported_cut.is_empty() else (1 if tasks.size() <= 10 else (2 if tasks.size() <= 25 else 3))

func facet_difficulty(id: int) -> int:
	var small: bool = int(tasks[id].tier) == 3 or str(tasks[id].name).contains("腰下") or str(tasks[id].name).contains("上腰") or str(tasks[id].name).contains("八星")
	return mini(4, cut_difficulty() + int(small))

func overall_score() -> int:
	var total := 0
	var count := 0
	for score in facet_scores:
		if score >= 0: total += score; count += 1
	return int(round(float(total) / maxf(1.0,float(count))))

func all_a_or_better() -> bool:
	if facet_grades.is_empty(): return false
	for grade in facet_grades:
		if grade not in ["S", "A"]: return false
	return true

func target_angle() -> float: return tasks[facet].angle

func facet_normal(id: int, actual_angle: float) -> Vector3:
	var azimuth: float = tasks[id].azimuth
	var a := deg_to_rad(actual_angle)
	return Vector3(sin(a) * cos(azimuth), (1.0 if tasks[id].tier < 2 else -1.0) * cos(a), sin(a) * sin(azimuth)).normalized()

func count_complete(values: Array[float]) -> int:
	var result := 0
	for id in active_ids():
		if values[id] >= 1.0: result += 1
	return result

func section_done(values: Array[float]) -> bool: return count_complete(values) == active_ids().size()

func advance() -> bool:
	if failed: return false
	match stage:
		Stage.RAW: stage = Stage.MOUNT
		Stage.MOUNT:
			if awaiting_transfer:
				section = 1
				facet = tasks.find(tasks.filter(func(t): return t.section == 1)[0])
				awaiting_transfer = false
			stage = Stage.CUT
			wheel = 0
		Stage.CUT:
			if not section_done(cut): return false
			stage = Stage.POLISH
			facet = active_ids()[0]
			wheel = 1
		Stage.POLISH:
			if not section_done(polish): return false
			if section == 0:
				stage = Stage.MOUNT
				awaiting_transfer = true
			else:
				stage = Stage.SHOWCASE
				optical_return = light_return()
		Stage.SHOWCASE: return false
	angle = cut_angles[facet] if stage == Stage.POLISH else target_angle()
	depth_offset = 0.0
	return true

func next_facet(direction: int = 1) -> void:
	var ids := active_ids()
	facet = ids[posmod(ids.find(facet) + direction, ids.size())]
	angle = cut_angles[facet] if stage == Stage.POLISH else target_angle()
	depth_offset = 0.0

func set_water(enabled: bool) -> void:
	if enabled and not water and temperature > GEMS[gem_id].heat: thermal_damage += (temperature - 30.0) * 0.18
	water = enabled
	check_fracture()

func cool(delta: float) -> void: temperature = 20.0 + (temperature - 20.0) * exp(-delta * (0.45 if water else 0.06))

func check_fracture() -> void:
	if thermal_damage >= 18.0 * GEMS[gem_id].toughness and not failed: fracture("热应力贯穿裂纹 · 原石报废")

func fracture(reason: String) -> void:
	remember_repair_state()
	failed = true
	failure_reason = reason
	last_error = reason
	var normal := Vector3(0.8, 0.25, 0.3).normalized()
	var other := Solid.clip(body, -normal, 0.0, -2)
	body = Solid.clip(body, normal, 0.0, -2)
	inner_body = Solid.clip(inner_body, normal, 0.0, -2)
	removal_events.append({"body": other, "fracture": true})
	quality = 0.0
	revision += 1

## Wrong angles remove a different half-space. Nothing snaps to an ideal mesh.
func work(delta: float, allow_overcut: bool = false) -> int:
	last_error = ""
	if failed: return -2
	if stage not in [Stage.CUT, Stage.POLISH]: return -1
	if (stage == Stage.CUT and wheel != 0) or (stage == Stage.POLISH and wheel == 0):
		last_error = "换盘：600# 切面 / 3000# 一次抛光"
		return -1
	var values: Array[float] = cut if stage == Stage.CUT else polish
	if values[facet] >= (1.25 if allow_overcut and stage == Stage.CUT else 1.0):
		last_error = "该面此工序已完成，请转动分度轮或换盘"
		return -1
	if stage == Stage.POLISH and absf(angle - cut_angles[facet]) > 0.6:
		last_error = "抛光需贴合实际刻面：%.1f°" % cut_angles[facet]
		return -1
	var heating: float = (31.0 if stage == Stage.CUT else 15.0) * pressure
	temperature += (heating - (1.7 if water else 0.035) * (temperature - 20.0)) * delta
	thermal_damage += maxf(0.0, temperature - GEMS[gem_id].heat) * delta * 0.75
	check_fracture()
	if failed: return -2
	if stage == Stage.CUT:
		if is_inf(starts[facet]):
			cut_angles[facet] = angle
			cut_depths[facet] = depth_offset
			starts[facet] = Solid.support(body, facet_normal(facet, angle)) + 0.01
			chip_sources[facet] = body
		var normal := facet_normal(facet, cut_angles[facet])
		var next_progress: float = minf(1.25 if allow_overcut else 1.0, values[facet] + delta * 0.64 * pressure)
		var final_depth: float = tasks[facet].d - cut_depths[facet]
		var distance: float = lerpf(starts[facet], final_depth, next_progress)
		var before: float = Solid.volume(body)
		body = Solid.clip(body, normal, distance, facet)
		inner_body = Solid.clip(inner_body, normal, distance, facet)
		var after: float = Solid.volume(body)
		if before - after > 1.0 and (int(next_progress * 5) > int(values[facet] * 5) or next_progress >= 1.0):
			removal_events.append({"body": Solid.clip(chip_sources[facet], -normal, -distance, facet), "fracture": false})
			chip_sources[facet] = body
		if next_progress>=0.80 and not chipped_tasks.has(facet) and chip_risk()>1.0:
			remember_repair_state()
			make_edge_chip()
		values[facet] = next_progress
		revision += 1
		if after < initial_volume * 0.025:
			fracture("过切损伤 · 剩余晶体不足")
			return -2
		quality = geometry_quality()
	else:
		values[facet] = minf(1.0, values[facet] + delta * 0.85 * pressure)
		prepolish[facet] = values[facet]
		revision += 1
	return 1 if values[facet] >= (1.25 if allow_overcut and stage == Stage.CUT else 1.0) else 0

func remember_repair_state() -> void:
	repair_checkpoint = {"body": body.duplicate(true), "inner": inner_body.duplicate(true), "chips": chips.duplicate(true), "chipped": chipped_tasks.duplicate(true), "quality": quality}

func can_magic_repair() -> bool:
	return not repair_checkpoint.is_empty() and (failed or not chips.is_empty())

func magic_repair() -> bool:
	if not can_magic_repair(): return false
	body = repair_checkpoint.body
	inner_body = repair_checkpoint.inner
	chips = repair_checkpoint.chips
	chipped_tasks = repair_checkpoint.chipped
	quality = repair_checkpoint.quality
	failed = false
	failure_reason = ""
	last_error = ""
	thermal_damage = 0.0
	temperature = 20.0
	removal_events.clear()
	repair_checkpoint.clear()
	revision += 1
	return true

func geometry_quality() -> float:
	var error := 0.0
	for i in range(tasks.size()):
		if cut[i] > 0.0: error += absf(cut_angles[i] - tasks[i].angle) * 1.8 + absf(cut_depths[i]) * 1.3
	return clampf(100.0 - error - chips.size()*4.0, 0.0, 100.0)

func carats() -> float: return snappedf(GEMS[gem_id].rough * Solid.volume(body) / initial_volume, 0.01)

func light_return() -> float:
	var hits := 0
	var returned := 0
	for x in range(-3, 4):
		for z in range(-3, 4):
			var ray: Dictionary = Solid.trace(body, Vector3(x * 2.5, -100, z * 2.5), Vector3(0, 1, 0), GEMS[gem_id].ri)
			if ray.hit:
				hits += 1
				if ray.exit.y < -0.05: returned += 1
	return float(returned) / maxf(1, hits)

func save_piece() -> bool:
	if stage != Stage.SHOWCASE or saved or failed: return false
	var planes: Array = []
	for f in body: planes.append([f.n.x, f.n.y, f.n.z, f.d, f.tag])
	collection.append({"gem_id": gem_id, "shape_id": shape_id, "shape": cut_name(), "recipe": imported_cut, "quality": quality, "score": overall_score(), "scores": facet_scores.duplicate(), "grades": facet_grades.duplicate(), "carats": carats(), "planes": planes, "chips": chips, "crystal_orientation": crystal_orientation, "return": optical_return, "date": Time.get_datetime_string_from_system()})
	if not save_collection():
		collection.pop_back()
		return false
	saved = true
	return true

func save_collection() -> bool:
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(collection, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return false
	return DirAccess.rename_absolute(save_path + ".tmp", save_path) == OK

func load_collection() -> void:
	if not FileAccess.file_exists(save_path): return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if parsed is Array:
		for entry in parsed:
			if entry is Dictionary and entry.get("gem_id") is float and int(entry.gem_id) >= 0 and int(entry.gem_id) < GEMS.size() and entry.get("carats") is float and entry.get("quality") is float: collection.append(entry)

## This is a tuned game risk index, not a fracture-mechanics probability.
func chip_risk() -> float:
	var d: Dictionary = Data.ENTRIES[gem_id]
	var n := facet_normal(facet,angle)
	var alignment := 0.0
	for plane in Data.cleavage_normals(gem_id):
		var oriented: Vector3 = plane.rotated(Vector3.RIGHT,crystal_orientation*PI/6.0)
		alignment = maxf(alignment,pow(absf(n.dot(oriented)),8.0))
	var fine := 1.25 if shape_id in [2,4] or tasks[facet].tier==3 else 1.0
	return (0.25+float(d.brittleness)*0.4+float(d.cleavage_strength)*alignment)*fine*maxf(0.0,(pressure-1.0)*2.0+maxf(0.0,depth_offset-1.0)*0.18)

func make_edge_chip() -> bool:
	# Truncate a real exposed facet corner. A single plane is a convex chip
	# approximation, not a full conchoidal or propagated fracture simulation.
	var face: Dictionary = {}
	for f in body:
		if f.tag==facet: face=f; break
	if face.is_empty(): return false
	var corner: Vector3 = face.v[0]
	for v in face.v:
		if v.x+v.z>corner.x+corner.z: corner=v
	var radial := corner.normalized()
	var n: Vector3 = (radial*0.75+face.n*0.25).normalized()
	var distance := Solid.support(body,n)-clampf(chip_risk()*1.4,1.2,4.0)
	var detached := Solid.clip(body,-n,-distance,-3)
	var damaged := Solid.clip(body,n,distance,-3)
	if damaged.is_empty() or Solid.volume(detached)<0.01: return false
	body=damaged
	inner_body=Solid.clip(inner_body,n,distance,-3)
	removal_events.append({"body":detached,"fracture":false})
	chips.append({"facet":facet,"risk":chip_risk(),"normal":[n.x,n.y,n.z],"distance":distance})
	chipped_tasks[facet]=true
	revision+=1
	return true

func collection_body(entry: Dictionary) -> Array:
	if not entry.get("planes") is Array or entry.planes.size()<4 or entry.planes.size()>256: return []
	var reconstructed: Array=Stock.box(Vector3(128,128,128))
	for plane in entry.planes:
		if not plane is Array or plane.size()!=5: return []
		var n:=Vector3(float(plane[0]),float(plane[1]),float(plane[2]))
		var d:=float(plane[3])
		if not n.is_finite() or not is_finite(d) or n.length()<0.99 or n.length()>1.01: return []
		reconstructed=Solid.clip(reconstructed,n,d,int(plane[4]))
	return reconstructed

func restore_piece(entry: Dictionary) -> bool:
	var restored:=collection_body(entry)
	if restored.is_empty(): return false
	reset(int(entry.gem_id),int(entry.get("shape_id",0)))
	if entry.get("recipe") is Dictionary and entry.recipe.get("ok",false):
		imported_cut=entry.recipe.duplicate(true)
		reset(int(entry.gem_id))
	body=restored
	inner_body=restored.duplicate(true)
	stage=Stage.SHOWCASE
	saved=true
	quality=float(entry.quality)
	if entry.get("scores") is Array:
		for i in range(mini(facet_scores.size(),entry.scores.size())): facet_scores[i] = int(entry.scores[i])
	if entry.get("grades") is Array:
		for i in range(mini(facet_grades.size(),entry.grades.size())): facet_grades[i] = str(entry.grades[i])
	optical_return=float(entry.get("return",0.0))
	initial_volume=GEMS[gem_id].rough*Solid.volume(body)/maxf(0.001,float(entry.carats))
	chips=entry.get("chips",[]).duplicate(true)
	crystal_orientation=int(entry.get("crystal_orientation",0))
	for i in range(tasks.size()): cut[i]=1.0; polish[i]=1.0; prepolish[i]=1.0
	revision+=1
	return true
