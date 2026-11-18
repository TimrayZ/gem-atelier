extends SceneTree
const Workshop=preload("res://scripts/workshop.gd")
const Solid=preload("res://scripts/solid_geometry.gd")
func _initialize() -> void:
	var m=Workshop.new()
	m.reset(4,4)
	m.stage=2
	m.pressure=1.8
	var aligned: float=m.chip_risk()
	m.crystal_orientation=2
	assert(absf(aligned-m.chip_risk())>0.05,"Crystal orientation affects directional cleavage risk")
	m.pressure=1.0
	assert(m.chip_risk()<1.0,"Light pressure is safe in the game model")
	m.reset(4,4)
	while m.stage!=4:
		assert(not m.failed,"Nonfatal edge damage must allow finishing")
		if m.stage in [0,1]: m.advance(); continue
		var values: Array[float]=m.cut if m.stage==2 else m.polish
		if m.section_done(values): m.advance(); continue
		if values[m.facet]>=1.0: m.next_facet(); continue
		m.wheel=0 if m.stage==2 else 1
		# Risky pressure on the final table produces a corner that cannot be
		# accidentally removed by a later crown cut during this test.
		m.pressure=1.8 if m.tasks[m.facet].tier==3 and m.stage==2 else 1.0
		var before: float=Solid.volume(m.body)
		assert(m.work(0.08)>=0)
		assert(Solid.volume(m.body)<=before+0.01,"Damage never adds material")
		m.removal_events.clear()
	assert(m.chips.size()>0 and m.body.any(func(f): return f.tag==-3),"Permanent chipped plane reaches the viewer")
	assert(not m.failed and m.quality<100.0,"Chipping is distinct from catastrophic loss")
	m.save_path="user://test_damage_v09.json"
	assert(m.save_piece())
	var saved=JSON.parse_string(FileAccess.get_file_as_string(m.save_path))
	assert(saved[0].chips.size()>0 and saved[0].planes.any(func(p):return int(p[4])==-3),"Save actual missing geometry")
	DirAccess.remove_absolute(m.save_path)
	print("DIRECTION / PERMANENT CHIP / CONTINUATION / SAVE: passed; chips=",m.chips.size())
	quit()
