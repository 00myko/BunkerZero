extends Node

# Dynamic gameplay score for Bunker Zero.
# The three loop beds stay intentionally quiet. One-shot cues sit on top at
# low volume and the entire system obeys the GAMEPLAY MUSIC setting.

enum BedState { NONE, HUB, CHASE, HEAVY }

const SAFE_HUB_PATH: String = "res://assets/Audio/Gameplay Music/Room 1 - Safe Hub Loop.mp3"
const ENTERING_COMBAT_PATH: String = "res://assets/Audio/Gameplay Music/Entering Combat Room - Tension Build.mp3"
const CHASE_PATH: String = "res://assets/Audio/Gameplay Music/Zombie Alerted - Chase Tension Loop.mp3"
const HEAVY_COMBAT_PATH: String = "res://assets/Audio/Gameplay Music/Heavy Combat Loop.mp3"
const ROOM_CLEARED_PATH: String = "res://assets/Audio/Gameplay Music/Room Cleared.mp3"

var safe_hub_stream: AudioStream = null
var entering_combat_stream: AudioStream = null
var chase_stream: AudioStream = null
var heavy_combat_stream: AudioStream = null
var room_cleared_stream: AudioStream = null

# These are deliberately conservative. The processed audio is already leveled,
# so these values keep music beneath weapons, zombies, footsteps and ambience.
const HUB_BASE_DB: float = -8.5
const ENTERING_BASE_DB: float = -10.0
const CHASE_BASE_DB: float = -7.0
const HEAVY_BASE_DB: float = -6.5
const CLEARED_BASE_DB: float = -4.5
const DEFAULT_USER_VOLUME: float = 70.0
const PAUSE_DUCK_DB: float = -6.0

var bed_a: AudioStreamPlayer
var bed_b: AudioStreamPlayer
var transition_player: AudioStreamPlayer
var active_bed: AudioStreamPlayer
var inactive_bed: AudioStreamPlayer
var bed_state: BedState = BedState.NONE
var active_bed_base_db: float = -80.0
var transition_base_db: float = -80.0
var gameplay_active: bool = false
var user_volume: float = DEFAULT_USER_VOLUME
var pause_duck_db: float = 0.0
var bed_tween: Tween = null
var transition_tween: Tween = null
var combat_pressure: float = 0.0
var last_combat_action_msec: int = 0
var suppress_dynamic_changes: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_players()
	user_volume = clampf(float(SaveManager.get_value("audio", "gameplay_music", DEFAULT_USER_VOLUME)), 0.0, 100.0)

func _load_audio_exact(path: String) -> AudioStream:
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_error("Required gameplay music failed to load: " + path)
	return stream

func _process(delta: float) -> void:
	if not gameplay_active or suppress_dynamic_changes or get_tree().paused:
		return
	if not RunManager.run_active:
		return

	combat_pressure = maxf(0.0, combat_pressure - delta * 0.16)
	if bed_state == BedState.HEAVY:
		var quiet_for: float = float(Time.get_ticks_msec() - last_combat_action_msec) / 1000.0
		if combat_pressure <= 0.34 and quiet_for >= 4.5:
			_crossfade_bed(chase_stream, CHASE_BASE_DB, 2.2, BedState.CHASE)

func _create_players() -> void:
	bed_a = AudioStreamPlayer.new()
	bed_a.name = "GameplayMusicBedA"
	bed_a.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bed_a)

	bed_b = AudioStreamPlayer.new()
	bed_b.name = "GameplayMusicBedB"
	bed_b.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bed_b)

	transition_player = AudioStreamPlayer.new()
	transition_player.name = "GameplayMusicTransition"
	transition_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(transition_player)

	active_bed = bed_a
	inactive_bed = bed_b

func enter_gameplay() -> void:
	# Do not load the complete gameplay soundtrack from this autoload's _ready().
	# Autoloads run before the first main-menu frame and synchronous audio imports
	# can leave iOS displaying the Godot launch screen. Load only the bed needed now.
	if safe_hub_stream == null:
		safe_hub_stream = _load_audio_exact(SAFE_HUB_PATH)
	gameplay_active = true
	suppress_dynamic_changes = false
	pause_duck_db = 0.0
	combat_pressure = 0.0
	last_combat_action_msec = 0
	_stop_transition(0.0)
	_crossfade_bed(safe_hub_stream, HUB_BASE_DB, 1.0, BedState.HUB)

