extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var hand: Node3D = $Hand

@export var default_hand_distance: float = 3.5
@export var hand_offset: float = 0.15
@export var collision_mask: int = 1 << 0

var held_object: Node3D = null

func _process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var dir = camera.project_ray_normal(mouse_pos)

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, from + dir * 1000)
	query.collision_mask = collision_mask
	query.exclude = [hand]

	var result = space_state.intersect_ray(query)

	if result.size() > 0:
		var hit_pos: Vector3 = result.position
		var hit_normal: Vector3 = result.normal
		hand.global_transform.origin = hit_pos + hit_normal * hand_offset
		hand.handle_click(result)  # Panggil handle_click dengan result
	else:
		hand.global_transform.origin = from + dir * default_hand_distance

	hand.look_at(camera.global_transform.origin, Vector3.UP)
