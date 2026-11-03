extends Node2D

const Tex := preload("res://godot/scenes/texturas.gd")
const Animal := preload("res://godot/scenes/animal.gd")
const Nublina := preload("res://godot/scenes/nublina.gd")
const Vento := preload("res://godot/scenes/vento.gd")
const ArcoIris := preload("res://godot/scenes/arco_iris.gd")
const Narrador := preload("res://godot/scenes/narrador.gd")
const SHADER_FLORESTA := preload("res://godot/shaders/floresta.gdshader")

# Pode ser substituída no Inspector ou por -- --pasta-json=C:/fotos.
@export_dir var pasta_json: String = "res://godot/dados_json"
const NOMES := ["cachorro", "dinossauro", "leao"]
const ROTULOS := ["Cachorrinho", "Dinossauro", "Leão"]
const APELIDOS := ["Pipoca", "Dino", "Léo"]
const TITULOS := ["Pipoca e o rabinho parado", "Dino, o escondidinho", "Léo, o rei sem rugido"]
const CORES := {
	"bege": "#dec49a", "amarelo": "#ffe059", "laranja": "#ff993d",
	"verde": "#79c968", "azul": "#65b8ef", "marrom": "#a57753",
	"rosa": "#f49cbe", "roxo": "#ac86dc", "vermelho": "#ef6b65",
	"branco": "#ffffff", "preto": "#46434b", "cinza": "#aaaaaa"
}
# Quanto da floresta volta a ter cor a cada amigo pintado.
const SATURACAO := [0.0, 0.42, 0.74, 1.0]
const BRILHO := [0.78, 0.88, 0.96, 1.04]
const VINHETA := [0.6, 0.38, 0.2, 0.0]
const POSICAO_NUVEM := [Vector2(1015, 100), Vector2(880, 92), Vector2(735, 88), Vector2(800, 72)]
const ESPERA_CUTUCAR := 40.0

var etapa: int = 0
var iniciada: bool = false
var animando: bool = false
var pendentes: Dictionary = {}
var assinaturas: Dictionary = {}
var pintados: Dictionary = {}
var animais: Dictionary = {}
var cutucados: Dictionary = {}

var fundo: ShaderMaterial
var nublina: Node2D
var vento: Node2D
var arco: Node2D
var narrador: Node
var musica: AudioStreamPlayer
var efeito: AudioStreamPlayer
var magia: AudioStreamPlayer
var sopro: AudioStreamPlayer
var pop: AudioStreamPlayer
var ambiente: AudioStreamPlayer
var espera: Timer

var capitulo_label: Label
var status: Label
var legenda: Label
var painel_legenda: PanelContainer
var controles_aventura: HBoxContainer
var introducao: Control
var paragrafos: Dictionary = {}
var icones: Array[TextureRect] = []
var placas: Array[PanelContainer] = []

func _ready() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--pasta-json="):
			pasta_json = argumento.trim_prefix("--pasta-json=")
	preparar_audio()
	montar_cenario()
	montar_interface()
	narrador.legenda.connect(_ao_narrar)
	narrador.terminou.connect(_ao_terminar_fala)
	narrador.falar(["intro_1", "intro_2", "intro_3"])
	var timer := Timer.new()
	timer.wait_time = 0.75
	timer.timeout.connect(ler_pasta)
	add_child(timer)
	timer.start()
	espera = Timer.new()
	espera.one_shot = true
	espera.timeout.connect(cutucar)
	add_child(espera)
	ler_pasta()

# ---------------------------------------------------------------- cenário

func montar_cenario() -> void:
	var cenario: TextureRect = $Cenario
	fundo = ShaderMaterial.new()
	fundo.shader = SHADER_FLORESTA
	cenario.material = fundo
	aplicar_clima(0, 0.0)

	arco = ArcoIris.new()
	arco.position = Vector2(576, 640)
	add_child(arco)

	nublina = Nublina.new()
	nublina.position = POSICAO_NUVEM[0]
	add_child(nublina)

	for i in range(3):
		var animal := Animal.new()
		add_child(animal)
		animal.configurar(NOMES[i])
		animal.position = Vector2(220 + 355 * i, 340)
		animais[NOMES[i]] = animal

	vento = Vento.new()
	add_child(vento)
	vento.rajada.connect(func(forca: float):
		var tw := create_tween()
		tw.tween_method(func(v: float): fundo.set_shader_parameter("rajada", v), 0.0, forca, 1.0).set_trans(Tween.TRANS_SINE)
		tw.tween_method(func(v: float): fundo.set_shader_parameter("rajada", v), forca, 0.0, 2.0).set_trans(Tween.TRANS_SINE)
		var som := create_tween()
		som.tween_property(ambiente, "volume_db", -14.0, 1.0)
		som.tween_property(ambiente, "volume_db", -22.0, 2.0)
	)

