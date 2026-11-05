extends Node2D
## Um animal da Floresta Encantada. Começa cinza, escondido atrás de uma moita,
## espiando com medo. Quando recebe as cores do cartão pintado, sai do esconderijo.

const Tex := preload("res://godot/scenes/texturas.gd")
const SHADER_PINTURA := preload("res://godot/shaders/pintura.gdshader")
const SHADER_DESBOTAR := preload("res://godot/shaders/desbotar.gdshader")
const CINZAS := ["#d7d8de", "#c4c6cf", "#b3b5bf"]
const PE := 135.0 # distância do centro do nó até as patas
const BASE_MOITA := 8.0 # a moita vai até um pouquinho abaixo das patas

## tamanho: maior lado na tela. espiar: quanto do corpo aparece por cima da moita.
## olhos: posição (0..1) no desenho, para as gotinhas de medo. voo: altura em que flutua.
const DADOS := {
	"onca": {"tamanho": 232.0, "espiar": 0.42, "olhos": [Vector2(0.29, 0.25), Vector2(0.55, 0.25)], "pulo": 12.0, "ritmo": 2.8, "balanco": 0.05, "voo": 0.0},
	"macaco": {"tamanho": 250.0, "espiar": 0.45, "olhos": [Vector2(0.33, 0.25), Vector2(0.5, 0.25)], "pulo": 22.0, "ritmo": 4.0, "balanco": 0.12, "voo": 0.0},
	"tamandua": {"tamanho": 262.0, "espiar": 0.5, "olhos": [Vector2(0.63, 0.2)], "pulo": 7.0, "ritmo": 2.0, "balanco": 0.04, "voo": 0.0},
	"borboleta": {"tamanho": 205.0, "espiar": 0.5, "olhos": [Vector2(0.47, 0.27), Vector2(0.53, 0.27)], "pulo": 14.0, "ritmo": 1.6, "balanco": 0.06, "voo": 46.0},
}

var nome: String
var dados: Dictionary
var feliz := false
var escondido := true
var em_destaque := false
var animando := false
var t := 0.0
var proxima_gota := 2.0
var proximo_chacoalho := 3.0
var escala := 1.0
var altura := 0.0 # altura do desenho na textura (px)
var topo_moita := 0.0

var textura: Texture2D
var regioes: Texture2D
var corpo: Node2D
var cinza: Sprite2D
var colorido: Sprite2D
var sombra: Sprite2D
var holofote: Sprite2D
var moita: Sprite2D

func configurar(nome_animal: String) -> void:
	nome = nome_animal
	dados = DADOS[nome]
	textura = load("res://godot/assets/animais/%s.png" % nome)
	regioes = load("res://godot/assets/animais/%s_regioes.png" % nome)
	var tam := textura.get_size()
	escala = float(dados["tamanho"]) / maxf(tam.x, tam.y)
	altura = tam.y
	t = randf() * 10.0
	proxima_gota = randf_range(1.0, 3.5)

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
	sombra.modulate = Color(0.1, 0.1, 0.18, 0.0)
	add_child(sombra)

	corpo = Node2D.new()
	corpo.scale = Vector2.ONE * escala
	add_child(corpo)
	cinza = Sprite2D.new()
	cinza.texture = textura
	cinza.position = Vector2(0, -altura / 2.0)
	cinza.material = novo_material(CINZAS)
	corpo.add_child(cinza)
	colorido = Sprite2D.new()
	colorido.texture = textura
	colorido.position = cinza.position
	colorido.hide()
	corpo.add_child(colorido)

	# A moita fica na frente do corpo enquanto ele está escondido.
	moita = Sprite2D.new()
	moita.texture = Tex.moita()
	var largura := maxf(tam.x * escala * 1.02, 225.0)
	moita.scale = Vector2(1.0, 0.82) * largura / 280.0
	moita.offset = Vector2(0, -78) # pivô na base, para chacoalhar pelo pé
	moita.position = Vector2(0, PE + BASE_MOITA)
	moita.material = ShaderMaterial.new()
	moita.material.shader = SHADER_DESBOTAR
	add_child(moita)
	topo_moita = PE + BASE_MOITA - 150.0 * moita.scale.y
	corpo.position = Vector2(0, posicao_escondido())
	_atualizar_corte()

## Material que pinta o desenho por regiões com até três cores (ciclando se vierem menos).
func novo_material(cores: Array) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER_PINTURA
	m.set_shader_parameter("regioes", regioes)
	for i in range(3):
		m.set_shader_parameter("cor%d" % i, Color(cores[i % cores.size()]))
	return m

## Onde ficam as patas (no nó) para só a cabeça aparecer por cima da moita.
func posicao_escondido() -> float:
	return topo_moita + (1.0 - float(dados["espiar"])) * altura * escala

func chao() -> float:
	return PE - float(dados["voo"])

