extends Node2D
## Nublina, a nuvem distraída que engoliu as cores. Começa cinza e cobrindo o sol;
## a cada amigo pintado ela solta uma cor, fica mais clarinha e vai abrindo o céu.

const Tex := preload("res://godot/scenes/texturas.gd")
const CONTORNO := "M60 132 Q18 132 20 100 Q22 70 55 68 Q58 32 100 30 Q124 4 156 24 Q196 14 206 54 Q246 56 244 96 Q242 132 204 132 Z"
const ROSTOS := {
	# Sonolenta e encabulada: olhos fechados, boquinha torta.
	"sonolenta": '<path fill="none" d="M92 86 Q103 95 114 86 M146 86 Q157 95 168 86 M120 110 Q130 104 140 110"/>',
	# Arrependida: olhos abertos, preocupada.
	"preocupada": '<ellipse fill="#3e3a46" cx="103" cy="86" rx="6" ry="8"/><ellipse fill="#3e3a46" cx="157" cy="86" rx="6" ry="8"/><path fill="none" d="M92 76 L112 70 M168 76 L148 70 M118 112 Q124 106 130 112 Q136 118 142 112"/><ellipse fill="#f4a8bd" stroke="none" opacity="0.7" cx="84" cy="102" rx="10" ry="6"/><ellipse fill="#f4a8bd" stroke="none" opacity="0.7" cx="176" cy="102" rx="10" ry="6"/>',
	# Rindo à toa no final.
	"feliz": '<path fill="none" d="M92 90 Q103 78 114 90 M146 90 Q157 78 168 90"/><path fill="#ef6b65" d="M110 104 Q130 132 150 104 Z"/><ellipse fill="#f4a8bd" stroke="none" opacity="0.8" cx="82" cy="102" rx="12" ry="7"/><ellipse fill="#f4a8bd" stroke="none" opacity="0.8" cx="178" cy="102" rx="12" ry="7"/>',
}

var sprite: Sprite2D
var chuva: CPUParticles2D
var t := 0.0
var base := Vector2.ZERO
var tremendo := 0.0

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
	humor(0)

## 0 = começo (cinza escura), 1 e 2 = soltando cores, 3 = final feliz.
func humor(etapa: int) -> void:
	var tons := ["#8e8f9c", "#a9aab6", "#c7c8d2", "#ffffff"]
	var rosto: String = ROSTOS["sonolenta" if etapa == 0 else ("feliz" if etapa >= 3 else "preocupada")]
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="260" height="150" viewBox="0 0 260 150"><g stroke="#4a4652" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"><path fill="%s" d="%s"/>%s</g></svg>' % [tons[mini(etapa, 3)], CONTORNO, rosto]
	sprite.texture = Tex.svg(svg)
	chuva.amount = [26, 14, 6, 1][mini(etapa, 3)]
	chuva.emitting = etapa < 3

func _process(delta: float) -> void:
	t += delta
	tremendo = maxf(tremendo - delta * 2.0, 0.0)
	var balanco := Vector2(sin(t * 0.8) * 6.0, sin(t * 1.3) * 4.0)
	var tremor := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * tremendo * 6.0
	sprite.position = balanco + tremor
	var respira := 1.0 + sin(t * 1.1) * 0.02
	sprite.scale = Vector2(respira, 2.0 - respira)

## Nublina se espreme e solta uma cor. Retorna a posição de onde a cor sai.
func soltar_cor() -> Vector2:
	tremendo = 1.0
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.18, 0.85), 0.18)
	tw.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return global_position + Vector2(0, 30)

func ir_para(destino: Vector2, duracao: float = 2.5) -> void:
	var tw := create_tween()
	tw.tween_property(self, "position", destino, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
