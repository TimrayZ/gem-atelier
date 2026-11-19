extends SceneTree
const Cut=preload("res://scripts/cut_import.gd")
const Workshop=preload("res://scripts/workshop.gd")
const Solid=preload("res://scripts/solid_geometry.gd")
func _initialize() -> void:
 var asc=Cut.read_file("res://cuts/atelier-octagon.asc")
 var gcs=Cut.read_file("res://cuts/atelier-octagon.gcs")
 assert(asc.get("ok",false),str(asc))
 assert(gcs.get("ok",false),str(gcs))
 assert(asc.tasks.size()==25 and gcs.tasks.size()==25)
 assert(not Cut.asc("GemCad 5.0\na 40 1 0").ok)
 assert(not Cut.gcs('<!DOCTYPE bad><GemCutStudio/>').ok)
 assert(not Cut.asc("GemCad 5.0\ng 0 0").ok)
 var masses=[]
 for design in [asc,gcs]:
  var m=Workshop.new()
  assert(m.apply_cut(design))
  assert(m.cut_name()=="Atelier Practice Octagon")
  var guard=0
  while m.stage!=4 and guard<10000:
   guard+=1
   assert(not m.failed)
   if m.stage in [0,1]: m.advance();continue
   var values=m.cut if m.stage==2 else m.polish
   if m.section_done(values):m.advance();continue
   if values[m.facet]>=1:m.next_facet();continue
   m.wheel=0 if m.stage==2 else 1
   assert(m.work(0.12)>=0)
   m.removal_events.clear()
  assert(m.stage==4 and m.body.size()<256)
  masses.append(Solid.volume(m.body))
  m.save_path="user://test_import_release.json"
  assert(m.save_piece())
  var loaded=Workshop.new()
  loaded.save_path=m.save_path
  loaded.load_collection()
  assert(loaded.restore_piece(loaded.collection[0]))
  assert(loaded.cut_name()==m.cut_name() and loaded.tasks.size()==25)
  assert(absf(Solid.volume(loaded.body)-Solid.volume(m.body))<0.1)
  DirAccess.remove_absolute(m.save_path)
 assert(absf(masses[0]-masses[1])<0.1,"ASC and GCS conventions yield matching solids")
 print("ASC / GCS / VALIDATION / ACTUAL CUT / IMPORTED SAVE RESTORE: passed")
 quit()
