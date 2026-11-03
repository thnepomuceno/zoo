extends Node2D
## Arco-íris que nasce da esquerda para a direita no final da aventura.

const CORES := ["#ef6b65", "#ff993d", "#ffe059", "#79c968", "#65b8ef", "#7f8be0", "#ac86dc"]

var progresso := 0.0:
	set(v):
		progresso = v
		queue_redraw()
var raio := 560.0
var largura := 20.0

func _draw() -> void:
	if progresso <= 0.0:
		return
	var fim := PI + PI * clampf(progresso, 0.0, 1.0)
	for i in CORES.size():
		var cor := Color(CORES[i])
		cor.a = 0.55
		draw_arc(Vector2.ZERO, raio - i * largura, PI, fim, 96, cor, largura + 1.0, true)
