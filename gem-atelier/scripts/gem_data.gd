extends RefCounted
## Factual properties are separate from the dimensionless gameplay risk model.
const ENTRIES = [
	{"formula":"BeAl₂O₄", "structure":"斜方晶系；Cr 微量取代 Al 与变色有关。", "rough":"板状、短柱状晶体；可见假六方连生或磨圆砾石。", "cuts":"椭圆、垫形、混合式；需兼顾颜色、晶向与保重。", "hardness":"8.5", "toughness":"宝石用途通常韧性优良。", "cleavage":"矿物手册记 {110} 较明显、{010} 不完全、{001} 较差；GIA 宝石护理资料通常列无解理。游戏只给予较弱方向敏感性。", "ri":"1.746–1.756，双折射、二轴晶", "spectrum":"Cr 相关选择性吸收；绿、红透射窗口随照明光谱改变相对贡献。游戏采用拟合吸收带，未模拟完整偏振及多色性。", "source":"chrysoberyl", "brittleness":0.18, "cleavage_strength":0.18},
	{"formula":"SiO₂", "structure":"三方晶系石英；微量铁及辐照相关色心产生紫色。", "rough":"六方外形的柱体、尖顶晶簇、断片或磨圆料。", "cuts":"明亮式、椭圆、阶梯式及弧面；依色带选向。", "hardness":"7", "toughness":"通常良好，仍会脆性破裂。", "cleavage":"实用宝石学通常视为无明显解理；贝壳状断口。矿物手册记少见的弱解理或裂理。", "ri":"1.544 / 1.553，单轴正晶", "spectrum":"宽可见光吸收带形成紫色；热处理可改变色心，游戏温度并非真实处理温度。", "source":"quartz", "brittleness":0.30, "cleavage_strength":0.0},
	{"formula":"Al₂O₃", "structure":"三方晶系刚玉；蓝色常涉及 Fe–Ti 电荷转移，具体取决于样品。", "rough":"桶状、双锥或六方外形晶体；冲积料常已磨圆。", "cuts":"椭圆、垫形、混合式；有星光的材料常作弧面。", "hardness":"9", "toughness":"通常韧性优良。", "cleavage":"无真正解理；可存在 {0001}、{10−11} 裂理。裂理取决于缺陷，游戏不假设每颗都有。", "ri":"约 1.759–1.772，单轴负晶", "spectrum":"Fe、Ti 等杂质的吸收影响蓝色。游戏选择浅蓝样本的拟合谱，不代表所有蓝宝石。", "source":"corundum", "brittleness":0.14, "cleavage_strength":0.0},
	{"formula":"C", "structure":"立方晶系；碳原子构成三维共价网络。", "rough":"八面体、磨蚀的十二面体外形、双晶或不规则断片。", "cuts":"圆形明亮、椭圆、阶梯式等；八心八箭要求严格光学对称，八重几何对称并不保证达标。", "hardness":"10", "toughness":"硬度高，沿解理仍可能崩裂。", "cleavage":"{111} 八面体方向完全解理；薄腰、尖角更脆弱。", "ri":"n(589 nm)≈2.4175；n(486 nm)≈2.4354", "spectrum":"无色样品可见光吸收弱；本作不模拟荧光。色散采用 B–G 波段差 0.044 的近似 Cauchy 拟合。", "source":"diamond", "brittleness":0.28, "cleavage_strength":0.75},
	{"formula":"KAlSi₃O₈", "structure":"单斜晶系钾长石；Al、Si、O 构成骨架，K 占据空隙。", "rough":"短柱状、板状晶体、双晶或沿解理形成的块状断片。", "cuts":"阶梯式、椭圆等；薄尖角需格外谨慎。", "hardness":"6–6.5", "toughness":"脆性，解理较发育。", "cleavage":"{001} 与 {010} 两组完全解理，约呈直角；游戏简化为两个正交方向。", "ri":"约 1.518–1.525，双折射、二轴晶", "spectrum":"透明浅色正长石的吸收取决于杂质；游戏采用弱蓝端吸收。", "source":"orthoclase", "brittleness":0.72, "cleavage_strength":0.95},
 {"formula":"SiC","structure":"碳化硅有多种多型；本作珠宝材料为实验室合成莫桑石。","rough":"天然常为微小六方薄板；珠宝加工通常使用合成晶体片或晶锭断块，本作采用后者。","cuts":"明亮式、椭圆、阶梯式；高色散不代表任意切形都有更多可见火彩。","hardness":"约 9.25–9.5","toughness":"通常良好；晶向和内部缺陷仍影响加工。","cleavage":"方向性按弱敏感模型处理，不把所有 SiC 多型当成同一晶体。","ri":"代表性合成材料约 2.648–2.691；本作取标量 2.648。","spectrum":"无色样本可见光吸收弱；B–G 色散代表值 0.104。尚未完整模拟双折射重影。","source":"Moissanite","brittleness":0.25,"cleavage_strength":0.15},
 {"formula":"Be₃Al₂Si₆O₁₈","structure":"六方晶系绿柱石，Cr/V 等杂质可产生绿色。","rough":"六方柱状、平顶或带锥面终端，也有破碎或磨圆料。","cuts":"常用切角长方阶梯式，也可椭圆、明亮式；裂隙较多的原料需避开薄尖角。","hardness":"7.5–8","toughness":"与裂隙及充填情况有关，不能只按硬度判断。","cleavage":"{0001} 不完全解理，脆性。","ri":"约 1.565–1.610，成分和品种相关。","spectrum":"本作拟合蓝紫与红端吸收，保留绿色透射窗，非实测谱。","source":"beryl","brittleness":0.63,"cleavage_strength":0.30},
 {"formula":"MgAl₂O₄","structure":"立方晶系；粉红色与微量 Cr 等杂质相关。","rough":"常为八面体，可有尖晶石律双晶；也见磨圆颗粒。","cuts":"明亮、椭圆、垫形与阶梯等。","hardness":"7.5–8","toughness":"通常良好，仍属脆性矿物。","cleavage":"可有 {111} 裂理，不等同于普遍发育的完全解理。","ri":"代表值约 1.719，单折射。","spectrum":"本作采用绿色波段的拟合吸收带；不同样本吸收不同。","source":"Spinel","brittleness":0.24,"cleavage_strength":0.0},
 {"formula":"Al₂SiO₄(F,OH)₂","structure":"斜方晶系黄玉；颜色与杂质和色心有关。","rough":"长短柱状，多面终端，柱面常有纵向生长条纹。","cuts":"椭圆、阶梯、明亮式等，装夹方向应考虑底面解理。","hardness":"8","toughness":"脆性，解理可降低某些方向的耐久性。","cleavage":"{001} 完全解理；本作加入方向相关的缺角风险。","ri":"约 1.606–1.644，双折射。","spectrum":"本作金色样本以蓝紫端拟合吸收呈色；不代表所有黄玉。","source":"topaz","brittleness":0.58,"cleavage_strength":0.85},
 {"formula":"Al₂O₃","structure":"三方晶系刚玉；Cr 微量取代产生红色。","rough":"桶状、柱状、平板状或磨圆颗粒，和蓝宝石同属刚玉。","cuts":"椭圆、垫形、混合与明亮式；星光原料常作弧面。","hardness":"9","toughness":"通常优良，缺陷与裂隙仍影响加工。","cleavage":"无真正解理，可有裂理。","ri":"约 1.759–1.772。","spectrum":"本作以蓝紫、绿黄波段的拟合吸收产生红色；尚不模拟荧光。","source":"corundum","brittleness":0.14,"cleavage_strength":0.0},
 {"formula":"NaAlSi₂O₆","structure":"以硬玉为主的多晶集合体；白绿分区可来自成分及结构变化。","rough":"不规则块体或磨圆砾石，可能有外皮。","cuts":"蛋面、雕件；游戏蛋面以多面体近似。","hardness":"约 6.5–7","toughness":"通常优良，具体受结构和裂隙影响。","cleavage":"单晶有两组解理；集合体的破裂行为更复杂。","ri":"约 1.66，集合体近似。","spectrum":"白绿分区与散射使用游戏拟合，并非实测样本；未完整模拟多晶体散射。","source":"jadeite","brittleness":0.22,"cleavage_strength":0.1},
 {"formula":"SiO₂","structure":"紫色和黄色石英同晶体色带，颜色与铁的状态及生长条件有关。","rough":"具色带的六方柱状石英晶体。","cuts":"长方阶梯、混合切工；常让台面同时展示紫黄两区。","hardness":"7","toughness":"通常良好。","cleavage":"无明显解理，常见贝壳状断口。","ri":"约 1.544–1.553。","spectrum":"本作沿晶体方向混合紫色与黄色拟合吸收，分区为近似。","source":"quartz","brittleness":0.30,"cleavage_strength":0.0},
 {"formula":"电气石族，成分可变","structure":"不同生长区微量元素浓度不同，可形成粉绿颜色分带。","rough":"长柱状晶体或磨圆料。","cuts":"长方阶梯和混合切工可展示纵向色带；西瓜碧玺常作薄片。","hardness":"约 7–7.5","toughness":"尚可；包裹体和裂隙影响加工。","cleavage":"解理不明显。","ri":"代表值约 1.62，实际随成分变化。","spectrum":"本作使用粉绿两区拟合吸收，未模拟完整多色性和双折射。","source":"tourmaline","brittleness":0.35,"cleavage_strength":0.05}

]

