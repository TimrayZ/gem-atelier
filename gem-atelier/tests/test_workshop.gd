extends SceneTree
const Workshop = preload("res://scripts/workshop.gd")
const Solid = preload("res://scripts/solid_geometry.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func closed(body: Array) -> bool:
	var edges: Dictionary = {}
	for f in body:
		for i in range(f.v.size()):
			var a: Vector3 = f.v[i].snapped(Vector3.ONE*0.001)
			var b: Vector3 = f.v[(i+1)%f.v.size()].snapped(Vector3.ONE*0.001)
			var key: String = str(a)+str(b) if str(a)<str(b) else str(b)+str(a)
			edges[key] = edges.get(key,0)+1
	for count in edges.values():
		if count != 2: return false
	return true

func finish_face(m, id: int, angle_error: float = 0.0, depth: float = 0.0) -> void:
	m.facet = id
	m.angle = m.tasks[id].angle+angle_error if m.stage == 2 else m.cut_angles[id]
	m.depth_offset = depth
	var values: Array[float] = m.cut if m.stage == 2 else m.polish
	for frame in range(22):
		var before: float = Solid.volume(m.body)
		m.work(0.08)
		check(Solid.volume(m.body) <= before+0.02,"Material removal is monotonic")
		if values[id] >= 1.0 or m.failed: break
	check(values[id] == 1.0 and not m.failed,"Facet operation completes")

func complete(m, pavilion_angle_error: float = 0.0) -> void:
	m.advance()
	m.advance()
	for section in range(2):
		for id in m.active_ids(): finish_face(m,id,pavilion_angle_error if id<8 else 0.0)
		check(m.advance() and m.stage==3,"Cut section enters prepolish")
		check(not m.advance(),"Unpolished section blocks transfer/showcase")
		for wheel in [1]:
			m.wheel = wheel
			for id in m.active_ids(): finish_face(m,id)
		var before: float = Solid.volume(m.body)
		check(m.advance(),"Completed polish unlocks next stage")
		if section == 0:
			check(m.awaiting_transfer and m.stage==1,"Transfer required before crown")
			check(m.advance() and m.stage==2 and m.section==1,"Transfer unlocks crown")
			check(absf(Solid.volume(m.body)-before)<0.001,"Transfer preserves existing geometry")
	check(m.stage==4,"Both halves reach showcase")

func _initialize() -> void:
	var rough: Array = Solid.ellipsoid(Vector3(44,48,40))
	check(closed(rough),"Ellipsoid is watertight")
	var normal := Vector3(0.7,0.5,0.2).normalized()
	var kept: Array = Solid.clip(rough,normal,8.0,0)
	var removed: Array = Solid.clip(rough,-normal,-8.0,0)
	check(closed(kept) and closed(removed),"Both halves are closed after cutting")
	check(absf(Solid.volume(rough)-Solid.volume(kept)-Solid.volume(removed))<0.2,"Removed fragment conserves volume")
	for f in kept:
		for v in f.v: check(normal.dot(v)<=8.0002,"All retained vertices satisfy cut plane")
	var partial = Workshop.new()
	partial.advance()
	partial.advance()
	partial.work(0.4)
	check(partial.cut[0]>0 and partial.cut[0]<1,"Partial stroke remains partial")
	check(Solid.volume(partial.body)<partial.initial_volume,"First stroke changes the ellipsoid itself")
	check(partial.body.any(func(f):return f.tag==-1) and partial.body.any(func(f):return f.tag==0),"Uncut skin and first flat face coexist")
	check(Solid.volume(partial.inner_body)<Solid.volume(partial.body),"Finite rind thickness remains after first cut")
	check(closed(partial.inner_body),"Exposed inner crystal is a closed clipped solid")
	check(partial.inner_body.any(func(f):return f.tag==0),"Cut exposes an inner-crystal cross-section")
	check(not partial.advance(),"One partial face cannot unlock a finished gem")
	var tilted = Workshop.new()
	tilted.advance()
	tilted.advance()
	tilted.angle = 25.0
	check(tilted.work(0.4)>=0,"Wrong angle is allowed to cut")
	check(tilted.cut_angles[0]==25.0,"Actual wrong angle is recorded")
	check(tilted.body.any(func(f):return f.tag==0 and f.n.distance_to(tilted.facet_normal(0,25))<0.001),"Actual plane normal matches wrong angle")
	var deep = Workshop.new()
	deep.advance()
	deep.advance()
	finish_face(deep,0,0.0,10.0)
	var shallow = Workshop.new()
	shallow.advance()
	shallow.advance()
	finish_face(shallow,0)
	check(Solid.volume(deep.body)<Solid.volume(shallow.body),"Deeper feed physically removes more material")
	for id in range(3):
		var m = Workshop.new()
		m.reset(id)
		check(m.body.all(func(f):return f.tag==-1),"Raw has no predetermined gemstone facets")
		check(not m.save_piece(),"Unfinished piece cannot be saved")
		complete(m)
		check(closed(m.body),"Finished gemstone remains watertight")
		check(m.body.all(func(f):return f.tag>=0),"Ideal cutting removes all original ellipsoid skin")
		check(m.body.size()==25,"Seventeen main faces and eight girdle planes")
		check(m.carats()>0 and m.carats()<m.GEMS[id].rough,"Weight follows actual remaining volume")
		m.save_path = "user://test_geometry_%d.json"%id
		check(m.save_piece(),"Actual solid can be saved")
		check(not m.save_piece(),"Duplicate collection prevented")
		var loaded = Workshop.new()
		loaded.save_path = m.save_path
		loaded.load_collection()
		check(loaded.collection.size()==1 and loaded.collection[0].planes.size()==25,"Saved geometry round trip")
		loaded.stage = 4
		check(loaded.save_piece(),"Existing collection file can be replaced")
		DirAccess.remove_absolute(m.save_path)
		print("MATERIAL ",id," mass=",m.carats()," axial return=",m.optical_return)
	var ideal = Workshop.new()
	ideal.reset(1)
	complete(ideal)
	var bad = Workshop.new()
	bad.reset(1)
	complete(bad,-18.0)
	print("OPTICAL COMPARISON ideal=",ideal.optical_return," shallow=",bad.optical_return)
	check(ideal.optical_return>bad.optical_return+0.2,"Shallow pavilion leaks from actual Snell/TIR geometry")
	var shape_before: float = Solid.volume(bad.body)
	bad.quality=100.0
	check(absf(bad.light_return()-bad.optical_return)<0.001,"Optical paths do not depend on quality score")
	check(absf(Solid.volume(bad.body)-shape_before)<0.001,"Viewing never repairs the wrong shape")
	var hot = Workshop.new()
	hot.reset(1)
	hot.advance()
	hot.advance()
	hot.set_water(false)
	hot.temperature=78.0
	for frame in range(20):
		hot.work(0.08)
		if hot.failed: break
	check(hot.failed and hot.body.any(func(f):return f.tag==-2),"Heat stress creates actual fracture cap")
	check(hot.work(1.0)==-2 and not hot.advance() and not hot.save_piece(),"Fractured specimen permanently blocks work, advance and saving")
	hot.cool(100)
	check(hot.failed,"Cooling cannot heal a fracture")
	check(not hot.removal_events.is_empty(),"Fracture creates a real separated chunk")
	print("GEOMETRY / PROCESS / OPTICS: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
