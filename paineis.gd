extends Node2D

const Dados := preload("res://dados.gd")
const Textos := preload("res://textos.gd")
const Visual := preload("res://visual.gd")
const Estado := preload("res://estado.gd")
const EditorAvatar := preload("res://editor_avatar.gd")

const CARTAO := Rect2(80, 44, 1120, 632)
const RET_FECHAR := Rect2(1146, 60, 38, 38)
const POR_PAGINA := 16
const CORES_LINGUAGEM := {"Python": Color("3b82f6"), "JavaScript": Color("eab308"), "PHP": Color("8b5cf6"), "Java": Color("f97316"), "Bash": Color("22c55e"), "SQL": Color("06b6d4"), "C": Color("94a3b8"), "Go": Color("38bdf8")}

var principal
var painel := ""
var dados: Dictionary = {}
var mouse := Vector2.ZERO
var tempo := 0.0
var pagina := 0
var aba_loja := "visual"
var editor := EditorAvatar.new()
var campo_startup: LineEdit
var campo_codigo: LineEdit
var form_startup := {"setor": 0, "forma": "circulo", "cor": 6, "cor2": 10, "icone": "foguete"}
var linhas_politica: Array = []
var rolagem := 0


func estado():
	return Estado.atual


func _ready() -> void:
	campo_startup = criar_campo("Nome da empresa", 20, Vector2(500, 150), Vector2(360, 44))
	campo_codigo = criar_campo("Cole aqui o código DDOS4:...", 100000, Vector2(130, 470), Vector2(760, 44))
	for i in Textos.POLITICA.size():
		var p: String = Textos.POLITICA[i]
		if p == "":
			linhas_politica.append(["", 15, Visual.TEXTO_SUAVE])
			continue
		var titulo := i == 0 or (p.length() > 1 and p[0].is_valid_int() and p[1] == ".")
		var tamanho := 22 if i == 0 else (17 if titulo else 15)
		for linha in Visual.quebrar(p, tamanho, 960):
			linhas_politica.append([linha, tamanho, Visual.TEXTO if titulo else Visual.TEXTO_SUAVE])


func criar_campo(dica: String, maximo: int, pos: Vector2, tamanho: Vector2) -> LineEdit:
	var campo := LineEdit.new()
	campo.placeholder_text = dica
	campo.max_length = maximo
	campo.position = pos
	campo.size = tamanho
	var normal := StyleBoxFlat.new()
	normal.bg_color = Visual.CARTAO_CLARO
	normal.set_corner_radius_all(10)
	normal.set_border_width_all(1)
	normal.border_color = Visual.BORDA
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var foco := normal.duplicate() as StyleBoxFlat
	foco.border_color = Visual.DESTAQUE
	campo.add_theme_stylebox_override("normal", normal)
	campo.add_theme_stylebox_override("focus", foco)
	campo.add_theme_font_size_override("font_size", 16)
	campo.add_theme_color_override("font_color", Visual.TEXTO)
	campo.add_theme_color_override("font_placeholder_color", Visual.TEXTO_SUAVE)
	campo.visible = false
	add_child(campo)
	return campo


func aberto() -> bool:
	return painel != ""


func abrir(tipo: String, d: Dictionary) -> void:
	painel = tipo
	dados = d.duplicate()
	pagina = 0
	rolagem = 0
	if tipo == "avatar":
		editor.aparencia = estado().perfil["avatar"].duplicate()
		editor.equipados = estado().perfil["equipados"].duplicate()
		editor.itens = estado().perfil["itens"]
		editor.origem = Vector2(130, 130)
	if tipo == "startup":
		campo_startup.text = ""
	if tipo == "backup":
		campo_codigo.text = ""


func fechar() -> void:
	if painel == "avatar":
		salvar_avatar()
	painel = ""
	dados = {}
	campo_startup.release_focus()
	campo_codigo.release_focus()


func salvar_avatar() -> void:
	if estado().perfil.is_empty():
		return
	estado().perfil["avatar"] = editor.aparencia.duplicate()
	estado().perfil["equipados"] = editor.equipados.duplicate()
	estado().salvar()


func _process(delta: float) -> void:
	tempo += delta
	mouse = get_local_mouse_position()
	campo_startup.visible = painel == "startup" and estado().perfil.get("startup", {}).is_empty() and not principal.licao_aberta()
	campo_codigo.visible = painel == "backup" and not principal.licao_aberta()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not aberto() or principal.licao_aberta():
		return
	if event is InputEventMouseButton:
		var e := make_input_local(event) as InputEventMouseButton
		if e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			clicar(e.position)
		elif e.pressed and painel == "politica" and (e.button_index == MOUSE_BUTTON_WHEEL_DOWN or e.button_index == MOUSE_BUTTON_WHEEL_UP):
			rolar(3 if e.button_index == MOUSE_BUTTON_WHEEL_DOWN else -3)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if painel == "beco" and dados.has("desafio"):
				dados.erase("desafio")
			else:
				fechar()
		elif painel == "politica" and event.keycode == KEY_DOWN:
			rolar(1)
		elif painel == "politica" and event.keycode == KEY_UP:
			rolar(-1)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()


func rolar(passos: int) -> void:
	rolagem = clampi(rolagem + passos, 0, maxi(0, linhas_politica.size() - 21))


func clicar(pos: Vector2) -> void:
	if painel != "intro" and RET_FECHAR.has_point(pos):
		if painel == "beco" and dados.has("desafio"):
			dados.erase("desafio")
		else:
			fechar()
		return
	if painel == "avatar" and editor.clicar(pos):
		salvar_avatar()
		return
	for b in botoes():
		if b["rect"].has_point(pos):
			if b.get("ativo", true):
				b["acao"].call()
			return


func botao(rect: Rect2, rotulo: String, acao: Callable, ativo := true, estilo := "normal") -> Dictionary:
	return {"rect": rect, "rotulo": rotulo, "acao": acao, "ativo": ativo, "estilo": estilo}


func botoes() -> Array:
	match painel:
		"missoes":
			return botoes_missoes()
		"loja":
			return botoes_loja()
		"academia":
			return botoes_academia()
		"beco":
			return botoes_beco()
		"empresa":
			return botoes_empresa(dados.get("id", ""))
		"bolsa":
			return botoes_bolsa()
		"sede":
			return botoes_sede()
		"avatar":
			return [botao(Rect2(960, 610, 200, 48), "Pronto", fechar, true, "principal")]
		"startup":
			return botoes_startup()
		"backup":
			return botoes_backup()
		"politica":
			return [botao(Rect2(112, 618, 160, 44), "Voltar", fechar), botao(Rect2(900, 618, 120, 44), "Subir", rolar.bind(-8), rolagem > 0), botao(Rect2(1030, 618, 120, 44), "Descer", rolar.bind(8), rolagem < linhas_politica.size() - 21)]
		"excluir":
			return [botao(Rect2(450, 420, 180, 50), "Excluir", excluir_conta, true, "perigo"), botao(Rect2(650, 420, 180, 50), "Cancelar", abrir.bind("sede", {}))]
		"intro":
			return [botao(Rect2(470, 600, 340, 52), "Explorar a cidade", fechar, true, "principal")]
	return []


