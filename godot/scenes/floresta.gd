extends Node2D

# Pode ser substituída no Inspector ou por -- --pasta-json=C:/fotos.
@export_dir var pasta_json: String = "res://godot/dados_json"
const NOMES := ["cachorro", "dinossauro", "leao"]
const ROTULOS := ["Cachorrinho", "Dinossauro", "Leão"]
const CORES := {
	"bege": "#dec49a", "amarelo": "#ffe059", "laranja": "#ff993d",
	"verde": "#79c968", "azul": "#65b8ef", "marrom": "#a57753",
	"rosa": "#f49cbe", "roxo": "#ac86dc", "vermelho": "#ef6b65",
	"branco": "#ffffff", "preto": "#46434b", "cinza": "#aaaaaa"
}
const HISTORIA := "Hoje, o sol acordou e encontrou a Floresta dos Abraços toda sem cor! Durante a noite, uma nuvem distraída levou as cores para passear. Mas deixou um segredo: cada desenho pintado por vocês pode trazer a alegria de volta. Primeiro, vamos ajudar o cachorrinho; depois, o dinossauro; e, por último, o leão. Preparem os lápis: nossa aventura vai começar!"
const CAPITULOS := [
	"O cachorrinho Pipoca perdeu as cores e ficou quietinho perto da árvore. Ele quer brincar outra vez! Pinte o cachorro no papel com as cores que você escolher. Depois, mostre o desenho à câmera.",
	"Pipoca voltou a brincar e encontrou Dino, o dinossauro, escondido atrás das folhas. Até seu pescoço comprido ficou sem cor! Agora, pinte o dinossauro no papel e mostre à câmera para ajudar nosso amigo.",
	"Com seus passos alegres, Dino levou a turma até o leão Léo. O rei da floresta estava com vergonha da sua juba sem cor. Falta só ele! Pinte o leão no papel e mostre à câmera."
]
const FINAL := "Viva! Pipoca abanou o rabinho, Dino dançou entre as árvores e Léo soltou um rugido de alegria! A nuvem viu a festa e devolveu todas as cores à floresta. Vocês ajudaram cada amigo, um de cada vez. Juntos, fizeram o dia ficar mais bonito!"
var etapa: int = 0
var iniciada: bool = false
var pendentes: Dictionary = {}
var capitulo_label: Label
var musica: AudioStreamPlayer
var efeito: AudioStreamPlayer
var controles_aventura: HBoxContainer
var assinaturas: Dictionary = {}
var pintados: Dictionary = {}
var imagens: Dictionary = {}
var modelos: Dictionary = {}
var status: Label
var progresso: Label
var introducao: PanelContainer
var voz: String = ""

func _ready() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--pasta-json="):
			pasta_json = argumento.trim_prefix("--pasta-json=")
	montar_interface()
	preparar_audio()
	var vozes := DisplayServer.tts_get_voices_for_language("pt")
	if not vozes.is_empty():
		voz = vozes[0]
		narrar(HISTORIA)
	var timer := Timer.new()
	timer.wait_time = 0.75
	timer.timeout.connect(ler_pasta)
	add_child(timer)
	timer.start()
	ler_pasta()

func narrar(texto: String) -> void:
	if not voz.is_empty():
		DisplayServer.tts_stop()
		DisplayServer.tts_speak(texto, voz, 90, 1.0, 0.9)

func rotulo(texto: String, tamanho: int = 24) -> Label:
	var label := Label.new()
	label.text = texto
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", Color("#302c35"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func painel() -> PanelContainer:
	var caixa := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#fff8e9")
	estilo.border_color = Color("#dccb9e")
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(16)
	estilo.content_margin_left = 16
	estilo.content_margin_right = 16
	estilo.content_margin_top = 8
	estilo.content_margin_bottom = 8
	caixa.add_theme_stylebox_override("panel", estilo)
	return caixa

