extends CanvasLayer

@onready var dim: ColorRect = $Dim
@onready var center: CenterContainer = $Dim/CenterContainer

var can_restart := false


func _ready() -> void:
	layer = 100                                 
	process_mode = Node.PROCESS_MODE_ALWAYS      

	
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

	
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("DeathScreen: no player found in the 'player' group.")
		return
	player.died.connect(_on_player_died)


func _on_player_died() -> void:
	can_restart = false
	dim.modulate.a = 0.0
	show()
	get_tree().paused = true

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)   
	tween.tween_property(dim, "modulate:a", 1.0, 0.5)
	tween.tween_callback(func(): can_restart = true)

	
	await get_tree().create_timer(1.0, true, false, true).timeout
	can_restart = true


func _input(event: InputEvent) -> void:
	if can_restart and event.is_action_pressed("ui_accept"):
		get_tree().paused = false
		get_tree().reload_current_scene()