func _draw() -> void:
	if not aberto():
		return
	draw_rect(Rect2(0, 0, 1280, 720), Visual.SOBREPOSICAO)
	if painel == "excluir":
		desenhar_excluir()
		desenhar_botoes()
		return
	if painel == "intro":
		desenhar_intro()
		desenhar_botoes()
		return
	var fundo := Color("0b120d") if painel == "beco" else Visual.CARTAO
	Visual.caixa(self, CARTAO, fundo, 22, Color("166534") if painel == "beco" else Visual.BORDA, 1, 24)
	Visual.caixa(self, RET_FECHAR, Visual.CARTAO_CLARO, 10, Visual.BORDA_HOVER if RET_FECHAR.has_point(mouse) else Visual.BORDA, 1)
	var c := RET_FECHAR.get_center()
	draw_line(c + Vector2(-7, -7), c + Vector2(7, 7), Visual.TEXTO, 2.0, true)
	draw_line(c + Vector2(-7, 7), c + Vector2(7, -7), Visual.TEXTO, 2.0, true)
	match painel:
		"missoes":
			desenhar_missoes()
		"loja":
			desenhar_loja()
		"academia":
			desenhar_academia()
		"beco":
			desenhar_beco()
		"empresa":
			desenhar_empresa(dados.get("id", ""))
		"bolsa":
			desenhar_bolsa()
		"sede":
			desenhar_sede()
		"avatar":
			cabecalho("Seu visual", "Monte seu personagem. As mudanças são salvas na hora.")
			editor.desenhar(self, tempo, mouse)
		"startup":
			desenhar_startup()
		"backup":
			desenhar_backup()
		"politica":
			desenhar_politica()
	desenhar_botoes()


func desenhar_botoes() -> void:
	for b in botoes():
		if b.get("estilo", "") == "invisivel":
			continue
		var r: Rect2 = b["rect"]
		match b.get("estilo", "normal"):
			"principal":
				Visual.botao(self, r, b["rotulo"], Visual.PRINCIPAL, r.has_point(mouse), b["ativo"], 15, true)
			"perigo":
				Visual.botao(self, r, b["rotulo"], Visual.PERIGO, r.has_point(mouse), b["ativo"], 15)
			"ouro":
				Visual.botao(self, r, b["rotulo"], Visual.CREDITOS, r.has_point(mouse), b["ativo"], 14)
			_:
				Visual.botao(self, r, b["rotulo"], Visual.DESTAQUE, r.has_point(mouse), b["ativo"], 14)


func cabecalho(titulo: String, subtitulo: String) -> void:
	Visual.texto(self, Vector2(112, 94), titulo, 28, Visual.TEXTO)
	Visual.texto(self, Vector2(112, 120), subtitulo, 14, Visual.TEXTO_SUAVE)


func barra(r: Rect2, valor: float, cor: Color) -> void:
	Visual.caixa(self, r, Visual.LINHA, int(r.size.y / 2))
	if valor > 0.0:
		Visual.caixa(self, Rect2(r.position, Vector2(maxf(r.size.y, r.size.x * clampf(valor, 0.0, 1.0)), r.size.y)), cor, int(r.size.y / 2))


func desenhar_missoes() -> void:
	cabecalho("Central de Missões", "Complete missões para ganhar dinheiro, XP e aprender a jogar.")
	Visual.texto(self, Vector2(112, 160), "Missões principais", 16, Visual.CREDITOS)
	var ativas: Array = estado().missoes_ativas().slice(0, 5)
	if ativas.is_empty():
		Visual.texto(self, Vector2(112, 200), "Você completou todas as missões principais. Lenda!", 15, Visual.HUMANO)
	for i in ativas.size():
		var m: Dictionary = ativas[i]
		var r := Rect2(112, 172 + i * 88, 590, 80)
		var feita: bool = estado().missao_concluida(m)
		Visual.caixa(self, r, Visual.CARTAO_CLARO, 12, Visual.CREDITOS if feita else Visual.BORDA, 1)
		Visual.texto(self, r.position + Vector2(16, 24), m["titulo"], 15, Visual.TEXTO)
		Visual.paragrafo(self, r.position + Vector2(16, 44), m["descricao"], 12, Visual.TEXTO_SUAVE, 400, 1.3, 2)
		var atual := mini(estado().valor(m["contador"]), int(m["alvo"]))
		barra(Rect2(r.position.x + 16, r.end.y - 12, 400, 5), float(atual) / float(m["alvo"]), Visual.CREDITOS)
		Visual.texto(self, Vector2(r.position.x + 424, r.end.y - 6), "%d/%d" % [atual, int(m["alvo"])], 11, Visual.TEXTO_SUAVE)
		if not feita:
			Visual.texto(self, Vector2(r.end.x - 150, r.position.y + 30), "+%s" % Visual.dinheiro(m["dinheiro"]), 13, Visual.CREDITOS, HORIZONTAL_ALIGNMENT_RIGHT, 136)
			Visual.texto(self, Vector2(r.end.x - 150, r.position.y + 50), "+%d XP" % int(m["xp"]), 12, Visual.DESTAQUE, HORIZONTAL_ALIGNMENT_RIGHT, 136)
	Visual.texto(self, Vector2(730, 160), "Diárias de hoje", 16, Visual.DESTAQUE)
	var diarias: Array = estado().diarias_hoje()
	var resgatadas: Array = estado().diarias_estado()["resgatadas"]
	for i in diarias.size():
		var d: Dictionary = diarias[i]
		var r2 := Rect2(730, 172 + i * 88, 440, 80)
		var feita2: bool = estado().valor_diario(d["contador"]) >= int(d["alvo"])
		var ja: bool = d["id"] in resgatadas
		Visual.caixa(self, r2, Visual.CARTAO_CLARO, 12, Visual.HUMANO if ja else (Visual.DESTAQUE if feita2 else Visual.BORDA), 1)
		Visual.texto(self, r2.position + Vector2(16, 24), d["titulo"] + ("  (resgatada)" if ja else ""), 15, Visual.TEXTO)
		Visual.texto(self, r2.position + Vector2(16, 44), d["descricao"], 12, Visual.TEXTO_SUAVE)
		var atual2 := mini(estado().valor_diario(d["contador"]), int(d["alvo"]))
		barra(Rect2(r2.position.x + 16, r2.end.y - 12, 270, 5), float(atual2) / float(d["alvo"]), Visual.DESTAQUE)
		Visual.texto(self, Vector2(r2.position.x + 294, r2.end.y - 6), "%d/%d" % [atual2, int(d["alvo"])], 11, Visual.TEXTO_SUAVE)
	var seq: Dictionary = estado().perfil["sequencia"]
	var caixa_seq := Rect2(730, 448, 440, 120)
	Visual.caixa(self, caixa_seq, Visual.com_alfa(Color("f97316"), 0.1), 14, Color("f97316"), 1)
	var chama := caixa_seq.position + Vector2(44, 62)
	draw_colored_polygon(PackedVector2Array([chama + Vector2(0, -30), chama + Vector2(16, -6), chama + Vector2(11, 14), chama + Vector2(-11, 14), chama + Vector2(-16, -6)]), Color("f97316"))
	draw_circle(chama + Vector2(0, 4), 8.0, Color("fde047"), true, -1.0, true)
	Visual.texto(self, caixa_seq.position + Vector2(84, 40), "Sequência de %d dia(s)" % int(seq["dias"]), 18, Visual.TEXTO)
	Visual.texto(self, caixa_seq.position + Vector2(84, 64), "Melhor sequência: %d dia(s)" % int(seq["melhor"]), 13, Visual.TEXTO_SUAVE)
	Visual.paragrafo(self, caixa_seq.position + Vector2(84, 88), "Volte amanhã para manter a chama acesa e ganhar mais dinheiro na entrada.", 12, Visual.TEXTO_SUAVE, 340, 1.3, 2)


