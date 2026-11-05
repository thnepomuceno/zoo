extends Node2D
## Nuvem carregada que o vento forte trouxe: cobre o sol e chove de leve.
## A cada animal que aparece ela clareia, chove menos e vai abrindo o céu.

const Tex := preload("res://godot/scenes/texturas.gd")
const CONTORNO := "M60 132 Q18 132 20 100 Q22 70 55 68 Q58 32 100 30 Q124 4 156 24 Q196 14 206 54 Q246 56 244 96 Q242 132 204 132 Z"

var sprite: Sprite2D
var chuva: CPUParticles2D
var t := 0.0

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
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="260" height="150" viewBox="0 0 260 150"><g stroke="#4a4652" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"><path fill="#%s" d="%s"/><path fill="none" stroke="#ffffff" stroke-opacity="0.45" stroke-width="6" d="M70 64 Q82 48 100 50 M150 40 Q168 34 182 46"/></g></svg>' % [tom.to_html(false), CONTORNO]
	sprite.texture = Tex.svg(svg)
	chuva.amount = maxi(int(round(26.0 * (1.0 - k))), 1)
	chuva.emitting = nivel < total
	create_tween().tween_property(sprite, "modulate:a", 1.0 - k * 0.35, 1.5)

func _process(delta: float) -> void:
	t += delta
	sprite.position = Vector2(sin(t * 0.8) * 6.0, sin(t * 1.3) * 4.0)
	var respira := 1.0 + sin(t * 1.1) * 0.02
	sprite.scale = Vector2(respira, 2.0 - respira)

func ir_para(destino: Vector2, duracao: float = 2.5) -> void:
	var tw := create_tween()
	tw.tween_property(self, "position", destino, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
