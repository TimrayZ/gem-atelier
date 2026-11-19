extends RefCounted
const Solid=preload("res://scripts/solid_geometry.gd")
const Stock=preload("res://scripts/rough_stock.gd")

static func fail(message: String) -> Dictionary: return {"ok":false,"error":message}

static func read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return fail("文件不存在")
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>1024*1024: return fail("无法读取或文件超过 1 MB")
	var text=file.get_as_text().trim_prefix("\ufeff")
	match path.get_extension().to_lower():
		"asc": return asc(text)
		"gcs": return gcs(text)
	return fail("请选择 GemCAD .asc 或 Gem Cut Studio .gcs；二进制 .gem 暂不支持")

static func tier(angle: float, depth: float, index: float, gear: int, name: String) -> Dictionary:
	var pavilion=angle<0.0
	var a=absf(angle)
	var girdle=absf(a-90.0)<0.0001
	return {"tier":1 if girdle else (0 if pavilion else (3 if a<0.0001 else 2)),"section":0 if pavilion or girdle else 1,"index":index*96.0/gear,"azimuth":PI/2.0+TAU*index/gear,"angle":a,"d":depth,"name":name}

static func asc(text: String) -> Dictionary:
	if not text.strip_edges().begins_with("GemCad"): return fail("缺少 GemCad 文件头")
	var gear=96
	var tasks: Array=[]
	var title="导入切工"
	var have_title=false
	for raw in text.replace("\r","").split("\n"):
		var line=raw.strip_edges().replace("\t"," ")
		if line.is_empty(): continue
		var parts=line.split(" ",false)
		match parts[0]:
			"g":
				if parts.size()<2 or not parts[1].is_valid_int(): return fail("无效分度轮")
				gear=int(parts[1])
				if gear<1 or gear>720: return fail("分度轮需为 1–720")
				if parts.size()>2 and float(parts[2])!=0.0: return fail("暂不支持带非零分度偏移的 ASC")
			"H":
				if not have_title: title=line.substr(2).left(64); have_title=true
			"a":
				if parts.size()<4 or not parts[1].is_valid_float() or not parts[2].is_valid_float(): return fail("刻面角度或距离无效")
				var angle=float(parts[1]); var depth=float(parts[2])
				if absf(angle)>90.0: return fail("ASC 角度需在 ±90° 内")
				if angle==0.0 and (depth<0 or parts[1].begins_with("-")): return fail("本版暂不导入平底底尖，请移除该行后重试")
				var j=3
				var label="导入刻面"
				while j<parts.size():
					if parts[j]=="G": break
					if parts[j]=="n":
						j+=2
						continue
					if not parts[j].is_valid_float(): return fail("不支持的 ASC 刻面字段："+parts[j])
					var index=float(parts[j])
					if index<0 or index>gear: return fail("分度超出轮齿范围")
					tasks.append(tier(angle,depth,index,gear,label))
					j+=1
	return normalize(tasks,title,gear)

static func gcs(text: String) -> Dictionary:
	if text.to_upper().contains("<!DOCTYPE") or text.to_upper().contains("<!ENTITY"): return fail("不支持 XML 外部实体")
	var parser=XMLParser.new()
	if parser.open_buffer(text.to_utf8_buffer())!=OK: return fail("无法解析 GCS XML")
	var tasks: Array=[]
	var gear=96
	var title="导入 GCS"
	var root=false
	var angle=0.0
	var depth=0.0
	var have_depth=false
	var label="导入刻面"
	var guide=false
	while parser.read()==OK:
		if parser.get_node_type()!=XMLParser.NODE_ELEMENT: continue
		var node=parser.get_node_name()
		var attr: Dictionary={}
		for i in range(parser.get_attribute_count()): attr[parser.get_attribute_name(i)]=parser.get_attribute_value(i)
		match node:
			"GemCutStudio": root=true
			"index":
				gear=int(attr.get("gear","96"))
				if gear<1 or gear>720: return fail("GCS 分度轮需为 1–720")
			"info": title=str(attr.get("title",title)).left(64)
			"tier":
				if not str(attr.get("angle","")).is_valid_float(): return fail("GCS tier 缺少有效 angle")
				angle=float(attr.angle)
				depth=float(attr.get("depth","nan"))
				have_depth=attr.has("depth")
				label=str(attr.get("name","导入刻面")).left(40)
				guide=str(attr.get("guide","false"))=="true"
				if float(attr.get("frosting","0"))!=0: return fail("本版暂不支持磨砂面，请先导出无磨砂版本")
			"facet":
				if guide: continue
				if not have_depth: return fail("本版 GCS 需要 tier depth；请用 GCS 重新保存后导入")
				if not attr.has("index_angle"): return fail("本版 GCS 需要 index_angle")
				var a=-(180.0-angle) if angle>90 else angle
				if angle==180: return fail("暂不支持平底底尖")
				var task=tier(a,depth,float(attr.index_angle)/360.0*gear,gear,label)
				if attr.has("nx") and attr.has("ny") and attr.has("nz"):
					var n=Vector3(float(attr.ny),-float(attr.nz),-float(attr.nx))
					if not n.is_finite() or absf(n.length()-1.0)>0.01: return fail("GCS 法线无效")
					task.azimuth=atan2(n.z,n.x)
					task.angle=rad_to_deg(atan2(Vector2(n.x,n.z).length(),absf(n.y)))
					task.section=0 if n.y>=-0.00001 else 1
					task.tier=1 if absf(n.y)<0.00001 else (0 if task.section==0 else (3 if task.angle<0.0001 else 2))
				tasks.append(task)
	if not root: return fail("缺少 GemCutStudio 根节点")
	return normalize(tasks,title,gear)

static func normalize(tasks: Array, title: String, gear: int) -> Dictionary:
	if gear<1 or gear>720 or tasks.size()<5 or tasks.size()>180: return fail("分度或刻面数量无效（支持 5–180 面）")
	var body: Array=Stock.box(Vector3.ONE*1000.0)
	var both=[false,false]
	for t in tasks:
		if not is_finite(t.angle) or not is_finite(t.d) or not is_finite(t.azimuth) or t.d<=0 or t.d>100: return fail("角度／距离不是有效有限数或距离不为正")
		var a=deg_to_rad(t.angle)
		var n=Vector3(sin(a)*cos(t.azimuth),(1.0 if t.section==0 else -1.0)*cos(a),sin(a)*sin(t.azimuth))
		body=Solid.clip(body,n,t.d,0)
		both[t.section]=true
	if body.is_empty() or not both[0] or not both[1] or Solid.volume(body)<0.00001: return fail("切工没有形成有效的冠亭实体")
	var radius=0.0
	for f in body:
		for v in f.v:
			if v.length()>500: return fail("切工未封闭；请提供完整的冠部、亭部和腰围")
			radius=maxf(radius,Vector2(v.x,v.z).length())
	if radius<=0: return fail("切工宽度无效")
	var scale=30.0/radius
	for f in body:
		for v in f.v:
			if absf(v.y*scale)>55: return fail("切工过高，超出本作原石范围")
	for t in tasks: t.d*=scale
	tasks.sort_custom(func(a,b): return a.section<b.section or (a.section==b.section and a.tier<b.tier))
	return {"ok":true,"name":title,"gear":gear,"tasks":tasks,"note":"已归一化为约 60 游戏单位宽；RI 采用所选材料。"}
