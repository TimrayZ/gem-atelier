extends Node2D
## A small 284 x 207 canvas. Flat-shaded 3D facets are projected and snapped
## to this canvas, then enlarged with nearest-neighbour filtering.

const Solid = preload("res://scripts/solid_geometry.gd")
var model
var chunks: Array = []
var physics_root: Node3D
var optics: ColorRect
var optics_material: ShaderMaterial
var optics_display: TextureRect
var max_bounces := 12
var real_mode := false
var large_view_active := false
const Renderer=preload("res://scripts/gem_renderer.gd")
var pose := Quaternion.IDENTITY
var machine_center := Vector2(130, 110)
var optical_enabled := true
var inspection := false
var inclusion_enabled := false
var seen_generation := -1
var yaw: float = 0.35
var tilt: float = -0.52
var light_mode: int = 0
var working: bool = false
var auto_rotate: bool = false
var t: float = 0.0
var zoom: float = 1.0
var particles: Array[Dictionary] = []
var displayed_color := Color("56c7a1")

func _process(delta: float) -> void:
	t += delta
	if model == null:
		return
	if auto_rotate and model.stage == 4:
		yaw += delta * 0.3
	var key: String = ["day", "warm", "neutral"][light_mode]
	displayed_color = displayed_color.lerp(model.GEMS[model.gem_id][key], minf(1.0, delta * 5.0))
	update_solid_visuals(delta)
	for particle in particles:
		particle.pos += particle.vel * delta
		particle.vel.y += delta * 65.0
		particle.life -= delta
	particles = particles.filter(func(p): return p.life > 0.0)
	if working and particles.size() < 45 and int(t * 40) % 2 == 0:
		particles.append({"pos": Vector2(145, 142), "vel": Vector2(randf_range(-50, 65), randf_range(-55, -15)), "life": randf_range(0.15, 0.5)})
	queue_redraw()

func block(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(roundf(x), roundf(y), w, h), c)

func poly(points: Array, color: Color) -> void:
	# Triangulate before snapping: a thin projected face can collapse to a line
	# or acquire repeated vertices on the pixel grid. Such triangles have no area.
	var packed := PackedVector2Array(points)
	var indices := Geometry2D.triangulate_polygon(packed)
	for i in range(0, indices.size(), 3):
		var a: Vector2 = packed[indices[i]].round()
		var b: Vector2 = packed[indices[i+1]].round()
		var c: Vector2 = packed[indices[i+2]].round()
		if absf((b-a).cross(c-a)) >= 0.5:
			draw_colored_polygon(PackedVector2Array([a,b,c]),color)

func ellipse(center: Vector2, radius: Vector2, color: Color, segments: int = 24) -> void:
	var points: Array = []
	for i in range(segments):
		points.append(center + Vector2(cos(TAU * i / segments), sin(TAU * i / segments)) * radius)
	poly(points, color)

func star(p: Vector2, color: Color, size: int = 3) -> void:
	block(p.x - size, p.y, size * 2 + 1, 1, color)
	block(p.x, p.y - size, 1, size * 2 + 1, color)
	block(p.x - 1, p.y - 1, 3, 3, color)

func _draw() -> void:
	if model == null:
		return
	if model.stage == 4:
		draw_gallery()
	else:
		draw_workshop()
	if not inspection and model.stage in [2,3]:
		for chunk in chunks:
			draw_chunk(chunk)
	for particle in particles:
		block(particle.pos.x, particle.pos.y, 2, 1, Color("f7d99c") if model.stage == 2 else Color("a5e4e6"))