## Clima da floresta conforme quantos amigos já têm cor.
func aplicar_clima(nivel: int, duracao: float) -> void:
	var alvo := {"saturacao": SATURACAO[nivel], "brilho": BRILHO[nivel], "vinheta": VINHETA[nivel]}
	for parametro in alvo:
		if duracao <= 0.0:
			fundo.set_shader_parameter(parametro, alvo[parametro])
			continue
		var atual: float = fundo.get_shader_parameter(parametro)
		create_tween().tween_method(func(v: float): fundo.set_shader_parameter(parametro, v), atual, alvo[parametro], duracao).set_trans(Tween.TRANS_SINE)
	if vento:
		create_tween().tween_method(vento.definir_cor, vento.saturacao, SATURACAO[nivel], maxf(duracao, 0.01))
		nublina.humor(nivel)
		nublina.ir_para(POSICAO_NUVEM[nivel], maxf(duracao, 0.01))
	if musica:
		create_tween().tween_property(musica, "pitch_scale", 0.94 + 0.02 * nivel, maxf(duracao, 0.01))

# ---------------------------------------------------------------- interface

func rotulo(texto: String, tamanho: int = 24, cor: Color = Color("#302c35")) -> Label:
	var label := Label.new()
	label.text = texto
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func painel(fundo_cor: Color = Color("#fff8e9"), borda: Color = Color("#dccb9e")) -> PanelContainer:
	var caixa := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fundo_cor
	estilo.border_color = borda
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(18)
	estilo.content_margin_left = 18
	estilo.content_margin_right = 18
	estilo.content_margin_top = 8
	estilo.content_margin_bottom = 8
	estilo.shadow_color = Color(0, 0, 0, 0.18)
	estilo.shadow_size = 6
	estilo.shadow_offset = Vector2(0, 3)
	caixa.add_theme_stylebox_override("panel", estilo)
	return caixa

func botao(texto: String, cor: Color, tamanho: int = 18) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", tamanho)
	for estado in ["normal", "hover", "pressed", "focus"]:
		var e := StyleBoxFlat.new()
		e.bg_color = cor.lightened(0.12) if estado == "hover" else (cor.darkened(0.12) if estado == "pressed" else cor)
		e.set_corner_radius_all(14)
		e.content_margin_left = 16
		e.content_margin_right = 16
		e.content_margin_top = 6
		e.content_margin_bottom = 6
		e.border_color = cor.darkened(0.3)
		e.border_width_bottom = 4
		b.add_theme_stylebox_override(estado, e)
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(estado, Color.WHITE)
	return b

func montar_interface() -> void:
	var tela := CanvasLayer.new()
	add_child(tela)

	var topo := painel()
	topo.position = Vector2(20, 14)
	tela.add_child(topo)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 14)
	topo.add_child(linha)
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 0)
	textos.custom_minimum_size = Vector2(440, 0)
	linha.add_child(textos)
	textos.add_child(rotulo("Zoo das Cores", 28, Color("#5b3f8c")))
	capitulo_label = rotulo("A floresta que perdeu as cores", 17)
	textos.add_child(capitulo_label)
	status = rotulo("Olho Mágico: acordando...", 15, Color("#7a6f62"))
	textos.add_child(status)
	for i in range(3):
		var icone := TextureRect.new()
		icone.texture = animais[NOMES[i]].cinza.texture
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.custom_minimum_size = Vector2(54, 54)
		icone.modulate = Color(1, 1, 1, 0.55)
		linha.add_child(icone)
		icones.append(icone)

	controles_aventura = HBoxContainer.new()
	controles_aventura.add_theme_constant_override("separation", 8)
	controles_aventura.position = Vector2(24, 136)
	controles_aventura.hide()
	tela.add_child(controles_aventura)
	var ouvir := botao("Ouvir de novo", Color("#7b5fc7"), 15)
	ouvir.pressed.connect(func():
		if animando:
			return
		narrador.falar(["final_1", "final_2"] if etapa == 3 else ["cap_" + NOMES[etapa]])
	)
	controles_aventura.add_child(ouvir)
	var som := botao("Música: ligada", Color("#4f9fd6"), 15)
	som.pressed.connect(func():
		musica.stream_paused = not musica.stream_paused
		som.text = "Música: pausada" if musica.stream_paused else "Música: ligada"
	)
	controles_aventura.add_child(som)

	for i in range(3):
		var placa := painel()
		placa.position = Vector2(95 + 355 * i, 484)
		placa.size = Vector2(250, 44)
		placa.pivot_offset = Vector2(125, 22)
		tela.add_child(placa)
		var nome_label := rotulo("%s, o %s" % [APELIDOS[i], ROTULOS[i].to_lower()] if i != 2 else "Léo, o leão", 18)
		nome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placa.add_child(nome_label)
		placas.append(placa)

	painel_legenda = painel(Color(1, 0.98, 0.93, 0.94))
	painel_legenda.position = Vector2(60, 546)
	painel_legenda.size = Vector2(1032, 88)
	painel_legenda.hide()
	tela.add_child(painel_legenda)
	legenda = rotulo("", 20)
	legenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legenda.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	legenda.size_flags_vertical = Control.SIZE_EXPAND_FILL
	painel_legenda.add_child(legenda)

	montar_introducao(tela)

