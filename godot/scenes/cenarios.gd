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
		"esconderijo": "moita", # um para todos ou um por animal
		"nuvem": [Vector2(1015, 100), Vector2(925, 94), Vector2(835, 90), Vector2(745, 86), Vector2(800, 72)],
		"nuvem_rosto": true,
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
	"lagoa": {
		"titulo": "Lagoa Cristalina",
		"titulo_intro": "A Lagoa Cristalina",
		"pronto": true,
		"fundo": "res://godot/assets/lagoa/lagoa.png",
		"nomes": ["sapo", "peixe_lagoa", "capivara", "cobra"],
		# Na leitura da câmera o peixe vem só como "peixe".
		"apelidos": {"peixe": "peixe_lagoa"},
		"rotulos": ["Sapo verde", "Peixe azul", "Capivara marrom", "Cobra amarela"],
		"pedidos": ["o sapo verde", "o peixe azul", "a capivara marrom", "a cobra amarela"],
		"cor_pedida": ["verde", "azul", "marrom", "amarelo"],
		"capitulos": ["O sapo atrás dos juncos", "O peixinho atrás da pedra", "A capivara com receio", "A cobra enroladinha"],
		"intro": ["lagoa_intro_1", "lagoa_intro_2", "lagoa_intro_3"],
		"final": ["lagoa_final_1", "lagoa_final_2"],
		"fim": "Fim: a Lagoa voltou a ser cristalina!",
		"ajudante": "pato",
		"posicao_ajudante": Vector2(1066, 318), # boiando na lagoa
		# Vegetação na superfície e pedras no fundo, como na história.
		"esconderijo": ["junco", "pedra", "junco", "pedra"],
		# A fumaça da fábrica cobre o sol, triste; a cada amigo ela se afasta e se alegra.
		"nuvem": [Vector2(872, 104), Vector2(930, 96), Vector2(985, 90), Vector2(1035, 82), Vector2(1060, 66)],
		"nuvem_rosto": true,
		"escala_nuvem": 1.3,
		"sol": Vector2(872, 104),
		"copas": 0.35,
		"lago": [Vector2(0.5, 0.63), Vector2(0.55, 0.15)],
		"arco": Vector2(576, 640),
	},
	"marinha": {
		"titulo": "Aventura Marinha",
		"titulo_intro": "A Aventura Marinha",
		"pronto": true,
		"fundo": "res://godot/assets/marinha/marinha.png",
		"nomes": ["baleia", "peixe_mar", "tartaruga", "boto"],
		"apelidos": {"peixe": "peixe_mar"},
		"rotulos": ["Baleia azul", "Peixe laranja", "Tartaruga verde", "Boto cor-de-rosa"],
		"pedidos": ["a baleia azul", "o peixe laranja", "a tartaruga verde", "o boto cor-de-rosa"],
		"cor_pedida": ["azul", "laranja", "verde", "rosa"],
		"capitulos": ["A baleia atrás da pedra", "O peixinho entre as algas", "A tartaruga tímida", "O boto sem brincadeira"],
		"intro": ["marinha_intro_1", "marinha_intro_2", "marinha_intro_3"],
		"final": ["marinha_final_1", "marinha_final_2"],
		"fim": "Fim: o mar voltou a ter todas as cores!",
		"ajudante": "polvo",
		"posicao_ajudante": Vector2(1086, 262), # em cima da pedra grande
		"esconderijo": ["pedra", "alga", "pedra", "alga"],
		# A mancha de poluição tapa a luz que entra pela superfície e vai embora aos poucos.
		"nuvem": [Vector2(862, 46), Vector2(925, 40), Vector2(985, 36), Vector2(1035, 30), Vector2(1080, 22)],
		"nuvem_rosto": true,
		"escala_nuvem": 1.4,
		"sol": Vector2(862, 14),
		"copas": 0.0,
		"agua": true, # bolhas em vez de folhas e tudo ondulando devagar
		"brilho": [0.58, 0.7, 0.82, 0.93, 1.04], # o mar começa bem escuro
		"lago": [Vector2(0.5, 0.5), Vector2(0.0, 0.0)],
		"arco": Vector2(576, 640),
	},
}

static func atual() -> Dictionary:
	return DADOS.get(escolhido, DADOS["floresta"])
