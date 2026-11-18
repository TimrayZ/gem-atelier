extends RefCounted
const Solid=preload("res://scripts/solid_geometry.gd")
const NAMES=["板状断晶","六方柱状晶体","六方桶状晶体","八面体晶体","斜柱状解理块"]

static func box(r: Vector3) -> Array:
	var v: Array=[]
	for y in [-1,1]:
		for z in [-1,1]:
			for x in [-1,1]: v.append(Vector3(x,y,z)*r)
	var faces: Array=[]
	for ids in [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]:
		var points: Array=[]
		for i in ids: points.append(v[i])
		var f:=Solid.face(points,-1)
		if f.n.dot(points[0])<0:
			points.reverse()
			f=Solid.face(points,-1)
		faces.append(f)
	return faces

static func make(gem: int, kind: int) -> Array:
	if kind==1:
		var radii: Vector3=[Vector3(44,45,38),Vector3(42,51,40),Vector3(46,42,40),Vector3(45,43,43),Vector3(46,44,40)][gem]
		var worn: Array=Solid.ellipsoid(radii,20,10)
		worn=Solid.clip(worn,Vector3(0.35,0.8,0.2).normalized(),39.0,-1)
		return Solid.clip(worn,Vector3(-0.6,-0.2,0.6).normalized(),42.0,-1)
	var body: Array=box(Vector3(63,63,63))
	if gem==3:
		for x in [-1,1]:
			for y in [-1,1]:
				for z in [-1,1]:
					var n:=Vector3(x,y,z).normalized()
					body=Solid.clip(body,n,63.0/sqrt(3.0),-1)
	elif gem in [1,2]:
		for i in range(6):
			var a:=i*TAU/6.0
			body=Solid.clip(body,Vector3(cos(a),0,sin(a)),43.0,-1)
			if gem==1:
				body=Solid.clip(body,Vector3(cos(a)*0.6,-0.8,sin(a)*0.6),47.0,-1)
			else:
				for sign_y in [-1,1]:
					body=Solid.clip(body,Vector3(cos(a)*0.65,sign_y*0.76,sin(a)*0.65).normalized(),50.0,-1)
		body=Solid.clip(body,Vector3(0,1,0),44.0 if gem==1 else 49.0,-1)
		if gem==2: body=Solid.clip(body,Vector3(0,-1,0),49.0,-1)
	elif gem==0:
		body=box(Vector3(43,47,37))
		for i in range(4):
			var a:=PI/4.0+i*PI/2.0
			body=Solid.clip(body,Vector3(cos(a),0,sin(a)),49.0,-1)
		body=Solid.clip(body,Vector3(0.1,-1,0.04).normalized(),44.0,-1)
	else:
		body=box(Vector3(44,49,38))
		var skewed: Array=[]
		for f in body:
			var points: Array=[]
			for p in f.v: points.append(Vector3(p.x+p.y*0.12,p.y,p.z))
			skewed.append(Solid.face(points,-1))
		body=skewed
	return body

static func core(body: Array) -> Array:
	var inner: Array=[]
	for f in body:
		var points: Array=[]
		for p in f.v: points.append(p*0.94)
		inner.append(Solid.face(points,-1))
	return inner
