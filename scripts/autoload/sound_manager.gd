extends Node
## Tiny procedural sound effects (generated WAV tones) — no audio assets needed,
## fully offline and web-export friendly. Honours GameState.sound_enabled.

var _players: Array = []
var _next := 0

func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func _tone(freq: float, duration: float, volume: float = 0.25) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / rate
		var env := 1.0 - float(i) / float(frames)
		var sample := int(sin(TAU * freq * t) * env * volume * 32767.0)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream

func play(kind: String) -> void:
	if not GameState.sound_enabled or _players.is_empty():
		return
	var freq := 440.0
	var duration := 0.08
	match kind:
		"click": freq = 600.0
		"generate": freq = 520.0
		"merge": freq = 780.0; duration = 0.16
		"craft": freq = 880.0; duration = 0.18
		"coin": freq = 990.0; duration = 0.12
		"error": freq = 180.0; duration = 0.14
		"levelup": freq = 1040.0; duration = 0.25
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _tone(freq, duration)
	player.play()
