extends Node2D
## O ajudante sábio que pediu ajuda às crianças: a Coruja (floresta) ou o Galo (fazenda).
## Fica no galho ou na cerca, pisca, se preocupa e, a cada cartão pintado,
## bate as asas e manda a cor voando até o animal.

const Tex := preload("res://godot/scenes/texturas.gd")
const SHADER_DESBOTAR := preload("res://godot/shaders/desbotar.gdshader")

const TRACO := '<g stroke="#302c35" stroke-width="5" stroke-linejoin="round" stroke-linecap="round">%s</g>'
const DESENHOS := {
	"coruja": {
		"tamanho": Vector2(170, 192),
		"corpo": '<path fill="#8a5a3b" d="M40 50 L30 8 L68 34 Z M130 50 L140 8 L102 34 Z"/><ellipse fill="#8a5a3b" cx="85" cy="104" rx="62" ry="74"/><ellipse fill="#ecd4a8" cx="85" cy="132" rx="38" ry="42"/><path fill="none" stroke-width="3" d="M68 118 q6 7 12 0 M90 118 q6 7 12 0 M79 134 q6 7 12 0 M68 150 q6 7 12 0 M90 150 q6 7 12 0"/><ellipse fill="#ff993d" cx="66" cy="180" rx="13" ry="6"/><ellipse fill="#ff993d" cx="104" cy="180" rx="13" ry="6"/><circle fill="#f6e6c6" cx="62" cy="74" r="28"/><circle fill="#f6e6c6" cx="108" cy="74" r="28"/><path fill="#ff993d" d="M77 92 L93 92 L85 109 Z"/>',
		"abertos": '<circle fill="#ffd34d" cx="62" cy="74" r="17"/><circle fill="#ffd34d" cx="108" cy="74" r="17"/><circle fill="#302c35" cx="62" cy="75" r="9"/><circle fill="#302c35" cx="108" cy="75" r="9"/><circle fill="#ffffff" stroke="none" cx="58" cy="70" r="3.5"/><circle fill="#ffffff" stroke="none" cx="104" cy="70" r="3.5"/>',
		"fechados": '<path fill="none" d="M46 76 Q62 86 78 76 M92 76 Q108 86 124 76"/>',
		"preocupada": '<path fill="none" stroke-width="4" d="M42 52 L72 43 M128 52 L98 43"/>',
		"feliz": '<ellipse fill="#f4a8bd" stroke="none" opacity="0.8" cx="40" cy="96" rx="11" ry="6"/><ellipse fill="#f4a8bd" stroke="none" opacity="0.8" cx="130" cy="96" rx="11" ry="6"/>',
		"asa": '<svg xmlns="http://www.w3.org/2000/svg" width="52" height="100" viewBox="0 0 52 100"><g stroke="#302c35" stroke-width="5" stroke-linejoin="round" stroke-linecap="round"><path fill="#74482d" d="M26 4 Q50 30 44 70 Q38 96 26 96 Q14 96 8 70 Q2 30 26 4 Z"/><path fill="none" stroke-width="3" d="M16 62 Q26 70 36 62 M18 78 Q26 85 34 78"/></g></svg>',
		"ombro": Vector2(57, -40),
		"escala": 0.62,
	},
	# Galo de frente, com o rabo colorido aparecendo atrás, crista e barbela vermelhas.
	"galo": {
		"tamanho": Vector2(190, 200),
		"corpo": '<path fill="#2e8b57" d="M118 112 Q176 70 160 14 Q146 66 112 92 Z"/><path fill="#1f6f8b" d="M122 124 Q186 104 178 50 Q156 100 116 108 Z"/><path fill="#c0392b" d="M120 138 Q184 142 182 96 Q160 128 116 124 Z"/><path fill="none" stroke="#c46a2b" stroke-width="5" d="M70 168 L68 190 M100 168 L102 190"/><path fill="none" stroke="#c46a2b" stroke-width="4" d="M56 192 L80 192 M68 190 L60 184 M90 192 L114 192 M102 190 L110 184"/><ellipse fill="#d9643a" cx="85" cy="122" rx="54" ry="56"/><ellipse fill="#f2b45a" cx="85" cy="138" rx="32" ry="36"/><path fill="none" stroke-width="3" d="M70 126 q6 7 12 0 M90 126 q6 7 12 0 M80 142 q6 7 12 0"/><path fill="#e63b3b" d="M62 38 Q56 14 72 18 Q76 0 90 12 Q102 0 108 20 Q124 18 112 40 Z"/><circle fill="#f6e3c4" cx="85" cy="62" r="34"/><path fill="#e63b3b" d="M79 82 Q76 102 85 102 Q94 102 91 82 Z"/><path fill="#ffc23d" d="M74 70 L96 70 L85 86 Z"/>',
		"abertos": '<circle fill="#ffffff" cx="71" cy="56" r="10"/><circle fill="#ffffff" cx="99" cy="56" r="10"/><circle fill="#302c35" cx="72" cy="57" r="5.5"/><circle fill="#302c35" cx="98" cy="57" r="5.5"/><circle fill="#ffffff" stroke="none" cx="70" cy="54" r="2"/><circle fill="#ffffff" stroke="none" cx="96" cy="54" r="2"/>',
		"fechados": '<path fill="none" d="M61 58 Q71 65 81 58 M89 58 Q99 65 109 58"/>',
		"preocupada": '<path fill="none" stroke-width="4" d="M58 42 L80 37 M112 42 L90 37"/>',
		"feliz": '<ellipse fill="#f4a8bd" stroke="none" opacity="0.8" cx="60" cy="74" rx="8" ry="5"/><ellipse fill="#f4a8bd" stroke="none" opacity="0.8" cx="110" cy="74" rx="8" ry="5"/>',
		"asa": '<svg xmlns="http://www.w3.org/2000/svg" width="52" height="96" viewBox="0 0 52 96"><g stroke="#302c35" stroke-width="5" stroke-linejoin="round" stroke-linecap="round"><path fill="#b8452c" d="M26 4 Q48 26 44 64 Q38 92 26 92 Q14 92 8 64 Q4 26 26 4 Z"/><path fill="none" stroke-width="3" d="M16 56 Q26 64 36 56 M18 72 Q26 79 34 72"/></g></svg>',
		"ombro": Vector2(50, -6),
		"escala": 0.6,
	},
}

