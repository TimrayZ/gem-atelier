extends SceneTree
var font: SystemFont
var bold: SystemFont
var card: Control
var assets: String
var output: String
func _initialize() -> void:call_deferred("run")
func label(text: String,x: int,y: int,w: int,h: int,size: int=32,colour: Color=Color("4b3629"),heavy: bool=false) -> void:
 var node=Label.new();node.text=text;node.position=Vector2(x,y);node.size=Vector2(w,h)
 node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 node.add_theme_font_override("font",bold if heavy else font)
 node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",colour)
 card.add_child(node)
func rect(x: int,y: int,w: int,h: int,colour: Color) -> void:
 var node=ColorRect.new();node.position=Vector2(x,y);node.size=Vector2(w,h);node.color=colour;card.add_child(node)
func picture(path: String,x: int,y: int,w: int,h: int,nearest: bool=true) -> void:
 var image=Image.load_from_file(path)
 assert(image!=null,path)
 var node=TextureRect.new();node.texture=ImageTexture.create_from_image(image)
 node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST if nearest else CanvasItem.TEXTURE_FILTER_LINEAR
 node.position=Vector2(x,y);node.size=Vector2(w,h);card.add_child(node)
func run() -> void:
 root.size=Vector2i(1920,1080);root.content_scale_size=Vector2i.ZERO
 card=Control.new();card.size=Vector2(1920,1080);root.add_child(card)
 font=SystemFont.new();font.font_names=PackedStringArray(["Microsoft YaHei UI","Microsoft YaHei","sans-serif"])
 bold=SystemFont.new();bold.font_names=font.font_names;bold.font_weight=700
 var assets=ProjectSettings.globalize_path("res://../artifacts/media-assets")
 rect(0,0,1920,1080,Color("e8d8b6"));rect(0,0,1920,14,Color("6e523d"))
 rect(815,0,1105,1080,Color("23383d"))
 label("GEM ATELIER  /  首发体验版",82,90,1080,65,36,Color("6d805c"),true)
 label("石间小铺",77,218,1000,170,116,Color("4b3629"),true)
 label("从一块原石，\n到自己的宝石。",88,425,900,180,59,Color("4b3629"),true)
 label("10 种原料 × 10 种切工",88,710,1000,80,40,Color("6d805c"),true)
 label("像素火彩 · 变石换光 · 绒布收藏室",88,815,1110,70,33,Color("80684e"))
 picture(assets.path_join("gem-5-gem.png"),700,30,1290,850)
 picture(ProjectSettings.globalize_path("res://art/longlong-guide.png"),1430,660,400,410)
 label("Windows 试玩 · Godot",90,955,1000,55,30,Color("80684e"))
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/发布素材-v0.11.0/B站/封面-1920x1080.png"))
 quit()
