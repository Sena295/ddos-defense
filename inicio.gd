extends Node2D

const Dados := preload("res://dados.gd")
const Textos := preload("res://textos.gd")
const Visual := preload("res://visual.gd")
const Estado := preload("res://estado.gd")
const EditorAvatar := preload("res://editor_avatar.gd")

enum Tela { CARREGANDO, LOGIN, CADASTRO, AVATAR, PIN }

const TEMPO_CARREGANDO := 2.8

var principal
var tela := Tela.CARREGANDO
var tempo := 0.0
var tempo_carregando := 0.0
var mouse := Vector2.ZERO
var aceitou := false
var nome := ""
var perfil_pin := ""
var mostrar_importar := false
var editor := EditorAvatar.new()
var campo_nome: LineEdit
var campo_pin: LineEdit
var campo_pin_login: LineEdit
var campo_importar: LineEdit


func estado():
	return Estado.atual


func _ready() -> void:
	campo_nome = criar_campo("Seu apelido", 16, Vector2(370, 236), Vector2(400, 46), false)
	campo_pin = criar_campo("PIN de 4 números (opcional)", 4, Vector2(370, 336), Vector2(260, 46), true)
	campo_pin_login = criar_campo("PIN", 4, Vector2(540, 380), Vector2(200, 50), true)
	campo_importar = criar_campo("Cole o código DDOS4:...", 100000, Vector2(250, 596), Vector2(560, 44), false)
	campo_nome.text_changed.connect(func(t: String): nome = t.strip_edges())
	for campo in [campo_pin, campo_pin_login]:
		campo.text_changed.connect(filtrar_numeros.bind(campo))
	editor.origem = Vector2(130, 150)


func criar_campo(dica: String, maximo: int, pos: Vector2, tamanho: Vector2, secreto: bool) -> LineEdit:
	var campo := LineEdit.new()
	campo.placeholder_text = dica
	campo.max_length = maximo
	campo.position = pos
	campo.size = tamanho
	campo.secret = secreto
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
	campo.add_theme_font_size_override("font_size", 18)
	campo.add_theme_color_override("font_color", Visual.TEXTO)
	campo.add_theme_color_override("font_placeholder_color", Visual.TEXTO_SUAVE)
	campo.visible = false
	add_child(campo)
	return campo


func filtrar_numeros(texto: String, campo: LineEdit) -> void:
	var limpo := ""
	for ch in texto:
		if ch.is_valid_int():
			limpo += ch
	if limpo != texto:
		campo.text = limpo
		campo.caret_column = limpo.length()


func mostrar() -> void:
	visible = true
	tela = Tela.LOGIN if not estado().perfis.is_empty() else Tela.CADASTRO
	mostrar_importar = false
	campo_pin_login.text = ""


func _process(delta: float) -> void:
	if not visible:
		for campo in [campo_nome, campo_pin, campo_pin_login, campo_importar]:
			campo.visible = false
		return
	tempo += delta
	mouse = get_local_mouse_position()
	if tela == Tela.CARREGANDO:
		tempo_carregando += delta
		if tempo_carregando >= TEMPO_CARREGANDO:
			concluir_carregamento()
	var livre: bool = not principal.modal_aberto()
	campo_nome.visible = tela == Tela.CADASTRO and livre
	campo_pin.visible = tela == Tela.CADASTRO and livre
	campo_pin_login.visible = tela == Tela.PIN and livre
	campo_importar.visible = tela == Tela.LOGIN and mostrar_importar and livre
	queue_redraw()


func concluir_carregamento() -> void:
	if tela != Tela.CARREGANDO:
		return
	tela = Tela.LOGIN if not estado().perfis.is_empty() else Tela.CADASTRO


