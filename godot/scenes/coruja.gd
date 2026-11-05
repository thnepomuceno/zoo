extends Node2D
## A sábia Coruja, que pediu ajuda às crianças. Fica num galho, pisca, se preocupa
## e, a cada cartão pintado, bate as asas e manda a cor voando até o animal.

const Tex := preload("res://godot/scenes/texturas.gd")
const SHADER_DESBOTAR := preload("res://godot/shaders/desbotar.gdshader")

const CORPO := '<path fill="#8a5a3b" d="M40 50 L30 8 L68 34 Z M130 50 L140 8 L102 34 Z"/><ellipse fill="#8a5a3b" cx="85" cy="104" rx="62" ry="74"/><ellipse fill="#ecd4a8" cx="85" cy="132" rx="38" ry="42"/><path fill="none" stroke-width="3" d="M68 118 q6 7 12 0 M90 118 q6 7 12 0 M79 134 q6 7 12 0 M68 150 q6 7 12 0 M90 150 q6 7 12 0"/><ellipse fill="#ff993d" cx="66" cy="180" rx="13" ry="6"/><ellipse fill="#ff993d" cx="104" cy="180" rx="13" ry="6"/><circle fill="#f6e6c6" cx="62" cy="74" r="28"/><circle fill="#f6e6c6" cx="108" cy="74" r="28"/><path fill="#ff993d" d="M77 92 L93 92 L85 109 Z"/>'
const OLHOS_ABERTOS := '<circle fill="#ffd34d" cx="62" cy="74" r="17"/><circle fill="#ffd34d" cx="108" cy="74" r="17"/><circle fill="#302c35" cx="62" cy="75" r="9"/><circle fill="#302c35" cx="108" cy="75" r="9"/><circle fill="#ffffff" stroke="none" cx="58" cy="70" r="3.5"/><circle fill="#ffffff" stroke="none" cx="104" cy="70" r="3.5"/>'
const OLHOS_FECHADOS := '<path fill="none" d="M46 76 Q62 86 78 76 M92 76 Q108 86 124 76"/>'
const ROSTOS := {
	"preocupada": '<path fill="none" stroke-width="4" d="M42 52 L72 43 M128 52 L98 43"/>',
	"feliz": '<ellipse fill="#f4a8bd" stroke="none" opacity="0.8" cx="40" cy="96" rx="11" ry="6"/><ellipse fill="#f4a8bd" stroke="none" opacity="0.8" cx="130" cy="96" rx="11" ry="6"/>',
}
const ASA := '<svg xmlns="http://www.w3.org/2000/svg" width="52" height="100" viewBox="0 0 52 100"><g stroke="#302c35" stroke-width="5" stroke-linejoin="round" stroke-linecap="round"><path fill="#74482d" d="M26 4 Q50 30 44 70 Q38 96 26 96 Q14 96 8 70 Q2 30 26 4 Z"/><path fill="none" stroke-width="3" d="M16 62 Q26 70 36 62 M18 78 Q26 85 34 78"/></g></svg>'

const ESCALA := 0.62

var boneco: Node2D
var corpo: Sprite2D
var asas: Array[Sprite2D] = []
var material_cor: ShaderMaterial
var texturas: Dictionary = {}
var rosto := "preocupada"
var t := 0.0
var proxima_piscada := 2.5
var batendo := 0.0

func _ready() -> void:
	material_cor = ShaderMaterial.new()
	material_cor.shader = SHADER_DESBOTAR
	for r in ROSTOS:
		for aberto in [true, false]:
			texturas[r + str(aberto)] = Tex.svg('<svg xmlns="http://www.w3.org/2000/svg" width="170" height="192" viewBox="0 0 170 192"><g stroke="#302c35" stroke-width="5" stroke-linejoin="round" stroke-linecap="round">%s%s%s</g></svg>' % [CORPO, OLHOS_ABERTOS if aberto else OLHOS_FECHADOS, ROSTOS[r]])
	boneco = Node2D.new()
	boneco.scale = Vector2.ONE * ESCALA
	add_child(boneco)
	corpo = Sprite2D.new()
	corpo.material = material_cor
	boneco.add_child(corpo)
	var asa_tex := Tex.svg(ASA)
	for lado in [-1, 1]:
		var asa := Sprite2D.new()
		asa.texture = asa_tex
		asa.offset = Vector2(0, 44) # pivô no ombro
		asa.position = Vector2(lado * 57, -40)
		asa.flip_h = lado > 0
		asa.material = material_cor
		boneco.add_child(asa)
		asas.append(asa)
	humor(0, 1)

## A coruja fica preocupada até todos os animais aparecerem; aí fica feliz.
func humor(nivel: int, total: int) -> void:
	rosto = "feliz" if nivel >= total else "preocupada"
	corpo.texture = texturas[rosto + "true"]

func definir_saturacao(valor: float) -> void:
	material_cor.set_shader_parameter("saturacao", valor)

func _process(delta: float) -> void:
	t += delta
	batendo = maxf(batendo - delta, 0.0)
	corpo.position.y = sin(t * 1.6) * 2.5
	boneco.rotation = sin(t * 0.7) * 0.04
	var abre := absf(sin(t * 18.0)) * 0.9 if batendo > 0.0 else 0.04 + sin(t * 1.6) * 0.03
	asas[0].rotation = abre
	asas[1].rotation = -abre
	for asa in asas:
		asa.position.y = -40 + corpo.position.y
	proxima_piscada -= delta
	if proxima_piscada <= 0.0:
		proxima_piscada = randf_range(2.5, 5.0)
		piscar()

func piscar() -> void:
	corpo.texture = texturas[rosto + "false"]
	await get_tree().create_timer(0.13).timeout
	corpo.texture = texturas[rosto + "true"]

func bater_asas(duracao: float) -> void:
	batendo = duracao
	var tw := create_tween()
	tw.tween_property(boneco, "scale", Vector2(1.08, 0.92) * ESCALA, 0.12)
	tw.tween_property(boneco, "position:y", -22.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(boneco, "scale", Vector2.ONE * ESCALA, 0.22)
	tw.tween_property(boneco, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

## Bate as asas e solta a cor. Retorna a posição de onde a cor sai.
func soltar_cor() -> Vector2:
	bater_asas(0.9)
	return global_position + Vector2(0, -6)
