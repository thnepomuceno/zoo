extends RefCounted
## Texturas pequenas geradas em código (brilhos, folhas, estrelas, gotas, corações, esconderijos).

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

## Esconderijo pelo nome usado em cenarios.gd.
static func esconderijo(tipo: String) -> Texture2D:
	match tipo:
		"feno":
			return feno()
		"pedra":
			return pedra()
		"junco":
			return junco()
		"alga":
			return alga()
	return moita()

## Pedra com musgo (fundo da lagoa e do mar), do mesmo tamanho da moita.
static func pedra() -> Texture2D:
	return _guardado("pedra", '<svg xmlns="http://www.w3.org/2000/svg" width="280" height="156" viewBox="0 0 280 156"><g stroke="#302c35" stroke-width="7" stroke-linejoin="round" stroke-linecap="round"><path fill="#9a98a8" d="M12 150 Q2 100 34 74 Q52 24 116 18 Q168 8 206 34 Q254 48 266 100 Q274 136 268 150 Z"/><ellipse fill="#8a8898" cx="238" cy="138" rx="34" ry="16"/><ellipse fill="#8a8898" cx="34" cy="142" rx="26" ry="12"/></g><path fill="#bab8c6" d="M46 78 Q66 38 116 32 Q148 28 168 40 Q120 46 92 64 Q68 80 46 78 Z"/><path fill="#86c46a" stroke="#302c35" stroke-width="4" stroke-linejoin="round" d="M80 36 Q118 10 172 24 Q202 30 214 46 Q184 40 162 50 Q132 40 108 54 Q90 54 80 36 Z"/><path fill="none" stroke="#6f6d7e" stroke-width="4" stroke-linecap="round" d="M196 76 q-14 18 -6 38 M66 108 q20 -8 32 6 M150 96 q10 10 4 22"/></svg>')

## Moita de juncos e taboas na beira da lagoa.
static func junco() -> Texture2D:
	var hastes := ""
	for h in [[52, 4], [92, 0], [150, 2], [204, 6], [236, 14]]:
		hastes += '<path fill="none" stroke="#3f8a3a" stroke-width="5" d="M%d 90 Q%d 50 %d %d"/><rect fill="#a0703f" stroke="#302c35" stroke-width="3" x="%d" y="%d" width="12" height="30" rx="6"/>' % [h[0], h[0] - 4, h[0] + 2, h[1] + 30, h[0] - 4, h[1]]
	var folhas := ""
	for f in [[28, 40, 1], [74, 22, -1], [118, 30, 1], [170, 20, -1], [222, 36, 1], [254, 52, -1]]:
		folhas += '<path fill="#86cf6a" stroke="#302c35" stroke-width="4" stroke-linejoin="round" d="M%d 150 Q%d %d %d %d Q%d %d %d 150 Z"/>' % [f[0] - 10, f[0] + f[2] * 4, 90, f[0] + f[2] * 22, f[1], f[0] + f[2] * 6, 96, f[0] + 10]
	return _guardado("junco", '<svg xmlns="http://www.w3.org/2000/svg" width="280" height="156" viewBox="0 0 280 156">%s<g stroke="#302c35" stroke-width="7" stroke-linejoin="round"><path fill="#5fae4f" d="M10 150 Q6 112 28 98 Q30 62 58 70 Q68 34 96 54 Q112 22 138 46 Q158 18 180 48 Q204 30 218 64 Q248 58 250 94 Q274 106 270 150 Z"/></g>%s<g fill="#ffffff" stroke="#302c35" stroke-width="2"><circle cx="64" cy="112" r="6"/><circle cx="196" cy="118" r="6"/></g><g fill="#ffd34d"><circle cx="64" cy="112" r="2.5"/><circle cx="196" cy="118" r="2.5"/></g></svg>' % [hastes, folhas])

## Algas balançando em cima de uma pedrinha, com um coral rosa (fundo do mar).
static func alga() -> Texture2D:
	return _guardado("alga", '<svg xmlns="http://www.w3.org/2000/svg" width="280" height="156" viewBox="0 0 280 156"><g stroke="#302c35" stroke-width="7" stroke-linejoin="round" stroke-linecap="round"><path fill="#4fa86a" d="M18 150 Q8 104 32 84 Q20 44 52 30 Q58 60 74 58 Q78 16 106 6 Q112 44 128 44 Q144 6 170 14 Q166 50 184 52 Q204 18 232 30 Q218 70 240 80 Q270 100 262 150 Z"/><path fill="none" stroke="#f27f9b" stroke-width="12" d="M214 132 L214 92 M214 104 L196 80 M214 98 L234 74 M196 80 L188 62 M234 74 L244 58"/><path fill="#8f8da0" d="M8 150 Q14 120 62 118 Q140 106 206 120 Q264 122 272 150 Z"/></g><path fill="none" stroke="#f9a7bb" stroke-width="6" stroke-linecap="round" d="M214 132 L214 92 M214 104 L196 80 M214 98 L234 74 M196 80 L188 62 M234 74 L244 58"/><path fill="none" stroke="#7fd08a" stroke-width="5" stroke-linecap="round" d="M52 112 Q40 76 58 44 M104 110 Q96 60 110 22 M150 110 Q158 64 166 28 M188 104 Q200 72 224 40"/><path fill="#a9a7b8" d="M40 132 Q80 120 130 124 Q90 128 40 138 Z"/></svg>')

static func bolha() -> Texture2D:
	return _guardado("bolha", '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18"><circle fill="#ffffff" fill-opacity="0.25" stroke="#ffffff" stroke-width="1.6" cx="9" cy="9" r="7.5"/><ellipse fill="#ffffff" cx="6" cy="6" rx="2.2" ry="1.5"/></svg>')

static func gradiente(cores: Array) -> Gradient:
	var g := Gradient.new()
	if cores.is_empty():
		return g
	g.set_color(0, cores[0])
	g.set_color(1, cores[-1])
	for i in range(1, cores.size() - 1):
		g.add_point(float(i) / (cores.size() - 1), cores[i])
	return g