func _unhandled_input(event: InputEvent) -> void:
	if not visible or principal.modal_aberto():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var e := make_input_local(event) as InputEventMouseButton
		clicar(e.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if tela == Tela.CARREGANDO:
			concluir_carregamento()
		elif tela == Tela.PIN and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
			confirmar_pin()


func ids_ordenados() -> Array:
	var ids: Array = estado().perfis.keys()
	ids.sort()
	return ids


func retangulo_conta(indice: int) -> Rect2:
	return Rect2(120 + (indice % 3) * 352, 150 + (indice / 3) * 150, 336, 136)


func botoes() -> Array:
	var lista: Array = []
	match tela:
		Tela.LOGIN:
			var ids := ids_ordenados()
			for i in mini(ids.size(), 6):
				lista.append({"rect": retangulo_conta(i), "acao": escolher_conta.bind(ids[i]), "invisivel": true})
			lista.append({"rect": Rect2(120, 470, 336, 52), "rotulo": "Criar conta nova", "acao": nova_conta, "estilo": "principal", "ativo": ids.size() < 6})
			lista.append({"rect": Rect2(472, 470, 336, 52), "rotulo": "Importar código de backup", "acao": func(): mostrar_importar = not mostrar_importar})
			lista.append({"rect": Rect2(824, 470, 336, 52), "rotulo": "Política de privacidade", "acao": principal.abrir_painel.bind("politica", {})})
			if mostrar_importar:
				lista.append({"rect": Rect2(822, 596, 200, 44), "rotulo": "Importar", "acao": importar, "ativo": campo_importar.text.strip_edges() != ""})
		Tela.CADASTRO:
			lista.append({"rect": Rect2(780, 236, 130, 46), "rotulo": "Sortear", "acao": sortear_nome})
			lista.append({"rect": Rect2(366, 418, 420, 32), "acao": func(): aceitou = not aceitou, "invisivel": true})
			lista.append({"rect": Rect2(366, 456, 240, 28), "acao": principal.abrir_painel.bind("politica", {}), "invisivel": true})
			lista.append({"rect": Rect2(370, 564, 540, 52), "rotulo": "Continuar: criar personagem", "acao": ir_avatar, "estilo": "principal", "ativo": nome != "" and aceitou})
			if not estado().perfis.is_empty():
				lista.append({"rect": Rect2(370, 628, 540, 40), "rotulo": "Voltar para as contas", "acao": func(): tela = Tela.LOGIN})
		Tela.AVATAR:
			lista.append({"rect": Rect2(940, 620, 230, 52), "rotulo": "Começar a jogar", "acao": criar_conta, "estilo": "principal"})
			lista.append({"rect": Rect2(700, 620, 220, 52), "rotulo": "Voltar", "acao": func(): tela = Tela.CADASTRO})
		Tela.PIN:
			lista.append({"rect": Rect2(540, 450, 200, 50), "rotulo": "Entrar", "acao": confirmar_pin, "estilo": "principal"})
			lista.append({"rect": Rect2(540, 512, 200, 44), "rotulo": "Voltar", "acao": func(): tela = Tela.LOGIN})
	return lista


func clicar(pos: Vector2) -> void:
	if tela == Tela.CARREGANDO:
		if tempo_carregando > 0.3:
			concluir_carregamento()
		return
	if tela == Tela.AVATAR and editor.clicar(pos):
		return
	for b in botoes():
		if b["rect"].has_point(pos):
			if b.get("ativo", true):
				b["acao"].call()
			return


func escolher_conta(id: String) -> void:
	if estado().exige_pin(id):
		perfil_pin = id
		campo_pin_login.text = ""
		tela = Tela.PIN
		campo_pin_login.grab_focus()
		return
	if estado().entrar(id):
		principal.entrar_jogo(false)


func confirmar_pin() -> void:
	if estado().entrar(perfil_pin, campo_pin_login.text):
		campo_pin_login.release_focus()
		principal.entrar_jogo(false)
	else:
		principal.avisar("PIN incorreto", Visual.PERIGO)
		campo_pin_login.text = ""


func nova_conta() -> void:
	nome = ""
	aceitou = false
	campo_nome.text = ""
	campo_pin.text = ""
	editor.aparencia = {"pele": randi() % Dados.CORES_PELE.size(), "cabelo": randi() % Dados.ESTILOS_CABELO.size(), "cor_cabelo": randi() % 5, "roupa": randi() % 3, "cor_roupa": randi() % Dados.CORES_ROUPA.size(), "olhos": 0}
	tela = Tela.CADASTRO


func sortear_nome() -> void:
	nome = Dados.NOMES_ALEATORIOS[randi() % Dados.NOMES_ALEATORIOS.size()] + str(randi_range(10, 99))
	campo_nome.text = nome


func ir_avatar() -> void:
	if campo_pin.text != "" and campo_pin.text.length() != 4:
		principal.avisar("O PIN precisa ter exatamente 4 números (ou deixe em branco)", Visual.CREDITOS)
		return
	campo_nome.release_focus()
	campo_pin.release_focus()
	tela = Tela.AVATAR


func criar_conta() -> void:
	estado().criar_perfil(nome, campo_pin.text, editor.aparencia)
	estado().atualizar_sequencia()
	estado().salvar()
	principal.entrar_jogo(true)


func importar() -> void:
	var id: String = estado().importar_codigo(campo_importar.text)
	if id == "":
		principal.avisar("Código inválido. Ele começa com DDOS4:", Visual.PERIGO)
		return
	campo_importar.text = ""
	mostrar_importar = false
	principal.avisar("Conta %s importada!" % estado().perfis[id]["nome"], Visual.HUMANO)


func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(0, 0, 1280, 720), Visual.FUNDO)
	for x in range(0, 1281, 40):
		draw_line(Vector2(x, 0), Vector2(x, 720), Visual.GRADE, 1.0)
	for y in range(0, 721, 40):
		draw_line(Vector2(0, y), Vector2(1280, y), Visual.GRADE, 1.0)
	match tela:
		Tela.CARREGANDO:
			desenhar_carregando()
		Tela.LOGIN:
			desenhar_login()
		Tela.CADASTRO:
			desenhar_cadastro()
		Tela.AVATAR:
			Visual.texto(self, Vector2(130, 100), "Monte seu personagem", 30, Visual.TEXTO)
			Visual.texto(self, Vector2(130, 128), "Você pode mudar quando quiser no seu Perfil. Itens novos chegam pela Loja Tech.", 14, Visual.TEXTO_SUAVE)
			editor.desenhar(self, tempo, mouse)
		Tela.PIN:
			desenhar_pin()
	for b in botoes():
		if b.get("invisivel", false):
			continue
		var r: Rect2 = b["rect"]
		var principal_b: bool = b.get("estilo", "") == "principal"
		Visual.botao(self, r, b["rotulo"], Visual.PRINCIPAL if principal_b else Visual.DESTAQUE, r.has_point(mouse), b.get("ativo", true), 16, principal_b)


