extends Node
## Narrador: toca as falas gravadas (voz neural) em fila, emitindo a legenda de cada uma.
## Sem o .mp3, usa a voz portuguesa do sistema; sem voz nenhuma, só mostra a legenda.
## Frases livres (como os nomes que as crianças escreveram) entram na fila com FRASE na frente
## e são sempre faladas pela voz do sistema.

signal legenda(chave: String, texto: String)
signal terminou

const PASTA := "res://godot/assets/narracao/"
const VELOCIDADE_SISTEMA := 1.15
const FRASE := "="

var textos: Dictionary = {}
var fila: Array[String] = []
var falando := false
var player: AudioStreamPlayer
var voz_sistema := ""
var musica: AudioStreamPlayer
var volume_musica := -22.0
var _id_fala := 0
var _espera: SceneTreeTimer

func _ready() -> void:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(PASTA + "roteiro.json")) == OK:
		textos = json.data
	player = AudioStreamPlayer.new()
	player.volume_db = 2.0
	add_child(player)
	player.finished.connect(_proxima)
	voz_sistema = _melhor_voz()
	if not voz_sistema.is_empty():
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _tts_acabou)

## Escolhe a voz do sistema mais agradável: neural/natural > feminina pt-BR > qualquer pt.
func _melhor_voz() -> String:
	var melhor := ""
	var nota_melhor := -1
	for v in DisplayServer.tts_get_voices():
		var idioma := str(v.get("language", "")).to_lower()
		if not idioma.begins_with("pt"):
			continue
		var n := str(v.get("name", ""))
		var nota := 1
		if idioma.contains("br"):
			nota += 4
		for preferida in ["Natural", "Neural", "Online", "Francisca", "Thalita", "Maria"]:
			if n.contains(preferida):
				nota += 3
		if nota > nota_melhor:
			nota_melhor = nota
			melhor = str(v.get("id", ""))
	return melhor

func texto(chave: String) -> String:
	if chave.begins_with(FRASE):
		return chave.trim_prefix(FRASE)
	return str(textos.get(chave, ""))

func falar(chaves: Array, interromper: bool = true) -> void:
	if interromper:
		parar()
	for c in chaves:
		fila.append(str(c))
	if not falando:
		_proxima()

func parar() -> void:
	fila.clear()
	player.stop()
	if not voz_sistema.is_empty():
		DisplayServer.tts_stop()
	_id_fala += 1
	falando = false
	_abaixar_musica(false)

func _proxima() -> void:
	if fila.is_empty():
		falando = false
		_abaixar_musica(false)
		terminou.emit()
		return
	falando = true
	_abaixar_musica(true)
	var chave: String = fila.pop_front()
	var frase := texto(chave)
	legenda.emit(chave, frase)
	_id_fala += 1
	var caminho := PASTA + chave + ".mp3"
	if not chave.begins_with(FRASE) and ResourceLoader.exists(caminho):
		player.stream = load(caminho)
		player.play()
	elif not voz_sistema.is_empty():
		DisplayServer.tts_speak(frase, voz_sistema, 90, 1.05, VELOCIDADE_SISTEMA, _id_fala)
	else:
		# Sem voz: dá tempo de ler a legenda.
		var id := _id_fala
		await get_tree().create_timer(2.0 + frase.length() * 0.06).timeout
		if id == _id_fala and falando:
			_proxima()

func _tts_acabou(id: int) -> void:
	if id == _id_fala and falando:
		_proxima.call_deferred()

func _abaixar_musica(abaixar: bool) -> void:
	if musica:
		create_tween().tween_property(musica, "volume_db", volume_musica - (9.0 if abaixar else 0.0), 0.4)
