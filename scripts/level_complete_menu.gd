extends CanvasLayer

## Win-screen overlay shown when the local player touches the level's Goal
## Area2D. Pauses the tree while open. Single-player only — self-removes in
## multiplayer (mirrors timer_hud's pattern).

const NEXT_MODE := {"day": "night", "night": "forest", "forest": "day"}
const SCENE_FOR_MODE := {
	"day":    "res://scenes/level_2.tscn",
	"night":  "res://scenes/level_1.tscn",
	"forest": "res://scenes/level_4.tscn",
}

var _won: bool = false

@onready var _overlay: ColorRect = $Overlay
@onready var _replay_btn: Button = $Overlay/Panel/ReplayButton
@onready var _next_btn: Button = $Overlay/Panel/NextLevelButton
@onready var _menu_btn: Button = $Overlay/Panel/MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not MultiplayerManager.is_single_player:
		queue_free()
		return
	_overlay.visible = false
	_replay_btn.pressed.connect(_replay)
	_next_btn.pressed.connect(_next_level)
	_menu_btn.pressed.connect(_to_main_menu)


func show_win(_player: Node) -> void:
	if _won:
		return
	_won = true
	_overlay.visible = true
	get_tree().paused = true


func _replay() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _next_level() -> void:
	get_tree().paused = false
	var current: String = MultiplayerManager.selected_mode
	var next: String = NEXT_MODE.get(current, "day")
	MultiplayerManager.selected_mode = next
	get_tree().change_scene_to_file(SCENE_FOR_MODE[next])


func _to_main_menu() -> void:
	get_tree().paused = false
	MultiplayerManager.leave()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