func montar_introducao(tela: CanvasLayer) -> void:
	introducao = Control.new()
	introducao.set_anchors_preset(Control.PRESET_FULL_RECT)
	tela.add_child(introducao)
	var escuro := ColorRect.new()
	escuro.color = Color(0.08, 0.07, 0.14, 0.45)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	introducao.add_child(escuro)
	var caixa := painel()
	caixa.position = Vector2(176, 92)
	caixa.size = Vector2(800, 440)
	introducao.add_child(caixa)
	var margem := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 18)
	caixa.add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 14)
	margem.add_child(coluna)
	var titulo := rotulo("A floresta que perdeu as cores", 32, Color("#5b3f8c"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(titulo)
	for chave in ["intro_1", "intro_2", "intro_3"]:
		var p := rotulo(narrador.texto(chave), 20)
		p.modulate.a = 0.45
		coluna.add_child(p)
		paragrafos[chave] = p
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 16)
	botoes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	coluna.add_child(botoes)
	var repetir := botao("Ouvir a história", Color("#7b5fc7"), 20)
	repetir.pressed.connect(func(): narrador.falar(["intro_1", "intro_2", "intro_3"]))
	botoes.add_child(repetir)
	var comecar := botao("Vamos pintar!", Color("#4caf50"), 24)
	comecar.pressed.connect(iniciar_aventura)
	botoes.add_child(comecar)
	comecar.pivot_offset = Vector2(90, 24)
	var pulsar := create_tween().set_loops()
	pulsar.tween_property(comecar, "scale", Vector2(1.06, 1.06), 0.6).set_trans(Tween.TRANS_SINE)
	pulsar.tween_property(comecar, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)

func _ao_narrar(chave: String, texto: String) -> void:
	for c in paragrafos:
		create_tween().tween_property(paragrafos[c], "modulate:a", 1.0 if c == chave else 0.45, 0.3)
	if not chave.begins_with("intro"):
		legenda.text = texto
		legenda.modulate.a = 0.0
		create_tween().tween_property(legenda, "modulate:a", 1.0, 0.3)

func _ao_terminar_fala() -> void:
	if iniciada and etapa < 3 and not animando and not cutucados.has(etapa):
		espera.start(ESPERA_CUTUCAR)

func cutucar() -> void:
	if iniciada and etapa < 3 and not animando and not narrador.falando:
		cutucados[etapa] = true
		narrador.falar(["espera_" + NOMES[etapa]])

# ---------------------------------------------------------------- áudio

func preparar_audio() -> void:
	musica = tocador("res://godot/assets/audio/floresta.wav", -22.0, true)
	musica.pitch_scale = 0.94
	ambiente = tocador("res://godot/assets/audio/vento.wav", -22.0, true)
	efeito = tocador("res://godot/assets/audio/cores.wav", -12.0)
	magia = tocador("res://godot/assets/audio/magia.wav", -10.0)
	sopro = tocador("res://godot/assets/audio/sopro.wav", -12.0)
	pop = tocador("res://godot/assets/audio/pop.wav", -10.0)
	narrador = Narrador.new()
	narrador.musica = musica
	narrador.volume_musica = -22.0
	add_child(narrador)

func tocador(caminho: String, volume: float, repetir: bool = false) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	if ResourceLoader.exists(caminho):
		p.stream = load(caminho)
	p.volume_db = volume
	add_child(p)
	if repetir and p.stream:
		p.finished.connect(p.play)
		p.play()
	return p

# ---------------------------------------------------------------- aventura

func iniciar_aventura() -> void:
	if iniciada:
		return
	iniciada = true
	pop.play()
	var tw := create_tween()
	tw.tween_property(introducao, "modulate:a", 0.0, 0.5)
	tw.tween_callback(introducao.hide)
	controles_aventura.show()
	painel_legenda.show()
	atualizar_capitulo()
	narrador.falar(["cap_" + NOMES[etapa]])
	avancar_pendentes()

func atualizar_capitulo() -> void:
	for i in range(3):
		var animal: Node2D = animais[NOMES[i]]
		animal.em_destaque = i == etapa
		var vez := i == etapa
		create_tween().tween_property(animal, "modulate", Color.WHITE if (vez or i < etapa) else Color(0.72, 0.72, 0.8), 0.6)
		create_tween().tween_property(placas[i], "scale", Vector2(1.1, 1.1) if vez else Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
		var estilo: StyleBoxFlat = placas[i].get_theme_stylebox("panel")
		estilo.border_color = Color("#f2b632") if vez else (Color("#79c968") if i < etapa else Color("#dccb9e"))
	if etapa == 3:
		capitulo_label.text = "Fim: a floresta ganhou suas cores!"
		status.text = "Olho Mágico: missão cumprida. Vocês conseguiram!"
		return
	capitulo_label.text = "Capítulo %d de 3 · %s" % [etapa + 1, TITULOS[etapa]]
	status.text = "Olho Mágico: esperando o desenho do %s..." % ROTULOS[etapa].to_lower()

func avancar_pendentes() -> void:
	if not iniciada or animando:
		return
	animando = true
	espera.stop()
	while etapa < 3 and pendentes.has(NOMES[etapa]):
		var nome: String = NOMES[etapa]
		var cores: Array = pendentes[nome]
		pendentes.erase(nome)
		pintados[nome] = cores
		status.text = "Olho Mágico: achei o desenho! Lá vem a cor..."
		await transformar(nome, cores)
		etapa += 1
		aplicar_clima(etapa, 2.5)
		atualizar_capitulo()
		if etapa == 3:
			narrador.falar(["festa_leao", "final_1", "final_2"])
			grande_final()
		elif pendentes.has(NOMES[etapa]):
			narrador.falar(["festa_" + nome])
			await esperar_narrador(12.0)
		else:
			narrador.falar(["festa_" + nome, "cap_" + NOMES[etapa]])
	animando = false

func esperar_narrador(limite: float) -> void:
	var inicio := Time.get_ticks_msec()
	while narrador.falando and Time.get_ticks_msec() - inicio < limite * 1000.0:
		await get_tree().create_timer(0.2).timeout

## A Nublina solta a cor, ela voa até o amigo e explode nele.
func transformar(nome: String, cores_nomes: Array) -> void:
	narrador.parar()
	var cores: Array = []
	for c in cores_nomes:
		cores.append(Color(CORES[c]))
	var animal: Node2D = animais[nome]
	sopro.play()
	var origem: Vector2 = nublina.soltar_cor()
	await get_tree().create_timer(0.35).timeout
	await voar_cor(origem, animal.global_position + Vector2(0, -20), cores)
	magia.play()
	efeito.play()
	await animal.colorir(cores)
	var i := NOMES.find(nome)
	icones[i].texture = animal.cinza.texture
	var tw := create_tween()
	icones[i].pivot_offset = Vector2(27, 27)
	tw.tween_property(icones[i], "modulate", Color.WHITE, 0.2)
	tw.parallel().tween_property(icones[i], "scale", Vector2(1.4, 1.4), 0.2)
	tw.tween_property(icones[i], "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func voar_cor(origem: Vector2, destino: Vector2, cores: Array) -> void:
	var bola := Node2D.new()
	bola.position = origem
	add_child(bola)
	var luz := Sprite2D.new()
	luz.texture = Tex.brilho(64)
	luz.modulate = cores[0].lightened(0.2)
	luz.scale = Vector2.ONE * 1.3
	bola.add_child(luz)
	var rastro := CPUParticles2D.new()
	rastro.texture = Tex.brilho(16)
	rastro.amount = 90
	rastro.lifetime = 0.8
	rastro.local_coords = false
	rastro.spread = 180
	rastro.initial_velocity_min = 10
	rastro.initial_velocity_max = 50
	rastro.gravity = Vector2(0, 40)
	rastro.scale_amount_min = 0.6
	rastro.scale_amount_max = 1.4
	rastro.color_initial_ramp = Tex.gradiente(cores)
	var some := Gradient.new()
	some.set_color(0, Color(1, 1, 1, 1))
	some.set_color(1, Color(1, 1, 1, 0))
	rastro.color_ramp = some
	bola.add_child(rastro)
	var controle := (origem + destino) / 2.0 + Vector2(0, -180)
	var tw := create_tween()
	tw.tween_method(func(k: float):
		var a := origem.lerp(controle, k)
		var b := controle.lerp(destino, k)
		bola.position = a.lerp(b, k)
		luz.scale = Vector2.ONE * (1.3 + sin(k * PI) * 0.6)
	, 0.0, 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	rastro.emitting = false
	luz.hide()
	get_tree().create_timer(1.0).timeout.connect(bola.queue_free)

func grande_final() -> void:
	espera.stop()
	var tw := create_tween()
	tw.tween_property(arco, "progresso", 1.0, 3.5).set_delay(1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var confete := CPUParticles2D.new()
	confete.texture = Tex.confete()
	confete.amount = 160
	confete.lifetime = 5.0
	confete.position = Vector2(576, -20)
	confete.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confete.emission_rect_extents = Vector2(600, 10)
	confete.direction = Vector2(0, 1)
	confete.spread = 30
	confete.initial_velocity_min = 60
	confete.initial_velocity_max = 140
	confete.gravity = Vector2(10, 90)
	confete.angular_velocity_min = -400
	confete.angular_velocity_max = 400
	confete.scale_amount_min = 0.8
	confete.scale_amount_max = 1.6
	var cores: Array = []
	for c in ArcoIris.CORES:
		cores.append(Color(c))
	confete.color_initial_ramp = Tex.gradiente(cores)
	add_child(confete)
	confete.emitting = true
	get_tree().create_timer(7.0).timeout.connect(func(): confete.emitting = false)
	for i in range(3):
		animais[NOMES[i]].festejar(0.8 + i * 0.35)
		animais[NOMES[i]].em_destaque = false

# ---------------------------------------------------------------- leituras da câmera

func ler_pasta() -> void:
	var pasta := DirAccess.open(pasta_json)
	if pasta == null:
		status.text = "Olho Mágico: aguardando a pasta de leituras da câmera."
		return
	var arquivos: Array[String] = []
	for arquivo in pasta.get_files():
		if arquivo.get_extension().to_lower() == "json":
			arquivos.append(pasta_json.path_join(arquivo))
	arquivos.sort_custom(func(a: String, b: String):
		var tempo_a := FileAccess.get_modified_time(a)
		var tempo_b := FileAccess.get_modified_time(b)
		return a < b if tempo_a == tempo_b else tempo_a < tempo_b
	)
	for caminho in arquivos:
		var conteudo := FileAccess.get_file_as_string(caminho)
		if assinaturas.get(caminho, "") == conteudo:
			continue
		var json := JSON.new()
		if json.parse(conteudo.trim_prefix("\ufeff")) != OK:
			continue # Arquivo em gravação: tentar novamente no próximo ciclo.
		var dados: Variant = json.data
		if not dados is Dictionary:
			continue
		if dados.get("tipo", "") != "asas.leitura":
			continue
		var desenhos: Variant = dados.get("desenhos", [])
		if not desenhos is Array:
			continue
		assinaturas[caminho] = conteudo
		processar_animais(desenhos)

func processar_animais(desenhos: Array) -> void:
	for item in desenhos:
		if not item is Dictionary:
			continue
		var nome := str(item.get("nome", "")).strip_edges().to_lower().replace("ã", "a")
		if not nome in NOMES:
			continue
		var recebidas: Variant = item.get("cores", [])
		if not recebidas is Array:
			continue
		var cores: Array = []
		for recebida in recebidas:
			var cor := str(recebida).strip_edges().to_lower()
			if CORES.has(cor) and not cor in cores:
				cores.append(cor)
		if cores.is_empty():
			continue
		if pintados.has(nome):
			# Repintou um amigo que já tinha cor: nova explosão, mais rápida.
			if pintados[nome] != cores and not animais[nome].animando:
				pintados[nome] = cores
				var lista: Array = []
				for c in cores:
					lista.append(Color(CORES[c]))
				magia.play()
				animais[nome].colorir(lista, true)
		else:
			pendentes[nome] = cores
	avancar_pendentes()
