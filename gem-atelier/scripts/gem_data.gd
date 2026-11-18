extends RefCounted
## Factual properties are separate from the dimensionless gameplay risk model.
const ENTRIES = [
	{"formula":"BeAl₂O₄", "structure":"斜方晶系；Cr 微量取代 Al 与变色有关。", "rough":"板状、短柱状晶体；可见假六方连生或磨圆砾石。", "cuts":"椭圆、垫形、混合式；需兼顾颜色、晶向与保重。", "hardness":"8.5", "toughness":"宝石用途通常韧性优良。", "cleavage":"矿物手册记 {110} 较明显、{010} 不完全、{001} 较差；GIA 宝石护理资料通常列无解理。游戏只给予较弱方向敏感性。", "ri":"1.746–1.756，双折射、二轴晶", "spectrum":"Cr 相关选择性吸收；绿、红透射窗口随照明光谱改变相对贡献。游戏采用拟合吸收带，未模拟完整偏振及多色性。", "source":"chrysoberyl", "brittleness":0.18, "cleavage_strength":0.18},
	{"formula":"SiO₂", "structure":"三方晶系石英；微量铁及辐照相关色心产生紫色。", "rough":"六方外形的柱体、尖顶晶簇、断片或磨圆料。", "cuts":"明亮式、椭圆、阶梯式及弧面；依色带选向。", "hardness":"7", "toughness":"通常良好，仍会脆性破裂。", "cleavage":"实用宝石学通常视为无明显解理；贝壳状断口。矿物手册记少见的弱解理或裂理。", "ri":"1.544 / 1.553，单轴正晶", "spectrum":"宽可见光吸收带形成紫色；热处理可改变色心，游戏温度并非真实处理温度。", "source":"quartz", "brittleness":0.30, "cleavage_strength":0.0},
	{"formula":"Al₂O₃", "structure":"三方晶系刚玉；蓝色常涉及 Fe–Ti 电荷转移，具体取决于样品。", "rough":"桶状、双锥或六方外形晶体；冲积料常已磨圆。", "cuts":"椭圆、垫形、混合式；有星光的材料常作弧面。", "hardness":"9", "toughness":"通常韧性优良。", "cleavage":"无真正解理；可存在 {0001}、{10−11} 裂理。裂理取决于缺陷，游戏不假设每颗都有。", "ri":"约 1.759–1.772，单轴负晶", "spectrum":"Fe、Ti 等杂质的吸收影响蓝色。游戏为代表性拟合谱，不代表所有蓝宝石。", "source":"corundum", "brittleness":0.14, "cleavage_strength":0.0},
	{"formula":"C", "structure":"立方晶系；碳原子构成三维共价网络。", "rough":"八面体、磨蚀的十二面体外形、双晶或不规则断片。", "cuts":"圆形明亮、椭圆、阶梯式等；八心八箭要求严格光学对称，八重几何对称并不保证达标。", "hardness":"10", "toughness":"硬度高，沿解理仍可能崩裂。", "cleavage":"{111} 八面体方向完全解理；薄腰、尖角更脆弱。", "ri":"n(589 nm)≈2.4175；n(486 nm)≈2.4354", "spectrum":"无色样品可见光吸收弱；本作不模拟荧光。色散采用 B–G 波段差 0.044 的近似 Cauchy 拟合。", "source":"diamond", "brittleness":0.28, "cleavage_strength":0.75},
	{"formula":"KAlSi₃O₈", "structure":"单斜晶系钾长石；Al、Si、O 构成骨架，K 占据空隙。", "rough":"短柱状、板状晶体、双晶或沿解理形成的块状断片。", "cuts":"阶梯式、椭圆等；薄尖角需格外谨慎。", "hardness":"6–6.5", "toughness":"脆性，解理较发育。", "cleavage":"{001} 与 {010} 两组完全解理，约呈直角；游戏简化为两个正交方向。", "ri":"约 1.518–1.525，双折射、二轴晶", "spectrum":"透明浅色正长石的吸收取决于杂质；游戏采用弱蓝端吸收。", "source":"orthoclase", "brittleness":0.72, "cleavage_strength":0.95}
]

static func gaussian(l: float, mean: float, width: float) -> float:
	return exp(-0.5*pow((l-mean)/width,2.0))

## Author-fitted extinction per game length unit, shared by the plot and shader.
static func absorption(id: int, l: float) -> float:
	match id:
		0: return maxf(0.0005,0.0025+0.075*gaussian(l,575,20)+0.034*gaussian(l,423,30)-0.002*gaussian(l,670,35))
		1: return 0.0015+0.027*gaussian(l,545,43)
		3: return 0.00006
		4: return 0.0008+0.004*gaussian(l,430,45)
	return 0.0015+0.045*gaussian(l,585,65)+0.020*gaussian(l,695,42)

static func bands(id: int) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	for band in range(20): result.append(absorption(id,407.5+15.0*band))
	return result

static func cleavage_normals(id: int) -> Array:
	match id:
		0: return [Vector3(1,1,0).normalized(),Vector3.UP,Vector3.FORWARD]
		3: return [Vector3(1,1,1).normalized(),Vector3(-1,1,1).normalized(),Vector3(1,-1,1).normalized(),Vector3(1,1,-1).normalized()]
		4: return [Vector3.UP,Vector3.FORWARD]
	return []
