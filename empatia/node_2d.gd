extends Node2D

# Posiciones base (calculadas al centro)
var circle_pos: Vector2
var triangle_start_pos: Vector2
var triangle_target_pos: Vector2
var triangle_pos: Vector2

# Estado de arrastre, progreso y temporizador
var is_dragging: bool = false
var progress: float = 0.0
var is_completed: bool = false

# Dimensiones
const SHAPE_SIZE: float = 65.0
const SHAPE_OUTLINE_WIDTH: float = 8.0
const LINE_WIDTH: float = 8.0
const HORIZONTAL_SPACING: float = 240.0
const VERTICAL_TRAVEL: float = 180.0

# Colores
const COLOR_CIRCLE_INIT: Color = Color("e67e22")   # Naranja
const COLOR_TRIANGLE_INIT: Color = Color("9b59b6") # Morado
const COLOR_CELESTE: Color = Color("4fc3f7")       # Celeste al unirse

func _ready() -> void:
	_update_layout()
	get_viewport().size_changed.connect(_update_layout)

func _update_layout() -> void:
	var screen_center: Vector2 = get_viewport_rect().size / 2.0
	circle_pos = screen_center + Vector2(-HORIZONTAL_SPACING, 0)
	triangle_target_pos = screen_center + Vector2(HORIZONTAL_SPACING, 0)
	triangle_start_pos = triangle_target_pos - Vector2(0, VERTICAL_TRAVEL)
	
	if not is_completed:
		triangle_pos = triangle_start_pos
		progress = 0.0
	queue_redraw()

func _input(event: InputEvent) -> void:
	# Durante los 5 segundos de conexión completada, se ignora cualquier interacción
	if is_completed:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if triangle_pos.distance_to(event.position) < SHAPE_SIZE * 1.5:
				is_dragging = true
		else:
			# Solo se corta el arrastre: no resetea nada de golpe
			is_dragging = false

	elif event is InputEventMouseMotion and is_dragging:
		var clamped_y = clamp(event.position.y, triangle_start_pos.y, triangle_target_pos.y)
		triangle_pos.y = clamped_y
		progress = inverse_lerp(triangle_start_pos.y, triangle_target_pos.y, triangle_pos.y)
		
		# Si toca el fondo (unión completa)
		if progress >= 1.0:
			is_dragging = false
			is_completed = true
			triangle_pos = triangle_target_pos
			queue_redraw()
			_hold_and_reset()
		else:
			queue_redraw()

# Mantiene el estado por 5 segundos sin importar si se suelta el mouse
func _hold_and_reset() -> void:
	await get_tree().create_timer(5.0).timeout
	is_completed = false
	triangle_pos = triangle_start_pos
	progress = 0.0
	queue_redraw()

func _draw() -> void:
	var current_color_left = COLOR_CELESTE if is_completed else COLOR_CIRCLE_INIT
	var current_color_right = COLOR_CELESTE if is_completed else COLOR_TRIANGLE_INIT

	# 1. Figura izquierda: Si completó es Triángulo, de lo contrario Círculo
	if is_completed:
		var left_triangle_points: PackedVector2Array = [
			circle_pos + Vector2(0, -SHAPE_SIZE),
			circle_pos + Vector2(-SHAPE_SIZE * 0.866, SHAPE_SIZE * 0.7),
			circle_pos + Vector2(SHAPE_SIZE * 0.866, SHAPE_SIZE * 0.7),
			circle_pos + Vector2(0, -SHAPE_SIZE)
		]
		draw_polyline(left_triangle_points, current_color_left, SHAPE_OUTLINE_WIDTH, true)
	else:
		draw_arc(circle_pos, SHAPE_SIZE, 0.0, TAU, 64, current_color_left, SHAPE_OUTLINE_WIDTH, true)

	# 2. Figura derecha: Triángulo
	var right_triangle_points: PackedVector2Array = [
		triangle_pos + Vector2(0, -SHAPE_SIZE),
		triangle_pos + Vector2(-SHAPE_SIZE * 0.866, SHAPE_SIZE * 0.7),
		triangle_pos + Vector2(SHAPE_SIZE * 0.866, SHAPE_SIZE * 0.7),
		triangle_pos + Vector2(0, -SHAPE_SIZE)
	]
	draw_polyline(right_triangle_points, current_color_right, SHAPE_OUTLINE_WIDTH, true)

	# 3. Líneas de unión hacia el centro
	if progress > 0.0 or is_completed:
		var mid_x: float = (circle_pos.x + triangle_target_pos.x) / 2.0
		var circle_edge_x: float = circle_pos.x + (SHAPE_SIZE * 0.866 if is_completed else SHAPE_SIZE)
		var triangle_edge_x: float = triangle_pos.x - (SHAPE_SIZE * 0.866)
		
		var line_color: Color = COLOR_CELESTE if is_completed else Color("dcdcdc")

		var line_left_end = lerp(circle_edge_x, mid_x, progress)
		draw_line(Vector2(circle_edge_x, circle_pos.y), Vector2(line_left_end, circle_pos.y), line_color, LINE_WIDTH)

		var line_right_end = lerp(triangle_edge_x, mid_x, progress)
		draw_line(Vector2(triangle_edge_x, triangle_pos.y), Vector2(line_right_end, triangle_pos.y), line_color, LINE_WIDTH)
