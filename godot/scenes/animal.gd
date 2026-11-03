extends Node2D
## Um amigo da floresta. Fica cinza e tristinho até receber as cores do desenho.

const Tex := preload("res://godot/scenes/texturas.gd")
const SHADER_REVELAR := preload("res://godot/shaders/revelar.gdshader")
const REGIOES := ["#ffffff", "#eeeeee", "#dddddd"]
const CINZAS := ["#d7d8de", "#c4c6cf", "#b3b5bf"]
const PE := 135.0 # distância do centro do desenho até as patas

## Expressões: trocas no SVG original e enfeites extras por humor.
const ROSTOS := {
	"cachorro": {
		"boca": '<path fill="none" d="M145 140 L145 155 Q126 170 114 150 M145 155 Q164 170 177 150"/>',
		"triste": '<path fill="none" d="M145 140 L145 154 M124 167 Q145 151 166 167"/><path fill="none" stroke-width="4" d="M104 96 L128 88 M162 88 L186 96"/>',
		"feliz": '<path fill="none" d="M145 140 L145 152 M118 150 Q145 172 172 150"/><path fill="#ef6b65" stroke-width="3" d="M134 159 Q145 184 156 159 Z"/><ellipse fill="#f7a1b5" stroke="none" opacity="0.75" cx="92" cy="134" rx="12" ry="7"/><ellipse fill="#f7a1b5" stroke="none" opacity="0.75" cx="198" cy="134" rx="12" ry="7"/><circle fill="#fefefe" stroke="none" cx="121" cy="104" r="3"/><circle fill="#fefefe" stroke="none" cx="177" cy="104" r="3"/>',
		"olhos": [Vector2(-32, -41), Vector2(24, -41)],
	},
	"dinossauro": {
		"boca": '<path fill="none" d="M139 65 Q151 73 164 63"/>',
		"triste": '<path fill="none" d="M141 71 Q152 63 164 71"/><path fill="none" stroke-width="4" d="M110 40 Q120 34 131 41"/>',
		"feliz": '<path fill="none" d="M137 62 Q152 80 168 60"/><ellipse fill="#f7a1b5" stroke="none" opacity="0.75" cx="142" cy="55" rx="8" ry="5"/><circle fill="#fefefe" stroke="none" cx="123" cy="46" r="2.2"/>',
		"olhos": [Vector2(-29, -101)],
	},
	"leao": {
		"boca": '<path fill="none" d="M145 141 L145 155 Q127 168 119 149 M145 155 Q163 168 171 149"/>',
		"triste": '<path fill="none" d="M145 141 L145 153 M126 166 Q145 151 164 166"/><path fill="none" stroke-width="4" d="M104 96 L128 89 M162 89 L186 96"/>',
		"feliz": '<path fill="none" d="M145 141 L145 152 M121 150 Q145 170 169 150"/><path fill="#ef6b65" stroke-width="3" d="M135 158 Q145 178 155 158 Z"/><ellipse fill="#f7a1b5" stroke="none" opacity="0.75" cx="98" cy="134" rx="11" ry="7"/><ellipse fill="#f7a1b5" stroke="none" opacity="0.75" cx="192" cy="134" rx="11" ry="7"/><circle fill="#fefefe" stroke="none" cx="121" cy="104" r="3"/><circle fill="#fefefe" stroke="none" cx="177" cy="104" r="3"/>',
		"olhos": [Vector2(-32, -41), Vector2(24, -41)],
	},
}

## Jeito de se mexer de cada um quando está feliz.
const JEITO := {
	"cachorro": {"pulo": 18.0, "ritmo": 3.6, "balanco": 0.09},
	"dinossauro": {"pulo": 8.0, "ritmo": 2.0, "balanco": 0.05},
	"leao": {"pulo": 12.0, "ritmo": 2.6, "balanco": 0.04},
}

var nome: String
var modelo: String
var feliz := false
var em_destaque := false
var animando := false
var t := 0.0
var proxima_lagrima := 2.0
var escala := 0.95

var corpo: Node2D
var cinza: Sprite2D
var colorido: Sprite2D
var sombra: Sprite2D
var holofote: Sprite2D

