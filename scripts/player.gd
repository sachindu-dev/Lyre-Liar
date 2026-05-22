extends CharacterBody2D

# Pink Monster has full Idle / Walk / Jump sheets.
const PINK_IDLE := preload("res://Assets/PinkMonster/Pink_Monster_Idle_4.png")
const PINK_WALK := preload("res://Assets/PinkMonster/Pink_Monster_Walk_6.png")
const PINK_JUMP := preload("res://Assets/PinkMonster/Pink_Monster_Jump_8.png")

# Dude / Owlet ship idle only; walk and jump reuse the idle sheet (frozen idle while moving).
const DUDE_IDLE := preload("res://Assets/DudeMonster/Dude_Monster_Idle_4.png")
const OWLET_IDLE := preload("res://Assets/OwletMonster/Owlet_Monster_Idle_4.png")

enum AnimState { IDLE, WALK, JUMP }

const ANIM_BY_CHARACTER := {
	"pink": {
		AnimState.IDLE: [PINK_IDLE, 4,  6.0],
		AnimState.WALK: [PINK_WALK, 6,  8.0],
		AnimState.JUMP: [PINK_JUMP, 8, 10.0],
	},
	"dude": {
		AnimState.IDLE: [DUDE_IDLE, 4, 6.0],
		AnimState.WALK: [DUDE_IDLE, 4, 6.0],
		AnimState.JUMP: [DUDE_IDLE, 4, 6.0],
	},
	"owlet": {
		AnimState.IDLE: [OWLET_IDLE, 4, 6.0],
		AnimState.WALK: [OWLET_IDLE, 4, 6.0],
		AnimState.JUMP: [OWLET_IDLE, 4, 6.0],
	},
}

var _anim_data: Dictionary = ANIM_BY_CHARACTER["pink"]

const SPEED         := 220.0
const JUMP_VELOCITY := -380.0
const GRAVITY       := 980.0

## How often (in seconds) to send position to the server.
const SEND_INTERVAL := 1.0 / 15.0

## How fast remote players lerp to their target position.
const REMOTE_LERP_SPEED := 12.0

var spawn_point: Vector2

@onready var _sprite: Sprite2D = $Sprite2D

var _walk_timer  := 0.0
var _anim_state  := AnimState.IDLE
var _tick        := 0
var _send_timer := 0.0

var is_local_player := false
var session_id := ""
var _spawn_safety_timer := 0.2


# Remote interpolation targets
var _remote_target_pos := Vector2.ZERO
var _remote_target_vel := Vector2.ZERO
var _remote_initialized := false


func _ready() -> void:
	spawn_point = global_position

	var character: String = MultiplayerManager.selected_character
	if not ANIM_BY_CHARACTER.has(character):
		character = "pink"
	_anim_data = ANIM_BY_CHARACTER[character]

	var initial: Array = _anim_data[AnimState.IDLE]
	_sprite.texture = initial[0]
	_sprite.hframes = initial[1]
	_sprite.frame = 0

	# Determine if this is the local player
	if session_id == MultiplayerManager.session_id:
		is_local_player = true
		print("Player '", session_id, "' is LOCAL player.")
	else:
		is_local_player = false
		print("Player '", session_id, "' is REMOTE player. Local session: '", MultiplayerManager.session_id, "'")

	if not is_local_player:
		# Disable physics and input for remote players
		$Camera2D.enabled = false
		set_physics_process(false)
		# Listen for state updates from the server
		MultiplayerManager.player_state_changed.connect(_on_player_state_changed)
	else:
		# Local player setup
		$Camera2D.enabled = true
		$Camera2D.make_current()
		$Camera2D.reset_smoothing()
		print("Camera activated for local player: ", session_id)


func _process(delta: float) -> void:
	if is_local_player:
		return

	# Smoothly interpolate remote players
	if _remote_initialized:
		global_position = global_position.lerp(_remote_target_pos, clampf(REMOTE_LERP_SPEED * delta, 0.0, 1.0))
		_update_sprite(_remote_target_vel.x, _remote_target_vel.y, delta)


func _physics_process(delta: float) -> void:
	if not is_local_player:
		return

	if not is_on_floor():
		if _spawn_safety_timer > 0:
			_spawn_safety_timer -= delta
			velocity.y = 0
		else:
			velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED

	_tick += 1
	move_and_slide()
	_update_sprite(direction, velocity.y, delta)

	# Throttled movement send
	_send_timer += delta
	if _send_timer >= SEND_INTERVAL:
		_send_timer = 0.0
		MultiplayerManager.send_message("move", {
			"x": global_position.x,
			"y": global_position.y,
			"vx": velocity.x,
			"vy": velocity.y,
			"tick": _tick
		})


func _update_sprite(direction: float, vel_y: float, delta: float) -> void:
	var intended: AnimState
	if vel_y < -0.1 or vel_y > 0.1:
		intended = AnimState.JUMP
	elif direction != 0.0:
		intended = AnimState.WALK
	else:
		intended = AnimState.IDLE

	if direction != 0.0:
		_sprite.flip_h = direction < 0.0

	if intended != _anim_state:
		_anim_state   = intended
		_walk_timer   = 0.0
		_sprite.frame = 0
		var anim_data: Array = _anim_data[_anim_state]
		_sprite.texture = anim_data[0]
		_sprite.hframes = anim_data[1]

	var data: Array      = _anim_data[_anim_state]
	var frame_count: int = data[1]
	var fps: float       = data[2]

	_walk_timer += delta
	if _walk_timer >= 1.0 / fps:
		_walk_timer   = 0.0
		_sprite.frame = (_sprite.frame + 1) % frame_count



func respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	_spawn_safety_timer = 0.2
	if is_local_player:
		MultiplayerManager.send_message("move", {
			"x": global_position.x,
			"y": global_position.y,
			"vx": 0,
			"vy": 0,
			"tick": _tick
		})


func _on_player_state_changed(state_session_id: String, state: Dictionary) -> void:
	if state_session_id != session_id:
		return

	if state.has("x") and state.has("y"):
		_remote_target_pos = Vector2(state["x"], state["y"])
		if not _remote_initialized:
			global_position = _remote_target_pos
			_remote_initialized = true
	if state.has("vx") and state.has("vy"):
		_remote_target_vel = Vector2(state["vx"], state["vy"])
