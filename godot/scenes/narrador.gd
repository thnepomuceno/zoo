extends Node
## Narrador: toca as falas gravadas (voz neural) em fila, emitindo a legenda de cada uma.
## Sem o .mp3, usa a voz portuguesa do sistema; sem voz nenhuma, só mostra a legenda.
## Frases livres (como os nomes que as crianças escreveram) entram na fila com FRASE na frente.
## Elas são geradas na hora com a mesma voz neural (tools/falar_frase.py, precisa de Python,
## edge-tts e internet); se não der, saem pela voz do sistema.

signal legenda(chave: String, texto: String)
signal terminou

const PASTA := "res://godot/assets/narracao/"
const VELOCIDADE_SISTEMA := 1.15
const FRASE := "="

var textos: Dictionary = {}
## Com cores livres, usa a fala "<chave>_livre" quando ela existe (sem dizer a cor do animal).
var cores_livres := false
var fila: Array[String] = []
var falando := false
var player: AudioStreamPlayer
var voz_sistema := ""
var musica: AudioStreamPlayer
var volume_musica := -22.0
var _id_fala := 0
var _espera: SceneTreeTimer

const SCRIPT_FRASE := "res://tools/falar_frase.py"
const PASTA_FRASES := "user://frases/"
const ESPERA_FRASE := 8.0 # segundos que a fila espera uma frase ainda sendo gerada
var _frases: Dictionary = {} # frase -> caminho do .mp3 gerado
var _gerando: Dictionary = {} # frase -> id da tarefa
var _sem_neural := false

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

## A fala que vai ser usada no lugar de `chave` no modo atual.
func versao(chave: String) -> String:
	if cores_livres and textos.has(chave + "_livre"):
		return chave + "_livre"
	return chave

func texto(chave: String) -> String:
	if chave.begins_with(FRASE):
		return chave.trim_prefix(FRASE)
	return str(textos.get(chave, ""))

func falar(chaves: Array, interromper: bool = true) -> void:
	if interromper:
		parar()
	for c in chaves:
		fila.append(versao(str(c)))
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
	if chave.begins_with(FRASE) and _gerando.has(frase):
		# A frase ainda está sendo gerada: espera um pouco, sem travar a tela.
		var id := _id_fala
		var limite := Time.get_ticks_msec() + int(ESPERA_FRASE * 1000)
		while _gerando.has(frase) and Time.get_ticks_msec() < limite:
			await get_tree().process_frame
			if id != _id_fala:
				return
	if not chave.begins_with(FRASE) and ResourceLoader.exists(caminho):
		player.stream = load(caminho)
		player.play()
	elif chave.begins_with(FRASE) and _frases.has(frase):
		player.stream = AudioStreamMP3.load_from_file(_frases[frase])
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

# ---------------------------------------------------------------- frases livres com voz neural

## Começa a gerar, em segundo plano, o áudio de uma frase livre com a voz da narração.
func preparar_frase(frase: String) -> void:
	if _sem_neural or _frases.has(frase) or _gerando.has(frase):
		return
	var script := ProjectSettings.globalize_path(SCRIPT_FRASE)
	if not FileAccess.file_exists(script):
		_sem_neural = true # jogo exportado, sem a pasta tools
		return
	DirAccess.make_dir_recursive_absolute(PASTA_FRASES)
	var destino := ProjectSettings.globalize_path(PASTA_FRASES + frase.md5_text() + ".mp3")
	if FileAccess.file_exists(destino):
		_frases[frase] = destino
		return
	_gerando[frase] = WorkerThreadPool.add_task(func():
		var ok := false
		for python in ["python", "py"]:
			if OS.execute(python, [script, frase, destino]) == 0 and FileAccess.file_exists(destino):
				ok = true
				break
		_frase_pronta.call_deferred(frase, destino, ok)
	)

func _frase_pronta(frase: String, destino: String, ok: bool) -> void:
	WorkerThreadPool.wait_for_task_completion(_gerando[frase])
	_gerando.erase(frase)
	if ok:
		_frases[frase] = destino
	else:
		_sem_neural = true # sem internet/Python: daqui em diante, direto na voz do sistema

func _exit_tree() -> void:
	for tarefa in _gerando.values():
		WorkerThreadPool.wait_for_task_completion(tarefa)
