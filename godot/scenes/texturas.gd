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

## Moita onde os animais se escondem (contorno só por fora, como nos cartões).
static func moita() -> Texture2D:
	var bolas := [[52, 104, 44], [104, 74, 54], [166, 70, 58], [222, 100, 48], [140, 108, 50], [28, 126, 28], [252, 128, 26]]
	var contorno := ""
	var miolo := ""
	for b in bolas:
		contorno += '<circle cx="%d" cy="%d" r="%d"/>' % b
		miolo += '<circle cx="%d" cy="%d" r="%d"/>' % b
	var base := '<rect x="10" y="112" width="260" height="38" rx="14"/>'
	var brilhos := ""
	for b in [[92, 58, 20, 11], [160, 50, 22, 12], [215, 86, 16, 9], [48, 92, 14, 8]]:
		brilhos += '<ellipse cx="%d" cy="%d" rx="%d" ry="%d"/>' % b
	var flores := ""
	for f in [[70, 96, "#f49cbe"], [128, 64, "#ffe059"], [196, 84, "#ef6b65"], [236, 116, "#f49cbe"], [36, 124, "#ffe059"], [158, 116, "#ac86dc"]]:
		flores += '<g transform="translate(%d %d)"><circle fill="%s" stroke="#302c35" stroke-width="2" cx="0" cy="-5" r="5"/><circle fill="%s" stroke="#302c35" stroke-width="2" cx="5" cy="1" r="5"/><circle fill="%s" stroke="#302c35" stroke-width="2" cx="-5" cy="1" r="5"/><circle fill="#ffd34d" cx="0" cy="-1" r="3"/></g>' % [f[0], f[1], f[2], f[2], f[2]]
	return _guardado("moita", '<svg xmlns="http://www.w3.org/2000/svg" width="280" height="156" viewBox="0 0 280 156"><g fill="#302c35" stroke="#302c35" stroke-width="7">%s%s</g><g fill="#74c661">%s%s</g><g fill="#a6e487" opacity="0.85">%s</g>%s</svg>' % [contorno, base, miolo, base, brilhos, flores])

## Fardo de feno onde os animais da fazenda se escondem (mesmo tamanho da moita).
static func feno() -> Texture2D:
	# Contorno ondulado (palha despenteada) em vez de uma caixa reta.
	var borda := "M30 150 L22 60 Q14 34 34 30 "
	for x in range(46, 250, 16):
		borda += "Q%d %d %d %d " % [x - 4, 14 if (x / 16) % 2 == 0 else 22, x + 8, 28]
	borda += "Q266 34 258 60 L250 150 Z"
	var palha := ""
	for i in range(40):
		var x := 34 + (i * 53) % 214
		var y := 44 + (i * 37) % 96
		palha += "M%d %d q%d %d %d %d " % [x, y, 9, -3 + (i % 3) * 3, 18, (i % 5) - 2]
	return _guardado("feno", '<svg xmlns="http://www.w3.org/2000/svg" width="280" height="156" viewBox="0 0 280 156"><g stroke="#302c35" stroke-width="7" stroke-linejoin="round" stroke-linecap="round"><path fill="#f0c95a" d="%s"/></g><path fill="#f8dd84" opacity="0.9" d="M40 40 Q140 30 240 40 L238 62 Q140 52 42 62 Z"/><path fill="none" stroke="#c99a2e" stroke-width="3" stroke-linecap="round" d="%s"/><path fill="#d9a93c" opacity="0.55" d="M30 120 Q140 132 250 120 L250 146 L30 146 Z"/><g stroke="#302c35" stroke-width="4"><path fill="#b5572c" d="M86 26 Q92 90 88 150 L102 150 Q106 90 100 24 Z M178 24 Q172 90 176 150 L190 150 Q194 90 192 26 Z"/></g></svg>' % [borda, palha])

static func gradiente(cores: Array) -> Gradient:
	var g := Gradient.new()
	if cores.is_empty():
		return g
	g.set_color(0, cores[0])
	g.set_color(1, cores[-1])
	for i in range(1, cores.size() - 1):
		g.add_point(float(i) / (cores.size() - 1), cores[i])
	return g