func botoes_missoes() -> Array:
	var lista: Array = []
	var ativas: Array = estado().missoes_ativas().slice(0, 5)
	for i in ativas.size():
		var m: Dictionary = ativas[i]
		if estado().missao_concluida(m):
			lista.append(botao(Rect2(552, 172 + i * 88 + 20, 136, 40), "Resgatar", resgatar.bind(m["id"], false), true, "ouro"))
	var diarias: Array = estado().diarias_hoje()
	var resgatadas: Array = estado().diarias_estado()["resgatadas"]
	for i in diarias.size():
		var d: Dictionary = diarias[i]
		if estado().valor_diario(d["contador"]) >= int(d["alvo"]) and not d["id"] in resgatadas:
			lista.append(botao(Rect2(1030, 172 + i * 88 + 20, 126, 40), "Resgatar", resgatar.bind(d["id"], true), true, "ouro"))
	return lista


func resgatar(id: String, diaria: bool) -> void:
	var ok: bool = estado().resgatar_diaria(id) if diaria else estado().resgatar_missao(id)
	if ok:
		principal.confete(Vector2(640, 200), 50)


func itens_loja() -> Array:
	var lista: Array = []
	for id in Dados.ITENS:
		var reforco: bool = Dados.ITENS[id]["tipo"] == "reforco"
		if (aba_loja == "reforcos") == reforco:
			lista.append(id)
	return lista


func retangulo_item(indice: int) -> Rect2:
	return Rect2(112 + (indice % 5) * 212, 194 + (indice / 5) * 222, 200, 212)


func desenhar_loja() -> void:
	cabecalho("Loja Tech", "Itens para o seu personagem e reforços para usar nas operações.")
	Visual.texto(self, Vector2(1160, 120), "Carteira: %s" % Visual.dinheiro(estado().dinheiro()), 15, Visual.CREDITOS, HORIZONTAL_ALIGNMENT_RIGHT, 300)
	var itens := itens_loja()
	for i in itens.size():
		var id: String = itens[i]
		var item: Dictionary = Dados.ITENS[id]
		var r := retangulo_item(i)
		var possui: bool = estado().possui_item(id)
		Visual.caixa(self, r, Visual.CARTAO_CLARO, 14, Visual.BORDA_HOVER if r.has_point(mouse) else Visual.BORDA, 1)
		var palco := Rect2(r.position + Vector2(10, 10), Vector2(r.size.x - 20, 96))
		Visual.palco(self, palco, 10)
		if item["tipo"] == "reforco":
			var icones := {"seguro": "waf", "plantao": "servidor", "pentest": "ips", "consultoria": "treinamento"}
			Visual.icone(self, icones[id], palco.get_center(), Visual.CREDITOS, 2.2)
			Visual.texto(self, Vector2(palco.position.x, palco.end.y - 8), "Você tem: %d" % estado().reforcos(id), 11, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, palco.size.x)
		elif item["tipo"] == "pet":
			Visual.pet(self, palco.position + Vector2(palco.size.x / 2, 88), id, tempo, 1, 2.4)
		else:
			var equipados: Dictionary = estado().perfil["equipados"].duplicate()
			equipados[item["tipo"]] = id
			Visual.avatar(self, palco.position + Vector2(palco.size.x / 2, 92), 1.35, estado().perfil["avatar"], equipados, tempo, false)
		Visual.texto(self, r.position + Vector2(14, 128), item["nome"], 15, Visual.TEXTO)
		Visual.paragrafo(self, r.position + Vector2(14, 148), item["descricao"], 11, Visual.TEXTO_SUAVE, 176, 1.3, 2)
		if not possui or item["tipo"] == "reforco":
			Visual.texto(self, r.position + Vector2(14, 196), Visual.dinheiro(item["preco"]), 14, Visual.CREDITOS)


func botoes_loja() -> Array:
	var lista: Array = [
		botao(Rect2(112, 140, 140, 40), "Visual", func(): aba_loja = "visual", aba_loja != "visual"),
		botao(Rect2(262, 140, 140, 40), "Reforços", func(): aba_loja = "reforcos", aba_loja != "reforcos"),
	]
	var itens := itens_loja()
	for i in itens.size():
		var id: String = itens[i]
		var item: Dictionary = Dados.ITENS[id]
		var r := retangulo_item(i)
		var rb := Rect2(r.end.x - 94, r.end.y - 38, 84, 30)
		if item["tipo"] != "reforco" and estado().possui_item(id):
			var vestido: bool = estado().perfil["equipados"].get(item["tipo"], "") == id
			lista.append(botao(rb, "Tirar" if vestido else "Vestir", estado().equipar.bind(id)))
		else:
			lista.append(botao(rb, "Comprar", comprar_item.bind(id), estado().dinheiro() >= float(item["preco"]), "ouro"))
	return lista


func comprar_item(id: String) -> void:
	var erro: String = estado().comprar_item(id)
	if erro != "":
		principal.avisar(erro, Visual.PERIGO)
	else:
		principal.confete(Vector2(640, 300), 30)


func ids_licoes() -> Array:
	return Textos.LICOES.keys()


func retangulo_licao(indice: int) -> Rect2:
	return Rect2(112 + (indice % 4) * 268, 150 + (indice / 4) * 106, 256, 96)


func desenhar_academia() -> void:
	var ids := ids_licoes()
	var lidas: Array = estado().perfil["licoes_lidas"]
	cabecalho("Academia Cyber", "%d de %d lições lidas. Cada lição nova vale XP. As marcadas como NOVA apareceram nas suas operações." % [lidas.size(), ids.size()])
	var inicio := pagina * POR_PAGINA
	for k in range(inicio, mini(ids.size(), inicio + POR_PAGINA)):
		var id: String = ids[k]
		var licao: Dictionary = Textos.LICOES[id]
		var r := retangulo_licao(k - inicio)
		var lida: bool = id in lidas
		var nova: bool = estado().licao_desbloqueada(id) and not lida
		Visual.caixa(self, r, Visual.CARTAO_CLARO, 12, Visual.DESTAQUE if r.has_point(mouse) else (Visual.CREDITOS if nova else Visual.BORDA), 1)
		var cor_cat := {"Componente": Visual.DESTAQUE, "Conceito": Visual.HUMANO, "Ataque": Visual.PERIGO}
		Visual.texto(self, r.position + Vector2(14, 22), String(licao["categoria"]).to_upper(), 10, cor_cat.get(licao["categoria"], Visual.DESTAQUE))
		if Dados.COMPONENTES.has(id):
			Visual.icone(self, id, Vector2(r.end.x - 26, r.position.y + 26), Dados.COMPONENTES[id]["cor"], 0.9)
		Visual.paragrafo(self, r.position + Vector2(14, 46), licao["titulo"], 14, Visual.TEXTO, 200, 1.3, 2)
		Visual.texto(self, r.position + Vector2(14, r.size.y - 10), "lida" if lida else ("NOVA" if nova else "+15 XP"), 11, Visual.HUMANO if lida else (Visual.CREDITOS if nova else Visual.TEXTO_SUAVE))
	var paginas := ceili(float(ids.size()) / POR_PAGINA)
	Visual.texto(self, Vector2(0, 646), "Página %d de %d" % [pagina + 1, paginas], 13, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, 1280)