var tipo := "coruja"
var desenho: Dictionary
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
	desenho = DESENHOS[tipo]
	material_cor = ShaderMaterial.new()
	material_cor.shader = SHADER_DESBOTAR
	var tam: Vector2 = desenho["tamanho"]
	for r in ["preocupada", "feliz"]:
		for aberto in [true, false]:
			var miolo: String = desenho["corpo"] + desenho["abertos" if aberto else "fechados"] + desenho[r]
			texturas[r + str(aberto)] = Tex.svg('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">%s</svg>' % [tam.x, tam.y, tam.x, tam.y, TRACO % miolo])
	boneco = Node2D.new()
	boneco.scale = Vector2.ONE * escala()
	add_child(boneco)
	corpo = Sprite2D.new()
	corpo.material = material_cor
	# O desenho é centrado no corpo (x = 85), mesmo que o rabo deixe a imagem mais larga.
	corpo.offset = Vector2(tam.x / 2.0 - 85.0, 0)
	boneco.add_child(corpo)
	var asa_tex := Tex.svg(desenho["asa"])
	var ombro: Vector2 = desenho["ombro"]
	for lado in [-1, 1]:
		var asa := Sprite2D.new()
		asa.texture = asa_tex
		asa.offset = Vector2(0, 44) # pivô no ombro
		asa.position = Vector2(lado * ombro.x, ombro.y)
		asa.flip_h = lado > 0
		asa.material = material_cor
		boneco.add_child(asa)
		asas.append(asa)
	humor(0, 1)

func escala() -> float:
	return float(desenho["escala"])

## Fica preocupado até todos os animais aparecerem; aí fica feliz.
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
	var ombro: Vector2 = desenho["ombro"]
	for asa in asas:
		asa.position.y = ombro.y + corpo.position.y
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
	var e := escala()
	var tw := create_tween()
	tw.tween_property(boneco, "scale", Vector2(1.08, 0.92) * e, 0.12)
	tw.tween_property(boneco, "position:y", -22.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(boneco, "scale", Vector2.ONE * e, 0.22)
	tw.tween_property(boneco, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

## Bate as asas e solta a cor. Retorna a posição de onde a cor sai.
func soltar_cor() -> Vector2:
	bater_asas(0.9)
	return global_position + Vector2(0, -6)
