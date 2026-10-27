extends Node2D

const JSON_PATH := "res://godot/dados_json/leitura.json"

@onready var tartaruga: Sprite2D = $Tartaruga
@onready var patinho: Sprite2D = $Patinho
@onready var macaco: Sprite2D = $Macaco
@onready var peixinho: Sprite2D = $Peixinho
@onready var status_label: Label = $Interface/Status
@onready var pontuacao_label: Label = $Interface/Pontuacao
@onready var missao_label: Label = $Interface/Missao

var pontos_equipe: int = 0

func _ready() -> void:
	missao_label.text = "Missão: A floresta precisa de 1 verde, 1 amarelo, 1 marrom e 1 azul."
	status_label.text = "Aguardando os tratadores mostrarem os animais ao Olho Mágico..."
	pontuacao_label.text = "Pontos da equipe: 0"
	
	ler_dados_json()

func ler_dados_json() -> void:
	if not FileAccess.file_exists(JSON_PATH):
		status_label.text = "Arquivo JSON de leitura não encontrado."
		return

	var file = FileAccess.open(JSON_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		var dados = json.get_data()
		processar_animais(dados.get("desenhos", []))
	else:
		status_label.text = "Erro ao ler o formato do JSON."

func processar_animais(desenhos: Array) -> void:
	var animais_coloridos = 0
	pontos_equipe = 0
	
	for item in desenhos:
		var nome = item.get("nome", "").to_lower()
		var cores = item.get("cores", [])
		var validado = item.get("validado", false)

		if not validado or cores.is_empty():
			continue

		# Pega a primeira cor válida que veio do JSON para pintar o animal
		var cor_str = cores[0] 
		var sprite_alvo: Sprite2D = null

		# Identifica qual nó do animal deve ser pintado
		match nome:
			"tartaruga":
				sprite_alvo = tartaruga
				if "verde" in cores: animais_coloridos += 1; pontos_equipe += 25
			"patinho":
				sprite_alvo = patinho
				if "amarelo" in cores: animais_coloridos += 1; pontos_equipe += 25
			"macaco":
				sprite_alvo = macaco
				if "marrom" in cores: animais_coloridos += 1; pontos_equipe += 25
			"peixinho":
				sprite_alvo = peixinho
				if "azul" in cores: animais_coloridos += 1; pontos_equipe += 25

		# Se achou o animal correspondente, pinta com base na cor do JSON
		if sprite_alvo != null:
			pintar_sprite(sprite_alvo, cor_str)

	# Bônus se as 4 cores da missão estiverem cobertas (+20 pts)
	if animais_coloridos >= 4:
		pontos_equipe += 20
		pontuacao_label.text = "Pontos da equipe: " + str(pontos_equipe)
		status_label.text = "Missão Concluída! A floresta inteira acordou em festa! 🎉"
	else:
		pontuacao_label.text = "Pontos da equipe: " + str(pontos_equipe)
		status_label.text = "Animais coloridos: " + str(animais_coloridos) + " de 4."

# Função auxiliar que aplica a cor no sprite do animal
func pintar_sprite(sprite_animal: Sprite2D, cor_str: String) -> void:
	var nova_cor = Color.WHITE
	
	match cor_str.to_lower():
		"amarelo":
			nova_cor = Color(1.0, 0.9, 0.2)
		"laranja":
			nova_cor = Color(1.0, 0.6, 0.1)
		"verde":
			nova_cor = Color(0.2, 0.8, 0.2)
		"azul":
			nova_cor = Color(0.2, 0.6, 1.0)
		"marrom":
			nova_cor = Color(0.6, 0.4, 0.2)
		"rosa":
			nova_cor = Color(1.0, 0.4, 0.7)

	sprite_animal.modulate = nova_cor
