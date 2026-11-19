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
func fresh(number: int,title: String,sub: String) -> void:
 if is_instance_valid(card):root.remove_child(card);card.queue_free()
 card=Control.new();card.size=Vector2(1080,1440);root.add_child(card)
 rect(0,0,1080,1440,Color("e8d8b6"));rect(0,0,1080,12,Color("6e523d"))
 label("石间小铺  /  GEM ATELIER",64,44,950,50,26,Color("6d805c"),true)
 label(title,64,122,950,165,64,Color("4b3629"),true)
 label(sub,66,290,950,72,29,Color("80684e"))
 rect(64,1375,952,2,Color("b69c76"))
 label("Godot 实机画面与游戏素材 · 首发体验版",64,1385,875,35,22,Color("8a745a"))
 label("%02d / 06"%number,930,1385,120,35,22,Color("8a745a"))
func save(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join(name+".png"))
 print("CARD ",name)
func run() -> void:
 root.size=Vector2i(1080,1440);root.content_scale_size=Vector2i.ZERO
 assets=ProjectSettings.globalize_path("res://../artifacts/media-assets")
 output=ProjectSettings.globalize_path("res://../artifacts/发布素材-v0.11.0/小红书")
 DirAccess.make_dir_recursive_absolute(output)
 font=SystemFont.new();font.font_names=PackedStringArray(["Microsoft YaHei UI","Microsoft YaHei","sans-serif"])
 bold=SystemFont.new();bold.font_names=font.font_names;bold.font_weight=700
 fresh(1,"把原石，\n磨成自己的宝石。","一间安静的像素宝石小铺，今天开门。")
 rect(48,394,984,676,Color("23383d"))
 picture(assets.path_join("gem-5-gem.png"),-160,380,1400,700)
 label("10 种原料  ×  10 种切工",90,1120,930,70,43,Color("6d805c"),true)
 label("切一面，磨一面。\n最后换盏灯，慢慢转着看。",90,1210,930,120,34)
 await save("01-封面")
 fresh(2,"每块原石，\n都有自己的模样。","按矿物晶形简化成像素原料，再逐面加工。")
 for i in range(4):
  var x=62+(i%2)*500;var y=390+(i/2)*430
  rect(x,y,456,333,Color("cbb48b"))
  picture(assets.path_join("raw-%d.png"%[1,9,6,5][i]),x+10,y+10,436,306)
  label(["紫水晶 · 六方柱晶","红宝石 · 刚玉晶体","祖母绿 · 平顶柱晶","合成莫桑石 · 晶体片"][i],x+8,y+345,450,55,28,Color("4b3629"),true)
 await save("02-原石")
 fresh(3,"同一块石头，\n可以有不同的轮廓。","角度和进给都会留下来，切歪也会留下来。")
 rect(48,389,984,810,Color("23383d"))
 picture(assets.path_join("gem-5-gem.png"),62,402,460,330)
 picture(assets.path_join("gem-9-gem.png"),558,402,460,330)
 picture(assets.path_join("gem-6-gem.png"),185,758,710,370)
 label("圆形明亮 · 切角三角 · 长方阶梯",94,1140,950,50,30,Color("e5dcc1"))
 label("另有椭圆、枕形、梨形、马眼、六边阶梯等。\n支持导入 .asc / .gcs 切工文件。",66,1240,950,105,28)
 await save("03-切工")
 fresh(4,"换盏灯，\n看看另一种颜色。","同一颗亚历山大变石，同一个切形。")
 rect(48,410,984,350,Color("23383d"));rect(48,880,984,350,Color("23383d"))
 label("日光 · 6500 K",64,365,900,48,29,Color("497d63"),true)
 label("白炽灯 · 2850 K",64,835,900,48,29,Color("99536f"),true)
 picture(assets.path_join("gem-0-gem.png"),64,410,952,350)
 picture(assets.path_join("alex-warm-gem.png"),64,880,952,350)
 label("光源、吸收与光程，共同参与呈色。",66,1280,950,70,28)
 await save("04-变石换光")
 fresh(5,"这位小龙，\n叫她潘潘就好。","Grace Pandora Targaryen · 首字母是 GPT")
 picture(ProjectSettings.globalize_path("res://art/longlong-guide.png"),28,402,500,690)
 label("“全名有点长，对吧？\n名牌都差点写不下。”",550,435,450,150,34,Color("6d805c"),true)
 label("她爱收集亮晶晶的东西，\n也想做几颗自己的宝石。\n\n爷爷旅行去了。\n这阵子，你们一起看店，\n翻书，一起学加工。",550,665,450,400,31)
 label("平时安静待着，点击才会叽里呱啦。",66,1210,950,80,32,Color("80684e"))
 await save("05-认识潘潘")
 fresh(6,"做好的宝石，\n一颗颗摆进收藏室。","原来的切形、重量和缺角，都会留在作品里。")
 picture(assets.path_join("collection.png"),48,405,984,660,false)
 label("Windows 体验版 · 下载后完整解压即可玩",64,1130,950,70,34,Color("6d805c"),true)
 label("GitHub  /  TimrayZ / gem-atelier\n你想先挑哪一块？",64,1230,950,105,31)
 await save("06-收藏与下载")
 card.queue_free();await process_frame;quit()