## Corta o que estiver abaixo da moita, para as patas não aparecerem por baixo dela.
func _atualizar_corte() -> void:
	var corte := 2.0
	if escondido:
		var limite_local := (PE + BASE_MOITA - 4.0 - corpo.position.y) / escala
		corte = (limite_local + altura) / altura
	cinza.material.set_shader_parameter("corte", corte)
	if colorido.material:
		colorido.material.set_shader_parameter("corte", corte)

func definir_saturacao(valor: float) -> void:
	moita.material.set_shader_parameter("saturacao", valor)

func _process(delta: float) -> void:
	t += delta
	var alvo := 0.55 if em_destaque and not feliz else (0.35 if feliz else 0.0)
	holofote.modulate.a = lerpf(holofote.modulate.a, alvo * (0.8 + 0.2 * sin(t * 3.0)), delta * 3.0)
	if animando:
		_atualizar_corte()
		return
	var base := Vector2.ONE * escala
	if feliz:
		var fase: float = t * float(dados["ritmo"])
		var pulo := absf(sin(fase))
		var voo := float(dados["voo"])
		if voo > 0.0:
			# Flutua batendo as asas (o desenho "fecha" e "abre" na horizontal).
			corpo.position.y = chao() - sin(fase * 1.3) * float(dados["pulo"])
			corpo.scale = base * Vector2(1.0 - absf(sin(t * 7.0)) * 0.28, 1.0)
			corpo.rotation = sin(fase) * float(dados["balanco"])
			sombra.scale = Vector2(1.1 + sin(fase * 1.3) * 0.15, 0.24)
		else:
			var amassa := pow(1.0 - pulo, 6.0) # amassadinho ao tocar o chão
			corpo.position.y = PE - pulo * float(dados["pulo"])
			corpo.scale = base * Vector2(1.0 + amassa * 0.07, 1.0 - amassa * 0.08)
			corpo.rotation = sin(fase * 0.5) * float(dados["balanco"])
			sombra.scale = Vector2(1.7 - pulo * 0.3, 0.32)
	else:
		# Escondido: espia por cima da moita, se abaixa de medo e treme.
		var espia := sin(t * 0.9) * 0.5 + 0.5
		var abaixa := pow(maxf(sin(t * 0.37), 0.0), 10.0)
		var tremor := (0.018 if em_destaque else 0.009) * sin(t * 38.0)
		corpo.position.y = posicao_escondido() + (1.0 - espia) * 14.0 + abaixa * 40.0
		corpo.scale = base * Vector2(1.0 + sin(t * 1.5) * 0.008, 1.0 - sin(t * 1.5) * 0.014)
		corpo.rotation = tremor
		proxima_gota -= delta
		if proxima_gota <= 0.0:
			proxima_gota = randf_range(2.0, 4.0) if em_destaque else randf_range(4.5, 8.5)
			gotinha()
		proximo_chacoalho -= delta
		if proximo_chacoalho <= 0.0:
			proximo_chacoalho = randf_range(2.5, 5.0) if em_destaque else randf_range(6.0, 11.0)
			chacoalhar_moita(0.6)
		_atualizar_corte()

## Posição de um ponto do desenho (0..1) no espaço deste nó.
func ponto(uv: Vector2) -> Vector2:
	var tam := textura.get_size()
	return corpo.position + Vector2(uv.x * tam.x - tam.x / 2.0, uv.y * tam.y - tam.y) * escala