func botoes_academia() -> Array:
	var ids := ids_licoes()
	var lista: Array = []
	var inicio := pagina * POR_PAGINA
	for k in range(inicio, mini(ids.size(), inicio + POR_PAGINA)):
		lista.append({"rect": retangulo_licao(k - inicio), "rotulo": "", "acao": principal.abrir_licao.bind(ids[k]), "ativo": true, "estilo": "invisivel"})
	var paginas := ceili(float(ids.size()) / POR_PAGINA)
	lista.append(botao(Rect2(430, 620, 130, 40), "Anterior", func(): pagina -= 1, pagina > 0))
	lista.append(botao(Rect2(720, 620, 130, 40), "Próxima", func(): pagina += 1, pagina < paginas - 1))
	return lista


func desafio_do_dia() -> int:
	var pendentes: Array = []
	for i in Textos.DESAFIOS.size():
		if not estado().desafio_resolvido(Textos.DESAFIOS[i]["id"]):
			pendentes.append(i)
	if pendentes.is_empty():
		return -1
	return pendentes[hash(estado().hoje()) % pendentes.size()]


func retangulo_desafio(indice: int) -> Rect2:
	return Rect2(112 + (indice % 4) * 268, 160 + (indice / 4) * 112, 256, 100)


func desenhar_beco() -> void:
	if dados.has("desafio"):
		desenhar_desafio()
		return
	cabecalho("Beco Hacker", "Laboratório de código seguro. Ache a linha vulnerável e escolha a correção. Código seguro nível %d/5." % estado().codigo_seguro())
	var do_dia := desafio_do_dia()
	for i in Textos.DESAFIOS.size():
		var d: Dictionary = Textos.DESAFIOS[i]
		var r := retangulo_desafio(i)
		var feito: bool = estado().desafio_resolvido(d["id"])
		Visual.caixa(self, r, Color("0f1a12"), 12, Color("22c55e") if r.has_point(mouse) else (Visual.CREDITOS if i == do_dia else Color("1f3a28")), 1)
		var cor_ling: Color = CORES_LINGUAGEM.get(d["linguagem"], Visual.DESTAQUE)
		var largura := Visual.largura_texto(d["linguagem"], 11) + 16
		Visual.caixa(self, Rect2(r.position + Vector2(14, 12), Vector2(largura, 20)), Visual.com_alfa(cor_ling, 0.25), 10)
		Visual.texto(self, r.position + Vector2(14, 27), d["linguagem"], 11, cor_ling, HORIZONTAL_ALIGNMENT_CENTER, largura)
		Visual.texto(self, r.position + Vector2(14, 58), d["titulo"], 15, Visual.TEXTO)
		var status := "resolvido" if feito else ("DESAFIO DO DIA" if i == do_dia else "+R$ 250 mil  ·  +100 XP")
		Visual.texto(self, r.position + Vector2(14, 84), status, 11, Visual.HUMANO if feito else (Visual.CREDITOS if i == do_dia else Visual.TEXTO_SUAVE))


func botoes_beco() -> Array:
	var lista: Array = []
	if dados.has("desafio"):
		var d: Dictionary = Textos.DESAFIOS[dados["desafio"]]
		var etapa: int = dados["etapa"]
		if etapa == 0:
			for k in d["codigo"].size():
				lista.append({"rect": retangulo_linha(k), "rotulo": "", "acao": escolher_linha.bind(k), "ativo": true, "estilo": "invisivel"})
		elif etapa == 1:
			for k in 3:
				lista.append({"rect": retangulo_opcao_codigo(k), "rotulo": "", "acao": escolher_correcao.bind(k), "ativo": true, "estilo": "invisivel"})
		else:
			lista.append(botao(Rect2(860, 620, 150, 44), "Entender", principal.abrir_licao.bind(d["licao"])))
			lista.append(botao(Rect2(1020, 620, 150, 44), "Voltar", func(): dados.erase("desafio"), true, "principal"))
			if not dados.get("acertou", false):
				lista.append(botao(Rect2(700, 620, 150, 44), "Tentar de novo", func(): dados["etapa"] = 1))
		return lista
	for i in Textos.DESAFIOS.size():
		lista.append({"rect": retangulo_desafio(i), "rotulo": "", "acao": abrir_desafio.bind(i), "ativo": true, "estilo": "invisivel"})
	return lista


func abrir_desafio(indice: int) -> void:
	var ordem: Array = [0, 1, 2]
	var gerador := RandomNumberGenerator.new()
	gerador.seed = hash(Textos.DESAFIOS[indice]["id"])
	for i in range(2, 0, -1):
		var j := gerador.randi_range(0, i)
		var temp = ordem[i]
		ordem[i] = ordem[j]
		ordem[j] = temp
	dados = {"desafio": indice, "etapa": 0, "ordem": ordem, "erro_linha": -1}


func retangulo_linha(k: int) -> Rect2:
	return Rect2(126, 186 + k * 30, 696, 28)


func retangulo_opcao_codigo(k: int) -> Rect2:
	return Rect2(126, 430 + k * 60, 1030, 52)


func escolher_linha(k: int) -> void:
	var d: Dictionary = Textos.DESAFIOS[dados["desafio"]]
	if k == int(d["linha"]):
		dados["etapa"] = 1
		dados["erro_linha"] = -1
	else:
		dados["erro_linha"] = k


func escolher_correcao(posicao: int) -> void:
	var d: Dictionary = Textos.DESAFIOS[dados["desafio"]]
	var escolhida: int = dados["ordem"][posicao]
	dados["escolha"] = posicao
	dados["acertou"] = escolhida == int(d["correta"])
	dados["etapa"] = 2
	if dados["acertou"]:
		var primeira: bool = estado().resolver_desafio(d["id"])
		principal.confete(Vector2(640, 300), 50 if primeira else 20)
		if primeira:
			principal.avisar("Bug corrigido! +R$ 250 mil e +100 XP", Visual.HUMANO)
		estado().desbloquear_licao(d["licao"])


