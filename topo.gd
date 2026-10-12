extends Node2D

const Dados := preload("res://dados.gd")
const Textos := preload("res://textos.gd")
const Visual := preload("res://visual.gd")

const TEMPO_AVISO := 3.8
const MAX_AVISOS := 3
const RET_ENTENDI := Rect2(540, 600, 200, 48)

var principal
var avisos: Array = []
var particulas: Array = []
var licao := ""
var mouse := Vector2.ZERO


func avisar(texto_aviso: String, cor: Color, id_licao := "") -> void:
	for aviso in avisos:
		if aviso["texto"] == texto_aviso:
			aviso["tempo"] = 0.0
			return
	avisos.append({"texto": texto_aviso, "cor": cor, "tempo": 0.0, "licao": id_licao})
	if avisos.size() > MAX_AVISOS:
		avisos.pop_front()


func confete(origem: Vector2, quantidade: int) -> void:
	for i in quantidade:
		var cor: Color = Textos.CORES_AVATAR[i % Textos.CORES_AVATAR.size()]
		particulas.append({"pos": origem + Vector2(randf_range(-200, 200), randf_range(-10, 10)), "vel": Vector2(randf_range(-120, 120), randf_range(-260, -80)), "cor": cor, "vida": 0.0, "duracao": randf_range(1.2, 2.0), "giro": randf() * TAU})
	if particulas.size() > 400:
		particulas = particulas.slice(particulas.size() - 400)


func _process(delta: float) -> void:
	mouse = get_local_mouse_position()
	var segurar := avisos_retidos()
	for aviso in avisos:
		if not segurar:
			aviso["tempo"] += delta
	avisos = avisos.filter(func(a): return a["tempo"] < TEMPO_AVISO)
	for p in particulas:
		p["vida"] += delta
		p["vel"].y += 420.0 * delta
		p["pos"] += p["vel"] * delta
		p["giro"] += delta * 8.0
	particulas = particulas.filter(func(p): return p["vida"] < p["duracao"])
	queue_redraw()


func avisos_retidos() -> bool:
	if principal.tela != "operacao" or licao != "":
		return false
	var op = principal.operacao
	return not op.modal.is_empty() or op.fase == op.Fase.RELATORIO or op.fase == op.Fase.FIM


func base_avisos() -> Array:
	if licao != "" or principal.paineis.aberto():
		return [4.0, 1.0]
	if principal.tela == "operacao":
		if principal.operacao.pode_interagir():
			return [470.0, -1.0]
		return [4.0, 1.0]
	if principal.tela == "mundo":
		return [16.0, 1.0]
	return [672.0, -1.0]


func retangulo_aviso(indice: int) -> Rect2:
	var aviso: Dictionary = avisos[indice]
	var texto_completo: String = aviso["texto"] + ("  ·  toque para ler" if aviso["licao"] != "" and not "toque para ler" in aviso["texto"] else "")
	var largura := minf(1200.0, Visual.largura_texto(texto_completo, 14) + 44)
	var base := base_avisos()
	return Rect2(640 - largura / 2, base[0] + base[1] * indice * 40, largura, 34)


func _input(event: InputEvent) -> void:
	if licao != "":
		if event is InputEventMouseButton:
			var e := make_input_local(event) as InputEventMouseButton
			if e.pressed and e.button_index == MOUSE_BUTTON_LEFT and RET_ENTENDI.has_point(e.position):
				licao = ""
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER]:
				licao = ""
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not avisos_retidos():
		var e2 := make_input_local(event) as InputEventMouseButton
		for i in avisos.size():
			if retangulo_aviso(i).has_point(e2.position) and avisos[i]["licao"] != "":
				var id: String = avisos[i]["licao"]
				avisos.remove_at(i)
				principal.abrir_licao(id)
				get_viewport().set_input_as_handled()
				return


