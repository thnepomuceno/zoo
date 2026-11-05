extends RefCounted
## Os cenários de "A Magia das Cores" (especificação, carrossel com 4 opções).
## A aventura lê daqui a história, os animais, o ajudante e o jeito do fundo.

## Cenário escolhido no carrossel (ou por -- --cenario=fazenda).
static var escolhido := "floresta"

const ORDEM := ["floresta", "fazenda", "lagoa", "marinha"]

const DADOS := {
	"floresta": {
		"titulo": "Floresta Encantada",
		"titulo_intro": "A Floresta Encantada",
		"pronto": true,
		"fundo": "res://godot/assets/floresta/901cc787-2e1c-4038-8e52-4f627eb3e6dc.jpg",
		"nomes": ["onca", "macaco", "tamandua", "borboleta"],
		"rotulos": ["Onça amarela", "Macaco marrom", "Tamanduá preto", "Borboleta vermelha"],
		"pedidos": ["a onça amarela", "o macaco marrom", "o tamanduá preto", "a borboleta vermelha"],
		"cor_pedida": ["amarelo", "marrom", "preto", "vermelho"],
		"capitulos": ["A onça tremendo na moita", "O macaco sem coragem", "O tamanduá tímido", "A borboleta que não voa"],
		"intro": ["intro_1", "intro_2", "intro_3"],
		"final": ["final_1", "final_2"],
		"fim": "Fim: a Floresta Encantada voltou a ser colorida!",
		"ajudante": "coruja",
		"posicao_ajudante": Vector2(1080, 268),
		"esconderijo": "moita",
		"nuvem": [Vector2(1015, 100), Vector2(925, 94), Vector2(835, 90), Vector2(745, 86), Vector2(800, 72)],
		"escala_nuvem": 1.0,
		"sol": Vector2.ZERO, # o sol da floresta fica fora do quadro
		# Shader do fundo: quanto as copas balançam e onde fica o lago.
		"copas": 1.0,
		"lago": [Vector2(0.83, 0.835), Vector2(0.13, 0.055)],
		"arco": Vector2(576, 640),
	},
	"fazenda": {
		"titulo": "Fazenda Feliz",
		"titulo_intro": "A Fazenda Feliz",
		"pronto": true,
		"fundo": "res://godot/assets/fazenda/fazenda.png",
		"nomes": ["cavalo", "porco", "pato", "galinha"],
		"rotulos": ["Cavalo marrom", "Porco rosa", "Pato amarelo", "Galinha laranja"],
		"pedidos": ["o cavalo marrom", "o porco rosa", "o pato amarelo", "a galinha laranja"],
		"cor_pedida": ["marrom", "rosa", "amarelo", "laranja"],
		"capitulos": ["O cavalo atrás do feno", "O porquinho sem coragem", "O pato com saudade da lagoa", "A galinha encolhidinha"],
		"intro": ["fazenda_intro_1", "fazenda_intro_2", "fazenda_intro_3"],
		"final": ["fazenda_final_1", "fazenda_final_2"],
		"fim": "Fim: a Fazenda Feliz voltou a ter cor!",
		"ajudante": "galo",
		"posicao_ajudante": Vector2(1101, 252), # em cima do último mourão da cerca
		"esconderijo": "feno",
		# A nuvem da tempestade começa bem em cima do sol, triste, e vai se afastando e
		# se alegrando; no final fica no canto do céu, sorrindo.
		"nuvem": [Vector2(862, 112), Vector2(925, 104), Vector2(985, 96), Vector2(1035, 86), Vector2(1052, 70)],
		"nuvem_rosto": true,
		"escala_nuvem": 1.35,
		"sol": Vector2(858, 110),
		"copas": 0.0, # o celeiro não pode balançar
		"lago": [Vector2(0.8, 0.885), Vector2(0.165, 0.08)],
		"arco": Vector2(576, 640),
	},
	"lagoa": {"titulo": "Lagoa Cristalina", "pronto": false, "cor": "#5fb8d9"},
	"marinha": {"titulo": "Aventura Marinha", "pronto": false, "cor": "#2f6fae"},
}

static func atual() -> Dictionary:
	return DADOS.get(escolhido, DADOS["floresta"])