func desenhar_desafio() -> void:
	var d: Dictionary = Textos.DESAFIOS[dados["desafio"]]
	var etapa: int = dados["etapa"]
	var cor_ling: Color = CORES_LINGUAGEM.get(d["linguagem"], Visual.DESTAQUE)
	Visual.texto(self, Vector2(112, 94), d["titulo"], 26, Visual.TEXTO)
	Visual.texto(self, Vector2(112 + Visual.largura_texto(d["titulo"], 26) + 16, 94), d["linguagem"], 15, cor_ling)
	var instrucao: String = ["Passo 1: toque na linha que tem a vulnerabilidade.", "Passo 2: escolha a correção certa para essa linha.", ""][etapa]
	Visual.texto(self, Vector2(112, 122), instrucao, 14, Visual.CREDITOS)
	var linhas: Array = d["codigo"]
	var caixa_codigo := Rect2(112, 170, 724, 24 + linhas.size() * 30)
	Visual.caixa(self, caixa_codigo, Color("050a07"), 12, Color("1f3a28"), 1)
	for k in linhas.size():
		var r := retangulo_linha(k)
		var destaque := Color(0, 0, 0, 0)
		if etapa == 0 and r.has_point(mouse):
			destaque = Color(1, 1, 1, 0.06)
		if k == dados.get("erro_linha", -1):
			destaque = Visual.com_alfa(Visual.PERIGO, 0.18)
		if etapa > 0 and k == int(d["linha"]):
			destaque = Visual.com_alfa(Visual.CREDITOS, 0.2)
		if destaque.a > 0.0:
			Visual.caixa(self, r, destaque, 6)
		Visual.texto_mono(self, r.position + Vector2(8, 19), "%2d" % (k + 1), 13, Color("4b5563"), 8.5)
		Visual.texto_mono(self, r.position + Vector2(40, 19), String(linhas[k]), 13, Color("d1fae5"), 8.2)
	var x2 := 860.0
	if etapa == 0:
		Visual.paragrafo(self, Vector2(x2, 190), "Leia com calma. Pergunte-se: onde um dado que vem de fora (usuário, URL, formulário, arquivo) entra no código sem cuidado? Ou onde um segredo ficou exposto?", 13, Visual.TEXTO_SUAVE, 300, 1.45, 8)
		if dados.get("erro_linha", -1) >= 0:
			Visual.paragrafo(self, Vector2(x2, 330), "Essa linha não é o problema. Tente outra!", 14, Visual.PERIGO, 300, 1.4, 2)
	elif etapa == 1:
		for k in 3:
			var r2 := retangulo_opcao_codigo(k)
			Visual.caixa(self, r2, Visual.CARTAO_CLARO, 10, Visual.HUMANO if r2.has_point(mouse) else Visual.BORDA, 1)
			Visual.texto(self, r2.position + Vector2(16, 32), "%d" % (k + 1), 15, Visual.CREDITOS)
			Visual.texto_mono(self, r2.position + Vector2(44, 32), String(d["opcoes"][dados["ordem"][k]]), 13, Visual.TEXTO, 8.0)
	else:
		var acertou: bool = dados["acertou"]
		var r3 := Rect2(112, 430, 1060, 170)
		Visual.caixa(self, r3, Visual.com_alfa(Visual.HUMANO if acertou else Visual.PERIGO, 0.1), 12, Visual.HUMANO if acertou else Visual.PERIGO, 1)
		Visual.texto(self, r3.position + Vector2(20, 34), "Corrigido! Esse é o jeito seguro." if acertou else "Essa correção não resolve.", 19, Visual.HUMANO if acertou else Visual.PERIGO)
		Visual.texto_mono(self, r3.position + Vector2(20, 66), String(d["opcoes"][int(d["correta"])]), 13, Color("d1fae5"), 8.0)
		Visual.paragrafo(self, r3.position + Vector2(20, 100), "Por quê: " + String(d["explicacao"]), 14, Visual.TEXTO_SUAVE, 1010, 1.4, 3)


func desenhar_empresa(id: String) -> void:
	var e: Dictionary = estado().empresa_dados(id)
	if e.is_empty():
		return
	Visual.logo(self, Vector2(176, 132), 48.0, e["logo"], e["sigla"])
	Visual.texto(self, Vector2(244, 120), e["nome"], 30, Visual.TEXTO)
	Visual.texto(self, Vector2(244, 148), e["setor"], 15, Visual.TEXTO_SUAVE)
	for k in 3:
		Visual.estrela(self, Vector2(250 + k * 20, 172), 7.0, e["cor"] if k < e["dificuldade"] else Visual.BORDA)
	Visual.paragrafo(self, Vector2(112, 222), e["descricao"], 15, Visual.TEXTO_SUAVE, 620, 1.45, 4)
	Visual.texto(self, Vector2(112, 330), "Ameaças mais comuns", 14, Visual.TEXTO)
	var ameacas: Array = []
	for tipo in e["mix"]:
		if tipo != "humano":
			ameacas.append([tipo, e["mix"][tipo]])
	ameacas.sort_custom(func(a, b): return a[1] > b[1])
	var x := 112.0
	for a in ameacas.slice(0, 4):
		var nome: String = Dados.TIPOS_REQ[a[0]]["nome"]
		var largura := Visual.largura_texto(nome, 12) + 30
		Visual.caixa(self, Rect2(x, 342, largura, 26), Visual.com_alfa(Dados.TIPOS_REQ[a[0]]["cor"], 0.18), 13)
		if a[0] in Dados.HACKERS:
			Visual.losango(self, Vector2(x + 12, 355), 5.0, Dados.TIPOS_REQ[a[0]]["cor"])
		else:
			draw_rect(Rect2(x + 8, 351, 8, 8), Dados.TIPOS_REQ[a[0]]["cor"])
		Visual.texto(self, Vector2(x + 22, 360), nome, 12, Visual.TEXTO)
		x += largura + 8
	Visual.texto(self, Vector2(112, 404), "Sistemas", 14, Visual.TEXTO)
	var nomes: Array = []
	for s in e["sites"]:
		nomes.append(s["nome"])
	Visual.texto(self, Vector2(112, 428), " · ".join(nomes), 13, Visual.TEXTO_SUAVE)
	Visual.texto(self, Vector2(112, 466), "Datas de pico", 14, Visual.TEXTO)
	var eventos: Array = []
	for ev in e["eventos"]:
		eventos.append(Dados.EVENTOS[ev]["nome"])
	Visual.texto(self, Vector2(112, 490), " · ".join(eventos), 13, Visual.TEXTO_SUAVE)
	var painel_status := Rect2(780, 110, 390, 500)
	Visual.caixa(self, painel_status, Visual.CARTAO_CLARO, 16)
	var est: Dictionary = estado().estado_empresa(id) if id != "startup" else estado().estado_empresa("startup")
	var dono: bool = estado().eh_dono(id)
	var status := ""
	var cor_status := Visual.TEXTO
	if id == "startup":
		status = "Sua empresa: 50% do lucro é seu"
		cor_status = Visual.CREDITOS
	elif dono:
		status = "Você é dono: 35% do lucro é seu"
		cor_status = Visual.CREDITOS
	elif e["contrato"]:
		status = "Contrato disponível: 15% do lucro"
		cor_status = Visual.HUMANO
	elif estado().nivel() < int(e["nivel"]):
		status = "Bloqueada até o nível %s" % Dados.NIVEIS[int(e["nivel"])]["titulo"]
		cor_status = Visual.TEXTO_SUAVE
	else:
		status = "À venda por %s" % Visual.dinheiro(e["preco"])
		cor_status = Visual.DESTAQUE
	Visual.paragrafo(self, painel_status.position + Vector2(24, 42), status, 17, cor_status, 340, 1.3, 2)
	var linhas := [
		["Recorde", "dia %d" % int(est.get("recorde", 0))],
		["Temporadas jogadas", "%d" % int(est.get("temporadas", 0))],
		["Lucro acumulado", Visual.dinheiro(float(est.get("lucro", 0.0)))],
		["Caixa inicial", Visual.dinheiro(e["caixa"])],
	]
	for i in linhas.size():
		var y := painel_status.position.y + 120 + i * 34
		Visual.texto(self, Vector2(painel_status.position.x + 24, y), linhas[i][0], 14, Visual.TEXTO_SUAVE)
		Visual.texto(self, Vector2(painel_status.position.x + 24, y), linhas[i][1], 14, Visual.TEXTO, HORIZONTAL_ALIGNMENT_RIGHT, 340)
	var salvo: Dictionary = estado().obter_operacao(id)
	if not salvo.is_empty():
		Visual.texto(self, Vector2(painel_status.position.x + 24, painel_status.position.y + 284), "Partida em andamento: dia %d" % int(salvo.get("dia", 1)), 14, Visual.HUMANO)


