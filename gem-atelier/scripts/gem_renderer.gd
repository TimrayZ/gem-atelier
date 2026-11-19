extends RefCounted
## Shared by the live viewer and saved-piece thumbnails. No display score inputs.
const PIXEL=preload("res://shaders/gem_pixel.gdshader")
const REAL=preload("res://shaders/gem_optics.gdshader")
const PALETTES=[
	[Color("06352f"),Color("21946e"),Color("9adcb6"),Color("62b795")],
	[Color("291747"),Color("9650b3"),Color("dfb0ed"),Color("ba80d3")],
	[Color("101b48"),Color("265bc5"),Color("749cf0"),Color("597dd3")],
	[Color("263d59"),Color("6e9db8"),Color("c2e7eb"),Color("8abacb")],
	[Color("4c3c2c"),Color("b79c63"),Color("f1dfae"),Color("d5bf8b")]
]

static func configure(material: ShaderMaterial, model, body: Array, yaw: float, tilt: float, light: int, real_mode: bool, logical: Vector2, scale: float, footprint: Vector2, bounces: int=12) -> void:
	var shader=REAL if real_mode else PIXEL
	if material.shader!=shader: material.shader=shader
	var planes:=PackedVector4Array()
	for face in body:
		var n: Vector3=face.n.rotated(Vector3.UP,yaw).rotated(Vector3.RIGHT,tilt)
		planes.append(Vector4(n.x,n.y,n.z,face.d))
	material.set_shader_parameter("plane_count",mini(planes.size(),256))
	planes.resize(256)
	material.set_shader_parameter("planes",planes)
	material.set_shader_parameter("logical_size",logical)
	material.set_shader_parameter("center",logical*0.5)
	material.set_shader_parameter("gem_scale",scale)
	material.set_shader_parameter("material_id",model.gem_id)
	material.set_shader_parameter("refractive_index",model.GEMS[model.gem_id].ri)
	material.set_shader_parameter("dispersion",model.GEMS[model.gem_id].dispersion)
	material.set_shader_parameter("absorption_bands",model.Data.bands(model.gem_id))
	material.set_shader_parameter("illuminant",light)
	material.set_shader_parameter("pixel_footprint",footprint)
	material.set_shader_parameter("max_bounces",bounces)
	material.set_shader_parameter("art_pixel",maxf(logical.y/259.0,footprint.y) if logical.x>300 else 1.0)
	var palette: Array=PALETTES[model.gem_id]
	for i in range(4):
		var c: Color=palette[i]
		material.set_shader_parameter(["art_dark","art_mid","art_light","art_edge"][i],Vector3(c.r,c.g,c.b))
	material.set_shader_parameter("art_white",Vector3(1.0,0.91,0.73) if light==1 else Vector3(0.94,0.99,1.0))