static func gaussian(l: float, mean: float, width: float) -> float:
	return exp(-0.5*pow((l-mean)/width,2.0))

## Author-fitted extinction per game length unit, shared by the plot and shader.
static func absorption(id: int, l: float) -> float:
	match id:
		0: return maxf(0.0005,0.0025+0.075*gaussian(l,575,20)+0.028*gaussian(l,423,30)-0.002*gaussian(l,670,35))
		1: return 0.0015+0.027*gaussian(l,545,43)
		# A lighter blue sapphire specimen; game-tuned, not a measured sample.
		2: return (0.0015+0.045*gaussian(l,585,65)+0.020*gaussian(l,695,42))*0.12+0.010*gaussian(l,640,60)
		3,5: return 0.00006
		6: return 0.001+0.038*gaussian(l,435,42)+0.037*gaussian(l,660,47)
		7: return 0.001+0.032*gaussian(l,535,48)
		9: return 0.001+0.050*gaussian(l,545,52)+0.025*gaussian(l,425,35)
		10: return 0.0015
		11: return absorption(1,l)
		12: return absorption(7,l)
		8: return 0.0007+0.024*gaussian(l,430,48)
		4: return 0.0008+0.004*gaussian(l,430,45)
	return 0.0015+0.045*gaussian(l,585,65)+0.020*gaussian(l,695,42)

static func bands(id: int) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	for band in range(20): result.append(absorption(id,407.5+15.0*band))
	return result

static func alternate_bands(id: int) -> PackedFloat32Array:
	var other := 6 if id in [10,12] else (8 if id==11 else id)
	return bands(other)

static func cleavage_normals(id: int) -> Array:
	match id:
		0: return [Vector3(1,1,0).normalized(),Vector3.UP,Vector3.FORWARD]
		3: return [Vector3(1,1,1).normalized(),Vector3(-1,1,1).normalized(),Vector3(1,-1,1).normalized(),Vector3(1,1,-1).normalized()]
		5: return [Vector3.UP]
		6,8: return [Vector3.UP]
		4: return [Vector3.UP,Vector3.FORWARD]
	return []