func draw_workshop() -> void:
	block(0, 0, 284, 207, Color("6c5c47"))
	block(0, 0, 284, 140, Color("bba482"))
	# Painted wall, bricks and ambient grain.
	for i in range(76):
		var x := posmod(i * 83 + 17, 284)
		var y := posmod(i * 37 + 3, 139)
		block(x, y, 2, 1, Color("c2ad8c"))
	for y in [36, 79, 121]:
		block(0, y, 284, 1, Color("ad9777"))
	# Window and the distant garden.
	block(18, 12, 77, 86, Color("6a5843"))
	block(22, 16, 69, 78, Color("afbaa2"))
	block(25, 19, 63, 39, Color("d1d2ab"))
	block(25, 58, 63, 33, Color("9aa885"))
	poly([Vector2(25, 76), Vector2(37, 51), Vector2(44, 64), Vector2(54, 43), Vector2(68, 70), Vector2(80, 50), Vector2(88, 76), Vector2(88, 91), Vector2(25, 91)], Color("7d9072"))
	block(53, 17, 5, 77, Color("7b6c50"))
	block(24, 51, 64, 4, Color("7b6c50"))
	block(15, 95, 84, 5, Color("b99865"))
	poly([Vector2(25, 100), Vector2(88, 100), Vector2(193, 166), Vector2(88, 166)], Color(0.78, 0.85, 0.66, 0.045))
	# Tool rack, paper slips and copper lamp.
	block(111, 20, 62, 3, Color("9e8763"))
	for x in [118, 130, 143, 158]:
		block(x, 24, 2, 15, Color("91a69a"))
		block(x - 2, 38, 6, 10, Color("897257"))
	block(195, 22, 23, 29, Color("b5ad88"))
	block(198, 26, 17, 1, Color("757d65"))
	block(198, 30, 12, 1, Color("757d65"))
	block(198, 34, 15, 1, Color("757d65"))
	block(249, 64, 4, 85, Color("ae9669"))
	poly([Vector2(250, 64), Vector2(233, 38), Vector2(230, 40), Vector2(246, 67)], Color("b79f72"))
	poly([Vector2(219, 36), Vector2(237, 36), Vector2(243, 49), Vector2(212, 49)], Color("b49a67"))
	block(215, 49, 25, 2, Color("e3c68b"))
	poly([Vector2(214, 51), Vector2(239, 51), Vector2(269, 145), Vector2(145, 145)], Color(1.0, 0.86, 0.53, 0.035))
	# Workbench in deliberately large pixel shapes.
	block(0, 148, 284, 59, Color("66523c"))
	block(0, 148, 284, 4, Color("a38a61"))
	block(0, 153, 284, 2, Color("3b3a2f"))
	for i in range(16):
		block(posmod(i * 47, 284), 160 + i % 5 * 8, 20 + i % 4 * 7, 1, Color("725c42"))
	block(0, 187, 284, 3, Color("443e30"))
	block(17, 191, 72, 15, Color("534735"))
	block(26, 194, 54, 1, Color("7f6a4d"))
	block(48, 198, 10, 2, Color("b49d71"))
	# Small plant on the bench.
	block(26, 132, 12, 16, Color("b07e5e"))
	block(24, 131, 16, 4, Color("c39770"))
	block(31, 114, 2, 18, Color("7e9b76"))
	poly([Vector2(31, 125), Vector2(22, 115), Vector2(24, 111), Vector2(32, 117)], Color("789971"))
	poly([Vector2(33, 120), Vector2(41, 108), Vector2(45, 109), Vector2(40, 119)], Color("92ad7a"))
	# Spare polishing laps.
	ellipse(Vector2(235, 163), Vector2(21, 7), Color("323c37"))
	ellipse(Vector2(235, 160), Vector2(21, 6), Color("81928a"))
	ellipse(Vector2(235, 160), Vector2(16, 4), Color("64786f"))
	block(233, 158, 4, 3, Color("b2b8a0"))
	if model.stage <= 1 or inspection:
		# Specimen cushion and rough.
		poly([Vector2(86, 153), Vector2(105, 140), Vector2(186, 140), Vector2(204, 153), Vector2(198, 173), Vector2(93, 173)], Color("485849"))
		poly([Vector2(88, 152), Vector2(105, 142), Vector2(185, 142), Vector2(202, 152), Vector2(195, 162), Vector2(96, 162)], Color("71816b"))
		draw_rough(Vector2(145, 114), 1.05)
		if model.stage == 1:
			draw_clamp()
	else:
		# Lapidary machine, rotating lap and dop arm.
		block(96, 164, 99, 21, Color("182f31"))
		block(99, 164, 93, 3, Color("769082"))
		block(105, 178, 13, 4, Color("a98953"))
		block(176, 173, 6, 6, Color("8fc4a1") if working else Color("586d5f"))
		ellipse(Vector2(145, 157), Vector2(48, 14), Color("1b2e2e"))
		ellipse(Vector2(145, 153), Vector2(48, 13), Color("8a9d92"))
		ellipse(Vector2(145, 152), Vector2(43, 10), Color("5e7f78") if model.wheel == 0 else (Color("a2b5a3") if model.wheel == 1 else Color("bba67e")))
		for i in range(10):
			var a: float = i * TAU / 10.0 + t * (7.0 if working else 0.6)
			block(145 + cos(a) * 36, 152 + sin(a) * 8, 3, 1, Color("bfd0ba"))
		draw_handpiece()
		draw_gem(machine_center, 0.72, false)
		# Adjustable water drip.
		block(193, 94, 4, 62, Color("667f73"))
		block(175, 93, 21, 4, Color("93aa96"))
		if model.water:
			for i in range(4):
				block(176, 101 + fmod(t * 26.0 + i * 12.0, 47), 1, 3, Color("9fd6d1"))
		if working:
			star(Vector2(148, 142), Color("fff0c0"), 2)
	# Corner registration marks add an inspection-camera feel.
	for p in [Vector2(8, 8), Vector2(274, 8), Vector2(8, 196), Vector2(274, 196)]:
		block(p.x, p.y, 3, 1, Color("6d8b7b"))
		block(p.x, p.y, 1, 3, Color("6d8b7b"))

