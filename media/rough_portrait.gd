extends "res://scripts/pixel_world.gd"
func _draw() -> void:
 if model!=null: draw_solid(model.body,Vector2(142,104),1.6,false,false)