func botoes_empresa(id: String) -> Array:
	var e: Dictionary = estado().empresa_dados(id)
	var lista: Array = []
	if e.is_empty():
		return lista
	var salvo: Dictionary = estado().obter_operacao(id)
	if estado().pode_operar(id):
		lista.append(botao(Rect2(804, 470, 342, 52), "Continuar no dia %d" % int(salvo.get("dia", 1)) if not salvo.is_empty() else "Operar a empresa", operar.bind(id), true, "principal"))
	if id != "startup" and not estado().eh_dono(id):
		var nivel_ok: bool = estado().nivel() >= int(e["nivel"])
		lista.append(botao(Rect2(804, 534, 342, 52), "Comprar por %s" % Visual.dinheiro(e["preco"]) if nivel_ok else "Precisa ser %s" % Dados.NIVEIS[int(e["nivel"])]["titulo"], comprar_empresa.bind(id), nivel_ok and estado().dinheiro() >= float(e["preco"]), "ouro"))
	return lista


func operar(id: String) -> void:
	fechar()
	principal.operar(id)


func comprar_empresa(id: String) -> void:
	var erro: String = estado().comprar_empresa(id)
	if erro != "":
		principal.avisar(erro, Visual.PERIGO)
	else:
		principal.confete(Vector2(640, 200), 60)


func desenhar_bolsa() -> void:
	cabecalho("Bolsa Tech", "Compre empresas para receber 35% do lucro de cada dia em vez de 15% do contrato.")
	Visual.texto(self, Vector2(1160, 120), "Carteira: %s" % Visual.dinheiro(estado().dinheiro()), 15, Visual.CREDITOS, HORIZONTAL_ALIGNMENT_RIGHT, 300)
	for i in Dados.EMPRESAS.size():
		var e: Dictionary = Dados.EMPRESAS[i]
		var y := 146.0 + i * 33.0
		var r := Rect2(112, y, 1056, 30)
		if r.has_point(mouse):
			Visual.caixa(self, r, Visual.CARTAO_CLARO, 8)
		Visual.logo(self, Vector2(130, y + 15), 11.0, e["logo"], e["sigla"])
		Visual.texto(self, Vector2(152, y + 21), e["nome"], 14, Visual.TEXTO)
		Visual.texto(self, Vector2(310, y + 21), e["setor"], 12, Visual.TEXTO_SUAVE)
		Visual.texto(self, Vector2(520, y + 21), Visual.dinheiro(e["preco"]), 13, Visual.CREDITOS)
		Visual.texto(self, Vector2(660, y + 21), Dados.NIVEIS[int(e["nivel"])]["titulo"], 12, Visual.TEXTO_SUAVE if estado().nivel() >= int(e["nivel"]) else Visual.PERIGO)
		var status := "Sua" if estado().eh_dono(e["id"]) else ("Contrato" if e["contrato"] else "")
		Visual.texto(self, Vector2(860, y + 21), status, 12, Visual.CREDITOS if status == "Sua" else Visual.HUMANO)


func botoes_bolsa() -> Array:
	var lista: Array = []
	for i in Dados.EMPRESAS.size():
		var e: Dictionary = Dados.EMPRESAS[i]
		var y := 146.0 + i * 33.0
		lista.append(botao(Rect2(960, y + 1, 96, 28), "Ver", abrir.bind("empresa", {"id": e["id"]})))
		if not estado().eh_dono(e["id"]):
			lista.append(botao(Rect2(1064, y + 1, 100, 28), "Comprar", comprar_empresa.bind(e["id"]), estado().nivel() >= int(e["nivel"]) and estado().dinheiro() >= float(e["preco"]), "ouro"))
	return lista


func desenhar_sede() -> void:
	var p: Dictionary = estado().perfil
	cabecalho("Sua Sede", "Seu perfil, suas empresas e o controle da sua conta.")
	var palco := Rect2(112, 150, 300, 380)
	Visual.palco(self, palco)
	Visual.avatar(self, palco.position + Vector2(150, 330), 3.2, p["avatar"], p["equipados"], tempo, false)
	if p["equipados"].get("pet", "") != "":
		Visual.pet(self, palco.position + Vector2(240, 344), p["equipados"]["pet"], tempo, -1, 2.2)
	Visual.texto(self, Vector2(112, 560), p["nome"], 22, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, 300)
	Visual.texto(self, Vector2(112, 584), estado().titulo(), 14, Visual.DESTAQUE, HORIZONTAL_ALIGNMENT_CENTER, 300)
	barra(Rect2(142, 596, 240, 7), estado().progresso_nivel(), Visual.DESTAQUE)
	var linhas := [
		["Patrimônio na carteira", Visual.dinheiro(estado().dinheiro())],
		["Empresas suas", "%d" % estado().quantidade_empresas()],
		["Maior dia alcançado", "dia %d" % estado().valor("maior_dia")],
		["Desafios de código", "%d de %d" % [p["desafios"].size(), Textos.DESAFIOS.size()]],
		["Código seguro", "nível %d/5" % estado().codigo_seguro()],
		["Lições lidas", "%d de %d" % [p["licoes_lidas"].size(), Textos.LICOES.size()]],
		["Hackers bloqueados", "%d" % estado().valor("hackers_bloqueados")],
		["Melhor sequência", "%d dia(s)" % int(p["sequencia"]["melhor"])],
	]
	for i in linhas.size():
		var y := 168.0 + i * 36.0
		Visual.texto(self, Vector2(440, y), linhas[i][0], 14, Visual.TEXTO_SUAVE)
		Visual.texto(self, Vector2(440, y), linhas[i][1], 15, Visual.TEXTO, HORIZONTAL_ALIGNMENT_RIGHT, 340)
	Visual.texto(self, Vector2(440, 480), "Suas empresas", 14, Visual.TEXTO)
	var x := 440.0
	for e in Dados.EMPRESAS:
		if estado().eh_dono(e["id"]):
			Visual.logo(self, Vector2(x + 16, 512), 14.0, e["logo"], e["sigla"])
			x += 38.0
	if not p.get("startup", {}).is_empty():
		var s: Dictionary = estado().empresa_dados("startup")
		Visual.logo(self, Vector2(x + 16, 512), 14.0, s["logo"], s["sigla"])
	if x == 440.0 and p.get("startup", {}).is_empty():
		Visual.texto(self, Vector2(440, 516), "Nenhuma ainda. Compre na Bolsa Tech ou funde a sua.", 12, Visual.TEXTO_SUAVE)


