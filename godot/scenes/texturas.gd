extends RefCounted
## Texturas pequenas geradas em código (brilhos, folhas, estrelas, gotas, corações).

static var _cache: Dictionary = {}

static func svg(codigo: String, escala: float = 1.0) -> ImageTexture:
	var imagem := Image.new()
	if imagem.load_svg_from_string(codigo, escala) != OK:
		return null
	return ImageTexture.create_from_image(imagem)

static func _guardado(chave: String, codigo: String) -> Texture2D:
	if not _cache.has(chave):
		_cache[chave] = svg(codigo)
	return _cache[chave]

static func brilho(tamanho: int = 64) -> Texture2D:
	var chave := "brilho%d" % tamanho
	if not _cache.has(chave):
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = tamanho
		t.height = tamanho
		_cache[chave] = t
	return _cache[chave]

static func folha() -> Texture2D:
	return _guardado("folha", '<svg xmlns="http://www.w3.org/2000/svg" width="22" height="14" viewBox="0 0 22 14"><path fill="#ffffff" stroke="#00000055" stroke-width="1" d="M1 7 Q8 -1 21 7 Q8 15 1 7 Z"/><path fill="none" stroke="#00000044" stroke-width="1" d="M2 7 L19 7"/></svg>')

static func estrela() -> Texture2D:
	return _guardado("estrela", '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="#ffffff" d="M12 0 L14.6 9.4 L24 12 L14.6 14.6 L12 24 L9.4 14.6 L0 12 L9.4 9.4 Z"/></svg>')

static func gota() -> Texture2D:
	return _guardado("gota", '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="20" viewBox="0 0 14 20"><path fill="#9fd3f5" stroke="#4d7fa6" stroke-width="1.5" d="M7 1 Q1 11 2 14 Q4 19 7 19 Q10 19 12 14 Q13 11 7 1 Z"/><ellipse fill="#ffffff" cx="5" cy="13" rx="1.5" ry="2.2"/></svg>')

static func coracao() -> Texture2D:
	return _guardado("coracao", '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="22" viewBox="0 0 24 22"><path fill="#ff6f91" stroke="#302c35" stroke-width="1.5" d="M12 21 Q1 13 1.5 7 Q2 1 7 1.5 Q10 2 12 5.5 Q14 2 17 1.5 Q22 1 22.5 7 Q23 13 12 21 Z"/></svg>')

static func confete() -> Texture2D:
	return _guardado("confete", '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="6" viewBox="0 0 10 6"><rect fill="#ffffff" width="10" height="6" rx="1"/></svg>')

static func gradiente(cores: Array) -> Gradient:
	var g := Gradient.new()
	if cores.is_empty():
		return g
	g.set_color(0, cores[0])
	g.set_color(1, cores[-1])
	for i in range(1, cores.size() - 1):
		g.add_point(float(i) / (cores.size() - 1), cores[i])
	return g
