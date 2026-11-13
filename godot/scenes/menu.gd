extends Control
## Carrossel com os 4 cenários da especificação "A Magia das Cores".
## Setas (ou ← →) trocam o cenário. O professor escolhe o modo de pintura, que abre a aventura:
## "Cores predefinidas" (Enter ou P) ou "Cores livres" (L).
## Um cenário com "pronto": false aparece como "Em breve".
## Com aplica.exe -1 (ou -2, -3, -4) o carrossel mostra só aquela atividade (Cenarios.liberados).

const Cenarios := preload("res://godot/scenes/cenarios.gd")
const SHADER_DESBOTAR := preload("res://godot/shaders/desbotar.gdshader")
const AVENTURA := "res://godot/scenes/aventura.tscn"
const CARTAO := Vector2(400, 300)
const DISTANCIA := 390.0
const CENTRO := Vector2(576, 330)

var selecionado := 0
var lista: Array = [] # chaves dos cenários mostrados, na ordem do carrossel
var cartoes: Array[PanelContainer] = []
var pontos: Array[Panel] = []
var fundo: TextureRect
var fundo_material: ShaderMaterial
var jogar: HBoxContainer
var aviso: Label
var pop: AudioStreamPlayer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	lista = Cenarios.liberados()
	selecionado = maxi(lista.find(Cenarios.escolhido), 0)

	fundo = TextureRect.new()
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fundo_material = ShaderMaterial.new()
	fundo_material.shader = SHADER_DESBOTAR
	fundo_material.set_shader_parameter("saturacao", 0.55)
	fundo.material = fundo_material
	add_child(fundo)
	var veu := ColorRect.new()
	veu.color = Color(0.12, 0.08, 0.22, 0.45)
	veu.set_anchors_preset(Control.PRESET_FULL_RECT)
	veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veu)

	var titulo := rotulo("A Magia das Cores", 54, Color("#fff4c9"))
	titulo.position = Vector2(0, 26)
	titulo.size = Vector2(1152, 70)
	titulo.add_theme_color_override("font_outline_color", Color("#5b3f8c"))
	titulo.add_theme_constant_override("outline_size", 14)
	add_child(titulo)
	var sub := rotulo("Escolha um cenário para colorir", 22, Color.WHITE)
	sub.position = Vector2(0, 98)
	sub.size = Vector2(1152, 32)
	sub.add_theme_color_override("font_outline_color", Color("#302c35"))
	sub.add_theme_constant_override("outline_size", 6)
	add_child(sub)

	for i in lista.size():
		var cartao := montar_cartao(i)
		add_child(cartao)
		cartoes.append(cartao)

	for lado in [-1, 1]:
		var seta := botao("<" if lado < 0 else ">", Color("#7b5fc7"), 34)
		seta.custom_minimum_size = Vector2(64, 64)
		seta.position = Vector2(CENTRO.x + lado * 380 - 32, 540)
		seta.pressed.connect(mudar.bind(lado))
		seta.visible = lista.size() > 1
		add_child(seta)

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 12)
	linha.position = Vector2(CENTRO.x - (lista.size() * 22 - 12) / 2.0, 506)
	linha.visible = lista.size() > 1
	add_child(linha)
	for i in lista.size():
		var ponto := Panel.new()
		ponto.custom_minimum_size = Vector2(10, 10)
		linha.add_child(ponto)
		pontos.append(ponto)

	# Os dois modos de pintura no lugar do "Jogar!".
	jogar = HBoxContainer.new()
	jogar.add_theme_constant_override("separation", 24)
	jogar.position = Vector2(CENTRO.x - 312, 532)
	add_child(jogar)
	for livre in [false, true]:
		var modo := botao("Pintura com
cores livres" if livre else "Pintura com
cores predefinidas", Color("#e0569b") if livre else Color("#4caf50"), 22)
		modo.custom_minimum_size = Vector2(300, 76)
		modo.pivot_offset = Vector2(150, 38)
		modo.tooltip_text = "A criança escolhe as cores de cada animal." if livre else "A atividade diz qual cor usar em cada animal."
		modo.pressed.connect(abrir.bind(livre))
		jogar.add_child(modo)
		var pulsar := create_tween().set_loops()
		pulsar.tween_interval(0.6 if livre else 0.0) # um pulsa depois do outro
		pulsar.tween_property(modo, "scale", Vector2(1.05, 1.05), 0.6).set_trans(Tween.TRANS_SINE)
		pulsar.tween_property(modo, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
		pulsar.tween_interval(0.0 if livre else 0.6)
	aviso = rotulo("Este cenário chega em breve!", 22, Color("#fff4c9"))
	aviso.position = Vector2(0, 550)
	aviso.size = Vector2(1152, 40)
	aviso.add_theme_color_override("font_outline_color", Color("#302c35"))
	aviso.add_theme_constant_override("outline_size", 6)
	add_child(aviso)

	pop = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://godot/assets/audio/pop.wav"):
		pop.stream = load("res://godot/assets/audio/pop.wav")
	pop.volume_db = -10.0
	add_child(pop)
	arrumar(0.0)

func dados(i: int) -> Dictionary:
	return Cenarios.DADOS[lista[i]]

func montar_cartao(i: int) -> PanelContainer:
	var d := dados(i)
	var cartao := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#fff8e9")
	estilo.border_color = Color("#dccb9e")
	estilo.set_border_width_all(5)
	estilo.set_corner_radius_all(22)
	estilo.set_content_margin_all(12)
	estilo.shadow_color = Color(0, 0, 0, 0.3)
	estilo.shadow_size = 12
	estilo.shadow_offset = Vector2(0, 6)
	cartao.add_theme_stylebox_override("panel", estilo)
	cartao.size = CARTAO
	cartao.pivot_offset = CARTAO / 2.0
	cartao.gui_input.connect(_clique_cartao.bind(i))
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 8)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartao.add_child(coluna)
	var imagem_area := CARTAO - Vector2(24, 72)
	if d.get("pronto", false):
		var imagem := TextureRect.new()
		imagem.texture = load(d["fundo"])
		imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		imagem.custom_minimum_size = imagem_area
		imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coluna.add_child(imagem)
	else:
		var vazio := PanelContainer.new()
		var e := StyleBoxFlat.new()
		e.bg_color = Color(d["cor"])
		e.set_corner_radius_all(12)
		vazio.add_theme_stylebox_override("panel", e)
		vazio.custom_minimum_size = imagem_area
		vazio.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var breve := rotulo("Em breve", 34, Color.WHITE)
		breve.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
		breve.add_theme_constant_override("outline_size", 8)
		breve.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vazio.add_child(breve)
		coluna.add_child(vazio)
	var nome := rotulo("%d · %s" % [Cenarios.ORDEM.find(lista[i]) + 1, d["titulo"]], 26, Color("#5b3f8c"))
	coluna.add_child(nome)
	return cartao

func rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var label := Label.new()
	label.text = texto
	label.uppercase = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func botao(texto: String, cor: Color, tamanho: int) -> Button:
	var b := Button.new()
	b.text = texto.to_upper()
	b.add_theme_font_size_override("font_size", tamanho)
	b.focus_mode = Control.FOCUS_NONE # as setas do teclado ficam para o carrossel
	for estado in ["normal", "hover", "pressed", "focus"]:
		var e := StyleBoxFlat.new()
		e.bg_color = cor.lightened(0.12) if estado == "hover" else (cor.darkened(0.12) if estado == "pressed" else cor)
		e.set_corner_radius_all(18)
		e.set_content_margin_all(8)
		e.border_color = cor.darkened(0.3)
		e.border_width_bottom = 5
		b.add_theme_stylebox_override(estado, e)
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(estado, Color.WHITE)
	return b

## Coloca o cartão escolhido no meio, grande, e os vizinhos menores dos lados.
func arrumar(duracao: float) -> void:
	for i in cartoes.size():
		var d := i - selecionado
		var cartao := cartoes[i]
		var alvo_pos := CENTRO + Vector2(d * DISTANCIA, 0) - CARTAO / 2.0
		var alvo_escala := Vector2.ONE if d == 0 else Vector2.ONE * 0.66
		var alvo_cor := Color.WHITE if d == 0 else (Color(0.82, 0.82, 0.9, 0.85) if absi(d) == 1 else Color(1, 1, 1, 0))
		cartao.z_index = 2 if d == 0 else 1
		cartao.mouse_filter = Control.MOUSE_FILTER_STOP if absi(d) <= 1 else Control.MOUSE_FILTER_IGNORE
		var estilo: StyleBoxFlat = cartao.get_theme_stylebox("panel")
		estilo.border_color = Color("#f2b632") if d == 0 else Color("#dccb9e")
		if duracao <= 0.0:
			cartao.position = alvo_pos
			cartao.scale = alvo_escala
			cartao.modulate = alvo_cor
			continue
		var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(cartao, "position", alvo_pos, duracao)
		tw.tween_property(cartao, "scale", alvo_escala, duracao)
		tw.tween_property(cartao, "modulate", alvo_cor, duracao * 0.7)
	for i in pontos.size():
		var e := StyleBoxFlat.new()
		e.bg_color = Color("#f2b632") if i == selecionado else Color(1, 1, 1, 0.6)
		e.set_corner_radius_all(5)
		pontos[i].add_theme_stylebox_override("panel", e)
	var d := dados(selecionado)
	var pronto: bool = d.get("pronto", false)
	jogar.visible = pronto
	aviso.visible = not pronto
	if pronto:
		fundo.texture = load(d["fundo"])
		fundo.modulate.a = 0.0 if duracao > 0.0 else 1.0
		create_tween().tween_property(fundo, "modulate:a", 1.0, maxf(duracao, 0.01))

func mudar(passo: int) -> void:
	var novo := clampi(selecionado + passo, 0, cartoes.size() - 1)
	if novo == selecionado:
		return
	selecionado = novo
	pop.play()
	arrumar(0.45)

func _clique_cartao(evento: InputEvent, i: int) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		if i == selecionado:
			abrir(Cenarios.cores_livres)
		else:
			mudar(i - selecionado)

func abrir(livre: bool = false) -> void:
	if not dados(selecionado).get("pronto", false):
		return
	Cenarios.escolhido = lista[selecionado]
	Cenarios.cores_livres = livre
	get_tree().change_scene_to_file(AVENTURA)

func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	if not evento.keycode in [KEY_LEFT, KEY_RIGHT, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_P, KEY_L, KEY_1, KEY_2, KEY_3, KEY_4]:
		return
	get_viewport().set_input_as_handled() # antes de abrir: abrir() já tira o menu da árvore
	match evento.keycode:
		KEY_LEFT:
			mudar(-1)
		KEY_RIGHT:
			mudar(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_P:
			abrir(false)
		KEY_L:
			abrir(true)
		KEY_1, KEY_2, KEY_3, KEY_4:
			var alvo := lista.find(Cenarios.ORDEM[evento.keycode - KEY_1])
			if alvo >= 0:
				mudar(alvo - selecionado)
