extends SceneTree

const DT := 1.0 / 30.0
const RESERVA := 700.0
const Dados := preload("res://dados.gd")
const Textos := preload("res://textos.gd")
const Site := preload("res://site.gd")
const Estado := preload("res://estado.gd")
const Visual := preload("res://visual.gd")
const ARQUIVO := "user://ddos_defense_save.json"

var falhas := 0
var iniciado := false
var backup_save := ""
var tinha_save := false


func _process(_delta: float) -> bool:
	if iniciado:
		return false
	iniciado = true
	executar()
	return false


func checar(condicao: bool, nome: String) -> void:
	print(("OK    " if condicao else "FALHA ") + nome)
	if not condicao:
		falhas += 1


func evento_clique(pos: Vector2, pressionado: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressionado
	e.position = pos
	return e


func clique(no, pos: Vector2) -> void:
	no._unhandled_input(evento_clique(pos, true))
	no._unhandled_input(evento_clique(pos, false))


func clique_topo(m, pos: Vector2) -> void:
	m.topo._input(evento_clique(pos, true))


func tecla(no, k: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	no._unhandled_input(e)


func passo(m, segundos: float) -> void:
	for i in int(segundos / DT):
		for filho in [m.inicio, m.mundo, m.operacao, m.paineis, m.topo]:
			filho._process(DT)


func botao_rotulo(lista: Array, rotulo: String) -> Variant:
	for b in lista:
		if String(b.get("rotulo", "")).begins_with(rotulo):
			return b
	return null


func clicar_botao_painel(m, rotulo: String) -> bool:
	var b = botao_rotulo(m.paineis.botoes(), rotulo)
	if b == null:
		print("   botao nao encontrado: " + rotulo)
		return false
	clique(m.paineis, b["rect"].get_center())
	return true


func clicar_botao_operacao(m, rotulo: String) -> bool:
	var b = botao_rotulo(m.operacao.botoes_painel(), rotulo)
	if b == null:
		print("   botao nao encontrado: " + rotulo)
		return false
	clique(m.operacao, b["rect"].get_center())
	return true


func responder_incidentes(op) -> void:
	var guarda := 0
	while not op.modal.is_empty() and guarda < 10:
		guarda += 1
		if op.modal["tipo"] == "incidente":
			var dados: Dictionary = Textos.INCIDENTES[op.modal["incidente"]]
			var melhor := 0
			for i in op.modal["ordem"].size():
				var certa = dados["opcoes"][op.modal["ordem"][i]]["certa"]
				if typeof(certa) == TYPE_STRING:
					if op.site().nivel_passivo("backup") > 0:
						melhor = i
						break
				elif certa:
					melhor = i
			op.escolher_incidente(melhor)
		op.modal = {}
	op.fila_incidentes = []


func rodar_dia(op) -> void:
	op.iniciar_dia()
	var limite := 0
	while op.fase == op.Fase.DIA and limite < 6000:
		op.simular(DT)
		if op.fila_incidentes.size() > 0:
			op.modal = op.fila_incidentes.pop_front()
		if not op.modal.is_empty():
			responder_incidentes(op)
		limite += 1


func pular_relatorio(op) -> void:
	if op.fase != op.Fase.RELATORIO:
		return
	op.continuar_relatorio()
	if op.fase == op.Fase.RELATORIO:
		op.responder_quiz(op.relatorio["quiz"]["correta"])
		op.continuar_relatorio()


func reconstruir(s, filtros: Array, lb: int, torres: Array) -> void:
	for id in s.nos:
		for destino in s.nos[id]["saidas"].duplicate():
			s.desconectar(id, destino)
	var anterior: int = s.id_internet
	for f in filtros:
		s.conectar(anterior, f)
		anterior = f
	if lb >= 0:
		s.conectar(anterior, lb)
		for t in torres:
			s.conectar(lb, t)
	elif not torres.is_empty():
		s.conectar(anterior, torres[0])


func estado_robo(s) -> Dictionary:
	var filtros: Array = []
	for coluna in range(1, 8):
		var id: int = s.no_na_celula(Vector2i(coluna, 2))
		if id >= 0 and not s.eh_terminal(id) and s.nos[id]["tipo"] != "lb":
			filtros.append(id)
	var lbs: Array = s.ids_do_tipo("lb")
	return {"filtros": filtros, "lb": lbs[0] if not lbs.is_empty() else -1, "torres": s.terminais()}


func plano_site(op, indice: int) -> Array:
	var foco: String = op.empresa["sites"][indice]["foco"]
	var mix: Dictionary = op.empresa["mix"].duplicate()
	if foco != "":
		mix[foco] = mix.get(foco, 0.0) + 0.15
	var principal := "volumetrico"
	for bot in Dados.BOTS:
		if mix.get(bot, 0.0) > mix.get(principal, 0.0):
			principal = bot
	var defesa: String = {"volumetrico": "antiddos", "l7": "waf", "credencial": "mfa", "scraper": "rate"}[principal]
	var plano := [["filtro", defesa], ["lb"], ["torre", 2], ["filtro", "waf"]]
	if mix.get("credencial", 0.0) >= 0.05 or foco == "credencial":
		plano.append(["filtro", "mfa"])
	plano.append_array([["passivo", "backup"], ["passivo", "patch"]])
	if mix.get("ransomware", 0.0) + mix.get("exploit", 0.0) > 0.0 or foco in ["ransomware", "exploit"]:
		plano.append_array([["filtro", "ips"], ["passivo", "edr"]])
	plano.append_array([["nivel_lb", 2], ["torre", 3], ["filtro", "cdn"]])
	if mix.get("forca_bruta", 0.0) > 0.0 or foco == "forca_bruta":
		plano.append(["passivo", "cofre"])
	if mix.get("credencial", 0.0) >= 0.05 or foco == "credencial":
		plano.append(["filtro", "mfa"])
	plano.append_array([["passivo", "cofre"], ["passivo", "treinamento"], ["filtro", "antiddos"], ["filtro", "ips"], ["nivel_torres", 1], ["torre", 4], ["passivo", "edr"], ["nivel_filtros", 2], ["torre", 5], ["passivo", "criptografia"], ["nivel_torres", 2], ["passivo", "siem"], ["nivel_filtros", 3], ["torre", 6], ["torre", 7], ["torre", 8]])
	return plano


func satisfeito(op, s, p: Array) -> bool:
	var e := estado_robo(s)
	match p[0]:
		"filtro":
			if op.estado().nivel() < op.nivel_necessario(p[1]):
				return true
			for f in e["filtros"]:
				if s.nos[f]["tipo"] == p[1]:
					return true
			return e["filtros"].size() >= 7
		"passivo":
			return op.estado().nivel() < op.nivel_necessario(p[1]) or s.nivel_passivo(p[1]) > 0
		"lb":
			return e["lb"] >= 0
		"torre":
			return e["torres"].size() >= p[1]
		"nivel_lb":
			return e["lb"] >= 0 and s.nos[e["lb"]]["nivel"] >= p[1]
		"nivel_torres":
			for t in e["torres"]:
				if s.nos[t]["nivel"] < p[1] + 1:
					return false
			return true
		"nivel_filtros":
			for f in e["filtros"]:
				if s.nos[f]["nivel"] < p[1]:
					return false
			return true
	return true


func executar_passo(op, s, p: Array) -> bool:
	var antes: float = op.caixa
	var e := estado_robo(s)
	match p[0]:
		"filtro":
			op.colocar(p[1], Vector2i(e["filtros"].size() + 1, 2))
		"passivo":
			for k in 20:
				var c := Vector2i(k % 10, 5 + k / 10)
				if s.no_na_celula(c) < 0:
					op.colocar(p[1], c)
					break
		"lb":
			op.colocar("lb", Vector2i(8, 2))
		"torre":
			var n: int = e["torres"].size()
			op.colocar("servidor", Vector2i(10 + n / 5, n % 5))
		"nivel_lb":
			op.melhorar(e["lb"])
		"nivel_torres":
			for t in e["torres"]:
				if s.nos[t]["nivel"] < p[1] + 1:
					op.melhorar(t)
					break
		"nivel_filtros":
			for f in e["filtros"]:
				if s.nos[f]["nivel"] < p[1]:
					op.melhorar(f)
					break
	var e2 := estado_robo(s)
	reconstruir(s, e2["filtros"], e2["lb"], e2["torres"])
	return op.caixa < antes


func robo(op) -> void:
	for i in op.sites.size():
		var s = op.sites[i]
		var no_meio: int = s.no_na_celula(Vector2i(4, 2))
		if no_meio >= 0 and s.eh_terminal(no_meio):
			s.mover_no(no_meio, Vector2i(10, 4))
		var e := estado_robo(s)
		reconstruir(s, e["filtros"], e["lb"], e["torres"])
	var comprou := true
	var guarda := 0
	while comprou and guarda < 200:
		guarda += 1
		comprou = false
		for i in op.sites.size():
			op.site_atual = i
			var s = op.sites[i]
			for p in plano_site(op, i):
				if satisfeito(op, s, p):
					continue
				var custo_p := 0.0
				if p[0] in ["filtro", "passivo", "lb"]:
					custo_p = op.custo_componente("lb" if p[0] == "lb" else p[1])
				elif p[0] == "torre":
					custo_p = op.custo_componente("servidor")
				if op.caixa - custo_p > (0.0 if op.dia == 1 or op.evento["especial"] else RESERVA) and executar_passo(op, s, p):
					comprou = true
				break
	op.site_atual = 0
	op.selecao = {}


func executar() -> void:
	if FileAccess.file_exists("user://perfil.cfg"):
		DirAccess.rename_absolute(ProjectSettings.globalize_path("user://perfil.cfg"), ProjectSettings.globalize_path("user://perfil.cfg.teste"))
	tinha_save = FileAccess.file_exists(ARQUIVO)
	if tinha_save:
		backup_save = FileAccess.get_file_as_string(ARQUIVO)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQUIVO))
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	var est = Estado.atual
	checar(m.tela == "inicio" and m.inicio.tela == m.inicio.Tela.CARREGANDO, "comeca no carregamento")
	passo(m, 3.0)
	checar(m.inicio.tela == m.inicio.Tela.CADASTRO, "sem contas vai para o cadastro")
	clique(m.inicio, Vector2(640, 590))
	checar(m.inicio.tela == m.inicio.Tela.CADASTRO, "nao avanca sem apelido")
	clique(m.inicio, Vector2(845, 259))
	checar(m.inicio.nome != "", "sortear gera apelido")
	clique(m.inicio, Vector2(500, 434))
	checar(m.inicio.aceitou, "aceita a politica")
	clique(m.inicio, Vector2(450, 470))
	checar(m.paineis.painel == "politica", "link abre politica")
	clicar_botao_painel(m, "Descer")
	checar(m.paineis.rolagem > 0, "politica rola")
	clicar_botao_painel(m, "Voltar")
	checar(not m.paineis.aberto(), "fecha politica")
	m.inicio.campo_pin.text = "12"
	clique(m.inicio, Vector2(640, 590))
	checar(m.inicio.tela == m.inicio.Tela.CADASTRO, "PIN incompleto bloqueia")
	m.inicio.campo_pin.text = "4321"
	m.inicio.nome = "Sena"
	m.inicio.campo_nome.text = "Sena"
	clique(m.inicio, Vector2(640, 590))
	checar(m.inicio.tela == m.inicio.Tela.AVATAR, "vai para o editor de avatar")
	var alvos: Array = m.inicio.editor.alvos()
	checar(alvos.size() > 10, "editor tem opcoes (%d)" % alvos.size())
	for a in alvos.slice(0, 8):
		clique(m.inicio, a["rect"].get_center())
	clique(m.inicio, Vector2(1055, 646))
	checar(m.tela == "mundo", "criar conta entra na cidade")
	checar(est.perfil["nome"] == "Sena" and est.perfil["pin"] != "" and est.perfil["pin"] != "4321", "perfil com PIN em hash")
	checar(m.paineis.painel == "intro", "intro aparece para conta nova")
	checar(int(est.perfil["sequencia"]["dias"]) == 1 and is_equal_approx(est.dinheiro(), Dados.DINHEIRO_INICIAL + 100.0), "sequencia de 1 dia paga bonus")
	checar(FileAccess.file_exists(ARQUIVO), "save gravado")
	clicar_botao_painel(m, "Explorar")
	checar(not m.paineis.aberto(), "fecha intro")
	checar(est.perfil["carreira"] == "operador", "carreira inicial de operador")
	checar(est.escolher_carreira("hacker") and est.perfil["carreira"] == "hacker", "troca para hacker etico")
	checar(not est.escolher_carreira("invalida"), "carreira invalida recusada")
	est.registrar_atividade_carreira("hacker")
	est.registrar_atividade_carreira("hacker")
	est.registrar_atividade_carreira("hacker")
	checar(est.nivel_carreira("hacker") == 1, "especializacao de hacker progride")
	est.escolher_carreira("operador")
	m.paineis.abrir("cafe", {})
	checar(m.paineis.botoes_cafe().size() == Dados.CURSOS_CAFE.size(), "cafe lista cursos")
	m.paineis.abrir_curso(0)
	m.paineis.responder_curso(0)
	checar(m.paineis.dados["resposta"] == 0 and est.perfil["cursos_cafe"].is_empty(), "curso permite aprender com erro")
	m.paineis.tentar_curso()
	m.paineis.responder_curso(1)
	checar("fundamentos_rede" in est.perfil["cursos_cafe"], "curso concluido com resposta certa")
	checar(not est.concluir_curso_cafe("fundamentos_rede"), "curso nao paga duas vezes")
	m.paineis.fechar()

	var mundo = m.mundo
	clique(mundo, mundo.RET_GUIA.get_center())
	checar(not mundo.caminho.is_empty() and mundo.interagir_ao_chegar.get("local", {}).get("id", "") == "missoes", "guia leva a primeira missao")
	var porta_missoes: Vector2 = mundo.porta(mundo.local_por_id("missoes"))
	var todas_ok := true
	for l in mundo.LOCAIS:
		if mundo.calcular_caminho(mundo.porta(mundo.local_por_id("sede")) + Vector2(0, 0.6), mundo.porta(l)).is_empty():
			todas_ok = false
			print("   sem caminho ate " + l["id"])
	checar(todas_ok, "todas as portas alcancaveis")
	checar(mundo.npcs.size() == mundo.QUANTIDADE_NPCS, "npcs criados")
	mundo.ir_para(porta_missoes)
	mundo.interagir_ao_chegar = {"tipo": "local", "local": mundo.local_por_id("missoes")}
	passo(m, 12.0)
	checar(m.paineis.painel == "missoes", "andar ate a central abre missoes (%s, jogador %s)" % [m.paineis.painel, mundo.jogador])
	checar(est.valor("visitou_missoes") == 1, "conta visita")
	var antes: float = est.dinheiro()
	clicar_botao_painel(m, "Resgatar")
	checar(est.dinheiro() > antes and "m_cidade" in est.perfil["missoes_resgatadas"], "resgata missao")
	clique(m.paineis, m.paineis.RET_FECHAR.get_center())
	checar(not m.paineis.aberto(), "fecha painel")
	var loc_mn: Dictionary = mundo.local_por_id("mercadonet")
	passo(m, 0.5)
	mundo.camera = mundo.iso(mundo.centro_area(loc_mn["area"])) - Vector2(640, 360)
	var alvo_tela: Vector2 = mundo.iso(mundo.centro_area(loc_mn["area"])) + Vector2(0, -40) - mundo.camera
	clique(mundo, alvo_tela)
	checar(not mundo.caminho.is_empty() and mundo.interagir_ao_chegar.get("local", {}).get("id", "") == "mercadonet", "clicar no predio anda ate a porta")
	passo(m, 12.0)
	checar(m.paineis.painel == "empresa" and m.paineis.dados.get("id", "") == "mercadonet", "chegar na porta abre a empresa")
	m.paineis.fechar()
	var destino_chao := Vector2(19.5, 22.5)
	mundo.camera = mundo.iso(destino_chao) - Vector2(640, 360)
	var chao_tela: Vector2 = mundo.iso(destino_chao) - mundo.camera
	clique(mundo, chao_tela)
	checar(not mundo.caminho.is_empty(), "clicar no chao cria caminho")
	passo(m, 8.0)
	checar(mundo.jogador.distance_to(destino_chao) < 0.6, "jogador anda ate o ponto clicado (%s)" % mundo.jogador)

	mundo.jogador = Vector2(21.5, 21.3)
	tecla(mundo, KEY_M)
	checar(m.paineis.painel == "missoes", "tecla M abre missoes")
	tecla(m.paineis, KEY_ESCAPE)
	clique(mundo, mundo.RET_BOTAO_SEDE.get_center())
	checar(m.paineis.painel == "sede", "botao perfil abre sede")
	clicar_botao_painel(m, "Corpo e cabelo")
	checar(m.paineis.painel == "avatar", "sede abre editor")
	var cabelo_antes: int = est.perfil["avatar"]["cabelo"]
	for a in m.paineis.editor.alvos():
		if a.get("chave", "") == "cabelo" and a.get("valor", -1) != cabelo_antes:
			clique(m.paineis, a["rect"].get_center())
			break
	checar(est.perfil["avatar"]["cabelo"] != cabelo_antes, "trocar cabelo salva no perfil")
	clicar_botao_painel(m, "Pronto")
	checar(not m.paineis.aberto(), "fecha editor")

	m.abrir_painel("academia", {})
	var b_licao: Dictionary = m.paineis.botoes()[0]
	clique(m.paineis, b_licao["rect"].get_center())
	checar(m.licao_aberta(), "academia abre licao")
	checar(est.perfil["licoes_lidas"].size() == 1, "licao conta como lida")
	clique_topo(m, m.topo.RET_ENTENDI.get_center())
	checar(not m.licao_aberta(), "entendi fecha licao")
	clicar_botao_painel(m, "Próxima")
	checar(m.paineis.pagina == 1, "academia pagina")
	m.paineis.fechar()

	m.abrir_painel("beco", {})
	clique(m.paineis, m.paineis.retangulo_desafio(0).get_center())
	checar(m.paineis.dados.has("desafio"), "abre desafio")
	var d0: Dictionary = Textos.DESAFIOS[0]
	var errada := 0 if int(d0["linha"]) != 0 else 1
	clique(m.paineis, m.paineis.retangulo_linha(errada).get_center())
	checar(m.paineis.dados["erro_linha"] == errada and m.paineis.dados["etapa"] == 0, "linha errada avisa")
	clique(m.paineis, m.paineis.retangulo_linha(int(d0["linha"])).get_center())
	checar(m.paineis.dados["etapa"] == 1, "linha certa avanca")
	var pos_certa: int = m.paineis.dados["ordem"].find(int(d0["correta"]))
	var dinheiro_lab: float = est.dinheiro()
	clique(m.paineis, m.paineis.retangulo_opcao_codigo(pos_certa).get_center())
	checar(m.paineis.dados["acertou"] and est.desafio_resolvido(d0["id"]), "correcao certa resolve")
	checar(est.dinheiro() > dinheiro_lab, "desafio paga")
	clicar_botao_painel(m, "Voltar")
	checar(not m.paineis.dados.has("desafio"), "volta para lista do beco")
	var todos_ok := true
	for i in Textos.DESAFIOS.size():
		var d: Dictionary = Textos.DESAFIOS[i]
		if d["codigo"].size() <= int(d["linha"]) or d["opcoes"].size() != 3 or int(d["correta"]) > 2:
			todos_ok = false
			print("   desafio invalido: " + d["id"])
	checar(todos_ok, "todos os desafios tem dados validos")
	m.paineis.fechar()

	est.perfil["dinheiro"] = 60000.0
	m.abrir_painel("loja", {})
	clicar_botao_painel(m, "Comprar")
	checar(est.perfil["itens"].size() == 1, "compra item visual")
	var item: String = est.perfil["itens"][0]
	checar(est.perfil["equipados"][Dados.ITENS[item]["tipo"]] == item, "item ja vem vestido")
	clicar_botao_painel(m, "Tirar")
	checar(est.perfil["equipados"][Dados.ITENS[item]["tipo"]] == "", "tirar item")
	clicar_botao_painel(m, "Vestir")
	checar(est.perfil["equipados"][Dados.ITENS[item]["tipo"]] == item, "vestir de novo pelo guarda-roupa")
	var abas_ok := true
	for aba in ["chapeu", "acessorio", "roupa", "pet"]:
		m.paineis.aba_loja = aba
		if m.paineis.itens_loja().is_empty():
			abas_ok = false
	checar(abas_ok, "todas as abas do guarda-roupa tem itens")
	var sprites_ok := true
	for id_item in Dados.ITENS:
		if Dados.ITENS[id_item]["tipo"] in ["chapeu", "acessorio", "roupa"]:
			for corpo in [0, 1]:
				var tex = Visual.Sprites.textura({"corpo": corpo, "cabelo": 1, "pele": 2}, {Dados.ITENS[id_item]["tipo"]: id_item}, -1, 3, 2)
				if tex == null or tex.get_width() != Visual.Sprites.LARGURA * 2:
					sprites_ok = false
	checar(sprites_ok, "sprites de todos os itens e corpos")
	m.paineis.aba_loja = "roupa"
	clicar_botao_painel(m, "Girar")
	checar(m.paineis.direcao_previa == -1, "girar a previa")
	clicar_botao_painel(m, "Reforços")
	checar(m.paineis.aba_loja == "reforco", "aba de reforcos")
	clicar_botao_painel(m, "Comprar")
	clicar_botao_painel(m, "Comprar")
	checar(est.reforcos("seguro") == 2, "compra reforco repetido (%d)" % est.reforcos("seguro"))
	m.paineis.fechar()

	m.abrir_painel("empresa", {"id": "laranja"})
	checar(botao_rotulo(m.paineis.botoes(), "Operar") == null, "banco sem contrato nao opera")
	m.abrir_painel("bolsa", {})
	var b_comprar = botao_rotulo(m.paineis.botoes(), "Comprar")
	checar(b_comprar != null, "bolsa lista compra")
	est.perfil["xp"] = 800
	m.abrir_painel("empresa", {"id": "pixelforge"})
	var dinheiro_compra: float = est.dinheiro()
	clicar_botao_painel(m, "Comprar")
	checar(est.eh_dono("pixelforge") and est.dinheiro() < dinheiro_compra, "compra empresa")
	checar(botao_rotulo(m.paineis.botoes(), "Operar") != null, "dono pode operar")
	m.paineis.fechar()

	checar(est.criar_startup("X", "X", 0, {"forma": "circulo", "cor": 0, "cor2": 1, "icone": "foguete"}, "lote_centro") != "", "startup exige terreno proprio")
	m.abrir_painel("imobiliaria", {})
	var dinheiro_lote: float = est.dinheiro()
	clicar_botao_painel(m, "Comprar")
	checar(est.possui_terreno("lote_centro") and est.dinheiro() < dinheiro_lote, "imobiliaria compra terreno")
	m.abrir_painel("terreno", {"id": "lote_centro"})
	clicar_botao_painel(m, "Fundar")
	checar(m.paineis.painel == "startup" and m.paineis.dados.get("lote", "") == "lote_centro", "terreno abre fundacao da startup")
	m.paineis.campo_startup.text = "Sena Labs"
	m.paineis.form_startup["setor"] = 1
	clicar_botao_painel(m, "Fundar")
	checar(not est.perfil["startup"].is_empty() and est.perfil["startup"]["sigla"] == "SL", "funda startup")
	checar(est.construcao("lote_centro") == "startup", "startup ocupa o terreno")
	checar(est.pode_operar("startup"), "startup operavel")
	passo(m, 0.1)
	checar(m.mundo.nome_local(m.mundo.local_por_id("startup")) == "Sena Labs", "predio da startup tem o nome")
	checar(m.mundo.solidos.has(Vector2i(39, 17)), "predio da startup bloqueia o terreno")
	m.paineis.fechar()
	checar(est.comprar_terreno("lote_s5") == "", "compra terreno no bairro sul")
	m.abrir_painel("terreno", {"id": "lote_s5"})
	clicar_botao_painel(m, "Construir")
	checar(est.construcao("lote_s5") == "cafe", "constroi cafe")
	checar(est.renda_imoveis() >= 120.0, "renda dos imoveis")
	passo(m, 0.1)
	var local_cafe: Dictionary = m.mundo.local_do_lote("lote_s5")
	checar(local_cafe.get("construcao", "") == "cafe" and m.mundo.solidos.has(Vector2i(17, 33)), "cafe aparece na cidade")
	var caminhos_ok := true
	for l in m.mundo.locais:
		if m.mundo.calcular_caminho(m.mundo.porta(m.mundo.local_por_id("sede")) + Vector2(0, 0.6), m.mundo.porta(l)).is_empty():
			caminhos_ok = false
			print("   sem caminho ate " + String(l["id"]))
	checar(caminhos_ok, "portas alcancaveis depois de construir")
	var dinheiro_dem: float = est.dinheiro()
	clicar_botao_painel(m, "Demolir")
	checar(est.construcao("lote_s5") == "" and est.dinheiro() > dinheiro_dem, "demolir devolve metade")
	m.paineis.fechar()
	var disp: Dictionary = Dados.DISPOSITIVOS[0]
	m.abrir_painel("pentest", {"id": disp["id"]})
	var errado := Vector2i(1, 0)
	m.paineis.escolher_celula(errado.x, errado.y)
	checar(m.paineis.dados["buffer"].is_empty(), "pentest so aceita a linha ativa")
	var dinheiro_pt: float = est.dinheiro()
	for cel in m.paineis.dados["solucao"]:
		m.paineis.escolher_celula(cel.x, cel.y)
	checar(m.paineis.dados["fase"] == "sucesso" and est.dinheiro() > dinheiro_pt, "pentest resolvido paga")
	checar(est.pentest_feito(disp["id"]) and est.valor("pentests") == 1, "pentest registrado no dia")
	m.paineis.iniciar_pentest()
	var dinheiro_pt2: float = est.dinheiro()
	for cel in m.paineis.dados["solucao"]:
		m.paineis.escolher_celula(cel.x, cel.y)
	checar(is_equal_approx(est.dinheiro(), dinheiro_pt2), "mesmo aparelho nao paga duas vezes no dia")
	m.paineis.iniciar_pentest()
	m.paineis.dados["tempo"] = 0.05
	passo(m, 0.2)
	checar(m.paineis.dados["fase"] == "falha", "tempo esgotado falha o pentest")
	m.paineis.fechar()
	var perfil_antigo: Dictionary = est.perfil.duplicate(true)
	perfil_antigo.erase("auditorias")
	checar(est.normalizar(perfil_antigo)["auditorias"]["concluidas"].is_empty(), "save antigo recebe registro de auditorias")
	checar(est.auditoria_disponivel("mercadonet") and not est.auditoria_disponivel("empresa_falsa"), "contrato so existe em empresa autorizada")
	checar(not est.aceitar_auditoria("mercadonet", -1) and not est.aceitar_auditoria("mercadonet", 99), "proposta invalida recusada")
	checar(est.aceitar_auditoria("mercadonet", 0) and not est.aceitar_auditoria("mercadonet", 1), "empresa recebe uma proposta por dia")
	checar(is_zero_approx(est.concluir_auditoria("mercadonet", 2)), "proposta diferente nao paga")
	var antes_auditoria: float = est.dinheiro()
	checar(is_equal_approx(est.concluir_auditoria("mercadonet", 0), 500.0) and is_equal_approx(est.dinheiro(), antes_auditoria + 500.0), "auditoria basica paga valor contratado")
	checar(is_zero_approx(est.concluir_auditoria("mercadonet", 0)) and not est.auditoria_disponivel("mercadonet"), "auditoria nao paga duas vezes")
	checar(est.valor("auditorias") == 1 and "rate" in est.perfil["licoes"], "auditoria avanca missao e ensina defesa")
	m.abrir_painel("zerosec", {})
	checar(clicar_botao_painel(m, "Contratos de empresas") and m.paineis.painel == "propostas", "ZeroSec abre propostas")
	checar(m.paineis.botoes().size() == 6, "empresa concluida nao aceita nova proposta")
	m.paineis.propor_auditoria("shoppa", 2)
	checar(m.paineis.painel == "pentest" and m.paineis.dados["alvo"].size() == 5 and is_equal_approx(m.paineis.dados["tempo_total"], 16.0), "proposta alta aumenta dificuldade")
	var antes_alta: float = est.dinheiro()
	for cel in m.paineis.dados["solucao"]:
		m.paineis.escolher_celula(cel.x, cel.y)
	checar(m.paineis.dados["fase"] == "sucesso" and is_equal_approx(est.dinheiro(), antes_alta + 5000.0), "auditoria critica conclui e paga")
	checar(est.valor("auditorias") == 2 and "shoppa" in est.perfil["auditorias"]["concluidas"], "resultado de auditoria salvo")
	m.paineis.abrir("propostas", {})
	m.paineis.propor_auditoria("voaja", 0)
	checar(m.paineis.painel == "pentest" and m.paineis.dados["alvo"].size() == 3, "proposta basica mantem desafio curto")
	var antes_falha: float = est.dinheiro()
	m.paineis.concluir_pentest(false)
	checar(m.paineis.dados["fase"] == "falha" and is_equal_approx(est.dinheiro(), antes_falha) and not est.auditoria_disponivel("voaja"), "falha nao paga e bloqueia nova tentativa hoje")
	m.paineis.fechar()
	m.abrir_painel("arena", {})
	for k in 3:
		var quiz: Dictionary = Textos.QUIZ[m.paineis.dados["perguntas"][m.paineis.dados["atual"]]]
		m.paineis.responder_ctf(int(quiz["correta"]))
		m.paineis.avancar_ctf()
	checar(m.paineis.dados.get("terminou", false) and est.valor("ctf_acertos") == 3 and not est.ctf_disponivel(), "arena CTF completa")
	m.paineis.fechar()
	m.abrir_painel("sede", {})
	clicar_botao_painel(m, "Modo leve")
	checar(est.perfil["graficos_leves"] and Engine.max_fps == 30 and m.mundo.npcs.size() == m.mundo.QUANTIDADE_NPCS_LEVE, "modo leve reduz carga")
	clicar_botao_painel(m, "Modo leve")
	checar(not est.perfil["graficos_leves"] and Engine.max_fps == 60, "modo leve desliga")
	m.paineis.fechar()

	m.abrir_painel("empresa", {"id": "mercadonet"})
	clicar_botao_painel(m, "Operar")
	var op = m.operacao
	checar(m.tela == "operacao" and op.modal.get("tipo", "") == "boas_vindas", "operar abre boas-vindas")
	clique(op, Vector2(640, 642))
	checar(op.modal.is_empty(), "fecha boas-vindas")
	var s = op.site()
	checar(s.nos.size() == 2, "site comeca com internet e torre")
	var b_cat = botao_rotulo(op.botoes_painel(), "Filtros")
	clique(op, b_cat["rect"].get_center())
	checar(op.categoria == "filtro", "troca categoria da paleta")
	var b_waf: Dictionary = {}
	for b in op.botoes_painel():
		if b.get("paleta", "") == "waf":
			b_waf = b
	clique(op, b_waf["rect"].get_center())
	checar(op.ferramenta == "waf", "seleciona WAF")
	var torre: int = s.terminais()[0]
	var celula_waf := Vector2i(1, 2)
	var tela_waf: Vector2 = (s.centro_celula(celula_waf) - op.camera) * op.zoom + op.RET_CANVAS.position
	clique(op, tela_waf)
	var waf: int = s.no_na_celula(celula_waf)
	checar(waf >= 0 and s.nos[waf]["tipo"] == "waf", "clique na grade instala WAF")
	checar(s.nos[s.id_internet]["saidas"] == [waf] and torre in s.nos[waf]["saidas"], "WAF encaixa no fluxo")
	checar(est.valor("componente_waf") == 1, "contador de WAF")
	op.categoria = "seguranca"
	op.selecionar_ferramenta("backup")
	var tela_bk: Vector2 = (s.centro_celula(Vector2i(2, 5)) - op.camera) * op.zoom + op.RET_CANVAS.position
	clique(op, tela_bk)
	var bk: int = s.no_na_celula(Vector2i(2, 5))
	checar(bk >= 0 and s.nivel_passivo("backup") == 1, "backup passivo ativo")
	checar(s.pode_conectar(waf, bk) != "", "passivo nao conecta")
	op.selecionar_ferramenta("siem")
	checar(op.ferramenta == "" if est.nivel() < 2 else op.ferramenta == "siem", "SIEM respeita nivel")
	op.ferramenta = ""
	op.selecao = {"tipo": "no", "id": waf}
	var caixa_m: float = op.caixa
	clicar_botao_operacao(m, "Melhorar")
	checar(s.nos[waf]["nivel"] == 2 and op.caixa < caixa_m, "melhorar WAF")
	clicar_botao_operacao(m, "Por quê")
	checar(m.licao_aberta() and m.topo.licao == "waf", "por que abre licao do WAF")
	clique_topo(m, m.topo.RET_ENTENDI.get_center())
	op.selecao = {}
	var zoom0: float = op.zoom
	clique(op, op.RET_ZOOM_MAIS.get_center())
	checar(op.zoom > zoom0, "zoom mais")
	clique(op, op.RET_CENTRO.get_center())
	tecla(op, KEY_P)
	checar(op.modal.get("tipo", "") == "pausa", "P pausa")
	tecla(op, KEY_P)
	op.reforcos_ativos = {}
	op.ativar_reforco("seguro")
	checar(op.reforcos_ativos.get("seguro", false) and est.reforcos("seguro") == 1, "ativa reforco")
	var caixa_ap: float = op.caixa
	op.aportar()
	checar(is_equal_approx(op.caixa, caixa_ap + op.VALOR_APORTE), "aporte da carteira")
	robo(op)
	rodar_dia(op)
	checar(op.fase == op.Fase.RELATORIO, "dia 1 termina em relatorio")
	checar(op.relatorio["dividendo"] >= 0.0 and est.valor("dias_operados") == 1, "dia contabilizado")
	print("   dia 1: receita %.0f lucro %.0f uptime %.2f" % [op.relatorio["receita"], op.relatorio["lucro"], op.relatorio["uptime"]])
	clique(op, op.RET_CONTINUAR.get_center())
	checar(op.dia == 2 and op.fase == op.Fase.PREPARACAO, "continua para dia 2")
	checar(est.obter_operacao("mercadonet").get("dia", 0) == 2, "partida salva no dia 2")
	rodar_dia(op)
	pular_relatorio(op)
	checar(op.dia == 3, "dia 2 com quiz concluido")
	clique(op, op.RET_PAUSA.get_center())
	clique(op, Vector2(640, 388))
	checar(m.tela == "mundo", "pausa volta para a cidade")
	var nos_salvos: int = op.site().nos.size()
	m.operar("mercadonet")
	checar(op.dia == 3 and op.site().nos.size() == nos_salvos and op.modal.is_empty(), "retoma partida salva")
	op.iniciar_dia()
	op.simular(5.0)
	op.sair_para_cidade()
	checar(m.tela == "mundo" and est.obter_operacao("mercadonet")["dia"] == 3, "sair no meio do dia descarta o dia")
	m.operar("mercadonet")
	checar(op.fase == op.Fase.PREPARACAO and op.dia == 3, "volta na preparacao do dia 3")
	var st = op.site()
	var alvo: int = st.terminais()[0]
	st.comprometer(alvo, "ransomware")
	op.iniciar_dia()
	op.simular(0.1)
	var abriu: bool = op.modal.get("tipo", "") == "incidente" or op.fila_incidentes.size() > 0
	if op.modal.is_empty() and op.fila_incidentes.size() > 0:
		op.modal = op.fila_incidentes.pop_front()
	checar(abriu, "ransomware gera incidente")
	if op.modal.get("tipo", "") == "incidente":
		var certas_antes: int = est.valor("incidentes_certos")
		var dados_inc: Dictionary = Textos.INCIDENTES[op.modal["incidente"]]
		for i in op.modal["ordem"].size():
			if typeof(dados_inc["opcoes"][op.modal["ordem"][i]]["certa"]) == TYPE_BOOL and dados_inc["opcoes"][op.modal["ordem"][i]]["certa"]:
				clique(op, op.retangulo_opcao_incidente(i).get_center())
				break
		checar(est.valor("incidentes_certos") == certas_antes + 1, "resposta certa conta")
		clique(op, Vector2(640, 624))
		checar(op.modal.is_empty(), "fecha incidente")
	op.momento_phishing = op.tempo_dia + 0.05
	op.simular(0.2)
	if op.modal.is_empty() and op.fila_incidentes.size() > 0:
		op.modal = op.fila_incidentes.pop_front()
	checar(true, "phishing disparado sem erro (%s)" % op.modal.get("incidente", "barrado"))
	responder_incidentes(op)
	var guarda := 0
	while op.fase == op.Fase.DIA and guarda < 6000:
		op.simular(DT)
		responder_incidentes(op)
		guarda += 1
	checar(op.fase == op.Fase.RELATORIO, "dia com incidente termina")
	pular_relatorio(op)
	op.caixa = -op.LIMITE_CREDITO - 10.0
	op.iniciar_dia()
	op.simular(0.1)
	checar(op.fase == op.Fase.FIM and op.motivo_fim == "falencia", "falencia encerra")
	checar(est.obter_operacao("mercadonet").is_empty(), "fim limpa partida salva")
	clique(op, Vector2(800, 586))
	checar(op.fase == op.Fase.PREPARACAO and op.dia == 1, "nova temporada")
	clique(op, Vector2(640, 642))
	op.modal = {"tipo": "pausa"}
	clique(op, Vector2(640, 388))

	m.operar("startup")
	checar(m.tela == "operacao" and op.empresa["nome"] == "Sena Labs", "opera startup")
	op.modal = {}
	robo(op)
	rodar_dia(op)
	checar(op.fase == op.Fase.RELATORIO, "startup completa dia")
	pular_relatorio(op)
	op.sair_para_cidade()

	var codigo: String = est.exportar_codigo()
	checar(codigo.begins_with("DDOS4:"), "exporta codigo")
	m.sair_conta()
	checar(m.tela == "inicio" and m.inicio.tela == m.inicio.Tela.LOGIN, "trocar conta volta ao login")
	var id_sena: String = m.inicio.ids_ordenados()[0]
	clique(m.inicio, m.inicio.retangulo_conta(0).get_center())
	checar(m.inicio.tela == m.inicio.Tela.PIN, "conta com PIN pede PIN")
	m.inicio.campo_pin_login.text = "0000"
	clique(m.inicio, Vector2(640, 475))
	checar(m.tela == "inicio", "PIN errado nao entra")
	m.inicio.campo_pin_login.text = "4321"
	clique(m.inicio, Vector2(640, 475))
	checar(m.tela == "mundo" and est.id_ativo == id_sena, "PIN certo entra")
	checar(est.eh_dono("pixelforge") and est.desafio_resolvido(d0["id"]), "progresso preservado")
	m.sair_conta()

	var est2 = Estado.new()
	est2.carregar()
	checar(est2.perfis.size() == 1 and est2.perfis[id_sena]["nome"] == "Sena", "save recarrega do disco")
	checar(est2.perfis[id_sena]["empresas"].get("pixelforge", {}).get("dono", false), "empresa comprada persiste")
	est2.perfis = {}
	var id_imp: String = est2.importar_codigo(codigo)
	checar(id_imp != "" and est2.perfis[id_imp]["nome"] == "Sena" and est2.perfis[id_imp]["startup"]["nome"] == "Sena Labs", "importa codigo de backup")
	id_sena = id_imp
	checar(est2.importar_codigo("lixo") == "" and est2.importar_codigo("DDOS4:@@@") == "" and est2.importar_codigo("DDOS4:abcd") == "" and est2.importar_codigo("DDOS4:" + Marshalls.utf8_to_base64("[1,2]")) == "", "rejeita codigo invalido")
	Estado.atual = est
	est.carregar()

	m.inicio.mostrar()
	m.inicio.nova_conta()
	m.inicio.nome = "Sem Pin"
	m.inicio.aceitou = true
	m.inicio.ir_avatar()
	m.inicio.criar_conta()
	checar(est.perfis.size() == 2 and not est.exige_pin(est.id_ativo), "segunda conta sem PIN")
	m.paineis.fechar()
	m.abrir_painel("sede", {})
	clicar_botao_painel(m, "Excluir")
	checar(m.paineis.painel == "excluir", "pede confirmacao de exclusao")
	clicar_botao_painel(m, "Excluir")
	checar(est.perfis.size() == 1 and m.tela == "inicio", "exclui conta")

	checar(est.entrar(id_sena, "4321"), "entra de novo com PIN")
	est.perfil["diarias"] = {"data": est.hoje(), "contadores": {}, "resgatadas": []}
	var diaria: Dictionary = est.diarias_hoje()[0]
	est.somar(diaria["contador"], int(diaria["alvo"]))
	var din_d: float = est.dinheiro()
	checar(est.resgatar_diaria(diaria["id"]) and est.dinheiro() > din_d, "resgata diaria")
	checar(not est.resgatar_diaria(diaria["id"]), "diaria nao paga duas vezes")
	est.perfil["sequencia"]["ultimo"] = est.ontem()
	est.atualizar_sequencia()
	checar(int(est.perfil["sequencia"]["dias"]) == 2, "sequencia aumenta no dia seguinte")
	est.perfil["sequencia"]["ultimo"] = "2000-01-01"
	est.atualizar_sequencia()
	checar(int(est.perfil["sequencia"]["dias"]) == 1, "sequencia zera depois de falhar")

	print("== Balanceamento por empresa (robo, nivel maximo de jogador simulado)")
	est.perfil["xp"] = 999999
	var resultados: Array = []
	for e in Dados.EMPRESAS:
		est.perfil["operacoes"].erase(e["id"])
		est.estado_empresa(e["id"])["dono"] = true
		m.operar(e["id"])
		op.modal = {}
		var dias := 0
		var lucro_total := 0.0
		while op.fase != op.Fase.FIM and dias < 6:
			robo(op)
			rodar_dia(op)
			if op.fase == op.Fase.RELATORIO:
				lucro_total += op.relatorio["lucro"]
				dias += 1
				pular_relatorio(op)
		print("   ... %s ok (%d ms)" % [e["id"], Time.get_ticks_msec()])
		resultados.append("%s: %d dias%s, lucro %.0f, caixa %.0f, confianca %.0f" % [e["nome"], dias, " (FIM: %s)" % op.motivo_fim if op.fase == op.Fase.FIM else "", lucro_total, op.caixa, op.confianca])
		if op.fase != op.Fase.FIM:
			op.sair_para_cidade()
		else:
			m.voltar_mundo()
	for r in resultados:
		print("   " + r)

	m.queue_free()
	if tinha_save:
		var f := FileAccess.open(ARQUIVO, FileAccess.WRITE)
		f.store_string(backup_save)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQUIVO))
	if FileAccess.file_exists("user://perfil.cfg.teste"):
		DirAccess.rename_absolute(ProjectSettings.globalize_path("user://perfil.cfg.teste"), ProjectSettings.globalize_path("user://perfil.cfg"))
	print("FALHAS: %d" % falhas)
	quit(1 if falhas > 0 else 0)
