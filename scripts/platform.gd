extends AnimatableBody2D

@export var move_offset := Vector2(150, 0)   
@export var move_time := 2.0                 
@export var pause_time := 0.5                


func _ready() -> void:
	var start := position
	var tween := create_tween().set_loops()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", start + move_offset, move_time)
	tween.tween_interval(pause_time)
	tween.tween_property(self, "position", start, move_time)
	tween.tween_interval(pause_time)