## Gotinha de medo que escorre do lado do rosto.
func gotinha() -> void:
	var olhos: Array = dados["olhos"]
	var olho: Vector2 = olhos.pick_random()
	var lado := -1.0 if olho.x < 0.5 else 1.0
	var gota := Sprite2D.new()
	gota.texture = Tex.gota()
	gota.scale = Vector2.ONE * 0.85
	var inicio := ponto(olho) + Vector2(lado * 26.0, -6.0)
	if inicio.y > topo_moita:
		return # o rosto está abaixado atrás da moita
	gota.position = inicio
	gota.modulate.a = 0.0
	add_child(gota)
	var tw := create_tween()
	tw.tween_property(gota, "modulate:a", 1.0, 0.2)
	tw.tween_property(gota, "position", inicio + Vector2(lado * 10, 46), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(gota, "modulate:a", 0.0, 0.4).set_delay(0.5)
	tw.tween_callback(gota.queue_free)

func chacoalhar_moita(forca: float = 1.0) -> void:
	var tw := create_tween()
	for i in range(4):
		var lado := 1.0 if i % 2 == 0 else -1.0
		tw.tween_property(moita, "rotation", lado * 0.05 * forca * (1.0 - i * 0.2), 0.08).set_trans(Tween.TRANS_SINE)
	tw.tween_property(moita, "rotation", 0.0, 0.1)

## Transformação: amassa, a cor explode de dentro para fora e ele pula para fora da moita.
func colorir(cores: Array, rapido: bool = false) -> void:
	animando = true
	var saindo := escondido
	colorido.material = novo_material(cores)
	colorido.material.set_shader_parameter("progresso", 0.0)
	colorido.material.set_shader_parameter("cor_borda", Color(cores[0]).lightened(0.55))
	colorido.show()
	_atualizar_corte()
	corpo.rotation = 0.0
	var base := Vector2.ONE * escala

	var tw := create_tween()
	tw.tween_property(corpo, "scale", base * Vector2(1.14, 0.82), 0.12 if rapido else 0.35).set_trans(Tween.TRANS_SINE)
	await tw.finished

	explodir(cores)
	create_tween().tween_method(func(v: float): colorido.material.set_shader_parameter("progresso", v), 0.0, 1.3, 0.6 if rapido else 1.2)
	if saindo:
		chacoalhar_moita(1.6)
		folhas_voando()
		# Pulão por cima da moita; lá no alto ela passa para trás dele.
		tw = create_tween()
		tw.tween_property(corpo, "scale", base * Vector2(0.88, 1.2), 0.16)
		tw.parallel().tween_property(corpo, "position:y", topo_moita - 26.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func():
			escondido = false
			move_child(moita, corpo.get_index())
			_atualizar_corte()
		)
		tw.tween_property(corpo, "position:y", chao(), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(corpo, "scale", base * 1.12, 0.3)
		tw.parallel().tween_property(sombra, "modulate:a", 0.45, 0.5)
		tw.parallel().tween_property(moita, "position:x", 22.0, 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(corpo, "scale", base, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		tw = create_tween()
		tw.tween_property(corpo, "scale", base * Vector2(0.88, 1.2), 0.16)
		tw.parallel().tween_property(corpo, "position:y", chao() - 70.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(corpo, "position:y", chao(), 0.42).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(corpo, "scale", base * 1.12, 0.3)
		tw.tween_property(corpo, "scale", base, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	if colorido.material.get_shader_parameter("progresso") < 1.3:
		await get_tree().create_timer(0.25).timeout
	cinza.material = novo_material(cores)
	colorido.hide()
	feliz = true
	animando = false
	coracoes()

## Material para mostrar este animal num ícone, com as cores atuais.
func material_icone() -> ShaderMaterial:
	var m: ShaderMaterial = cinza.material.duplicate()
	m.set_shader_parameter("corte", 2.0)
	return m

func explodir(cores: Array) -> void:
	var centro := ponto(Vector2(0.5, 0.5))
	var tinta := _particulas(Tex.brilho(32), 70, 1.3)
	tinta.position = centro
	tinta.initial_velocity_min = 180
	tinta.initial_velocity_max = 380
	tinta.scale_amount_min = 0.35
	tinta.scale_amount_max = 0.9
	tinta.gravity = Vector2(0, 420)
	tinta.color_initial_ramp = Tex.gradiente(cores)
	var estrelas := _particulas(Tex.estrela(), 26, 1.6)
	estrelas.position = centro
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
	anel.position = centro
	anel.scale = Vector2.ONE * 0.2
	anel.modulate = Color(cores[0]).lightened(0.6)
	add_child(anel)
	var tw := create_tween().set_parallel()
	tw.tween_property(anel, "scale", Vector2.ONE * 4.5, 0.7).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(anel, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(anel.queue_free)

## Folhas que voam da moita quando o animal sai.
func folhas_voando() -> void:
	var p := _particulas(Tex.folha(), 22, 1.6)
	p.position = Vector2(0, topo_moita + 30.0)
	p.direction = Vector2(0, -1)
	p.spread = 70
	p.initial_velocity_min = 160
	p.initial_velocity_max = 320
	p.gravity = Vector2(0, 380)
	p.angular_velocity_min = -400
	p.angular_velocity_max = 400
	p.scale_amount_min = 0.9
	p.scale_amount_max = 1.6
	p.color_initial_ramp = Tex.gradiente([Color("#5fae4f"), Color("#86cf6a"), Color("#3f8a3a")])

func coracoes() -> void:
	var p := _particulas(Tex.coracao(), 6, 2.2)
	p.position = ponto(Vector2(0.5, 0.0)) + Vector2(0, 10)
	p.explosiveness = 0.3
	p.direction = Vector2(0, -1)
	p.spread = 40
	p.initial_velocity_min = 50
	p.initial_velocity_max = 90
	p.gravity = Vector2(0, -20)
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.2

func _particulas(textura_p: Texture2D, quantidade: int, vida: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = textura_p
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
	while animando:
		await get_tree().create_timer(0.2).timeout
	animando = true
	var tw := create_tween()
	tw.tween_property(corpo, "position:y", chao() - 90.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(corpo, "rotation", TAU, 0.8)
	tw.tween_property(corpo, "position:y", chao(), 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tw.finished
	corpo.rotation = 0.0
	animando = false
	coracoes()