func draw_clamp() -> void:
	# Axial dop + adhesive, not claws gripping the sides of the gem.
	block(142, 48, 6, 30, Color("c1c4a7"))
	block(138, 76, 14, 6, Color("94734a"))
	if model.awaiting_transfer:
		block(142, 150, 6, 29, Color("c1c4a7"))
		block(136, 147, 18, 5, Color("94734a"))
		block(121, 178, 48, 5, Color("667f73"))

func draw_rough(center: Vector2, scale_factor: float) -> void:
	draw_solid(model.body, center, scale_factor * 0.92, false, false)

func draw_gallery() -> void:
	# One neutral colour for both channels; no scenery enters the optical rays.
	block(0,0,284,207,Color("23383d"))
	draw_gem(Vector2(142,103),1.5*zoom,true)

func rotate_vertex(v: Vector3) -> Vector3:
	return v.rotated(Vector3.UP, yaw).rotated(Vector3.RIGHT, tilt)

func draw_gem(center: Vector2, scale_factor: float, finished: bool) -> void:
	if finished and optical_enabled: return
	draw_solid(model.body, center, scale_factor, finished, not finished)


func _ready() -> void:
	physics_root = Node3D.new()
	add_child(physics_root)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6.0, 0.05, 6.0)
	collision.shape = shape
	floor_body.add_child(collision)
	floor_body.position = Vector3(1.42, -1.78, 0)
	physics_root.add_child(floor_body)
	optics = ColorRect.new()
	optics.size = Vector2(284, 207)
	optics.mouse_filter = Control.MOUSE_FILTER_IGNORE
	optics_material = ShaderMaterial.new()
	optics_material.shader = Renderer.PIXEL
	optics.material = optics_material
	add_child(optics)

