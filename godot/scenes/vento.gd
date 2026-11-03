extends Node2D
## Vento passando: fios de ar riscando a tela e folhas voando das árvores.
## Rajadas de vez em quando avisam o fundo (sinal `rajada`) para as copas balançarem mais.

const Tex := preload("res://godot/scenes/texturas.gd")

signal rajada(forca: float)

var tamanho := Vector2(1152, 648)
var fios: Array = []
var folhas: CPUParticles2D
var pozinho: CPUParticles2D
var saturacao := 0.0
var proxima_rajada := 4.0
var t := 0.0

func _ready() -> void:
	folhas = CPUParticles2D.new()
	folhas.texture = Tex.folha()
	folhas.amount = 14
	folhas.lifetime = 9.0
	folhas.preprocess = 6.0
	folhas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	folhas.position = Vector2(300, 110)
	folhas.emission_rect_extents = Vector2(320, 90)
	folhas.direction = Vector2(1, 0.25)
	folhas.spread = 25
	folhas.initial_velocity_min = 40
	folhas.initial_velocity_max = 90
	folhas.gravity = Vector2(12, 28)
	folhas.angular_velocity_min = -120
	folhas.angular_velocity_max = 120
	folhas.angle_min = -180
	folhas.angle_max = 180
	folhas.scale_amount_min = 0.7
	folhas.scale_amount_max = 1.3
	folhas.hue_variation_min = -0.06
	folhas.hue_variation_max = 0.06
	add_child(folhas)

	# Pólen dourado: só aparece quando a floresta recupera as cores.
	pozinho = CPUParticles2D.new()
	pozinho.texture = Tex.brilho(16)
	pozinho.amount = 40
	pozinho.lifetime = 6.0
	pozinho.preprocess = 4.0
	pozinho.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pozinho.position = Vector2(576, 470)
	pozinho.emission_rect_extents = Vector2(576, 120)
	pozinho.direction = Vector2(0.4, -1)
	pozinho.spread = 50
	pozinho.initial_velocity_min = 8
	pozinho.initial_velocity_max = 25
	pozinho.gravity = Vector2(6, -6)
	pozinho.scale_amount_min = 0.4
	pozinho.scale_amount_max = 1.0
	pozinho.color = Color(1, 0.92, 0.55, 0.0)
	add_child(pozinho)

	for i in range(7):
		fios.append(novo_fio(true))
	definir_cor(0.0)

func novo_fio(espalhado: bool) -> Dictionary:
	return {
		"x": randf_range(-200, tamanho.x) if espalhado else randf_range(-500, -150),
		"y": randf_range(40, tamanho.y * 0.8),
		"comprimento": randf_range(90, 220),
		"velocidade": randf_range(220, 380),
		"fase": randf() * TAU,
		"altura": randf_range(5, 12),
	}

## 0 = tudo cinza, 1 = cores todas de volta.
func definir_cor(valor: float) -> void:
	saturacao = valor
	var cinza := Color(0.62, 0.64, 0.66)
	var verde := Color(0.55, 0.82, 0.35)
	folhas.color = cinza.lerp(verde, valor)
	pozinho.color = Color(1, 0.92, 0.55, valor * 0.85)

func _process(delta: float) -> void:
	t += delta
	proxima_rajada -= delta
	var forca := 1.0
	if proxima_rajada <= 0.0:
		proxima_rajada = randf_range(6.0, 11.0)
		rajada.emit(randf_range(0.8, 1.4))
		for i in range(3):
			fios.append(novo_fio(false))
		folhas.speed_scale = 2.2
		create_tween().tween_property(folhas, "speed_scale", 1.0, 2.5)
	for fio in fios:
		fio["x"] += fio["velocidade"] * delta * forca
	fios = fios.filter(func(f): return f["x"] - f["comprimento"] < tamanho.x + 40)
	while fios.size() < 6:
		fios.append(novo_fio(false))
	queue_redraw()

func _draw() -> void:
	for fio in fios:
		var pontos := PackedVector2Array()
		var n := 14
		for i in range(n):
			var k := float(i) / (n - 1)
			var x: float = fio["x"] - fio["comprimento"] * (1.0 - k)
			var y: float = fio["y"] + sin(k * 5.0 + t * 3.0 + fio["fase"]) * fio["altura"]
			pontos.append(Vector2(x, y))
		var cores := PackedColorArray()
		for i in range(n):
			var k := float(i) / (n - 1)
			cores.append(Color(1, 1, 1, sin(k * PI) * 0.33))
		draw_polyline_colors(pontos, cores, 2.5, true)