func configurar(nome_animal: String) -> void:
	nome = nome_animal
	modelo = FileAccess.get_file_as_string("res://godot/assets/animais/" + nome + ".svg")
	t = randf() * 10.0
	proxima_lagrima = randf_range(1.0, 3.5)

	holofote = Sprite2D.new()
	holofote.texture = Tex.brilho(128)
	holofote.scale = Vector2(2.6, 0.9)
	holofote.position = Vector2(0, PE - 4)
	holofote.modulate = Color(1, 0.95, 0.7, 0)
	add_child(holofote)

	sombra = Sprite2D.new()
	sombra.texture = Tex.brilho(128)
	sombra.scale = Vector2(1.7, 0.32)
	sombra.position = Vector2(0, PE)
	sombra.modulate = Color(0.1, 0.1, 0.18, 0.45)
	add_child(sombra)

	corpo = Node2D.new()
	corpo.position = Vector2(0, PE)
	corpo.scale = Vector2.ONE * escala
	add_child(corpo)
	cinza = Sprite2D.new()
	cinza.position = Vector2(0, -PE)
	cinza.texture = desenhar(CINZAS, false)
	corpo.add_child(cinza)
	colorido = Sprite2D.new()
	colorido.position = Vector2(0, -PE)
	colorido.material = ShaderMaterial.new()
	colorido.material.shader = SHADER_REVELAR
	colorido.hide()
	corpo.add_child(colorido)

## Monta o SVG com as cores (hex) e a expressão pedida.
func desenhar(cores_hex: Array, alegre: bool) -> Texture2D:
	var svg := modelo
	var rosto: Dictionary = ROSTOS[nome]
	svg = svg.replace(rosto["boca"], "")
	svg = svg.replace("</g></svg>", (rosto["feliz"] if alegre else rosto["triste"]) + "</g></svg>")
	for i in range(3):
		# Marcadores evitam que uma substituição afete outra região.
		svg = svg.replace(REGIOES[i], "REGIAO_%d" % i)
	for i in range(3):
		svg = svg.replace("REGIAO_%d" % i, str(cores_hex[i % cores_hex.size()]).to_upper())
	return Tex.svg(svg)

func _process(delta: float) -> void:
	t += delta
	var alvo := 0.55 if em_destaque and not feliz else (0.35 if feliz else 0.0)
	holofote.modulate.a = lerpf(holofote.modulate.a, alvo * (0.8 + 0.2 * sin(t * 3.0)), delta * 3.0)
	if animando:
		return
	var base := Vector2.ONE * escala
	if feliz:
		var j: Dictionary = JEITO[nome]
		var fase: float = t * float(j["ritmo"])
		var pulo := absf(sin(fase))
		var chao := pow(1.0 - pulo, 6.0) # amassadinho ao tocar o chão
		corpo.position.y = PE - pulo * float(j["pulo"])
		corpo.scale = base * Vector2(1.0 + chao * 0.07, 1.0 - chao * 0.08)
		corpo.rotation = sin(fase * 0.5) * float(j["balanco"])
		sombra.scale = Vector2(1.7 - pulo * 0.3, 0.32)
	else:
		# Respiração lenta, cabisbaixo, um suspiro de vez em quando.
		var respira := sin(t * 1.5)
		var suspiro := pow(maxf(sin(t * 0.35), 0.0), 12.0)
		corpo.position.y = PE
		corpo.scale = base * Vector2(1.0 + respira * 0.008 + suspiro * 0.03, 1.0 - respira * 0.016 - suspiro * 0.05)
		corpo.rotation = sin(t * 0.6) * 0.012 - 0.02
		proxima_lagrima -= delta
		if proxima_lagrima <= 0.0:
			proxima_lagrima = randf_range(2.2, 4.5) if em_destaque else randf_range(4.0, 8.0)
			chorar()