func _draw() -> void:
	if licao != "":
		desenhar_licao()
	for i in (0 if avisos_retidos() else avisos.size()):
		var aviso: Dictionary = avisos[i]
		var t: float = aviso["tempo"]
		var alfa := clampf(minf(t / 0.2, (TEMPO_AVISO - t) / 0.5), 0.0, 1.0)
		var r := retangulo_aviso(i)
		var cor: Color = aviso["cor"]
		Visual.caixa(self, r, Visual.com_alfa(Visual.CARTAO_CLARO, alfa), 17, Visual.com_alfa(cor, alfa), 1, int(8.0 * alfa * alfa))
		var texto: String = aviso["texto"]
		if aviso["licao"] != "":
			texto += "  ·  toque para ler"  if not "toque para ler" in texto else ""
		Visual.texto(self, Vector2(r.position.x, r.position.y + 22), texto, 14, Visual.com_alfa(Visual.TEXTO, alfa), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	for p in particulas:
		var alfa_p: float = 1.0 - p["vida"] / p["duracao"]
		var tamanho := Vector2(7, 4).rotated(p["giro"])
		var c: Vector2 = p["pos"]
		draw_colored_polygon(PackedVector2Array([c - tamanho, c + Vector2(-tamanho.y, tamanho.x), c + tamanho, c + Vector2(tamanho.y, -tamanho.x)]), Visual.com_alfa(p["cor"], alfa_p))


func desenhar_licao() -> void:
	if not Textos.LICOES.has(licao):
		licao = ""
		return
	var dados: Dictionary = Textos.LICOES[licao]
	draw_rect(Rect2(0, 0, 1280, 720), Visual.SOBREPOSICAO)
	var cartao := Rect2(220, 70, 840, 600)
	Visual.caixa(self, cartao, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	var x := cartao.position.x + 40
	var tem_icone := Dados.COMPONENTES.has(licao)
	if tem_icone:
		var cor: Color = Dados.COMPONENTES[licao]["cor"]
		Visual.caixa(self, Rect2(x, 104, 52, 52), Visual.com_alfa(cor, 0.16), 14)
		Visual.icone(self, licao, Vector2(x + 26, 130), cor, 1.4)
	elif Dados.TIPOS_REQ.has(licao):
		Visual.caixa(self, Rect2(x, 104, 52, 52), Visual.com_alfa(Dados.TIPOS_REQ[licao]["cor"], 0.16), 14)
		Visual.losango(self, Vector2(x + 26, 130), 14.0, Dados.TIPOS_REQ[licao]["cor"])
	var deslocamento := 70.0 if tem_icone or Dados.TIPOS_REQ.has(licao) else 0.0
	var cores_cat := {"Componente": Visual.DESTAQUE, "Conceito": Visual.HUMANO, "Ataque": Visual.PERIGO}
	Visual.texto(self, Vector2(x + deslocamento, 120), String(dados["categoria"]).to_upper(), 12, cores_cat.get(dados["categoria"], Visual.DESTAQUE))
	Visual.paragrafo(self, Vector2(x + deslocamento, 150), dados["titulo"], 26, Visual.TEXTO, 700 - deslocamento, 1.2, 2)
	var y := Visual.paragrafo(self, Vector2(x, 212), dados["texto"], 16, Visual.TEXTO, 760, 1.5, 12)
	var caixa_real := Rect2(x, y + 6, 760, 100)
	Visual.caixa(self, caixa_real, Visual.CARTAO_CLARO, 12)
	Visual.texto(self, caixa_real.position + Vector2(18, 28), "No mundo real", 13, Visual.CREDITOS)
	Visual.paragrafo(self, caixa_real.position + Vector2(18, 52), dados["mundo_real"], 14, Visual.TEXTO_SUAVE, 724, 1.45, 3)
	Visual.botao(self, RET_ENTENDI, "Entendi", Visual.PRINCIPAL, RET_ENTENDI.has_point(mouse), true, 17, true)
