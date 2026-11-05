extends Node2D
## Nuvem carregada que o vento forte trouxe: cobre o sol e chove de leve.
## A cada animal que aparece ela clareia, chove menos e vai abrindo o céu.
## Com rosto (fazenda), começa tristonha e chorando e vai se alegrando até sorrir.

const Tex := preload("res://godot/scenes/texturas.gd")
const CONTORNO := "M60 132 Q18 132 20 100 Q22 70 55 68 Q58 32 100 30 Q124 4 156 24 Q196 14 206 54 Q246 56 244 96 Q242 132 204 132 Z"

var sprite: Sprite2D
var chuva: CPUParticles2D
var t := 0.0
var rosto := false
var texturas: Array = [] # [olhos abertos, piscando]
var proxima_piscada := 3.0

func _ready() -> void:
	sprite = Sprite2D.new()
	add_child(sprite)
	chuva = CPUParticles2D.new()
	chuva.texture = Tex.gota()
	chuva.amount = 26
	chuva.lifetime = 1.4
	chuva.position = Vector2(0, 40)
	chuva.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	chuva.emission_rect_extents = Vector2(85, 4)
	chuva.direction = Vector2(0.15, 1)
	chuva.spread = 4
	chuva.gravity = Vector2(30, 500)
	chuva.initial_velocity_min = 60
	chuva.initial_velocity_max = 110
	chuva.scale_amount_min = 0.45
	chuva.scale_amount_max = 0.7
	chuva.modulate = Color(0.85, 0.9, 1.0, 0.65)
	chuva.show_behind_parent = true
	add_child(chuva)
	humor(0, 1)

## nivel = quantos animais já apareceram, de um total.
func humor(nivel: int, total: int) -> void:
	var k := clampf(float(nivel) / total, 0.0, 1.0)
	var tom := Color("#8e8f9c").lerp(Color("#ffffff"), k)
	texturas.clear()
	for piscando in [false, true]:
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="260" height="150" viewBox="0 0 260 150"><g stroke="#4a4652" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"><path fill="#%s" d="%s"/><path fill="none" stroke="#ffffff" stroke-opacity="0.45" stroke-width="6" d="M70 64 Q82 48 100 50 M150 40 Q168 34 182 46"/>%s</g></svg>' % [tom.to_html(false), CONTORNO, desenhar_rosto(k, piscando) if rosto else ""]
		texturas.append(Tex.svg(svg))
	sprite.texture = texturas[0]
	chuva.amount = maxi(int(round(26.0 * (1.0 - k))), 1)
	chuva.emitting = nivel < total
	create_tween().tween_property(sprite, "modulate:a", 1.0 - k * 0.35, 1.5)

## k = 0: triste, sobrancelhas caídas e lágrima. k = 1: sorrisão, olhinhos fechados e bochechas.
func desenhar_rosto(k: float, piscando: bool) -> String:
	var s := ""
	if k >= 1.0:
		s += '<path fill="none" d="M98 84 Q108 72 118 84 M146 84 Q156 72 166 84"/>'
		s += '<ellipse fill="#f4a8bd" stroke="none" opacity="0.85" cx="88" cy="100" rx="11" ry="6"/><ellipse fill="#f4a8bd" stroke="none" opacity="0.85" cx="176" cy="100" rx="11" ry="6"/>'
		s += '<path fill="#ffffff" d="M112 100 Q132 126 152 100 Z"/>'
		return s
	if piscando:
		s += '<path fill="none" d="M100 82 Q108 87 116 82 M148 82 Q156 87 164 82"/>'
	else:
		s += '<circle fill="#4a4652" stroke="none" cx="108" cy="82" r="7"/><circle fill="#4a4652" stroke="none" cx="156" cy="82" r="7"/><circle fill="#ffffff" stroke="none" cx="105" cy="79" r="2.5"/><circle fill="#ffffff" stroke="none" cx="153" cy="79" r="2.5"/>'
	# Sobrancelhas: caídas para fora quando triste, retas quando melhora.
	var caida := 8.0 * (1.0 - k * 2.0)
	if caida > 0.0:
		s += '<path fill="none" stroke-width="4" d="M94 %.1f L118 %.1f M170 %.1f L146 %.1f"/>' % [66.0 + caida, 66.0 - caida * 0.3, 66.0 + caida, 66.0 - caida * 0.3]
	# Boca: de beicinho (curva para baixo) a sorriso.
	s += '<path fill="none" d="M118 108 Q132 %.1f 146 108"/>' % (96.0 + 26.0 * k)
	if k < 0.5:
		s += '<path fill="#9fd3f5" stroke="#4d7fa6" stroke-width="2" d="M100 92 Q95 102 97 105 Q100 109 103 105 Q105 102 100 92 Z"/>'
	return s

func _process(delta: float) -> void:
	t += delta
	if rosto and texturas.size() == 2:
		proxima_piscada -= delta
		if proxima_piscada <= 0.0:
			proxima_piscada = randf_range(2.5, 5.0)
			sprite.texture = texturas[1]
			get_tree().create_timer(0.14).timeout.connect(func():
				if is_instance_valid(sprite) and texturas.size() == 2:
					sprite.texture = texturas[0]
			)
	sprite.position = Vector2(sin(t * 0.8) * 6.0, sin(t * 1.3) * 4.0)
	var respira := 1.0 + sin(t * 1.1) * 0.02
	sprite.scale = Vector2(respira, 2.0 - respira)

func ir_para(destino: Vector2, duracao: float = 2.5) -> void:
	var tw := create_tween()
	tw.tween_property(self, "position", destino, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