func botoes_sede() -> Array:
	return [
		botao(Rect2(820, 160, 340, 50), "Editar visual", abrir.bind("avatar", {}), true, "principal"),
		botao(Rect2(820, 222, 340, 50), "Código de backup", abrir.bind("backup", {})),
		botao(Rect2(820, 284, 340, 50), "Política de privacidade", abrir.bind("politica", {})),
		botao(Rect2(820, 346, 340, 50), "Trocar de conta", trocar_conta),
		botao(Rect2(820, 560, 340, 50), "Excluir conta", abrir.bind("excluir", {}), true, "perigo"),
	]


func trocar_conta() -> void:
	fechar()
	principal.sair_conta()


func excluir_conta() -> void:
	var id: String = estado().id_ativo
	fechar()
	estado().excluir_conta(id)
	principal.sair_conta()
	principal.avisar("Conta excluída deste dispositivo.", Visual.HUMANO)


func desenhar_excluir() -> void:
	var cartao := Rect2(390, 230, 500, 270)
	Visual.caixa(self, cartao, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	Visual.texto(self, Vector2(cartao.position.x, 294), "Excluir esta conta?", 24, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, cartao.size.x)
	Visual.paragrafo(self, Vector2(430, 332), "Seu personagem, dinheiro, empresas, missões e lições serão apagados deste dispositivo. Não dá para desfazer, a não ser que você tenha um código de backup.", 14, Visual.TEXTO_SUAVE, 420, 1.45, 4)


func desenhar_intro() -> void:
	var cartao := Rect2(200, 70, 880, 610)
	Visual.caixa(self, cartao, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	Visual.avatar(self, Vector2(300, 250), 2.0, estado().perfil["avatar"], estado().perfil["equipados"], tempo, false)
	Visual.texto(self, Vector2(390, 140), "Bem-vindo à Cidade Tech, %s!" % estado().perfil["nome"], 26, Visual.TEXTO)
	Visual.paragrafo(self, Vector2(390, 176), "Você começa como estagiário de segurança. Ande pela cidade, aceite contratos, proteja empresas de bots e hackers, estude e suba até virar uma Lenda Cyber.", 15, Visual.TEXTO_SUAVE, 640, 1.45, 4)
	var passos := [
		["Andar", "WASD ou setas. No celular, toque no mapa ou direto num prédio."],
		["Entrar", "Chegue perto da porta e aperte E, ou toque no botão verde."],
		["Missões", "A missão atual aparece no canto. O prédio amarelo é a Central de Missões."],
		["Empresas", "Contratos com MercadoNet, Shoppa e VoaJá estão liberados. As outras se compram."],
		["Aprender", "Academia Cyber tem as lições e o Beco Hacker tem desafios de código."],
		["Progresso", "Tudo é salvo sozinho neste aparelho. Gere um código de backup no seu Perfil."],
	]
	for i in passos.size():
		var y := 330.0 + i * 42.0
		Visual.caixa(self, Rect2(240, y - 18, 110, 28), Visual.com_alfa(Visual.DESTAQUE, 0.15), 8)
		Visual.texto(self, Vector2(240, y + 1), passos[i][0], 13, Visual.DESTAQUE, HORIZONTAL_ALIGNMENT_CENTER, 110)
		Visual.texto(self, Vector2(366, y + 1), passos[i][1], 14, Visual.TEXTO)


func sigla_de(nome: String) -> String:
	var palavras := nome.strip_edges().split(" ", false)
	if palavras.size() >= 2:
		return (palavras[0].substr(0, 1) + palavras[1].substr(0, 1)).to_upper()
	return nome.strip_edges().substr(0, 2).to_upper()


func spec_logo_form() -> Dictionary:
	return {"forma": form_startup["forma"], "cor": Dados.CORES_LOGO[form_startup["cor"]], "cor2": Dados.CORES_LOGO[form_startup["cor2"]], "icone": form_startup["icone"]}


func desenhar_startup() -> void:
	if not estado().perfil.get("startup", {}).is_empty():
		desenhar_empresa("startup")
		return
	cabecalho("Terreno da Startup", "Funde sua própria empresa por %s e fique com 50%% do lucro." % Visual.dinheiro(Dados.CUSTO_STARTUP))
	Visual.texto(self, Vector2(500, 142), "Nome da empresa", 13, Visual.TEXTO_SUAVE)
	Visual.texto(self, Vector2(112, 230), "Setor", 13, Visual.TEXTO_SUAVE)
	Visual.texto(self, Vector2(112, 320), "Forma do logo", 13, Visual.TEXTO_SUAVE)
	Visual.texto(self, Vector2(112, 392), "Cor principal", 13, Visual.TEXTO_SUAVE)
	Visual.texto(self, Vector2(112, 452), "Cor do símbolo", 13, Visual.TEXTO_SUAVE)
	Visual.texto(self, Vector2(112, 512), "Símbolo", 13, Visual.TEXTO_SUAVE)
	var preview := Rect2(112, 140, 360, 74)
	Visual.caixa(self, preview, Visual.CARTAO_CLARO, 14)
	var nome := campo_startup.text.strip_edges()
	Visual.logo(self, preview.position + Vector2(40, 37), 26.0, spec_logo_form(), sigla_de(nome))
	Visual.texto(self, preview.position + Vector2(80, 34), nome if nome != "" else "Sua empresa", 18, Visual.TEXTO)
	Visual.texto(self, preview.position + Vector2(80, 56), Dados.SETORES_STARTUP[form_startup["setor"]]["setor"], 13, Visual.TEXTO_SUAVE)
	var grande := Vector2(1040, 420)
	Visual.caixa(self, Rect2(grande - Vector2(110, 90), Vector2(220, 180)), Visual.CARTAO_CLARO, 18)
	Visual.logo(self, grande, 60.0, spec_logo_form(), sigla_de(nome))
	for a in alvos_startup():
		var r: Rect2 = a["rect"]
		var sel := false
		match a["campo"]:
			"setor":
				sel = form_startup["setor"] == a["valor"]
				Visual.caixa(self, r, Visual.com_alfa(Visual.DESTAQUE, 0.18) if sel else Visual.CARTAO_CLARO, 10, Visual.DESTAQUE if sel else (Visual.BORDA_HOVER if r.has_point(mouse) else Visual.BORDA), 1)
				Visual.texto(self, Vector2(r.position.x, r.position.y + 21), Dados.SETORES_STARTUP[a["valor"]]["setor"], 12, Visual.TEXTO if sel else Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
			"forma":
				sel = form_startup["forma"] == a["valor"]
				Visual.caixa(self, r, Visual.CARTAO_CLARO, 10, Visual.DESTAQUE if sel else Visual.BORDA, 2 if sel else 1)
				Visual.forma(self, a["valor"], r.get_center(), 14.0, Visual.TEXTO_SUAVE if not sel else Visual.TEXTO)
			"cor", "cor2":
				sel = form_startup[a["campo"]] == a["valor"]
				draw_circle(r.get_center(), 13.0, Dados.CORES_LOGO[a["valor"]], true, -1.0, true)
				if sel:
					draw_arc(r.get_center(), 17.0, 0.0, TAU, 28, Visual.TEXTO, 2.0, true)
			"icone":
				sel = form_startup["icone"] == a["valor"]
				Visual.caixa(self, r, Visual.com_alfa(Visual.DESTAQUE, 0.18) if sel else Visual.CARTAO_CLARO, 8, Visual.DESTAQUE if sel else Visual.BORDA, 1)
				Visual.simbolo(self, a["valor"], r.get_center(), Visual.TEXTO if sel else Visual.TEXTO_SUAVE, 1.1)


func alvos_startup() -> Array:
	var lista: Array = []
	for i in Dados.SETORES_STARTUP.size():
		lista.append({"rect": Rect2(112 + i * 170, 242, 160, 34), "campo": "setor", "valor": i})
	for i in Dados.FORMAS_LOGO.size():
		lista.append({"rect": Rect2(112 + i * 56, 332, 48, 44), "campo": "forma", "valor": Dados.FORMAS_LOGO[i]})
	for i in Dados.CORES_LOGO.size():
		lista.append({"rect": Rect2(112 + i * 40, 402, 32, 32), "campo": "cor", "valor": i})
		lista.append({"rect": Rect2(112 + i * 40, 462, 32, 32), "campo": "cor2", "valor": i})
	for i in Dados.ICONES_LOGO.size():
		lista.append({"rect": Rect2(112 + (i % 9) * 52, 524 + (i / 9) * 50, 44, 44), "campo": "icone", "valor": Dados.ICONES_LOGO[i]})
	return lista


func botoes_startup() -> Array:
	if not estado().perfil.get("startup", {}).is_empty():
		return botoes_empresa("startup")
	var lista: Array = []
	for a in alvos_startup():
		lista.append({"rect": a["rect"], "rotulo": "", "acao": func(): form_startup[a["campo"]] = a["valor"], "ativo": true, "estilo": "invisivel"})
	var pode: bool = estado().dinheiro() >= Dados.CUSTO_STARTUP and campo_startup.text.strip_edges().length() >= 2
	lista.append(botao(Rect2(880, 600, 290, 52), "Fundar por %s" % Visual.dinheiro(Dados.CUSTO_STARTUP), fundar, pode, "principal"))
	return lista


func fundar() -> void:
	var nome := campo_startup.text.strip_edges()
	var erro: String = estado().criar_startup(nome, sigla_de(nome), form_startup["setor"], {"forma": form_startup["forma"], "cor": form_startup["cor"], "cor2": form_startup["cor2"], "icone": form_startup["icone"]})
	if erro != "":
		principal.avisar(erro, Visual.PERIGO)
		return
	principal.confete(Vector2(640, 200), 80)
	campo_startup.release_focus()


func desenhar_backup() -> void:
	cabecalho("Código de backup", "Leve seu progresso para outro aparelho sem precisar de servidor.")
	var codigo: String = estado().exportar_codigo()
	var caixa_codigo := Rect2(112, 150, 1056, 120)
	Visual.caixa(self, caixa_codigo, Color("050a12"), 12, Visual.BORDA, 1)
	var trecho := codigo.substr(0, 125) + "..." if codigo.length() > 125 else codigo
	Visual.texto_mono(self, caixa_codigo.position + Vector2(18, 36), trecho.substr(0, 128), 12, Color("93c5fd"), 7.8)
	Visual.texto(self, caixa_codigo.position + Vector2(18, 70), "%d caracteres  ·  contém seu personagem, dinheiro, empresas, missões e lições" % codigo.length(), 12, Visual.TEXTO_SUAVE)
	Visual.texto(self, caixa_codigo.position + Vector2(18, 96), "Guarde num lugar seguro e não publique: quem tiver o código tem uma cópia da sua conta.", 12, Visual.CREDITOS)
	Visual.texto(self, Vector2(112, 440), "Importar um código", 16, Visual.TEXTO)
	Visual.texto(self, Vector2(112, 540), "O código importado vira uma conta neste aparelho. Se for a mesma conta, ela é atualizada.", 12, Visual.TEXTO_SUAVE)


func botoes_backup() -> Array:
	return [
		botao(Rect2(112, 290, 240, 48), "Copiar código", copiar_codigo, true, "principal"),
		botao(Rect2(364, 290, 280, 48), "Baixar arquivo de backup", baixar_codigo),
		botao(Rect2(904, 470, 264, 44), "Importar código", importar_codigo, campo_codigo.text.strip_edges() != ""),
	]


func copiar_codigo() -> void:
	DisplayServer.clipboard_set(estado().exportar_codigo())
	principal.avisar("Código copiado! Cole num lugar seguro", Visual.HUMANO)


func baixar_codigo() -> void:
	var codigo: String = estado().exportar_codigo()
	var nome_arquivo := "ddos-defense-%s.txt" % String(estado().perfil["nome"]).to_lower().replace(" ", "-")
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(codigo.to_utf8_buffer(), nome_arquivo, "text/plain")
		principal.avisar("Download iniciado: %s" % nome_arquivo, Visual.HUMANO)
		return
	var caminho := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join(nome_arquivo)
	var arquivo := FileAccess.open(caminho, FileAccess.WRITE)
	if arquivo == null:
		caminho = "user://" + nome_arquivo
		arquivo = FileAccess.open(caminho, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(codigo)
		arquivo.close()
		principal.avisar("Backup salvo em %s" % ProjectSettings.globalize_path(caminho), Visual.HUMANO)


func importar_codigo() -> void:
	var id: String = estado().importar_codigo(campo_codigo.text)
	if id == "":
		principal.avisar("Código inválido. Ele começa com DDOS4:", Visual.PERIGO)
		return
	campo_codigo.text = ""
	if id == estado().id_ativo:
		estado().perfil = estado().perfis[id]
		principal.avisar("Conta atualizada com o código importado", Visual.HUMANO)
	else:
		principal.avisar("Conta %s importada. Ela aparece em Trocar de conta" % estado().perfis[id]["nome"], Visual.HUMANO)


func desenhar_politica() -> void:
	var y := 96.0
	for i in range(rolagem, mini(linhas_politica.size(), rolagem + 21)):
		var linha: Array = linhas_politica[i]
		Visual.texto(self, Vector2(120, y), linha[0], linha[1], linha[2])
		y += 24.0