func chorar() -> void:
	var olhos: Array = ROSTOS[nome]["olhos"]
	var olho: Vector2 = olhos.pick_random()
	var lado := signf(olho.x)
	var gota := Sprite2D.new()
	gota.texture = Tex.gota()
	gota.scale = Vector2.ONE * 0.9
	var inicio := (olho + Vector2(0, 14)) * escala + Vector2(0, PE * (1.0 - escala))
	gota.position = inicio
	gota.modulate.a = 0.0
	add_child(gota)
	var tw := create_tween()
	tw.tween_property(gota, "modulate:a", 1.0, 0.25)
	tw.tween_property(gota, "position", inicio + Vector2(lado * 4, 70), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(gota, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tw.tween_callback(gota.queue_free)

## Transformação: amassa, a cor explode de dentro pra fora, pula de alegria.
func colorir(cores: Array, rapido: bool = false) -> void:
	animando = true
	var hex: Array = []
	for c in cores:
		hex.append("#" + Color(c).to_html(false))
	colorido.texture = desenhar(hex, true)
	colorido.material.set_shader_parameter("progresso", 0.0)
	colorido.material.set_shader_parameter("cor_borda", Color(cores[0]).lightened(0.55))
	colorido.show()
	corpo.rotation = 0.0
	var base := Vector2.ONE * escala

	var tw := create_tween()
	tw.tween_property(corpo, "scale", base * Vector2(1.14, 0.82), 0.12 if rapido else 0.35).set_trans(Tween.TRANS_SINE)
	await tw.finished

	explodir(cores)
	tw = create_tween().set_parallel()
	tw.tween_method(func(v: float): colorido.material.set_shader_parameter("progresso", v), 0.0, 1.3, 0.6 if rapido else 1.2)
	tw.tween_property(corpo, "scale", base * Vector2(0.88, 1.2), 0.16)
	tw.tween_property(corpo, "position:y", PE - 70.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(corpo, "position:y", PE, 0.42).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(corpo, "scale", base * 1.12, 0.3)
	tw.chain().tween_property(corpo, "scale", base, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	cinza.texture = colorido.texture
	colorido.material.set_shader_parameter("progresso", 1.3)
	feliz = true
	animando = false
	coracoes()

func explodir(cores: Array) -> void:
	var tinta := _particulas(Tex.brilho(32), 70, 1.3)
	tinta.initial_velocity_min = 180
	tinta.initial_velocity_max = 380
	tinta.scale_amount_min = 0.35
	tinta.scale_amount_max = 0.9
	tinta.gravity = Vector2(0, 420)
	tinta.color_initial_ramp = Tex.gradiente(cores)
	var estrelas := _particulas(Tex.estrela(), 26, 1.6)
	estrelas.initial_velocity_min = 90
	estrelas.initial_velocity_max = 260
	estrelas.gravity = Vector2(0, 60)
	estrelas.angular_velocity_min = -360
	estrelas.angular_velocity_max = 360
	estrelas.scale_amount_min = 0.5
	estrelas.scale_amount_max = 1.3
	estrelas.color_initial_ramp = Tex.gradiente([Color("#fff6b0"), Color.WHITE, Color("#ffd86b")])
	# Anel de luz que se expande.
	var anel := Sprite2D.new()
	anel.texture = Tex.brilho(128)
	anel.position = Vector2(0, -10)
	anel.scale = Vector2.ONE * 0.2
	anel.modulate = Color(cores[0]).lightened(0.6)
	add_child(anel)
	var tw := create_tween().set_parallel()
	tw.tween_property(anel, "scale", Vector2.ONE * 4.5, 0.7).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(anel, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(anel.queue_free)

func coracoes() -> void:
	var p := _particulas(Tex.coracao(), 6, 2.2)
	p.position = Vector2(0, -150)
	p.explosiveness = 0.3
	p.direction = Vector2(0, -1)
	p.spread = 40
	p.initial_velocity_min = 50
	p.initial_velocity_max = 90
	p.gravity = Vector2(0, -20)
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.2

func _particulas(textura: Texture2D, quantidade: int, vida: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = textura
	p.amount = quantidade
	p.lifetime = vida
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.position = Vector2(0, -20)
	var some := Gradient.new()
	some.set_color(0, Color(1, 1, 1, 1))
	some.set_color(1, Color(1, 1, 1, 0))
	some.add_point(0.7, Color(1, 1, 1, 1))
	p.color_ramp = some
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p

## Dança da vitória (final): um pulão com giro.
func festejar(atraso: float) -> void:
	await get_tree().create_timer(atraso).timeout
	animando = true
	var tw := create_tween()
	tw.tween_property(corpo, "position:y", PE - 90.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(corpo, "rotation", TAU, 0.8)
	tw.tween_property(corpo, "position:y", PE, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tw.finished
	corpo.rotation = 0.0
	animando = false
	coracoes()
