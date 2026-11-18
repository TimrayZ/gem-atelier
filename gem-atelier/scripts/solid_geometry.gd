extends RefCounted
## Closed convex solid: every cut retains n.dot(p) <= d, with a real cap.
const EPS := 0.00005

static func face(points: Array, tag: int) -> Dictionary:
	var normal: Vector3 = (points[1] - points[0]).cross(points[2] - points[0]).normalized()
	return {"v": points, "n": normal, "d": normal.dot(points[0]), "tag": tag}

static func ellipsoid(radii: Vector3, longitude: int = 20, latitude: int = 10) -> Array:
	var result: Array = []
	for j in range(latitude):
		for i in range(longitude):
			var points: Array = []
			for ij in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var a: float = TAU * ij.x / longitude
				var b: float = PI * ij.y / latitude
				var p := Vector3(sin(b) * cos(a), -cos(b), sin(b) * sin(a)) * radii
				if points.is_empty() or p.distance_to(points.back()) > EPS: points.append(p)
			if points.size() > 2 and points[0].distance_to(points.back()) < EPS: points.pop_back()
			if points.size() < 3: continue
			var f := face(points, -1)
			if f.n.dot(points[0]) < 0.0:
				points.reverse()
				f = face(points, -1)
			result.append(f)
	return result

static func unique_append(points: Array, p: Vector3) -> void:
	for old in points:
		if p.distance_squared_to(old) < EPS * EPS: return
	points.append(p)

static func clip(body: Array, normal: Vector3, distance: float, tag: int) -> Array:
	var result: Array = []
	var cap: Array = []
	var removed := false
	for f in body:
		var output: Array = []
		var vertices: Array = f.v
		for i in range(vertices.size()):
			var a: Vector3 = vertices[i]
			var b: Vector3 = vertices[(i + 1) % vertices.size()]
			var da: float = normal.dot(a) - distance
			var db: float = normal.dot(b) - distance
			if da <= EPS: unique_append(output, a)
			else: removed = true
			if (da < -EPS and db > EPS) or (da > EPS and db < -EPS):
				var p: Vector3 = a.lerp(b, da / (da - db))
				unique_append(output, p)
				unique_append(cap, p)
			elif absf(da) <= EPS: unique_append(cap, a)
		if output.size() >= 3:
			var area := Vector3.ZERO
			for k in range(1, output.size() - 1): area += (output[k] - output[0]).cross(output[k + 1] - output[0])
			if area.length_squared() > EPS * EPS: result.append({"v": output, "n": f.n, "d": f.d, "tag": f.tag})
	if removed and cap.size() >= 3:
		var center := Vector3.ZERO
		for p in cap: center += p
		center /= cap.size()
		var axis := normal.cross(Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT).normalized()
		var second := normal.cross(axis)
		cap.sort_custom(func(a, b): return atan2((a - center).dot(second), (a - center).dot(axis)) < atan2((b - center).dot(second), (b - center).dot(axis)))
		result.append({"v": cap, "n": normal, "d": distance, "tag": tag})
	return result

static func volume(body: Array) -> float:
	var total := 0.0
	for f in body:
		for i in range(1, f.v.size() - 1): total += f.v[0].dot(f.v[i].cross(f.v[i + 1])) / 6.0
	return absf(total)

static func support(body: Array, normal: Vector3) -> float:
	var value := -INF
	for f in body:
		for p in f.v: value = maxf(value, normal.dot(p))
	return value

static func centroid(body: Array) -> Vector3:
	var points: Array = []
	for f in body:
		for p in f.v: unique_append(points, p)
	var center := Vector3.ZERO
	for p in points: center += p
	return center / maxf(1.0, points.size())

static func ray_entry(body: Array, origin: Vector3, direction: Vector3) -> Dictionary:
	var near := 0.0
	var far := INF
	var normal := Vector3.ZERO
	for f in body:
		var denominator: float = f.n.dot(direction)
		var numer: float = f.d - f.n.dot(origin)
		if absf(denominator) < EPS:
			if numer < -EPS: return {}
			continue
		var hit: float = numer / denominator
		if denominator < 0.0:
			if hit > near:
				near = hit
				normal = f.n
		else: far = minf(far, hit)
	if near > far or far < 0.0: return {}
	return {"p": origin + direction * near, "n": normal, "t": near}

static func refract_ray(direction: Vector3, normal: Vector3, eta: float) -> Vector3:
	var cosine := normal.dot(direction)
	var k := 1.0 - eta * eta * (1.0 - cosine * cosine)
	if k < 0.0: return Vector3.ZERO
	return eta * direction - (eta * cosine + sqrt(k)) * normal

## Follows the transmitted branch with total internal reflection. No score input.
static func trace(body: Array, origin: Vector3, direction: Vector3, ri: float) -> Dictionary:
	var entry := ray_entry(body, origin, direction)
	if entry.is_empty(): return {"hit": false}
	var ray := refract_ray(direction, entry.n, 1.0 / ri).normalized()
	var point: Vector3 = entry.p + ray * 0.001
	var length := 0.0
	for bounce in range(12):
		var nearest := INF
		var normal := Vector3.ZERO
		for f in body:
			var denominator: float = f.n.dot(ray)
			if denominator > EPS:
				var distance: float = (f.d - f.n.dot(point)) / denominator
				if distance > EPS and distance < nearest:
					nearest = distance
					normal = f.n
		if is_inf(nearest): break
		length += nearest
		point += ray * nearest
		var outgoing := refract_ray(ray, -normal, ri)
		if outgoing.length_squared() > EPS: return {"hit": true, "exit": outgoing.normalized(), "bounces": bounce, "length": length}
		ray = ray - 2.0 * normal.dot(ray) * normal
		point += ray * 0.001
	return {"hit": true, "exit": Vector3.ZERO, "bounces": 12, "length": length}