func begin_combat_room(play_entry_cue: bool = true) -> void:
	if not gameplay_active:
		enter_gameplay()
	# Room 02 currently has both an Area3D trigger and a coordinate fallback.
	# If both fire, do not restart the transition cue or reset the music state.
	if RunManager.run_active and not suppress_dynamic_changes and (bed_state == BedState.CHASE or bed_state == BedState.HEAVY):
		return
	suppress_dynamic_changes = false
	combat_pressure = 0.20
	last_combat_action_msec = Time.get_ticks_msec()
	if play_entry_cue:
		if entering_combat_stream == null:
			entering_combat_stream = _load_audio_exact(ENTERING_COMBAT_PATH)
		_play_transition(entering_combat_stream, ENTERING_BASE_DB, 0.25)
	if chase_stream == null:
		chase_stream = _load_audio_exact(CHASE_PATH)
	_crossfade_bed(chase_stream, CHASE_BASE_DB, 2.6 if play_entry_cue else 0.9, BedState.CHASE)

func zombies_alerted() -> void:
	if not gameplay_active or suppress_dynamic_changes:
		return
	if bed_state == BedState.HUB or bed_state == BedState.NONE:
		if chase_stream == null:
			chase_stream = _load_audio_exact(CHASE_PATH)
		_crossfade_bed(chase_stream, CHASE_BASE_DB, 2.0, BedState.CHASE)

func notify_combat_action(strength: float = 0.35) -> void:
	if not gameplay_active or suppress_dynamic_changes or not RunManager.run_active:
		return
	combat_pressure = clampf(combat_pressure + maxf(strength, 0.0), 0.0, 2.0)
	last_combat_action_msec = Time.get_ticks_msec()
	# Heavy music only arrives after sustained pressure, not after one pistol shot.
	if combat_pressure >= 1.15 and bed_state != BedState.HEAVY:
		if heavy_combat_stream == null:
			heavy_combat_stream = _load_audio_exact(HEAVY_COMBAT_PATH)
		_crossfade_bed(heavy_combat_stream, HEAVY_BASE_DB, 1.6, BedState.HEAVY)

func room_cleared() -> void:
	if not gameplay_active:
		return
	suppress_dynamic_changes = true
	combat_pressure = 0.0
	_fade_out_bed(1.2)
	if room_cleared_stream == null:
		room_cleared_stream = _load_audio_exact(ROOM_CLEARED_PATH)
	_play_transition(room_cleared_stream, CLEARED_BASE_DB, 0.20)

func death_sequence() -> void:
	if not gameplay_active:
		return
	suppress_dynamic_changes = true
	combat_pressure = 0.0
	# Remove combat music quickly at the lethal hit, but leave the collapse
	# itself to the vocal, body impact and heartbeat. The final musical cue is
	# intentionally delayed until the screen is fully black.
	_fade_out_bed(0.45)
	_stop_transition(0.15)

func restart_combat() -> void:
	gameplay_active = true
	suppress_dynamic_changes = false
	combat_pressure = 0.20
	last_combat_action_msec = Time.get_ticks_msec()
	_stop_transition(0.20)
	if chase_stream == null:
		chase_stream = _load_audio_exact(CHASE_PATH)
	_crossfade_bed(chase_stream, CHASE_BASE_DB, 0.8, BedState.CHASE)

func leave_gameplay() -> void:
	gameplay_active = false
	suppress_dynamic_changes = true
	combat_pressure = 0.0
	pause_duck_db = 0.0
	if bed_tween != null and bed_tween.is_valid():
		bed_tween.kill()
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	for player in [bed_a, bed_b, transition_player]:
		if player != null:
			player.stop()
			player.volume_db = -80.0
	bed_state = BedState.NONE
	active_bed_base_db = -80.0
	transition_base_db = -80.0