func desenhar_carregando() -> void:
	var progresso := clampf(tempo_carregando / TEMPO_CARREGANDO, 0.0, 1.0)
	var pulso := 1.0 + 0.06 * sin(tempo * 4.0)
	Visual.icone(self, "waf", Vector2(640, 220), Visual.DESTAQUE, 3.2 * pulso)
	Visual.texto(self, Vector2(0, 330), "DDoS Defense", 56, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Visual.texto(self, Vector2(0, 366), "Cidade Tech  ·  segurança, arquitetura e muito ataque hacker", 18, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	var barra := Rect2(440, 414, 400, 10)
	Visual.caixa(self, barra, Visual.LINHA, 5)
	Visual.caixa(self, Rect2(barra.position, Vector2(maxf(10.0, barra.size.x * ease(progresso, 0.6)), 10)), Visual.DESTAQUE, 5)
	var dica: String = Textos.DICAS_CARREGANDO[int(tempo / 0.6) % Textos.DICAS_CARREGANDO.size()]
	Visual.texto(self, Vector2(0, 456), dica, 15, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	draw_line(Vector2(340, 556), Vector2(940, 556), Visual.LINHA, 4.0, true)
	for k in 14:
		var x := 340.0 + fmod(tempo * 140.0 + k * 43.0, 600.0)
		var hacker := k % 4 == 1
		var bot := k % 3 == 0
		if ((bot or hacker) and x > 620.0) or (x > 616.0 and x < 664.0):
			continue
		if hacker:
			Visual.losango(self, Vector2(x, 556), 6.0, Color("a855f7"))
		else:
			draw_rect(Rect2(x - 4, 552, 8, 8), Visual.BOT if bot else Visual.HUMANO)
	Visual.caixa(self, Rect2(620, 532, 40, 48), Visual.CARTAO, 10, Visual.DESTAQUE, 1)
	Visual.icone(self, "waf", Vector2(640, 556), Visual.DESTAQUE, 0.9)
	Visual.avatar(self, Vector2(250, 600), 1.4, {"pele": 2, "cabelo": 2, "cor_cabelo": 6, "roupa": 0, "cor_roupa": 5, "olhos": 2}, {"roupa": "capuz", "acessorio": "headset"}, tempo, false)
	Visual.avatar(self, Vector2(1030, 600), 1.4, {"pele": 0, "cabelo": 4, "cor_cabelo": 3, "roupa": 1, "cor_roupa": 0, "olhos": 1}, {"acessorio": "oculos_hacker"}, tempo + 1.0, false)
	if tempo_carregando > 0.3:
		Visual.texto(self, Vector2(0, 690), "Toque para pular", 13, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, 1280)


func desenhar_login() -> void:
	Visual.icone(self, "waf", Vector2(140, 84), Visual.DESTAQUE, 1.6)
	Visual.texto(self, Vector2(170, 98), "DDoS Defense", 34, Visual.TEXTO)
	Visual.texto(self, Vector2(120, 134), "Escolha sua conta neste aparelho", 15, Visual.TEXTO_SUAVE)
	var ids := ids_ordenados()
	for i in mini(ids.size(), 6):
		var p: Dictionary = estado().perfis[ids[i]]
		var r := retangulo_conta(i)
		Visual.caixa(self, r, Visual.CARTAO, 16, Visual.DESTAQUE if r.has_point(mouse) else Visual.BORDA, 1, 10)
		Visual.palco(self, Rect2(r.position + Vector2(14, 14), Vector2(96, 108)), 12)
		Visual.avatar(self, r.position + Vector2(62, 116), 1.5, p.get("avatar", {}), p.get("equipados", {}), tempo + i, false)
		Visual.texto(self, r.position + Vector2(126, 42), p.get("nome", ""), 19, Visual.TEXTO)
		Visual.texto(self, r.position + Vector2(126, 66), Dados.NIVEIS[Dados.nivel_por_xp(int(p.get("xp", 0)))]["titulo"], 13, Visual.DESTAQUE)
		Visual.texto(self, r.position + Vector2(126, 92), Visual.dinheiro(float(p.get("dinheiro", 0.0))), 15, Visual.CREDITOS)
		if String(p.get("pin", "")) != "":
			Visual.cadeado(self, r.position + Vector2(r.size.x - 26, 30), Visual.TEXTO_SUAVE, 0.9)
		Visual.texto(self, r.position + Vector2(126, 116), "%d dia(s) de sequência" % int(p.get("sequencia", {}).get("dias", 0)), 11, Visual.TEXTO_SUAVE)
	if mostrar_importar:
		Visual.texto(self, Vector2(250, 584), "Código de backup", 13, Visual.TEXTO_SUAVE)
	Visual.texto(self, Vector2(0, 700), "Contas e progresso ficam salvos só neste aparelho. Empresas do jogo são fictícias.", 12, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, 1280)


func desenhar_cadastro() -> void:
	var cartao := Rect2(330, 90, 620, 590)
	Visual.caixa(self, cartao, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	Visual.texto(self, Vector2(370, 152), "Crie sua conta", 30, Visual.TEXTO)
	Visual.texto(self, Vector2(370, 182), "Leva 30 segundos. Nada sai do seu aparelho.", 15, Visual.TEXTO_SUAVE)
	Visual.texto(self, Vector2(370, 226), "Como quer ser chamado?", 15, Visual.TEXTO)
	Visual.texto(self, Vector2(370, 326), "Proteger a conta com PIN", 15, Visual.TEXTO)
	Visual.texto(self, Vector2(644, 366), "Útil se mais gente usa este aparelho", 12, Visual.TEXTO_SUAVE)
	var caixa_marcada := Rect2(370, 421, 26, 26)
	Visual.caixa(self, caixa_marcada, Visual.HUMANO if aceitou else Visual.CARTAO_CLARO, 6, Visual.BORDA_HOVER, 1)
	if aceitou:
		draw_polyline(PackedVector2Array([caixa_marcada.position + Vector2(6, 13), caixa_marcada.position + Vector2(11, 18), caixa_marcada.position + Vector2(20, 8)]), Visual.FUNDO, 2.5, true)
	Visual.texto(self, Vector2(408, 440), "Li e aceito a Política de Privacidade", 15, Visual.TEXTO)
	Visual.texto(self, Vector2(370, 476), "Ler a política de privacidade", 14, Visual.DESTAQUE)
	draw_line(Vector2(370, 480), Vector2(370 + Visual.largura_texto("Ler a política de privacidade", 14), 480), Visual.DESTAQUE, 1.0)
	Visual.caixa(self, Rect2(370, 496, 540, 56), Visual.CARTAO_CLARO, 10)
	Visual.paragrafo(self, Vector2(386, 518), "Não pedimos e-mail, telefone nem senha de outros serviços. O PIN fica guardado só como um código embaralhado (hash).", 13, Visual.TEXTO_SUAVE, 510)


func desenhar_pin() -> void:
	var p: Dictionary = estado().perfis.get(perfil_pin, {})
	var cartao := Rect2(440, 130, 400, 450)
	Visual.caixa(self, cartao, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	Visual.avatar(self, Vector2(640, 290), 2.0, p.get("avatar", {}), p.get("equipados", {}), tempo, false)
	Visual.texto(self, Vector2(cartao.position.x, 330), p.get("nome", ""), 22, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, cartao.size.x)
	Visual.texto(self, Vector2(cartao.position.x, 360), "Digite seu PIN", 14, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, cartao.size.x)
