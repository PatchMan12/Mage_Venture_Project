extends CanvasLayer

const HEALTH_COLOR := Color(0.85, 0.15, 0.15)   
const MANA_COLOR := Color(0.2, 0.45, 1.0)       

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthRow/HealthBar
@onready var mana_bar: ProgressBar = $MarginContainer/VBoxContainer/ManaRow/ManaBar
@onready var attack_icon: TextureRect = $MarginContainer/VBoxContainer/AttackRow/AttackIcon


func _ready() -> void:
	_style_bar(health_bar, HEALTH_COLOR)
	_style_bar(mana_bar, MANA_COLOR)

	
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("HUD: no player found in the 'player' group.")
		return

	player.health_changed.connect(_on_health_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.attack_changed.connect(_on_attack_changed)
	_on_health_changed(player.health, player.max_health)
	_on_mana_changed(player.mana, player.max_mana)
	player.emit_attack_changed()   # show the starting attack's icon


func _style_bar(bar: ProgressBar, color: Color) -> void:
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(160, 16)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)


func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


func _on_mana_changed(current: float, maximum: float) -> void:
	mana_bar.max_value = maximum
	mana_bar.value = current


func _on_attack_changed(icon: Texture2D) -> void:
	attack_icon.texture = icon