func set_paused_duck(paused: bool) -> void:
	pause_duck_db = PAUSE_DUCK_DB if paused else 0.0
	_refresh_live_volumes(0.30)

func set_user_volume(value: float, save_value: bool = true) -> void:
	user_volume = clampf(value, 0.0, 100.0)
	if save_value:
		SaveManager.set_value("audio", "gameplay_music", user_volume)
	_refresh_live_volumes(0.18)

func get_user_volume() -> float:
	return user_volume

func _crossfade_bed(stream: AudioStream, base_db: float, duration: float, new_state: BedState) -> void:
	if stream == null:
		return
	if bed_state == new_state and active_bed != null and active_bed.playing:
		active_bed_base_db = base_db
		_refresh_live_volumes(0.25)
		return

	if bed_tween != null and bed_tween.is_valid():
		bed_tween.kill()

	var old_player: AudioStreamPlayer = active_bed
	var new_player: AudioStreamPlayer = inactive_bed
	new_player.stop()
	new_player.stream = stream
	_set_stream_loop(stream, true)
	new_player.volume_db = -80.0
	new_player.play()

	active_bed = new_player
	inactive_bed = old_player
	bed_state = new_state
	active_bed_base_db = base_db

	var target_db: float = _resolved_db(base_db)
	bed_tween = create_tween()
	bed_tween.set_parallel(true)
	bed_tween.set_trans(Tween.TRANS_SINE)
	bed_tween.set_ease(Tween.EASE_IN_OUT)
	if old_player != null and old_player.playing:
		bed_tween.tween_property(old_player, "volume_db", -80.0, maxf(duration, 0.01))
	bed_tween.tween_property(new_player, "volume_db", target_db, maxf(duration, 0.01))
	var old_to_stop := old_player
	bed_tween.finished.connect(func() -> void:
		if old_to_stop != null and old_to_stop != active_bed:
			old_to_stop.stop()
	)

func _fade_out_bed(duration: float) -> void:
	if active_bed == null or not active_bed.playing:
		return
	if bed_tween != null and bed_tween.is_valid():
		bed_tween.kill()
	var player_to_stop := active_bed
	bed_tween = create_tween()
	bed_tween.tween_property(player_to_stop, "volume_db", -80.0, maxf(duration, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bed_tween.finished.connect(func() -> void:
		if player_to_stop != null:
			player_to_stop.stop()
	)
	bed_state = BedState.NONE
	active_bed_base_db = -80.0

func _play_transition(stream: AudioStream, base_db: float, fade_in: float) -> void:
	if stream == null or transition_player == null:
		return
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	transition_player.stop()
	transition_player.stream = stream
	_set_stream_loop(stream, false)
	transition_base_db = base_db
	transition_player.volume_db = -80.0 if fade_in > 0.0 else _resolved_db(base_db)
	transition_player.play()
	if fade_in > 0.0:
		transition_tween = create_tween()
		transition_tween.tween_property(transition_player, "volume_db", _resolved_db(base_db), fade_in).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _stop_transition(fade_out: float) -> void:
	if transition_player == null or not transition_player.playing:
		return
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	if fade_out <= 0.0:
		transition_player.stop()
		transition_player.volume_db = -80.0
		return
	transition_tween = create_tween()
	transition_tween.tween_property(transition_player, "volume_db", -80.0, fade_out).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition_tween.finished.connect(func() -> void:
		if transition_player != null:
			transition_player.stop()
	)

func _refresh_live_volumes(duration: float) -> void:
	if active_bed != null and active_bed.playing:
		var tween := create_tween()
		tween.tween_property(active_bed, "volume_db", _resolved_db(active_bed_base_db), duration)
	if transition_player != null and transition_player.playing:
		var transition_refresh := create_tween()
		transition_refresh.tween_property(transition_player, "volume_db", _resolved_db(transition_base_db), duration)

func _resolved_db(base_db: float) -> float:
	if user_volume <= 0.0:
		return -80.0
	var user_gain_db: float = linear_to_db(user_volume / 100.0)
	return base_db + user_gain_db + pause_duck_db

func _set_stream_loop(stream: AudioStream, enabled: bool) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = enabled