func update_solid_visuals(_delta: float) -> void:
	if seen_generation != model.generation:
		seen_generation = model.generation
		displayed_color = model.GEMS[model.gem_id][["day","warm","neutral"][light_mode]]
		for old in chunks:
			old.node.queue_free()
		chunks.clear()
	var normal: Vector3 = model.facet_normal(model.facet, model.cut_angles[model.facet] if model.cut[model.facet] > 0 else model.angle)
	# Gem coordinates use screen-down +Y; physics coordinates below use Godot +Y up.
	pose = Quaternion(normal, Vector3(0, 1, 0))
	var bottom := -INF
	for f in model.body:
		for v in f.v:
			var q := machine_vertex(v)
			bottom = maxf(bottom, q.y)
	machine_center = Vector2(133, 150.0 - bottom * 0.72)
	while not model.removal_events.is_empty():
		spawn_chunk(model.removal_events.pop_front())
	for chunk in chunks.duplicate():
		chunk.life -= _delta
		if chunk.life <= 0.0:
			chunk.node.queue_free()
			chunks.erase(chunk)
	optics.visible = model.stage == 4 and optical_enabled and not large_view_active
	if is_instance_valid(optics_display): optics_display.visible = optics.visible
	if optics.visible:
		Renderer.configure(optics_material,model,model.body,yaw,tilt,light_mode,real_mode,Vector2(284,207),1.5*zoom,Vector2(0.5,0.5),max_bounces)
		var inclusions := PackedVector4Array()
		for p in [Vector3(-6,-4,8),Vector3(9,8,-6),Vector3(-11,12,4)]:
			var v: Vector3 = rotate_vertex(p)
			inclusions.append(Vector4(v.x,v.y,v.z,0.55 if model.gem_id==3 else 1.2))
		optics_material.set_shader_parameter("inclusions",inclusions)
		optics_material.set_shader_parameter("inclusion_count",(1 if model.gem_id==3 else 3) if inclusion_enabled else 0)
		optics_material.set_shader_parameter("scattering_strength", (0.00003 if model.gem_id==3 else (0.001 if model.gem_id==4 else 0.00015))+model.thermal_damage*0.00002)
		optics_material.set_shader_parameter("surface_roughness",0.004+minf(0.06,model.thermal_damage*0.0015))
		optics_material.set_shader_parameter("refractive_index", model.GEMS[model.gem_id].ri)
		optics_material.set_shader_parameter("dispersion", model.GEMS[model.gem_id].dispersion)
		optics_material.set_shader_parameter("illuminant", light_mode)

func machine_vertex(v: Vector3) -> Vector3:
	return (pose * v).rotated(Vector3.RIGHT, -0.35)

func draw_handpiece() -> void:
	# Octagonal handpiece rests on a height-adjusted platform. Dop follows the
	# crystal axis, while the chosen facet normal points down onto the lap.
	var axis := Vector3(0, -1 if model.section == 0 else 1, 0)
	var mount_hit := Solid.ray_entry(model.body, axis*100.0, -axis)
	var attach: Vector3 = mount_hit.p if not mount_hit.is_empty() else axis*35.0
	var a := machine_vertex(attach)
	var b := machine_vertex(attach + axis * 34.0)
	var c := machine_vertex(attach + axis * 52.0)
	var pa := machine_center + Vector2(a.x,a.y)*0.72
	var pb := machine_center + Vector2(b.x,b.y)*0.72
	var pc := machine_center + Vector2(c.x,c.y)*0.72
	draw_line(pa.round(),pb.round(),Color("c7c7a7"),4.0)
	draw_line(pb.round(),pc.round(),Color("80988a"),8.0)
	ellipse(pa,Vector2(5,3),Color("9e8050"),8)
	var wheel_points: Array = []
	for i in range(8):
		wheel_points.append(pc+Vector2(cos(i*TAU/8),sin(i*TAU/8))*10.0)
	poly(wheel_points,Color("b9ab7d"))
	ellipse(pc,Vector2(4,4),Color("3b5149"),8)
	var platform_y: float = minf(144.0,pc.y+10)
	block(pc.x-16,platform_y,32,4,Color("879b86"))
	block(pc.x+12,platform_y+4,5,159-platform_y,Color("536f63"))
	block(pc.x+6,159,18,4,Color("263e37"))
	# Table work uses a 45-degree adapter; the stone axis is vertical.
	if model.tasks[model.facet].tier == 3:
		poly([pb+Vector2(-6,0),pb+Vector2(8,0),pb+Vector2(8,-10)],Color("c7ac75"))

