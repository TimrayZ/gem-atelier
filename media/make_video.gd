extends SceneTree
const Workshop=preload("res://scripts/workshop.gd")
var app
var cache: Array=[]
var title: Label
var game_display: TextureRect
var end_card: Control
func _initialize() -> void:call_deferred("run")
func make_piece(id: int,shape: int) -> Dictionary:
 var m=Workshop.new();m.reset(id,shape)
 var guard=0
 while m.stage!=4 and guard<10000:
  guard+=1
  if m.stage in [0,1]:m.advance();continue
  var values=m.cut if m.stage==2 else m.polish
  if m.section_done(values):m.advance();continue
  if values[m.facet]>=1:m.next_facet();continue
  m.wheel=0 if m.stage==2 else 1
  m.work(.12);m.removal_events.clear()
 assert(m.stage==4)
 var planes=[]
 for f in m.body:planes.append([f.n.x,f.n.y,f.n.z,f.d,f.tag])
 return {"gem_id":id,"shape_id":shape,"shape":m.cut_name(),"quality":m.quality,"carats":m.carats(),"planes":planes,"chips":[],"date":"演示收藏"}
func use_piece(index: int) -> void:
 var m=Workshop.new()
 var restored=m.restore_piece(cache[index]);assert(restored)
 m.collection=cache;m.save_path="user://promo_unused.json"
 app.model=m;app.world.model=m;app.world.seen_generation=-1
 app.world.auto_rotate=false;app.world.real_mode=false;app.world.light_mode=0;app.world.zoom=1.0
 app.collection_room.hide();app.guide.cancel();app.refresh();app.exhibition.open()
func add_label(parent: Node,text: String,pos: Vector2,dim: Vector2,size: int,col: Color=Color("4b3629")) -> Label:
 var l=Label.new();l.text=text;l.position=pos;l.size=dim;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.add_theme_font_override("font",app.font);l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",col);parent.add_child(l);return l
func run() -> void:
 root.size=Vector2i(1920,1080);root.content_scale_size=Vector2i.ZERO
 var bg=ColorRect.new();bg.size=Vector2(1920,1080);bg.color=Color("dfccaa");root.add_child(bg)
 var view=SubViewport.new();view.size=Vector2i(1120,720);view.own_world_3d=true;root.add_child(view)
 app=load("res://main.tscn").instantiate();view.add_child(app)
 app.model.collection.clear();app.model.save_path="user://promo_unused.json";app.set_debug(false)
 game_display=TextureRect.new();game_display.position=Vector2(232,88);game_display.size=Vector2(1456,936)
 game_display.texture=view.get_texture();game_display.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;root.add_child(game_display)
 title=add_label(root,"石间小铺  /  从一块原石开始",Vector2(60,20),Vector2(1800,60),36)
 add_label(root,"游戏实机演示 · 部分加工过程加速  |  GitHub: TimrayZ/gem-atelier",Vector2(62,1030),Vector2(1780,35),23,Color("80684e"))
 for pair in [[3,1],[5,4],[0,1],[6,3],[7,5],[8,9],[9,8]]:cache.append(make_piece(pair[0],pair[1]))
 end_card=Control.new();end_card.size=Vector2(1920,1080);root.add_child(end_card)
 var end_bg=ColorRect.new();end_bg.size=Vector2(1920,1080);end_bg.color=Color("e8d8b6");end_card.add_child(end_bg)
 add_label(end_card,"石间小铺",Vector2(120,240),Vector2(1700,150),108)
 add_label(end_card,"GEM ATELIER",Vector2(126,400),Vector2(1400,80),48,Color("6d805c"))
 add_label(end_card,"10 种原料 × 10 种切工\n切出自己的第一颗收藏。",Vector2(128,530),Vector2(1400,160),45)
 add_label(end_card,"Windows 体验版  /  GitHub: TimrayZ/gem-atelier",Vector2(128,760),Vector2(1680,70),36)
 add_label(end_card,"BGM: Carefree — Kevin MacLeod (incompetech.com) · CC BY 4.0\n角色立绘：参考图辅助的 AI 生成；画面由 Godot 实机渲染。",Vector2(128,937),Vector2(1700,90),23,Color("80684e"))
 end_card.hide()
 app.sound.audible=true;app.sound.music.play()
 for frame in range(2160):
  if frame in [0,90,180,270]:
   var id=[1,9,6,5][frame/90]
   app.model.reset(id,0);app.refresh();app.world.yaw=.2
   app.get_node("GemScroll").scroll_vertical=maxi(0,id*50-100)
   title.text="原石各有模样  /  "+app.model.GEMS[id].name
  if frame<360:app.world.yaw+=.012
  if frame==360:
   app.model.reset(0,1);app.refresh();app.toggle_fast();title.text="逐面切削与一次抛光  /  按 F8 可以快速加工"
  if frame==720:use_piece(0);title.text="像素钻石  /  转动寻找折射、反光与火彩"
  if frame==870:use_piece(1);title.text="合成莫桑石  /  同一光源下，观察更多色散"
  if frame==1020:use_piece(2);title.text="亚历山大变石  /  先看看日光下的绿色"
  if frame==1170:app.world.light_mode=1;title.text="换成白炽灯  /  同一块变石转为红紫色"
  if frame>=720 and frame<1320:app.world.yaw=.1+(frame%150)*.009
  if frame==1320:
   app.exhibition.close();app.model.reset(0,0);app.refresh();app.open_character()
   title.text="认识潘潘  /  格蕾丝·潘多拉·坦格利安"
  if frame==1650:
   app.guide.cancel();app.model.collection=cache;app.show_collection();title.text="爷爷旅行去了  /  你们一起看店，慢慢填满收藏室"
  if frame==1860:app.inspect_collected(1);title.text="十种原料，十种切工  /  还有 ASC 与 GCS 切工导入"
  if frame>=1860 and frame<2010:app.world.yaw=.2+(frame-1860)*.009
  if frame==2010:game_display.hide();end_card.show()
  if frame%180==0:print("MOVIE ",frame," / 2160")
  await process_frame
 app.sound.stop_all();app.queue_free();await process_frame
 print("MOVIE COMPLETE: 72 seconds at 30 fps")
 quit()
