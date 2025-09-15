extends Node

@export var mob_scene: PackedScene


func _on_mob_timer_timeout():
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on the SpawnPath.
	# We store the reference to the SpawnLocation node.
	var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	# And give it a random offset.
	mob_spawn_location.progress_ratio = randf()

	var player_position = $Player.position
	mob.initialize(mob_spawn_location.position, player_position)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)
	
	# We connect the mob to the score label to update the score upon squashing one.
	mob.squashed.connect($UserInterface/ScoreLabel._on_mob_squashed.bind())


func _on_player_hit() -> void:
	$MobTimer.stop()
	$UserInterface/Retry.show()
	
func _ready():
	$UserInterface/Retry.hide()
	$UserInterface/DashPopup.hide()
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and $UserInterface/Retry.visible:
		# This restarts the current scene.
		get_tree().reload_current_scene()


func _on_score_label_dash_unlocked() -> void:
	var popup = $UserInterface/DashPopup
	popup.show()
	await get_tree().create_timer(1.0).timeout
	popup.hide()


func _on_top_teleport_area_body_entered(body: Node3D) -> void:
	if body != $Player:
		return
	
	# teleport player to Ground2 spawn
	var spawn_pos = $Ground2/Spawn2.global_position
	$Player.velocity = Vector3.ZERO
	$Player.global_position = spawn_pos

	# switch camera to the second one
	$CameraPivot2/Camera3D.current = true


func _on_return_teleport_area_2_body_entered(body: Node3D) -> void:
	if body != $Player:
		return

	# Avoid instant re-triggering
	$ReturnTeleportArea2.monitoring = false

	# Teleport the player to Ground/Spawn1
	var spawn_pos: Vector3 = $Ground/Spawn1.global_position
	$Player.velocity = Vector3.ZERO
	$Player.global_position = spawn_pos

	# Switch camera back to the first one
	$CameraPivot/Camera3D.current = true

	# Small delay, then re-enable the area (prevents ping-ponging)
	await get_tree().create_timer(0.1).timeout
	$ReturnTeleportArea2.monitoring = true


func _on_pickup_area_body_entered(body: Node3D) -> void:
	if body != $Player:
		return

	# 1) subtract 6 from score
	$UserInterface/ScoreLabel.adjust_score(-6)

	# 2) unlock double jump on the player
	$Player.unlock_double_jump()

	# 3) remove the pickup so it can't be triggered again
	$DoubleJumpCube.queue_free()