func montar_interface() -> void:
	var tela := CanvasLayer.new()
	add_child(tela)
	var topo := painel()
	topo.position = Vector2(35, 20)
	topo.size = Vector2(1080, 110)
	tela.add_child(topo)
	var textos := VBoxContainer.new()
	topo.add_child(textos)
	textos.add_child(rotulo("Zoo das Cores", 32))
	capitulo_label = rotulo("Uma aventura para devolver as cores à floresta", 20)
	textos.add_child(capitulo_label)
	progresso = rotulo("Amigos coloridos: 0 de 3", 20)
	textos.add_child(progresso)
	for i in range(3):
		var nome: String = NOMES[i]
		modelos[nome] = FileAccess.get_file_as_string("res://godot/assets/animais/" + nome + ".svg")
		var imagem := Sprite2D.new()
		imagem.position = Vector2(220 + 355 * i, 367)
		add_child(imagem)
		imagens[nome] = imagem
		aplicar_cores(nome, [])
		var placa := painel()
		placa.position = Vector2(90 + 355 * i, 520)
		placa.size = Vector2(260, 48)
		tela.add_child(placa)
		var nome_label := rotulo(ROTULOS[i])
		nome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placa.add_child(nome_label)
	var rodape := painel()
	rodape.position = Vector2(35, 585)
	rodape.size = Vector2(1080, 50)
	tela.add_child(rodape)
	status = rotulo("Escolha um amigo para pintar. O Olho Mágico está esperando!", 21)
	rodape.add_child(status)
	introducao = painel()
	introducao.position = Vector2(200, 165)
	introducao.size = Vector2(750, 390)
	tela.add_child(introducao)
	var margem := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 24)
	introducao.add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 18)
	margem.add_child(coluna)
	coluna.add_child(rotulo("A floresta que perdeu as cores", 30))
	coluna.add_child(rotulo(HISTORIA))
	var repetir := Button.new()
	repetir.text = "Ouvir a história"
	repetir.pressed.connect(func(): narrar(HISTORIA))
	coluna.add_child(repetir)
	var comecar := Button.new()
	comecar.text = "Vamos pintar!"
	comecar.pressed.connect(iniciar_aventura)
	coluna.add_child(comecar)
	var controles := HBoxContainer.new()
	controles_aventura = controles
	controles.hide()
	controles.position = Vector2(720, 175)
	tela.add_child(controles)
	var ouvir := Button.new()
	ouvir.text = "Ouvir novamente"
	ouvir.pressed.connect(func():
		narrar(HISTORIA if not iniciada else (FINAL if etapa == 3 else CAPITULOS[etapa]))
	)
	controles.add_child(ouvir)
	var som := Button.new()
	som.text = "Música: ligada"
	som.pressed.connect(func():
		musica.stream_paused = not musica.stream_paused
		som.text = "Música: pausada" if musica.stream_paused else "Música: ligada"
	)
	controles.add_child(som)

func aplicar_cores(nome: String, cores: Array) -> void:
	var svg: String = modelos[nome]
	var regioes := ["#ffffff", "#eeeeee", "#dddddd"]
	for i in range(3):
		var cor: String = "#eeeeee" if cores.is_empty() else CORES[cores[i % cores.size()]]
		# Marcadores evitam que uma substituição afete outra região.
		svg = svg.replace(regioes[i], "REGIAO_%d" % i)
		svg = svg.replace("REGIAO_%d" % i, cor.to_upper())
	var bitmap := Image.new()
	if bitmap.load_svg_from_string(svg) == OK:
		imagens[nome].texture = ImageTexture.create_from_image(bitmap)

func ler_pasta() -> void:
	var pasta := DirAccess.open(pasta_json)
	if pasta == null:
		status.text = "Aguardando a pasta de leituras da câmera."
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

func preparar_audio() -> void:
	musica = AudioStreamPlayer.new()
	musica.stream = load("res://godot/assets/audio/floresta.wav")
	musica.volume_db = -24.0
	add_child(musica)
	musica.finished.connect(func(): musica.play())
	musica.play()
	efeito = AudioStreamPlayer.new()
	efeito.stream = load("res://godot/assets/audio/cores.wav")
	efeito.volume_db = -14.0
	add_child(efeito)

func iniciar_aventura() -> void:
	introducao.hide()
	controles_aventura.show()
	iniciada = true
	atualizar_capitulo()
	avancar_pendentes()

func atualizar_capitulo() -> void:
	progresso.text = "Amigos coloridos: %d de 3" % etapa
	if etapa == 3:
		capitulo_label.text = "A floresta ganhou suas cores! Vocês conseguiram juntos!"
		status.text = "Pipoca, Dino e Léo agradecem! A floresta está em festa!"
		narrar(FINAL)
		return
	capitulo_label.text = "%d. %s — %s" % [etapa + 1, ROTULOS[etapa], CAPITULOS[etapa]]
	status.text = "Sua vez: pinte o %s e mostre à câmera." % ROTULOS[etapa].to_lower()
	for i in range(3):
		imagens[NOMES[i]].modulate = Color.WHITE if i <= etapa else Color(0.75, 0.75, 0.75, 0.65)
	narrar(CAPITULOS[etapa])

func avancar_pendentes() -> void:
	if not iniciada:
		return
	var mudou := false
	while etapa < 3 and pendentes.has(NOMES[etapa]):
		var nome: String = NOMES[etapa]
		pintados[nome] = pendentes[nome]
		aplicar_cores(nome, pintados[nome])
		pendentes.erase(nome)
		var animacao := create_tween()
		animacao.tween_property(imagens[nome], "scale", Vector2(1.12, 1.12), 0.22)
		animacao.tween_property(imagens[nome], "scale", Vector2.ONE, 0.25)
		etapa += 1
		mudou = true
	if mudou:
		efeito.play()
		atualizar_capitulo()

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
			if pintados[nome] != cores:
				pintados[nome] = cores
				aplicar_cores(nome, cores)
		else:
			pendentes[nome] = cores
	avancar_pendentes()
