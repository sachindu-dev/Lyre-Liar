extends Node2D

## Level scene. Terrain, spawn points, and camera bounds come from the scene,
## not from this script — paint geometry (e.g. with a TileMapLayer) in the
## editor and add Marker2D children under a `SpawnPoints` node for spawns.

@export var world_size: Vector2 = Vector2(2048, 2048)

var _spawn_index := 0


func _ready() -> void:
	$KillZone.body_entered.connect(_on_kill_zone_body_entered)

	MultiplayerManager.connection_failed.connect(_on_connection_failed)
	MultiplayerManager.player_connected.connect(_add_player)
	MultiplayerManager.player_disconnected.connect(_remove_player)

	for pid in MultiplayerManager.active_players:
		_add_player(pid)

	if MultiplayerManager.is_hosting_intent:
		MultiplayerManager.room_code_ready.connect(_on_room_code_ready)
		_display_room_code()
	else:
		_display_room_code(MultiplayerManager.join_intent_code)
		print("Level: Join completed")


func _on_room_code_ready(code: String) -> void:
	_display_room_code(code)


func _on_connection_failed(reason: String) -> void:
	if MultiplayerManager.is_single_player:
		return
	print("Connection failed: ", reason)
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _add_player(session_id: String) -> void:
	if has_node(session_id):
		print("Player ", session_id, " already exists")
		return

	print("Spawning player with session_id '", session_id, "'")
	var player = preload("res://scenes/player.tscn").instantiate()
	player.session_id = session_id
	player.name = session_id
	player.position = _next_spawn_position()
	_spawn_index += 1

	add_child(player)
	print("Player ", session_id, " spawned at ", player.position)

	if player.is_local_player:
		var cam: Camera2D = player.get_node("Camera2D")
		cam.limit_left   = 0
		cam.limit_top    = 0
		cam.limit_right  = int(world_size.x)
		cam.limit_bottom = int(world_size.y)


func _remove_player(session_id: String) -> void:
	if has_node(session_id):
		get_node(session_id).queue_free()
		print("Player ", session_id, " removed")


func _next_spawn_position() -> Vector2:
	var positions := _spawn_positions()
	if positions.is_empty():
		push_warning("Level1: no Marker2D children under 'SpawnPoints'; spawning at (0, 0)")
		return Vector2.ZERO
	return positions[_spawn_index % positions.size()]


func _spawn_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var holder := get_node_or_null("SpawnPoints")
	if holder == null:
		return positions
	for child in holder.get_children():
		if child is Node2D:
			positions.append((child as Node2D).position)
	return positions


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body.has_method("respawn"):
		body.respawn()


func _display_room_code(custom_code: String = "") -> void:
	var room_code = custom_code

	if room_code.is_empty():
		room_code = MultiplayerManager.room_code

	print("Room code to display: '", room_code, "'")

	if room_code.is_empty():
		print("WARNING: Room code is empty!")
		return

	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 100
	add_child(ui_layer)

	var label = Label.new()
	label.text = "Room: " + room_code
	label.anchor_left = 0
	label.anchor_top = 0
	label.offset_left = 20
	label.offset_top = 20
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	ui_layer.add_child(label)
	print("Room code label created: ", room_code)