func draw_solid(body: Array, center: Vector2, scale_factor: float, finished: bool, machine: bool) -> void:
	var faces: Array = []
	var exposed_core: Dictionary = {}
	if model.crust:
		for f in model.inner_body:
			if f.tag >= 0:
				var cap: Array = []
				for p in f.v:
					var v: Vector3 = machine_vertex(p) if machine else rotate_vertex(p)
					cap.append(center+Vector2(v.x,v.y)*scale_factor)
				exposed_core[f.tag] = cap
	for f in body:
		var points: Array = []
		var depth := 0.0
		for p in f.v:
			var v: Vector3 = machine_vertex(p) if machine else rotate_vertex(p)
			points.append(center+Vector2(v.x,v.y)*scale_factor*(220.0/(220.0-v.z) if finished else 1.0))
			depth += v.z
		var n: Vector3 = machine_vertex(f.n) if machine else rotate_vertex(f.n)
		faces.append({"p":points,"n":n,"z":depth/f.v.size(),"tag":f.tag})
	faces.sort_custom(func(a,b): return a.z < b.z)
	var light := Vector3(-0.45,-0.75,0.8).normalized()
	for f in faces:
		var shade: float = maxf(0.0,f.n.dot(light))
		var raw: bool = f.tag == -1
		var c: Color = Color("82745c") if raw and model.crust else displayed_color
		c = c.darkened(0.70-shade*0.53)
		if raw:
			c = c.lightened(fmod(absf(f.n.x*17.0+f.n.z*23.0),0.06))
		elif f.tag == -3:
			c = displayed_color.darkened(0.48).lightened(shade*0.25)
		elif f.tag == -2:
			c = Color("1e302c").lightened(shade*0.12)
		elif f.tag >= 0:
			var polished: float = model.polish[f.tag]
			var spec: float = pow(maxf(0.0,f.n.dot(Vector3(-0.3,-0.4,0.86).normalized())),32.0)
			c = c.lerp(displayed_color.lightened(0.75),spec*polished)
			if not finished and f.tag == model.facet: c = c.lightened(0.10)
		if model.crust and f.tag >= 0:
			poly(f.p,Color("82745c").darkened(0.65-shade*0.45))
			if exposed_core.has(f.tag): poly(exposed_core[f.tag],c)
		else:
			poly(f.p,c)
		if not raw:
			var points := PackedVector2Array(f.p)
			points.append(points[0])
			draw_polyline(points,Color(displayed_color,0.20),1.0)
			if f.tag >= 0 and model.prepolish[f.tag] < 1.0:
				var mid: Vector2 = (f.p[0]+f.p[1]+f.p[2])/3.0
				block(mid.x,mid.y,3,1,Color(displayed_color,0.25))

func spawn_chunk(event: Dictionary) -> void:
	if event.body.is_empty(): return
	while chunks.size() >= 12:
		var old: Dictionary = chunks.pop_front()
		old.node.queue_free()
	var center: Vector3 = Solid.centroid(event.body)
	var vertices := PackedVector3Array()
	var transformed: Array = []
	for f in event.body:
		var local: Array = []
		for v in f.v:
			var q := machine_vertex(v-center)*0.72*0.01
			q.y = -q.y
			vertices.append(q)
			local.append(q)
		transformed.append(local)
	var body := RigidBody3D.new()
	var collider := CollisionShape3D.new()
	var convex := ConvexPolygonShape3D.new()
	convex.points = vertices
	collider.shape = convex
	body.add_child(collider)
	body.mass = maxf(0.001,Solid.volume(event.body)*0.00001)
	body.gravity_scale = 0.18
	var material := PhysicsMaterial.new()
	material.bounce = 0.18
	material.friction = 0.8
	body.physics_material_override = material
	physics_root.add_child(body)
	var pos := machine_vertex(center)*0.72
	body.position = Vector3((machine_center.x+pos.x)*0.01,-(machine_center.y+pos.y)*0.01,pos.z*0.01)
	body.linear_velocity = Vector3(randf_range(-0.18,0.18),0.05,0.02)
	body.angular_velocity = Vector3(randf_range(-2,2),randf_range(-2,2),randf_range(-2,2))
	chunks.append({"node":body,"faces":transformed,"life":2.5,"crack":event.fracture})

func draw_chunk(chunk: Dictionary) -> void:
	if not is_instance_valid(chunk.node): return
	for f in chunk.faces:
		var points: Array = []
		for v in f:
			var p: Vector3 = chunk.node.global_transform*v
			points.append(Vector2(p.x,-p.y)*100.0)
		var alpha: float = minf(1.0,chunk.life)
		poly(points,Color(displayed_color.darkened(0.35),alpha))
