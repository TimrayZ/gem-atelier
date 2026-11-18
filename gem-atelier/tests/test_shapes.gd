extends SceneTree
const Workshop=preload("res://scripts/workshop.gd")
const Solid=preload("res://scripts/solid_geometry.gd")
func _initialize() -> void:
	for gem in range(Workshop.GEMS.size()):
		for shape in range(Workshop.SHAPES.size()):
			var m=Workshop.new()
			m.reset(gem,shape)
			var guard:=0
			while m.stage!=4 and guard<10000:
				guard+=1
				assert(not m.failed,"Recipe must preserve viable solid")
				if m.stage in [0,1]: m.advance(); continue
				var values: Array[float]=m.cut if m.stage==2 else m.polish
				if m.section_done(values): m.advance(); continue
				if values[m.facet]>=1: m.next_facet(); continue
				m.wheel=0 if m.stage==2 else 1
				assert(m.work(0.12)>=0,"Recipe should have valid tools and angle")
				m.removal_events.clear()
			assert(m.stage==4,"Every material/shape combination reaches viewer")
			assert(m.carats()>0,"Remaining volume must be positive")
			assert(m.body.size()<256,"Fits optical boundary budget")
			print("SHAPE ",gem,"/",shape," tasks=",m.tasks.size()," faces=",m.body.size()," mass=",m.carats())
	print("ALL ",Workshop.GEMS.size()*Workshop.SHAPES.size()," MATERIAL / SHAPE COMBINATIONS: passed")
	quit()
