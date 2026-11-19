extends RefCounted
## Shared by the live viewer and saved-piece thumbnails. No display score inputs.
const PIXEL=preload("res://shaders/gem_pixel.gdshader")
const REAL=preload("res://shaders/gem_optics.gdshader")
# Shared fitted spectral shapes; independently art-directed optical density.
# Colourless stones stay neutral. These are visual controls, not measured spectra.
const REAL_ABSORPTION_SCALE = [1.20, 1.15, 1.35, 1.0, 1.0, 1.0, 1.20, 1.15, 1.15, 1.25, 1.0, 1.0, 1.0]
const PIXEL_ABSORPTION_SCALE = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
static func configure(material: ShaderMaterial, model, body: Array, yaw: float, tilt: float, light: int, real_mode: bool, logical: Vector2, scale: float, footprint: Vector2, bounces: int=12, weights: Vector3=Vector3(-1,0,0)) -> void:
	var shader=REAL if real_mode else PIXEL
	if material.shader!=shader: material.shader=shader
	var planes:=PackedVector4Array()
	var centers:=PackedVector3Array()
	for face in body:
		var n: Vector3=face.n.rotated(Vector3.UP,yaw).rotated(Vector3.RIGHT,tilt)
		planes.append(Vector4(n.x,n.y,n.z,face.d))
		var center:=Vector3.ZERO
		for vertex in face.v: center+=vertex
		center/=face.v.size()
		centers.append(center.rotated(Vector3.UP,yaw).rotated(Vector3.RIGHT,tilt))
	material.set_shader_parameter("plane_count",mini(planes.size(),256))
	planes.resize(256)
	material.set_shader_parameter("planes",planes)
	if not real_mode:
		centers.resize(256)
		material.set_shader_parameter("facet_centers",centers)
		var body_colour: Color=model.GEMS[model.gem_id][["day","warm","neutral"][light]]
		if weights.x>=0.0:
			body_colour=model.GEMS[model.gem_id].day*weights.x+model.GEMS[model.gem_id].warm*weights.y+model.GEMS[model.gem_id].neutral*weights.z
		var outline:=body_colour.lerp(Color("829195"),0.35).darkened(0.07)
		material.set_shader_parameter("outline_colour",Vector3(outline.r,outline.g,outline.b))
	material.set_shader_parameter("logical_size",logical)
	material.set_shader_parameter("center",logical*0.5)
	material.set_shader_parameter("gem_scale",scale)
	material.set_shader_parameter("material_id",model.gem_id)
	material.set_shader_parameter("refractive_index",model.GEMS[model.gem_id].ri)
	material.set_shader_parameter("dispersion",model.GEMS[model.gem_id].dispersion)
	var bands: PackedFloat32Array = model.Data.bands(model.gem_id)
	var scale_factor: float = (REAL_ABSORPTION_SCALE if real_mode else PIXEL_ABSORPTION_SCALE)[model.gem_id]
	for i in range(bands.size()): bands[i] *= scale_factor
	material.set_shader_parameter("absorption_bands",bands)
	var alt: PackedFloat32Array = model.Data.alternate_bands(model.gem_id)
	for i in range(alt.size()): alt[i] *= scale_factor
	material.set_shader_parameter("absorption_bands_alt",alt)
	material.set_shader_parameter("zoned",model.gem_id in [10,11,12])
	var axis := Vector3.UP if model.gem_id==10 else Vector3.RIGHT
	material.set_shader_parameter("zone_axis",axis.rotated(Vector3.UP,yaw).rotated(Vector3.RIGHT,tilt))
	material.set_shader_parameter("zone_width",20.0 if model.gem_id==10 else 12.0)
	material.set_shader_parameter("illuminant",light)
	if weights.x<0.0: weights=Vector3(1,0,0) if light==0 else (Vector3(0,1,0) if light==1 else Vector3(0,0,1))
	material.set_shader_parameter("light_weights",weights)
	material.set_shader_parameter("pixel_footprint",footprint)
	material.set_shader_parameter("max_bounces",bounces)
	material.set_shader_parameter("art_pixel",maxf(1.5,maxf(logical.y/150.0,footprint.y)))
