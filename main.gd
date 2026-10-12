extends Node2D

const Dados := preload("res://dados.gd")
const Site := preload("res://site.gd")
const Visual := preload("res://visual.gd")

enum Tela { CARREGANDO, CADASTRO, POLITICA, MENU, EMPRESAS, ACADEMIA, JOGO }
enum Fase { PREPARACAO, DIA, RELATORIO, FIM }

const ARQUIVO_PERFIL := "user://perfil.cfg"
const TEMPO_CARREGANDO := 2.8
const DELTA_MAXIMO := 0.1
const DURACAO_DIA := 40.0
const TAXA_INICIAL := 1.8
const TAXA_POR_DIA := 0.8
const TAXA_MAXIMA := 30.0
const SOFISTICACAO_POR_DIA := 0.02
const SOFISTICACAO_MAXIMA := 0.35
const PESO_POR_DIA := 0.07
const DIA_INICIO_PESO := 8
const CRESCIMENTO_EMPRESA := 0.1
const APORTE_BASE := 150.0
const APORTE_POR_DIA := 40.0
const RECUPERACAO_CONFIANCA := 10.0
const BONUS_EXPANSAO := 900.0
const BONUS_QUIZ := 200.0
const DIAS_EXPANSAO := [4, 8]
const MULT_SITES := [1.0, 0.55, 0.45]
const FOCO_EXTRA := 0.15
const CRESCIMENTO_TORRE := 1.3
const REEMBOLSO := 0.5
const LIMITE_CREDITO := 1200.0
const TEMPO_AVISO := 3.5
const MAX_AVISOS := 3

const RET_TOPO := Rect2(20, 10, 1240, 48)
const RET_CANVAS := Rect2(20, 104, 1240, 410)
const RET_PAINEL := Rect2(20, 522, 910, 188)
const RET_LATERAL := Rect2(940, 522, 320, 188)
const RET_INICIAR := Rect2(956, 652, 288, 46)
const RET_PAUSA := Rect2(1212, 16, 40, 36)
const RET_VELOCIDADE := Rect2(1166, 16, 42, 36)
const RET_FECHAR_PAINEL := Rect2(890, 532, 30, 30)
const RET_CARTAO_RELATORIO := Rect2(140, 36, 1000, 648)
const RET_CONTINUAR := Rect2(880, 618, 236, 48)

const NOMES_BOTS := {"volumetrico": "Inundação", "l7": "Imitador", "credencial": "Senhas", "scraper": "Copiador"}
const DEFESA_BOT := {"volumetrico": "Anti-DDoS ou CDN", "l7": "WAF ou CAPTCHA", "credencial": "Login 2FA", "scraper": "Rate Limit"}

static var pular_carregamento := false

var tela := Tela.CARREGANDO
var tela_retorno := Tela.MENU
var fase := Fase.PREPARACAO
var modal: Dictionary = {}
var perfil := {"nome": "", "cor": 0, "aceitou": false}
var progresso := {"recordes": {}, "licoes": [], "partidas": 0, "boas_vindas": false}
var empresa: Dictionary = {}
var indice_empresa := 0
var sites: Array = []
var site_atual := 0
var dia := 1
var evento: Dictionary = {}
var tempo_dia := 0.0
var caixa := 0.0
var confianca := 100.0
var velocidade := 1.0
var ferramenta := ""
var selecao: Dictionary = {}
var modo_conectar := -1
var arraste: Dictionary = {}
var mouse := Vector2.ZERO
var tempo_anim := 0.0
var tempo_carregando := 0.0
var avisos: Array = []
var particulas: Array = []
var banner: Dictionary = {}
var relatorio: Dictionary = {}
var elogios_dia: Array = []
var elogiados: Dictionary = {}
var quiz_usados: Array = []
var rolagem_politica := 0
var linhas_politica: Array = []
var totais := {"receita": 0.0, "prejuizo": 0.0}
var motivo_fim := ""
var campo_nome: LineEdit


func _ready() -> void:
	randomize()
	criar_campo_nome()
	carregar_perfil()
	linhas_politica = montar_politica()
	if pular_carregamento:
		pular_carregamento = false
		concluir_carregamento()


func criar_campo_nome() -> void:
	campo_nome = LineEdit.new()
	campo_nome.max_length = 16
	campo_nome.placeholder_text = "Seu apelido"
	campo_nome.position = Vector2(370, 228)
	campo_nome.size = Vector2(400, 46)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Visual.CARTAO_CLARO
	normal.set_corner_radius_all(10)
	normal.set_border_width_all(1)
	normal.border_color = Visual.BORDA
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var foco := normal.duplicate() as StyleBoxFlat
	foco.border_color = Visual.DESTAQUE
	campo_nome.add_theme_stylebox_override("normal", normal)
	campo_nome.add_theme_stylebox_override("focus", foco)
	campo_nome.add_theme_font_size_override("font_size", 18)
	campo_nome.add_theme_color_override("font_color", Visual.TEXTO)
	campo_nome.add_theme_color_override("font_placeholder_color", Visual.TEXTO_SUAVE)
	campo_nome.visible = false
	campo_nome.text_changed.connect(func(texto_novo: String): perfil["nome"] = texto_novo.strip_edges())
	add_child(campo_nome)


func carregar_perfil() -> void:
	var arquivo := ConfigFile.new()
	if arquivo.load(ARQUIVO_PERFIL) != OK:
		return
	perfil["nome"] = arquivo.get_value("perfil", "nome", "")
	perfil["cor"] = arquivo.get_value("perfil", "cor", 0)
	perfil["aceitou"] = arquivo.get_value("perfil", "aceitou", false)
	progresso["recordes"] = arquivo.get_value("progresso", "recordes", {})
	progresso["licoes"] = arquivo.get_value("progresso", "licoes", [])
	progresso["partidas"] = arquivo.get_value("progresso", "partidas", 0)
	progresso["boas_vindas"] = arquivo.get_value("progresso", "boas_vindas", false)


func salvar_perfil() -> void:
	var arquivo := ConfigFile.new()
	arquivo.set_value("perfil", "nome", perfil["nome"])
	arquivo.set_value("perfil", "cor", perfil["cor"])
	arquivo.set_value("perfil", "aceitou", perfil["aceitou"])
	for chave in progresso:
		arquivo.set_value("progresso", chave, progresso[chave])
	arquivo.save(ARQUIVO_PERFIL)


func apagar_dados() -> void:
	var pasta := DirAccess.open("user://")
	if pasta:
		for arquivo in ["perfil.cfg", "recorde.cfg"]:
			if pasta.file_exists(arquivo):
				pasta.remove(arquivo)
	perfil = {"nome": "", "cor": 0, "aceitou": false}
	progresso = {"recordes": {}, "licoes": [], "partidas": 0, "boas_vindas": false}
	campo_nome.text = ""
	modal = {}
	tela = Tela.CADASTRO
	avisar("Seus dados foram apagados deste dispositivo.", Visual.HUMANO)


func montar_politica() -> Array:
	var linhas: Array = []
	for i in Dados.POLITICA.size():
		var paragrafo: String = Dados.POLITICA[i]
		if paragrafo == "":
			linhas.append(["", 15, Visual.TEXTO_SUAVE])
			continue
		var titulo := i == 0 or (paragrafo.length() > 1 and paragrafo[0].is_valid_int() and paragrafo[1] == ".")
		var tamanho := 22 if i == 0 else (17 if titulo else 15)
		for linha in Visual.quebrar(paragrafo, tamanho, 840):
			linhas.append([linha, tamanho, Visual.TEXTO if titulo else Visual.TEXTO_SUAVE])
	return linhas


func site():
	return sites[site_atual]


func pode_interagir() -> bool:
	return tela == Tela.JOGO and modal.is_empty() and (fase == Fase.PREPARACAO or fase == Fase.DIA)


func _process(delta: float) -> void:
	mouse = get_local_mouse_position()
	tempo_anim += delta
	for aviso in avisos:
		aviso["tempo"] += delta
	avisos = avisos.filter(func(a): return a["tempo"] < TEMPO_AVISO)
	atualizar_particulas(delta)
	if not banner.is_empty():
		banner["tempo"] += delta
		if banner["tempo"] > banner["duracao"]:
			banner = {}
	match tela:
		Tela.CARREGANDO:
			tempo_carregando += delta
			if tempo_carregando >= TEMPO_CARREGANDO:
				concluir_carregamento()
		Tela.JOGO:
			if modal.is_empty() and (fase == Fase.PREPARACAO or fase == Fase.DIA):
				simular(minf(delta, DELTA_MAXIMO) * velocidade)
	campo_nome.visible = tela == Tela.CADASTRO and modal.is_empty()
	queue_redraw()


func concluir_carregamento() -> void:
	tela = Tela.MENU if perfil["aceitou"] and perfil["nome"] != "" else Tela.CADASTRO
	campo_nome.text = perfil["nome"]


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and pode_interagir() and fase == Fase.DIA:
		modal = {"tipo": "pausa"}


func simular(dt: float) -> void:
	for s in sites:
		s.atualizar(dt)
		coletar(s)
	if fase != Fase.DIA:
		return
	tempo_dia += dt
	if tempo_dia >= DURACAO_DIA:
		for s in sites:
			s.gerando = false
	if caixa < -LIMITE_CREDITO:
		finalizar("falencia")
		return
	if caixa < 0.0 and not elogiados.has("aviso_credito"):
		elogiados["aviso_credito"] = true
		avisar("Caixa negativo: usando o crédito do banco. Abaixo de %s é falência" % Visual.dinheiro(-LIMITE_CREDITO), Visual.PERIGO, "custo_queda")
	if confianca <= 0.0:
		finalizar("confianca")
		return
	var todos_vazios := tempo_dia >= DURACAO_DIA
	for s in sites:
		if not s.vazio():
			todos_vazios = false
	if todos_vazios:
		fim_do_dia()


func coletar(s) -> void:
	caixa += s.receita - s.prejuizo
	totais["receita"] += s.receita
	totais["prejuizo"] += s.prejuizo
	confianca = maxf(0.0, confianca - s.reputacao_perdida)
	s.receita = 0.0
	s.prejuizo = 0.0
	s.reputacao_perdida = 0.0
	for ev in s.eventos:
		tratar_evento(s, ev)
	s.eventos.clear()


func tratar_evento(s, ev: Dictionary) -> void:
	if ev["tipo"] == "queda":
		var custo: float = s.custo_queda / maxf(1.0, s.terminais().size())
		avisar("%s: torre travou! Prejuízo de %s por segundo" % [s.nome, Visual.dinheiro(custo)], Visual.PERIGO, "escala_horizontal")
		desbloquear_licao("escala_horizontal", false)
		desbloquear_licao("custo_queda", false)
		return
	match ev["motivo"]:
		"sem_saida":
			avisar("%s: clientes sem caminho! Algum componente está sem saída" % s.nome, Visual.CREDITOS, "sem_saida")
			desbloquear_licao("sem_saida", false)
		"falso_positivo":
			avisar("%s: um filtro barrou um cliente real" % s.nome, Visual.CREDITOS, "falso_positivo")
			desbloquear_licao("falso_positivo", false)
		"vazamento":
			avisar("%s: conta invadida! Multa da LGPD e confiança em queda" % s.nome, Visual.PERIGO, "vazamento")
			desbloquear_licao("vazamento", false)
		"caido":
			var licao := "health_check" if not s.ids_do_tipo("lb").is_empty() else "escala_horizontal"
			avisar("%s: clientes enviados para torre fora do ar" % s.nome, Visual.PERIGO, licao)
			desbloquear_licao(licao, false)
		"fila_cheia", "paciencia":
			avisar("%s: clientes desistiram na fila" % s.nome, Visual.CREDITOS, "fila")
			desbloquear_licao("fila", false)


func avisar(texto_aviso: String, cor: Color, licao := "") -> void:
	for aviso in avisos:
		if aviso["texto"] == texto_aviso:
			aviso["tempo"] = 0.0
			return
	avisos.append({"texto": texto_aviso, "cor": cor, "tempo": 0.0, "licao": licao})
	if avisos.size() > MAX_AVISOS:
		avisos.pop_front()


func desbloquear_licao(id: String, mostrar := true) -> void:
	if not Dados.LICOES.has(id):
		return
	var licoes: Array = progresso["licoes"]
	if id in licoes:
		return
	licoes.append(id)
	salvar_perfil()
	if mostrar:
		avisar("Nova lição: %s  ·  toque para ler" % Dados.LICOES[id]["titulo"], Visual.DESTAQUE, id)


func elogiar(id: String, texto_elogio: String) -> void:
	if elogiados.has(id):
		return
	elogiados[id] = true
	elogios_dia.append(texto_elogio)
	avisar("Mandou bem! " + texto_elogio.get_slice(".", 0) + ".", Visual.HUMANO)
	confete(Vector2(640, 140), 40)


func confete(origem: Vector2, quantidade: int) -> void:
	for i in quantidade:
		var cor: Color = Dados.CORES_AVATAR[i % Dados.CORES_AVATAR.size()]
		particulas.append({"pos": origem + Vector2(randf_range(-200, 200), randf_range(-10, 10)), "vel": Vector2(randf_range(-120, 120), randf_range(-260, -80)), "cor": cor, "vida": 0.0, "duracao": randf_range(1.2, 2.0), "giro": randf() * TAU})


func atualizar_particulas(delta: float) -> void:
	for p in particulas:
		p["vida"] += delta
		p["vel"].y += 420.0 * delta
		p["pos"] += p["vel"] * delta
		p["giro"] += delta * 8.0
	particulas = particulas.filter(func(p): return p["vida"] < p["duracao"])


func iniciar_partida(indice: int) -> void:
	indice_empresa = indice
	empresa = Dados.EMPRESAS[indice]
	var primeiro: Dictionary = empresa["sites"][0]
	sites = [Site.new(primeiro["nome"], primeiro["foco"], MULT_SITES[0])]
	site_atual = 0
	dia = 1
	caixa = empresa["caixa"]
	confianca = 100.0
	tempo_dia = 0.0
	velocidade = 1.0
	ferramenta = ""
	selecao = {}
	modo_conectar = -1
	arraste = {}
	banner = {}
	elogios_dia = []
	elogiados = {}
	totais = {"receita": 0.0, "prejuizo": 0.0}
	evento = evento_do_dia(dia)
	fase = Fase.PREPARACAO
	tela = Tela.JOGO
	progresso["partidas"] += 1
	salvar_perfil()
	modal = {"tipo": "boas_vindas"}


func evento_do_dia(numero: int) -> Dictionary:
	var id := "normal"
	var eventos: Array = empresa["eventos"]
	var ameacas: Array = empresa["ameacas"]
	if numero > 1:
		if numero % 5 == 0:
			id = ameacas[(numero / 5 - 1) % ameacas.size()]
		elif numero % 3 == 0:
			id = eventos[(numero / 3 - 1) % eventos.size()]
	var resultado: Dictionary = Dados.EVENTOS[id].duplicate(true)
	resultado["id"] = id
	var mix: Dictionary = empresa["mix"].duplicate()
	for tipo in resultado["mix"]:
		mix[tipo] = mix.get(tipo, 0.0) + resultado["mix"][tipo]
	if numero >= 10 and numero % 10 == 0:
		var extra: Dictionary = Dados.EVENTOS[eventos[(numero / 10 - 1) % eventos.size()]]
		resultado["nome"] = "%s + %s" % [extra["nome"], resultado["nome"]]
		resultado["multiplicador"] = resultado["multiplicador"] * 1.4
		resultado["explicacao"] = "Combo perigoso! %s E ao mesmo tempo: %s" % [extra["explicacao"], resultado["explicacao"]]
		for tipo in extra["mix"]:
			mix[tipo] = mix.get(tipo, 0.0) + extra["mix"][tipo]
	resultado["mix_final"] = mix
	return resultado


func taxa_do_dia() -> float:
	return minf(TAXA_MAXIMA, (TAXA_INICIAL + TAXA_POR_DIA * (dia - 1)) * evento["multiplicador"])


func mix_site(indice: int) -> Dictionary:
	var mix: Dictionary = evento["mix_final"].duplicate()
	var foco: String = empresa["sites"][indice]["foco"]
	if foco != "":
		mix[foco] = mix.get(foco, 0.0) + FOCO_EXTRA
	return mix


func iniciar_dia() -> void:
	if fase != Fase.PREPARACAO:
		return
	var sof := minf(SOFISTICACAO_MAXIMA, SOFISTICACAO_POR_DIA * (dia - 1))
	var peso := 1.0 + PESO_POR_DIA * maxi(0, dia - DIA_INICIO_PESO)
	var crescimento := 1.0 + CRESCIMENTO_EMPRESA * (dia - 1)
	for i in sites.size():
		sites[i].configurar_dia(taxa_do_dia(), mix_site(i), sof, peso, empresa["receita"] * crescimento, empresa["custo_queda"] * crescimento, evento.get("falso_geo", 1.0))
	tempo_dia = 0.0
	fase = Fase.DIA
	ferramenta = ""
	modo_conectar = -1
	banner = {"titulo": evento["nome"], "sub": evento["explicacao"], "tempo": 0.0, "duracao": 3.4, "especial": evento["especial"]}
	if evento.has("licao"):
		desbloquear_licao(evento["licao"])


func fim_do_dia() -> void:
	fase = Fase.RELATORIO
	ferramenta = ""
	modo_conectar = -1
	arraste = {}
	var r := {"dia": dia, "evento": evento["nome"], "especial": evento["especial"], "receita": 0.0, "queda": 0.0, "nuvem": 0.0, "multas": 0.0,
		"humanos": 0, "servidos": 0, "bots": 0, "bloqueados": 0, "quedas": 0, "caido": 0.0, "tempo_total": 0.0,
		"credenciais": 0, "vazamentos": 0, "etapa": 0, "resposta": -1, "quiz": {}}
	for s in sites:
		var e: Dictionary = s.estatisticas
		r["receita"] += e["receita"]
		r["queda"] += e["prejuizo_queda"]
		r["nuvem"] += e["custo_nuvem"]
		r["multas"] += e["multas"]
		r["humanos"] += e["humanos"]
		r["servidos"] += e["servidos"]
		r["bots"] += s.total("bots")
		r["bloqueados"] += s.total("bloqueados")
		r["quedas"] += e["quedas"]
		r["caido"] += e["segundos_caido"]
		r["tempo_total"] += e["tempo"] * maxi(1, s.terminais().size())
		r["credenciais"] += e["bots"].get("credencial", 0)
		r["vazamentos"] += e["vazamentos"]
	var aporte := APORTE_BASE + APORTE_POR_DIA * dia
	caixa += aporte
	r["aporte"] = aporte
	confianca = minf(100.0, confianca + RECUPERACAO_CONFIANCA)
	r["uptime"] = 1.0 - r["caido"] / maxf(1.0, r["tempo_total"])
	r["elogios"] = conquistas_do_dia(r)
	r["problemas"] = diagnosticar()
	if dia % 2 == 0:
		r["quiz"] = sortear_quiz()
	relatorio = r
	var recordes: Dictionary = progresso["recordes"]
	recordes[empresa["id"]] = maxi(recordes.get(empresa["id"], 0), dia)
	salvar_perfil()


func conquistas_do_dia(r: Dictionary) -> Array:
	var lista: Array = elogios_dia.duplicate()
	if r["quedas"] == 0:
		lista.append("Nenhuma torre caiu hoje. Uptime de 100% é exatamente o que o conselho quer ver.")
	if r["humanos"] > 0 and float(r["servidos"]) / r["humanos"] >= 0.97:
		lista.append("%d%% dos clientes atendidos. Experiência impecável, ninguém ficou sem resposta." % roundi(100.0 * r["servidos"] / r["humanos"]))
	if r["bots"] >= 10 and float(r["bloqueados"]) / r["bots"] >= 0.85:
		lista.append("%d%% dos bots bloqueados. Suas camadas de defesa estão afiadas." % roundi(100.0 * r["bloqueados"] / r["bots"]))
	if r["especial"] and r["quedas"] == 0:
		lista.append("Você segurou %s sem cair. É nessas horas que um bom CTO se paga." % r["evento"])
	if r["credenciais"] >= 8 and r["vazamentos"] == 0:
		lista.append("Nenhuma conta invadida em %d tentativas. Seus clientes nem perceberam o perigo." % r["credenciais"])
	if lista.is_empty():
		lista.append("Você manteve a empresa de pé. Cada dia no ar é aprendizado.")
	return lista


func diagnosticar() -> Array:
	var problemas: Array = []
	for s in sites:
		var e: Dictionary = s.estatisticas
		var perdidos: Dictionary = e["perdidos"]
		if e["quedas"] > 0:
			problemas.append({"titulo": "%s: torres travaram %d vez(es)" % [s.nome, e["quedas"]],
				"porque": "Chegou mais carga do que as torres processam e o trabalho acumulou até travar. Ficar fora do ar custou %s." % Visual.dinheiro(e["prejuizo_queda"]),
				"solucao": "mais torres com Load Balancer, upgrades, Auto Scaling, cache ou filtros.", "licao": "escala_horizontal"})
		if perdidos.get("sem_saida", 0) > 0:
			problemas.append({"titulo": "%s: %d clientes num beco sem saída" % [s.nome, perdidos["sem_saida"]],
				"porque": "Algum componente não tem conexão de saída, então a requisição não tinha para onde ir.",
				"solucao": "arraste do círculo à direita do componente até o próximo.", "licao": "sem_saida"})
		var tem_lb_sem_hc := false
		for id in s.ids_do_tipo("lb"):
			if s.nos[id]["nivel"] < 2:
				tem_lb_sem_hc = true
		if e["enviados_caido"] > 0 and tem_lb_sem_hc:
			problemas.append({"titulo": "%s: %d requisições foram para torre caída" % [s.nome, e["enviados_caido"]],
				"porque": "Sem Health Check o Load Balancer não sabe quem está fora do ar e continua mandando clientes para lá.",
				"solucao": "melhore o Load Balancer para o nível 2.", "licao": "health_check"})
		var falsos: int = perdidos.get("falso_positivo", 0)
		if falsos >= maxi(4, roundi(e["humanos"] * 0.03)):
			var pior := ""
			var maior := 0
			for tipo in e["falsos_por_componente"]:
				if e["falsos_por_componente"][tipo] > maior:
					maior = e["falsos_por_componente"][tipo]
					pior = tipo
			var nome_pior: String = Dados.COMPONENTES[pior]["nome"] if pior != "" else "filtro"
			problemas.append({"titulo": "%s: %s barrou %d clientes reais" % [s.nome, nome_pior, maior],
				"porque": "Todo filtro erra às vezes, e cada cliente barrado é venda perdida e confiança a menos.",
				"solucao": "use-o só onde o risco justifica, melhore o nível ou prefira WAF e Rate Limit.", "licao": "falso_positivo"})
		if e["vazamentos"] > 0:
			problemas.append({"titulo": "%s: %d contas invadidas" % [s.nome, e["vazamentos"]],
				"porque": "Ladrões de senha chegaram às torres. Cada invasão gerou multa da LGPD (%s) e derrubou a confiança." % Visual.dinheiro(e["multas"]),
				"solucao": "Login 2FA no caminho, com WAF e CAPTCHA antes.", "licao": "vazamento"})
		var bots_total: int = s.total("bots")
		var chegaram_total: int = s.total("chegaram")
		if bots_total >= 10 and float(chegaram_total) / bots_total > 0.3:
			var pior_bot := ""
			var maior_bot := 0
			for tipo in e["chegaram"]:
				if e["chegaram"][tipo] > maior_bot:
					maior_bot = e["chegaram"][tipo]
					pior_bot = tipo
			problemas.append({"titulo": "%s: %d%% dos bots chegaram às torres" % [s.nome, roundi(100.0 * chegaram_total / bots_total)],
				"porque": "O tipo que mais passou foi %s. Cada filtro é bom contra um tipo de bot diferente." % String(Dados.TIPOS_REQ[pior_bot]["nome"]).to_lower(),
				"solucao": "contra esse tipo, use %s." % DEFESA_BOT[pior_bot], "licao": "defesa_profundidade"})
		var desistentes: int = perdidos.get("fila_cheia", 0) + perdidos.get("paciencia", 0)
		if desistentes > 0:
			problemas.append({"titulo": "%s: %d clientes desistiram na fila" % [s.nome, desistentes],
				"porque": "A fila encheu ou a espera passou da paciência do cliente, porque as torres atrás dela não davam conta.",
				"solucao": "melhore a fila e, principalmente, a capacidade das torres depois dela.", "licao": "fila"})
		if e["custo_nuvem"] > 50.0 and e["custo_nuvem"] > e["receita"] * 0.25:
			problemas.append({"titulo": "%s: o Auto Scaling custou %s" % [s.nome, Visual.dinheiro(e["custo_nuvem"])],
				"porque": "O cluster ligou máquinas extras por causa da carga, inclusive carga de bots.",
				"solucao": "filtre os bots antes do Auto Scaling.", "licao": "autoscale"})
	return problemas.slice(0, 4)


func sortear_quiz() -> Dictionary:
	var disponiveis: Array = []
	for i in Dados.QUIZ.size():
		if not i in quiz_usados:
			disponiveis.append(i)
	if disponiveis.is_empty():
		quiz_usados = []
		disponiveis = range(Dados.QUIZ.size())
	var escolhido: int = disponiveis[randi() % disponiveis.size()]
	quiz_usados.append(escolhido)
	return Dados.QUIZ[escolhido]


func responder_quiz(opcao: int) -> void:
	if fase != Fase.RELATORIO or relatorio["quiz"].is_empty() or relatorio["resposta"] >= 0:
		return
	relatorio["resposta"] = opcao
	if opcao == relatorio["quiz"]["correta"]:
		caixa += BONUS_QUIZ
		avisar("Resposta certa! O conselho liberou %s" % Visual.dinheiro(BONUS_QUIZ), Visual.HUMANO)
		confete(Vector2(640, 300), 50)


func continuar_relatorio() -> void:
	if fase != Fase.RELATORIO:
		return
	if relatorio["etapa"] == 0 and not relatorio["quiz"].is_empty():
		relatorio["etapa"] = 1
		return
	if relatorio["etapa"] == 1 and relatorio["resposta"] < 0:
		return
	dia += 1
	elogios_dia = []
	if dia in DIAS_EXPANSAO and sites.size() < empresa["sites"].size():
		var novo: Dictionary = empresa["sites"][sites.size()]
		sites.append(Site.new(novo["nome"], novo["foco"], MULT_SITES[sites.size()]))
		caixa += BONUS_EXPANSAO
		avisar("Expansão! Novo sistema: %s. O conselho investiu %s" % [novo["nome"], Visual.dinheiro(BONUS_EXPANSAO)], Visual.DESTAQUE, "multi_site")
		desbloquear_licao("multi_site", false)
		confete(Vector2(640, 90), 40)
	evento = evento_do_dia(dia)
	fase = Fase.PREPARACAO
	selecao = {}


func finalizar(motivo: String) -> void:
	fase = Fase.FIM
	motivo_fim = motivo
	ferramenta = ""
	modo_conectar = -1
	arraste = {}
	var recordes: Dictionary = progresso["recordes"]
	recordes[empresa["id"]] = maxi(recordes.get(empresa["id"], 0), dia - 1)
	salvar_perfil()


func custo_componente(tipo: String) -> int:
	var base: float = Dados.COMPONENTES[tipo]["custo"]
	if tipo in Dados.TERMINAIS:
		var quantidade := 0
		for s in sites:
			quantidade += s.terminais().size()
		return roundi(base * pow(CRESCIMENTO_TORRE, maxi(0, quantidade - 1)))
	return roundi(base)


func custo_melhoria(no: Dictionary) -> int:
	return roundi(Dados.COMPONENTES[no["tipo"]]["custo"] * 0.7 * no["nivel"])


func colocar(tipo: String, celula: Vector2i) -> void:
	var s = site()
	if not s.celula_valida(celula) or s.no_na_celula(celula) >= 0:
		avisar("Escolha uma célula livre da grade", Visual.CREDITOS)
		return
	var custo := custo_componente(tipo)
	if caixa < custo:
		avisar("Caixa insuficiente: %s custa %s" % [Dados.COMPONENTES[tipo]["nome"], Visual.dinheiro(custo)], Visual.PERIGO)
		return
	var id: int = s.adicionar_no(tipo, celula)
	caixa -= custo
	s.nos[id]["investido"] = float(custo)
	var encaixou := encaixar(s, id)
	ferramenta = ""
	selecao = {}
	var nome_tipo: String = Dados.COMPONENTES[tipo]["nome"]
	if encaixou:
		avisar("%s instalado e encaixado no fluxo. Toque nele para ver detalhes" % nome_tipo, Visual.HUMANO)
	else:
		avisar("%s instalado. Agora conecte a entrada e a saída" % nome_tipo, Visual.DESTAQUE)
	desbloquear_licao(tipo)
	checar_elogios()


func encaixar(s, novo: int) -> bool:
	var celula: Vector2i = s.nos[novo]["celula"]
	var anterior: int = s.no_na_celula(celula - Vector2i(1, 0))
	if s.eh_terminal(novo):
		var balanceadores: Array = s.ids_do_tipo("lb")
		if balanceadores.size() == 1 and s.conectar(balanceadores[0], novo) == "":
			return true
		if anterior >= 0 and s.conectar(anterior, novo) == "":
			return true
		return false
	if anterior < 0 or s.eh_terminal(anterior) or s.pode_conectar(anterior, novo) != "":
		return false
	var saidas: Array = s.nos[anterior]["saidas"].duplicate()
	for destino in saidas:
		s.desconectar(anterior, destino)
	s.conectar(anterior, novo)
	for destino in saidas:
		s.conectar(novo, destino)
	return true


func melhorar(id: int) -> void:
	var s = site()
	if not s.nos.has(id):
		return
	var no: Dictionary = s.nos[id]
	if no["tipo"] == "internet" or no["nivel"] >= Dados.NIVEL_MAXIMO:
		return
	var custo := custo_melhoria(no)
	if caixa < custo:
		avisar("Caixa insuficiente para melhorar", Visual.PERIGO)
		return
	caixa -= custo
	no["nivel"] += 1
	no["investido"] += custo
	if no["tipo"] == "lb" and no["nivel"] == 2:
		desbloquear_licao("health_check")
	checar_elogios()


func vender(id: int) -> void:
	var s = site()
	if id == s.id_internet or not s.nos.has(id):
		return
	var valor := roundi(s.nos[id]["investido"] * REEMBOLSO)
	caixa += valor
	s.remover_no(id)
	selecao = {}
	avisar("Componente vendido por %s" % Visual.dinheiro(valor), Visual.TEXTO_SUAVE)


func limpar_saidas(id: int) -> void:
	var s = site()
	if not s.nos.has(id):
		return
	for destino in s.nos[id]["saidas"].duplicate():
		s.desconectar(id, destino)
	avisar("Saídas removidas. Sem saída, o tráfego fica sem caminho", Visual.CREDITOS)


func remover_aresta(de: int, para: int) -> void:
	site().desconectar(de, para)
	selecao = {}


func tentar_conectar(a: int, b: int) -> void:
	var erro: String = site().conectar(a, b)
	if erro != "":
		avisar(erro, Visual.PERIGO)
		return
	avisar("%s ligado a %s" % [nome_no(site(), a), nome_no(site(), b)], Visual.HUMANO)
	checar_elogios()


func nome_no(s, id: int) -> String:
	var tipo: String = s.nos[id]["tipo"]
	return "Internet" if tipo == "internet" else String(Dados.COMPONENTES[tipo]["nome"])


func checar_elogios() -> void:
	for s in sites:
		for id in s.nos:
			var no: Dictionary = s.nos[id]
			var tipo: String = no["tipo"]
			var saidas: Array = no["saidas"]
			if tipo == "internet":
				for destino in saidas:
					if s.nos[destino]["tipo"] == "cdn":
						elogiar("cdn_entrada", "CDN logo na entrada. O que sai do cache nem gasta filtro nem torre.")
			if tipo == "lb":
				var torres := 0
				for destino in saidas:
					if s.eh_terminal(destino):
						torres += 1
				if torres >= 2:
					elogiar("escala_horizontal", "Escala horizontal montada. O Load Balancer divide a carga e uma torre caída não derruba tudo.")
				if no["nivel"] >= 2:
					elogiar("health_check", "Health Check ativo. O balanceador para de mandar clientes para torre caída.")
				if no["nivel"] >= 3:
					elogiar("menor_carga", "Balanceamento por menor carga. Cada requisição vai para a torre mais livre.")
			if tipo in Dados.FILTROS and tipo != "cdn" and tipo != "redis":
				for destino in saidas:
					var tipo_destino: String = s.nos[destino]["tipo"]
					if tipo_destino in Dados.FILTROS and tipo_destino != tipo and tipo_destino != "cdn" and tipo_destino != "redis":
						elogiar("camadas", "Defesa em profundidade. Filtros diferentes em sequência pegam o que o anterior deixou passar.")
			if tipo == "fila":
				for destino in saidas:
					if s.eh_terminal(destino) or s.nos[destino]["tipo"] == "lb":
						elogiar("fila", "Fila antes das torres. Picos viram um fluxo constante que elas aguentam.")
			if tipo == "mfa" and "Banco" in String(empresa.get("setor", "")):
				elogiar("mfa_banco", "Login 2FA num banco. Senha vazada sozinha não abre conta de ninguém.")
			if tipo == "autoscale":
				elogiar("autoscale", "Auto Scaling na nuvem. Capacidade elástica que cresce no pico e encolhe depois.")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e := make_input_local(event) as InputEventMouseButton
		if e.pressed and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			rolar(-3 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 3)
			return
		if e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
			cancelar()
			return
		if e.button_index != MOUSE_BUTTON_LEFT:
			return
		if e.pressed:
			pressionar(e.position)
		else:
			soltar(e.position)
	elif event is InputEventMouseMotion:
		var m := make_input_local(event) as InputEventMouseMotion
		arrastar(m.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		tecla(event.keycode)


func linhas_visiveis_politica() -> int:
	return 20


func rolar(linhas: int) -> void:
	if tela == Tela.POLITICA:
		rolagem_politica = clampi(rolagem_politica + linhas, 0, maxi(0, linhas_politica.size() - linhas_visiveis_politica()))


func cancelar() -> void:
	if ferramenta != "" or modo_conectar >= 0:
		ferramenta = ""
		modo_conectar = -1
	else:
		selecao = {}


func tecla(codigo: Key) -> void:
	if not modal.is_empty():
		if codigo == KEY_ESCAPE or ((codigo == KEY_SPACE or codigo == KEY_ENTER or codigo == KEY_P) and modal["tipo"] != "apagar"):
			if modal["tipo"] == "boas_vindas":
				progresso["boas_vindas"] = true
				salvar_perfil()
			modal = {}
		return
	match tela:
		Tela.CARREGANDO:
			concluir_carregamento()
		Tela.POLITICA:
			if codigo == KEY_DOWN:
				rolar(1)
			elif codigo == KEY_UP:
				rolar(-1)
			elif codigo == KEY_ESCAPE:
				tela = tela_retorno
		Tela.EMPRESAS:
			if codigo == KEY_ESCAPE:
				tela = Tela.MENU
		Tela.ACADEMIA:
			if codigo == KEY_ESCAPE:
				tela = tela_retorno
		Tela.JOGO:
			tecla_jogo(codigo)


func tecla_jogo(codigo: Key) -> void:
	match fase:
		Fase.RELATORIO:
			if codigo == KEY_SPACE or codigo == KEY_ENTER:
				continuar_relatorio()
			elif relatorio.get("etapa", 0) == 1 and codigo >= KEY_1 and codigo <= KEY_3:
				responder_quiz(codigo - KEY_1)
		Fase.FIM:
			if codigo == KEY_SPACE or codigo == KEY_ENTER:
				iniciar_partida(indice_empresa)
		_:
			if codigo == KEY_SPACE or codigo == KEY_ENTER:
				iniciar_dia()
			elif codigo == KEY_P:
				modal = {"tipo": "pausa"}
			elif codigo == KEY_ESCAPE:
				if ferramenta != "" or modo_conectar >= 0 or not selecao.is_empty():
					cancelar()
				else:
					modal = {"tipo": "pausa"}
			elif codigo == KEY_F:
				velocidade = 2.0 if velocidade == 1.0 else 1.0
			elif codigo >= KEY_1 and codigo <= KEY_3 and codigo - KEY_1 < sites.size():
				trocar_site(codigo - KEY_1)


func trocar_site(indice: int) -> void:
	site_atual = indice
	selecao = {}
	modo_conectar = -1
	arraste = {}


func retangulo_aviso(indice: int) -> Rect2:
	var aviso: Dictionary = avisos[indice]
	var largura := Visual.largura_texto(aviso["texto"], 14) + 44
	var y := 672.0 - indice * 40
	if pode_interagir():
		y = 470.0 - indice * 40
	elif not modal.is_empty() or (tela == Tela.JOGO and (fase == Fase.RELATORIO or fase == Fase.FIM)):
		y = 2.0 + indice * 38
	return Rect2(640 - largura / 2, y, largura, 34)


func clicar_aviso(pos: Vector2) -> bool:
	if not modal.is_empty():
		return false
	for i in avisos.size():
		if retangulo_aviso(i).has_point(pos) and avisos[i]["licao"] != "":
			var licao: String = avisos[i]["licao"]
			avisos.remove_at(i)
			abrir_licao(licao)
			return true
	return false


func abrir_licao(id: String) -> void:
	desbloquear_licao(id, false)
	modal = {"tipo": "licao", "id": id}


func pressionar(pos: Vector2) -> void:
	if clicar_aviso(pos):
		return
	if not modal.is_empty():
		clicar_modal(pos)
		return
	match tela:
		Tela.CARREGANDO:
			if tempo_carregando > 0.3:
				concluir_carregamento()
		Tela.CADASTRO:
			clicar_cadastro(pos)
		Tela.POLITICA:
			clicar_politica(pos)
		Tela.MENU:
			clicar_menu(pos)
		Tela.EMPRESAS:
			clicar_empresas(pos)
		Tela.ACADEMIA:
			clicar_academia(pos)
		Tela.JOGO:
			pressionar_jogo(pos)


func arrastar(pos: Vector2) -> void:
	if arraste.has("rolagem"):
		var passos := roundi((arraste["inicio"].y - pos.y) / 25.0)
		if passos != 0:
			rolar(passos)
			arraste["inicio"] = pos
		return
	if arraste.is_empty() or arraste.get("ativo", false):
		return
	if pos.distance_to(arraste["inicio"]) > 10.0:
		arraste["ativo"] = true


func soltar(pos: Vector2) -> void:
	if arraste.is_empty():
		return
	var dados_arraste := arraste
	arraste = {}
	if dados_arraste.has("rolagem") or not pode_interagir():
		return
	var alvo: Dictionary = dados_arraste["alvo"]
	if not dados_arraste["ativo"]:
		clicar_canvas(alvo)
		return
	match alvo.get("tipo", ""):
		"porta":
			var destino: int = site().no_em(pos)
			if destino >= 0 and destino != alvo["id"]:
				tentar_conectar(alvo["id"], destino)
		"no":
			if not site().mover_no(alvo["id"], site().celula_em(pos)):
				avisar("Só dá para mover para uma célula livre", Visual.CREDITOS)


func alvo_em(pos: Vector2) -> Dictionary:
	var s = site()
	var celula: Vector2i = s.celula_em(pos)
	for id in s.nos:
		if s.tem_saida(id) and pos.distance_to(s.porta_saida(id)) <= 14.0:
			return {"tipo": "porta", "id": id, "celula": celula}
	var no: int = s.no_em(pos)
	if no >= 0:
		return {"tipo": "no", "id": no, "celula": celula}
	var aresta: Array = s.aresta_em(pos)
	if not aresta.is_empty():
		return {"tipo": "aresta", "de": aresta[0], "para": aresta[1], "celula": celula}
	return {"tipo": "celula", "celula": celula}


func clicar_canvas(alvo: Dictionary) -> void:
	var tipo_alvo: String = alvo.get("tipo", "")
	if modo_conectar >= 0:
		if tipo_alvo == "no" or tipo_alvo == "porta":
			tentar_conectar(modo_conectar, alvo["id"])
		modo_conectar = -1
		return
	if ferramenta != "":
		if tipo_alvo != "no" and tipo_alvo != "porta":
			colocar(ferramenta, alvo["celula"])
			return
		ferramenta = ""
	match tipo_alvo:
		"no", "porta":
			selecao = {"tipo": "no", "id": alvo["id"]}
		"aresta":
			selecao = {"tipo": "aresta", "de": alvo["de"], "para": alvo["para"]}
		_:
			selecao = {}


func retangulo_aba(indice: int) -> Rect2:
	return Rect2(20 + indice * 206, 64, 198, 34)


func pressionar_jogo(pos: Vector2) -> void:
	if fase == Fase.RELATORIO:
		clicar_relatorio(pos)
		return
	if fase == Fase.FIM:
		clicar_fim(pos)
		return
	if RET_PAUSA.has_point(pos):
		modal = {"tipo": "pausa"}
		return
	if RET_VELOCIDADE.has_point(pos):
		velocidade = 2.0 if velocidade == 1.0 else 1.0
		return
	for i in sites.size():
		if retangulo_aba(i).has_point(pos):
			trocar_site(i)
			return
	if RET_CANVAS.has_point(pos):
		arraste = {"inicio": pos, "alvo": alvo_em(pos), "ativo": false}
		return
	if fase == Fase.PREPARACAO and RET_INICIAR.has_point(pos):
		iniciar_dia()
		return
	if not selecao.is_empty() and RET_FECHAR_PAINEL.has_point(pos):
		selecao = {}
		return
	for b in botoes_painel():
		if b["rect"].has_point(pos):
			if b["ativo"]:
				b["acao"].call()
			return


func selecionar_ferramenta(tipo: String) -> void:
	ferramenta = "" if ferramenta == tipo else tipo
	selecao = {}
	modo_conectar = -1


func iniciar_conexao(id: int) -> void:
	modo_conectar = id


func retangulo_paleta(indice: int) -> Rect2:
	return Rect2(32 + (indice % 6) * 148, 552 + (indice / 6) * 78, 140, 72)


func botoes_painel() -> Array:
	var botoes: Array = []
	if not pode_interagir():
		return botoes
	var s = site()
	match selecao.get("tipo", ""):
		"no":
			var id: int = selecao["id"]
			if not s.nos.has(id):
				return botoes
			var no: Dictionary = s.nos[id]
			var tipo: String = no["tipo"]
			if tipo != "internet":
				var maximo: bool = no["nivel"] >= Dados.NIVEL_MAXIMO
				var custo := custo_melhoria(no)
				botoes.append({"rect": Rect2(36, 650, 200, 48), "rotulo": "Nível máximo" if maximo else "Melhorar  ·  %s" % Visual.dinheiro(custo), "ativo": not maximo and caixa >= custo, "acao": melhorar.bind(id), "principal": true})
			if s.tem_saida(id):
				botoes.append({"rect": Rect2(248, 650, 150, 48), "rotulo": "Conectar", "ativo": true, "acao": iniciar_conexao.bind(id)})
				botoes.append({"rect": Rect2(410, 650, 160, 48), "rotulo": "Limpar saídas", "ativo": not no["saidas"].is_empty(), "acao": limpar_saidas.bind(id)})
			if tipo != "internet":
				botoes.append({"rect": Rect2(582, 650, 150, 48), "rotulo": "Vender", "ativo": true, "acao": vender.bind(id)})
			var licao := "defesa_profundidade" if tipo == "internet" else tipo
			botoes.append({"rect": Rect2(744, 650, 140, 48), "rotulo": "Por quê?", "ativo": true, "acao": abrir_licao.bind(licao)})
		"aresta":
			botoes.append({"rect": Rect2(36, 650, 240, 48), "rotulo": "Remover conexão", "ativo": true, "acao": remover_aresta.bind(selecao["de"], selecao["para"])})
		_:
			for k in Dados.PALETA.size():
				var tipo_paleta: String = Dados.PALETA[k]
				botoes.append({"rect": retangulo_paleta(k), "paleta": tipo_paleta, "ativo": true, "acao": selecionar_ferramenta.bind(tipo_paleta)})
	return botoes


func clicar_modal(pos: Vector2) -> void:
	match modal["tipo"]:
		"licao", "boas_vindas":
			if retangulo_botao_modal().has_point(pos):
				if modal["tipo"] == "boas_vindas":
					progresso["boas_vindas"] = true
					salvar_perfil()
				modal = {}
		"pausa":
			if Rect2(490, 330, 300, 52).has_point(pos):
				modal = {}
			elif Rect2(490, 392, 300, 52).has_point(pos):
				modal = {}
				tela_retorno = Tela.JOGO
				tela = Tela.ACADEMIA
			elif Rect2(490, 454, 300, 52).has_point(pos):
				modal = {}
				tela = Tela.MENU
		"apagar":
			if Rect2(450, 400, 180, 50).has_point(pos):
				apagar_dados()
			elif Rect2(650, 400, 180, 50).has_point(pos):
				modal = {}


func retangulo_botao_modal() -> Rect2:
	if modal.get("tipo", "") == "boas_vindas":
		return Rect2(470, 616, 340, 52)
	return Rect2(540, 588, 200, 48)


func clicar_cadastro(pos: Vector2) -> void:
	if Rect2(780, 228, 130, 46).has_point(pos):
		var nome_novo: String = Dados.NOMES_ALEATORIOS[randi() % Dados.NOMES_ALEATORIOS.size()] + str(randi_range(10, 99))
		campo_nome.text = nome_novo
		perfil["nome"] = nome_novo
		return
	for k in Dados.CORES_AVATAR.size():
		if Vector2(390 + k * 60, 345).distance_to(pos) <= 22.0:
			perfil["cor"] = k
			return
	if Rect2(366, 392, 420, 32).has_point(pos):
		perfil["aceitou"] = not perfil["aceitou"]
		return
	if Rect2(366, 432, 240, 30).has_point(pos):
		tela_retorno = Tela.CADASTRO
		rolagem_politica = 0
		tela = Tela.POLITICA
		return
	if Rect2(370, 552, 540, 52).has_point(pos):
		if perfil["nome"] == "":
			avisar("Escolha um apelido (ou toque em Sortear)", Visual.CREDITOS)
		elif not perfil["aceitou"]:
			avisar("Para jogar, aceite a Política de Privacidade", Visual.CREDITOS)
		else:
			campo_nome.release_focus()
			salvar_perfil()
			tela = Tela.MENU


func clicar_politica(pos: Vector2) -> void:
	if Rect2(190, 618, 160, 44).has_point(pos):
		tela = tela_retorno
	elif Rect2(880, 618, 100, 44).has_point(pos):
		rolar(-6)
	elif Rect2(990, 618, 100, 44).has_point(pos):
		rolar(6)
	else:
		arraste = {"inicio": pos, "rolagem": true}


func botoes_menu() -> Array:
	return [
		{"rect": Rect2(100, 330, 380, 58), "rotulo": "Nova partida", "principal": true},
		{"rect": Rect2(100, 400, 380, 52), "rotulo": "Academia  ·  %d de %d lições" % [progresso["licoes"].size(), Dados.LICOES.size()]},
		{"rect": Rect2(100, 464, 380, 52), "rotulo": "Política de privacidade"},
		{"rect": Rect2(100, 528, 380, 52), "rotulo": "Apagar meus dados"},
	]


func clicar_menu(pos: Vector2) -> void:
	var botoes := botoes_menu()
	if botoes[0]["rect"].has_point(pos):
		tela = Tela.EMPRESAS
	elif botoes[1]["rect"].has_point(pos):
		tela_retorno = Tela.MENU
		tela = Tela.ACADEMIA
	elif botoes[2]["rect"].has_point(pos):
		tela_retorno = Tela.MENU
		rolagem_politica = 0
		tela = Tela.POLITICA
	elif botoes[3]["rect"].has_point(pos):
		modal = {"tipo": "apagar"}


func retangulo_empresa(indice: int) -> Rect2:
	return Rect2(40 + (indice % 4) * 305, 112 + (indice / 4) * 272, 290, 258)


func clicar_empresas(pos: Vector2) -> void:
	if Rect2(40, 664, 150, 44).has_point(pos):
		tela = Tela.MENU
		return
	for i in Dados.EMPRESAS.size():
		if retangulo_empresa(i).has_point(pos):
			iniciar_partida(i)
			return


func ids_licoes() -> Array:
	return Dados.LICOES.keys()


func retangulo_licao(indice: int) -> Rect2:
	return Rect2(40 + (indice % 4) * 305, 116 + (indice / 4) * 84, 290, 74)


func clicar_academia(pos: Vector2) -> void:
	if Rect2(40, 664, 190, 44).has_point(pos):
		tela = tela_retorno
		return
	var ids := ids_licoes()
	for i in ids.size():
		if retangulo_licao(i).has_point(pos) and ids[i] in progresso["licoes"]:
			modal = {"tipo": "licao", "id": ids[i]}
			return


func retangulo_opcao_quiz(indice: int) -> Rect2:
	return Rect2(260, 300 + indice * 70, 760, 58)


func retangulo_entender(indice: int) -> Rect2:
	return Rect2(1010, 298 + indice * 76, 96, 26)


func clicar_relatorio(pos: Vector2) -> void:
	if relatorio["etapa"] == 0:
		var problemas: Array = relatorio["problemas"]
		for i in problemas.size():
			if retangulo_entender(i).has_point(pos):
				abrir_licao(problemas[i]["licao"])
				return
		if RET_CONTINUAR.has_point(pos):
			continuar_relatorio()
		return
	if relatorio["resposta"] < 0:
		for i in 3:
			if retangulo_opcao_quiz(i).has_point(pos):
				responder_quiz(i)
				return
		return
	if RET_CONTINUAR.has_point(pos):
		continuar_relatorio()


func clicar_fim(pos: Vector2) -> void:
	if Rect2(330, 560, 200, 52).has_point(pos):
		iniciar_partida(indice_empresa)
	elif Rect2(540, 560, 200, 52).has_point(pos):
		tela = Tela.EMPRESAS
	elif Rect2(750, 560, 200, 52).has_point(pos):
		tela = Tela.MENU


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Visual.FUNDO)
	desenhar_grade_fundo()
	match tela:
		Tela.CARREGANDO:
			desenhar_carregando()
		Tela.CADASTRO:
			desenhar_cadastro()
		Tela.POLITICA:
			desenhar_politica()
		Tela.MENU:
			desenhar_menu()
		Tela.EMPRESAS:
			desenhar_empresas()
		Tela.ACADEMIA:
			desenhar_academia()
		Tela.JOGO:
			desenhar_jogo()
	desenhar_modal()
	desenhar_avisos()
	desenhar_particulas()


func desenhar_grade_fundo() -> void:
	for x in range(0, 1281, 40):
		draw_line(Vector2(x, 0), Vector2(x, 720), Visual.GRADE, 1.0)
	for y in range(0, 721, 40):
		draw_line(Vector2(0, y), Vector2(1280, y), Visual.GRADE, 1.0)


func hover(r: Rect2) -> bool:
	return r.has_point(mouse)


func desenhar_carregando() -> void:
	var progresso_carga := clampf(tempo_carregando / TEMPO_CARREGANDO, 0.0, 1.0)
	var pulso := 1.0 + 0.06 * sin(tempo_anim * 4.0)
	Visual.icone(self, "waf", Vector2(640, 230), Visual.DESTAQUE, 3.2 * pulso)
	Visual.texto(self, Vector2(0, 340), "DDoS Defense", 56, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Visual.texto(self, Vector2(0, 376), "Simulador de arquitetura e defesa de sistemas", 18, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	var barra := Rect2(440, 424, 400, 10)
	Visual.caixa(self, barra, Visual.LINHA, 5)
	Visual.caixa(self, Rect2(barra.position, Vector2(maxf(10.0, barra.size.x * ease(progresso_carga, 0.6)), 10)), Visual.DESTAQUE, 5)
	var dica: String = Dados.DICAS_CARREGANDO[int(tempo_anim / 0.6) % Dados.DICAS_CARREGANDO.size()]
	Visual.texto(self, Vector2(0, 466), dica, 15, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	draw_line(Vector2(340, 560), Vector2(940, 560), Visual.LINHA, 4.0, true)
	for k in 14:
		var x := 340.0 + fmod(tempo_anim * 140.0 + k * 43.0, 600.0)
		var bot := k % 3 == 0
		if (bot and x > 620.0) or (x > 616.0 and x < 664.0):
			continue
		Visual.caixa(self, Rect2(x - 5, 555, 10, 10), Visual.BOT if bot else Visual.HUMANO, 3, Visual.TRANSPARENTE, 0, 0, 2)
	Visual.caixa(self, Rect2(620, 536, 40, 48), Visual.CARTAO, 10, Visual.DESTAQUE, 1)
	Visual.icone(self, "waf", Vector2(640, 560), Visual.DESTAQUE, 0.9)
	if tempo_carregando > 0.3:
		Visual.texto(self, Vector2(0, 680), "Toque para pular", 13, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, 1280)


func desenhar_cadastro() -> void:
	var cartao := Rect2(330, 90, 620, 540)
	Visual.caixa(self, cartao, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	Visual.texto(self, Vector2(370, 152), "Crie seu perfil", 30, Visual.TEXTO)
	Visual.texto(self, Vector2(370, 182), "Leva 10 segundos. Nada sai do seu dispositivo.", 15, Visual.TEXTO_SUAVE)
	Visual.texto(self, Vector2(370, 218), "Como quer ser chamado?", 15, Visual.TEXTO)
	Visual.botao(self, Rect2(780, 228, 130, 46), "Sortear", Visual.DESTAQUE, hover(Rect2(780, 228, 130, 46)))
	Visual.texto(self, Vector2(370, 318), "Cor do avatar", 15, Visual.TEXTO)
	for k in Dados.CORES_AVATAR.size():
		var centro := Vector2(390 + k * 60, 345)
		draw_circle(centro, 18.0, Dados.CORES_AVATAR[k], true, -1.0, true)
		if perfil["cor"] == k:
			draw_arc(centro, 23.0, 0.0, TAU, 32, Visual.TEXTO, 2.0, true)
			if perfil["nome"] != "":
				Visual.texto(self, centro + Vector2(-20, 7), String(perfil["nome"]).substr(0, 1).to_upper(), 18, Visual.FUNDO, HORIZONTAL_ALIGNMENT_CENTER, 40)
	var caixa_marcada := Rect2(370, 395, 26, 26)
	Visual.caixa(self, caixa_marcada, Visual.HUMANO if perfil["aceitou"] else Visual.CARTAO_CLARO, 6, Visual.BORDA_HOVER, 1)
	if perfil["aceitou"]:
		draw_polyline(PackedVector2Array([caixa_marcada.position + Vector2(6, 13), caixa_marcada.position + Vector2(11, 18), caixa_marcada.position + Vector2(20, 8)]), Visual.FUNDO, 2.5, true)
	Visual.texto(self, Vector2(408, 414), "Li e aceito a Política de Privacidade", 15, Visual.TEXTO)
	Visual.texto(self, Vector2(370, 452), "Ler a política de privacidade", 14, Visual.DESTAQUE)
	draw_line(Vector2(370, 456), Vector2(370 + Visual.largura_texto("Ler a política de privacidade", 14), 456), Visual.DESTAQUE, 1.0)
	Visual.caixa(self, Rect2(370, 476, 540, 60), Visual.CARTAO_CLARO, 10)
	Visual.paragrafo(self, Vector2(386, 500), "Não pedimos e-mail, telefone nem senha. Seu apelido e progresso ficam salvos só neste dispositivo.", 13, Visual.TEXTO_SUAVE, 510)
	var pronto: bool = perfil["nome"] != "" and perfil["aceitou"]
	Visual.botao(self, Rect2(370, 552, 540, 52), "Começar", Visual.PRINCIPAL, hover(Rect2(370, 552, 540, 52)), pronto, 18, true)


func desenhar_politica() -> void:
	Visual.caixa(self, Rect2(170, 30, 940, 650), Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	var y := 90.0
	var visiveis := linhas_visiveis_politica()
	for i in range(rolagem_politica, mini(linhas_politica.size(), rolagem_politica + visiveis)):
		var linha: Array = linhas_politica[i]
		Visual.texto(self, Vector2(210, y), linha[0], linha[1], linha[2])
		y += 25.0
	var total := maxi(1, linhas_politica.size() - visiveis)
	var trilho := Rect2(1080, 70, 6, 520)
	Visual.caixa(self, trilho, Visual.LINHA, 3)
	var altura := trilho.size.y * clampf(float(visiveis) / maxf(1.0, linhas_politica.size()), 0.1, 1.0)
	Visual.caixa(self, Rect2(trilho.position.x, trilho.position.y + (trilho.size.y - altura) * rolagem_politica / total, 6, altura), Visual.BORDA_HOVER, 3)
	Visual.botao(self, Rect2(190, 618, 160, 44), "Voltar", Visual.DESTAQUE, hover(Rect2(190, 618, 160, 44)))
	Visual.botao(self, Rect2(880, 618, 100, 44), "Subir", Visual.DESTAQUE, hover(Rect2(880, 618, 100, 44)), rolagem_politica > 0)
	Visual.botao(self, Rect2(990, 618, 100, 44), "Descer", Visual.DESTAQUE, hover(Rect2(990, 618, 100, 44)), rolagem_politica < linhas_politica.size() - visiveis)


func desenhar_menu() -> void:
	Visual.icone(self, "waf", Vector2(124, 150), Visual.DESTAQUE, 2.2)
	Visual.texto(self, Vector2(160, 168), "DDoS Defense", 50, Visual.TEXTO)
	Visual.paragrafo(self, Vector2(102, 206), "Seja o CTO das maiores empresas do país e mantenha tudo no ar.", 16, Visual.TEXTO_SUAVE, 420, 1.35, 2)
	var cor_avatar: Color = Dados.CORES_AVATAR[perfil["cor"]]
	draw_circle(Vector2(122, 272), 20.0, cor_avatar, true, -1.0, true)
	Visual.texto(self, Vector2(102, 279), String(perfil["nome"]).substr(0, 1).to_upper(), 18, Visual.FUNDO, HORIZONTAL_ALIGNMENT_CENTER, 40)
	Visual.texto(self, Vector2(154, 279), "Olá, %s" % perfil["nome"], 19, Visual.TEXTO)
	for b in botoes_menu():
		var principal: bool = b.get("principal", false)
		Visual.botao(self, b["rect"], b["rotulo"], Visual.PRINCIPAL if principal else Visual.DESTAQUE, hover(b["rect"]), true, 17, principal)
	Visual.caixa(self, Rect2(560, 120, 660, 470), Visual.CARTAO, 20, Visual.BORDA, 1, 16)
	Visual.texto(self, Vector2(590, 164), "Seus recordes", 20, Visual.TEXTO)
	Visual.texto(self, Vector2(590, 188), "Dias que você manteve cada empresa no ar", 13, Visual.TEXTO_SUAVE)
	for i in Dados.EMPRESAS.size():
		var emp: Dictionary = Dados.EMPRESAS[i]
		var y := 214.0 + i * 44.0
		Visual.caixa(self, Rect2(590, y, 30, 30), emp["cor"], 8)
		Visual.texto(self, Vector2(590, y + 20), emp["sigla"], 12, Visual.FUNDO, HORIZONTAL_ALIGNMENT_CENTER, 30)
		Visual.texto(self, Vector2(634, y + 21), emp["nome"], 15, Visual.TEXTO)
		Visual.texto(self, Vector2(800, y + 21), emp["setor"], 13, Visual.TEXTO_SUAVE)
		var recorde: int = progresso["recordes"].get(emp["id"], 0)
		Visual.texto(self, Vector2(980, y + 21), "dia %d" % recorde if recorde > 0 else "não jogado", 14, Visual.CREDITOS if recorde > 0 else Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT, 210)
	Visual.texto(self, Vector2(0, 700), "Empresas e marcas do jogo são fictícias. Projeto educacional de código aberto.", 12, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, 1280)


func desenhar_empresas() -> void:
	Visual.texto(self, Vector2(40, 66), "Escolha a empresa que você vai proteger", 28, Visual.TEXTO)
	Visual.texto(self, Vector2(40, 94), "Cada uma tem tráfego, ameaças e datas de pico diferentes. Bancos são os mais difíceis.", 15, Visual.TEXTO_SUAVE)
	for i in Dados.EMPRESAS.size():
		var emp: Dictionary = Dados.EMPRESAS[i]
		var r := retangulo_empresa(i)
		var cor: Color = emp["cor"]
		Visual.caixa(self, r, Visual.CARTAO, 16, cor if hover(r) else Visual.BORDA, 2 if hover(r) else 1, 12)
		Visual.caixa(self, Rect2(r.position + Vector2(16, 16), Vector2(46, 46)), cor, 12)
		Visual.texto(self, Vector2(r.position.x + 16, r.position.y + 46), emp["sigla"], 17, Visual.FUNDO, HORIZONTAL_ALIGNMENT_CENTER, 46)
		Visual.texto(self, r.position + Vector2(74, 36), emp["nome"], 19, Visual.TEXTO)
		Visual.texto(self, r.position + Vector2(74, 56), emp["setor"], 13, Visual.TEXTO_SUAVE)
		for k in 3:
			Visual.estrela(self, Vector2(r.end.x - 52 + k * 16, r.position.y + 28), 6.0, cor if k < emp["dificuldade"] else Visual.BORDA)
		Visual.paragrafo(self, r.position + Vector2(16, 92), emp["descricao"], 12, Visual.TEXTO_SUAVE, 258, 1.45, 4)
		var nomes_sites: Array = []
		for s in emp["sites"]:
			nomes_sites.append(s["nome"])
		Visual.paragrafo(self, r.position + Vector2(16, 186), "Sistemas: " + " · ".join(nomes_sites), 11, Visual.TEXTO, 258, 1.4, 2)
		var recorde: int = progresso["recordes"].get(emp["id"], 0)
		Visual.texto(self, r.position + Vector2(16, 240), "Recorde: dia %d" % recorde if recorde > 0 else "Ainda não jogada", 13, Visual.CREDITOS if recorde > 0 else Visual.TEXTO_SUAVE)
	Visual.botao(self, Rect2(40, 664, 150, 44), "Voltar", Visual.DESTAQUE, hover(Rect2(40, 664, 150, 44)))


func desenhar_academia() -> void:
	var ids := ids_licoes()
	Visual.texto(self, Vector2(40, 66), "Academia", 30, Visual.TEXTO)
	Visual.texto(self, Vector2(40, 94), "%d de %d lições desbloqueadas. Novas lições aparecem enquanto você joga." % [progresso["licoes"].size(), ids.size()], 15, Visual.TEXTO_SUAVE)
	for i in ids.size():
		var r := retangulo_licao(i)
		var aberta: bool = ids[i] in progresso["licoes"]
		var licao: Dictionary = Dados.LICOES[ids[i]]
		Visual.caixa(self, r, Visual.CARTAO if aberta else Color(1, 1, 1, 0.02), 12, Visual.DESTAQUE if aberta and hover(r) else Visual.BORDA, 1)
		if aberta:
			Visual.texto(self, r.position + Vector2(14, 22), String(licao["categoria"]).to_upper(), 10, Visual.DESTAQUE)
			Visual.paragrafo(self, r.position + Vector2(14, 42), licao["titulo"], 14, Visual.TEXTO, 262, 1.3, 2)
		else:
			Visual.cadeado(self, r.position + Vector2(28, 40), Visual.BORDA_HOVER, 1.0)
			Visual.texto(self, r.position + Vector2(52, 44), "Desbloqueie jogando", 13, Visual.TEXTO_SUAVE)
	Visual.botao(self, Rect2(40, 664, 190, 44), "Voltar ao jogo" if tela_retorno == Tela.JOGO else "Voltar", Visual.DESTAQUE, hover(Rect2(40, 664, 190, 44)))


func desenhar_jogo() -> void:
	desenhar_site()
	desenhar_topo()
	desenhar_abas()
	desenhar_painel()
	desenhar_lateral()
	desenhar_banner()
	if fase == Fase.RELATORIO:
		desenhar_relatorio()
	elif fase == Fase.FIM:
		desenhar_fim()


func desenhar_site() -> void:
	var s = site()
	var mostrando_grade: bool = ferramenta != "" or arraste.get("ativo", false)
	for cx in s.COLUNAS:
		for cy in s.LINHAS:
			var r := Rect2(s.centro_celula(Vector2i(cx, cy)) - s.TAMANHO_NO / 2, s.TAMANHO_NO)
			Visual.caixa(self, r, Color(1, 1, 1, 0.035 if mostrando_grade else 0.012), 12, Color(1, 1, 1, 0.06) if mostrando_grade else Visual.TRANSPARENTE, 1 if mostrando_grade else 0)
	for a in s.nos:
		for b in s.nos[a]["saidas"]:
			var selecionada: bool = selecao.get("tipo", "") == "aresta" and selecao["de"] == a and selecao["para"] == b
			var ligada: bool = selecao.get("tipo", "") == "no" and (selecao["id"] == a or selecao["id"] == b)
			var pontos := PackedVector2Array()
			for k in 21:
				pontos.append(s.ponto_aresta(a, b, k / 20.0))
			var cor := Visual.DESTAQUE if selecionada else (Visual.BORDA_HOVER if ligada else Visual.LINHA)
			draw_polyline(pontos, cor, 3.5 if selecionada else 3.0, true)
	for p in s.pacotes:
		var cor_p: Color = Dados.TIPOS_REQ[p["tipo"]]["cor"]
		Visual.caixa(self, Rect2(p["pos"] - Vector2(4.5, 4.5), Vector2(9, 9)), cor_p, 3, Visual.TRANSPARENTE, 0, 0, 2)
	for id in s.nos:
		desenhar_no(s, id)
	for efeito in s.efeitos:
		desenhar_efeito(efeito)
	desenhar_interacao(s)


func desenhar_no(s, id: int) -> void:
	var no: Dictionary = s.nos[id]
	var tipo: String = no["tipo"]
	var r: Rect2 = s.retangulo_no(id)
	var cor: Color = Visual.DESTAQUE if tipo == "internet" else Dados.COMPONENTES[tipo]["cor"]
	var terminal: bool = tipo in Dados.TERMINAIS
	var caido: bool = no["caido"] > 0.0
	var proporcao: float = no["carga"] / s.CAPACIDADE
	if terminal and not caido and proporcao > 0.85:
		r.position += Vector2(sin(tempo_anim * 45.0), cos(tempo_anim * 38.0)) * 1.5
	var selecionado: bool = selecao.get("tipo", "") == "no" and selecao["id"] == id
	var em_conexao := modo_conectar == id
	var borda := Visual.BORDA_HOVER if hover(r) and pode_interagir() else Visual.BORDA
	if no["pulso"] > 0.0:
		borda = borda.lerp(cor, no["pulso"] * 0.8)
	if caido:
		borda = Visual.PERIGO
	if selecionado or em_conexao:
		borda = cor
	Visual.caixa(self, r, Color("1f1216") if caido else Visual.CARTAO, 12, borda, 2 if selecionado or em_conexao or caido else 1, 8)
	if terminal:
		Visual.torre(self, r, cor, no["nivel"], proporcao, caido, tempo_anim, no["escala"])
		var rotulo := ""
		if caido:
			rotulo = "OFFLINE %ds" % ceili(no["caido"])
		elif tipo == "autoscale":
			rotulo = "x%.1f  %d%%" % [no["escala"], int(proporcao * 100)]
		else:
			rotulo = "Torre  %d%%" % int(proporcao * 100)
		Visual.texto(self, Vector2(r.position.x, r.end.y - 6), rotulo, 10, Visual.PERIGO if caido else Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	elif tipo == "internet":
		Visual.icone(self, "internet", r.position + Vector2(r.size.x / 2, 26), cor, 1.1)
		Visual.texto(self, Vector2(r.position.x, r.position.y + 58), "Internet", 13, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		var por_minuto: float = s.taxa_atual() * 60.0 * Dados.REQ_POR_PACOTE
		Visual.texto(self, Vector2(r.position.x, r.position.y + 73), "%s req/min" % Visual.requisicoes(por_minuto) if s.gerando else "aguardando", 10, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	else:
		var badge := Rect2(r.position + Vector2(r.size.x / 2 - 17, 8), Vector2(34, 34))
		Visual.caixa(self, badge, Visual.com_alfa(cor, 0.16), 10)
		Visual.icone(self, tipo, badge.get_center(), cor, 0.95)
		for k in Dados.NIVEL_MAXIMO:
			draw_circle(Vector2(r.position.x + 10, r.position.y + 12 + k * 8), 2.6, cor if k < no["nivel"] else Visual.BORDA, true, -1.0, true)
		Visual.texto(self, Vector2(r.position.x, r.position.y + 58), Dados.COMPONENTES[tipo]["nome"], 11, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		Visual.texto(self, Vector2(r.position.x, r.position.y + 72), subtitulo_no(s, no), 10, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		if tipo == "fila" and not no["fila"].is_empty():
			var cheio: float = float(no["fila"].size()) / s.capacidade_fila(no)
			Visual.caixa(self, Rect2(r.end.x - 12, r.position.y + 10, 5, 30), Visual.LINHA, 2)
			Visual.caixa(self, Rect2(r.end.x - 12, r.position.y + 40 - 30 * cheio, 5, maxf(3.0, 30 * cheio)), cor, 2)
	if tipo != "internet":
		draw_circle(s.porta_entrada(id), 3.5, Visual.BORDA_HOVER, true, -1.0, true)
	if s.tem_saida(id):
		var porta: Vector2 = s.porta_saida(id)
		var perto: bool = pode_interagir() and porta.distance_to(mouse) <= 14.0
		var raio := 8.0 if perto else 6.0
		draw_circle(porta, raio, Visual.CARTAO_CLARO, true, -1.0, true)
		draw_arc(porta, raio, 0.0, TAU, 20, cor, 2.0, true)
		if no["saidas"].is_empty() and int(tempo_anim * 2.0) % 2 == 0:
			draw_arc(porta, 11.0, 0.0, TAU, 20, Visual.CREDITOS, 1.5, true)


func subtitulo_no(s, no: Dictionary) -> String:
	match no["tipo"]:
		"lb":
			return ["Round-robin", "RR + Health", "Menor carga"][no["nivel"] - 1]
		"fila":
			return "%d/%d na fila" % [no["fila"].size(), s.capacidade_fila(no)]
		"cdn", "redis":
			return "%d no cache" % no["contagem"]
	return "%d bloqueados" % no["contagem"]


func desenhar_efeito(e: Dictionary) -> void:
	var p: float = e["tempo"] / e["duracao"]
	var pos: Vector2 = e["pos"]
	var cor: Color = e.get("cor", Visual.TEXTO)
	var semente: float = e["semente"]
	match e["tipo"]:
		"captcha":
			var cor_bot: Color = e["cor_bot"]
			var alvo: Vector2 = e["alvo"]
			var mira := pos + Vector2(0, -34)
			if p < 0.35:
				Visual.robo(self, pos, cor_bot, 0.9)
				Visual.robo(self, alvo.lerp(mira, ease(p / 0.35, 0.5)), cor, 1.15)
			elif p < 0.55:
				var brilho := 1.0 - (p - 0.35) / 0.2
				draw_line(mira + Vector2(0, 6), pos, Color(1, 1, 1, brilho), 5.0, true)
				draw_line(mira + Vector2(0, 6), pos, cor, 2.5, true)
				draw_circle(pos, 10.0 * brilho, Visual.com_alfa(Color.WHITE, 0.5 * brilho), true, -1.0, true)
				Visual.robo(self, pos, cor_bot, 0.9, true)
				Visual.robo(self, mira, cor, 1.15)
			else:
				var q := (p - 0.55) / 0.45
				Visual.robo(self, mira + Vector2(0, -18 * q), Visual.com_alfa(cor, 1.0 - q), 1.15)
				for k in 10:
					var angulo := semente + k * TAU / 10.0
					var fragmento := pos + Vector2(cos(angulo), sin(angulo)) * (5.0 + q * 36.0)
					Visual.caixa(self, Rect2(fragmento - Vector2(3, 3), Vector2(6, 6)), Visual.com_alfa(cor_bot, 1.0 - q), 2, Visual.TRANSPARENTE, 0, 0, 1)
		"bloqueio":
			draw_arc(pos, 6.0 + p * 14.0, -PI / 2, PI / 2, 16, Visual.com_alfa(cor, 1.0 - p), 3.0, true)
			var cor_bot2: Color = e["cor_bot"]
			for k in 5:
				var angulo2 := semente + k * TAU / 5.0
				var fragmento2 := pos + Vector2(cos(angulo2), sin(angulo2)) * (3.0 + p * 18.0)
				Visual.caixa(self, Rect2(fragmento2 - Vector2(2, 2), Vector2(4, 4)), Visual.com_alfa(cor_bot2, 1.0 - p), 1, Visual.TRANSPARENTE, 0, 0, 1)
		"absorver":
			draw_arc(pos, 2.0 + 16.0 * (1.0 - p), 0.0, TAU, 24, Visual.com_alfa(cor, 1.0 - p), 2.0, true)
			draw_circle(pos, maxf(0.5, 4.0 * (1.0 - p)), Visual.com_alfa(cor, 0.6 * (1.0 - p)), true, -1.0, true)
		"cache":
			var c := pos + Vector2(0, -16.0 * p)
			draw_polyline(PackedVector2Array([c + Vector2(-5, 0), c + Vector2(-1, 4), c + Vector2(6, -5)]), Visual.com_alfa(cor, 1.0 - p), 2.5, true)
		"perdido":
			var a := Visual.com_alfa(cor, 1.0 - p)
			draw_line(pos + Vector2(-5, -5), pos + Vector2(5, 5), a, 2.0, true)
			draw_line(pos + Vector2(-5, 5), pos + Vector2(5, -5), a, 2.0, true)
		"queda":
			for k in 12:
				var angulo3 := semente + k * TAU / 12.0
				var direcao := Vector2(cos(angulo3), sin(angulo3))
				var inicio := pos + direcao * (10.0 + p * 30.0)
				draw_line(inicio, inicio + direcao * 8.0, Visual.com_alfa(Color("fbbf24").lerp(Color("ef4444"), p), 1.0 - p), 2.0, true)
			for k in 3:
				var fumaca := pos + Vector2(-12 + k * 12, -20 - p * 40.0 - k * 6)
				draw_circle(fumaca, 6.0 + p * 10.0, Color(0.6, 0.6, 0.65, 0.35 * (1.0 - p)), true, -1.0, true)
		"dinheiro":
			var valor: float = e["valor"]
			var texto_valor := ("+" if valor > 0.0 else "") + Visual.dinheiro(valor)
			var cor_dinheiro := Visual.HUMANO if valor > 0.0 else Visual.PERIGO
			Visual.texto(self, pos + Vector2(-60, -28.0 * p), texto_valor, 12, Visual.com_alfa(cor_dinheiro, 1.0 - p * p), HORIZONTAL_ALIGNMENT_CENTER, 120)
		"vazamento":
			Visual.cadeado(self, pos + Vector2(0, -18.0 * p), Visual.com_alfa(cor, 1.0 - p), 1.2, true)
			Visual.texto(self, pos + Vector2(-70, -30 - 18.0 * p), "Conta invadida!", 12, Visual.com_alfa(cor, 1.0 - p), HORIZONTAL_ALIGNMENT_CENTER, 140)


func desenhar_interacao(s) -> void:
	if not pode_interagir():
		return
	if ferramenta != "" and RET_CANVAS.has_point(mouse):
		var celula: Vector2i = s.celula_em(mouse)
		if s.celula_valida(celula):
			var livre: bool = s.no_na_celula(celula) < 0
			var r := Rect2(s.centro_celula(celula) - s.TAMANHO_NO / 2, s.TAMANHO_NO)
			var cor: Color = Dados.COMPONENTES[ferramenta]["cor"] if livre else Visual.PERIGO
			Visual.caixa(self, r, Visual.com_alfa(cor, 0.12), 12, cor, 2)
			Visual.icone(self, ferramenta, r.get_center(), Visual.com_alfa(cor, 0.8), 1.0)
	if arraste.get("ativo", false):
		var alvo: Dictionary = arraste["alvo"]
		if alvo.get("tipo", "") == "porta":
			var inicio: Vector2 = s.porta_saida(alvo["id"])
			var destino: int = s.no_em(mouse)
			var cor_linha := Visual.DESTAQUE
			if destino >= 0 and destino != alvo["id"]:
				var valido: bool = s.pode_conectar(alvo["id"], destino) == ""
				cor_linha = Visual.HUMANO if valido else Visual.PERIGO
				Visual.caixa(self, s.retangulo_no(destino).grow(4), Visual.TRANSPARENTE, 14, cor_linha, 2)
			draw_line(inicio, mouse, cor_linha, 2.5, true)
			draw_circle(mouse, 5.0, cor_linha, true, -1.0, true)
		elif alvo.get("tipo", "") == "no":
			var celula2: Vector2i = s.celula_em(mouse)
			if s.celula_valida(celula2):
				var ocupante: int = s.no_na_celula(celula2)
				var ok: bool = ocupante < 0 or ocupante == alvo["id"]
				Visual.caixa(self, Rect2(s.centro_celula(celula2) - s.TAMANHO_NO / 2, s.TAMANHO_NO), Visual.TRANSPARENTE, 12, Visual.HUMANO if ok else Visual.PERIGO, 2)
	var dica := ""
	if modo_conectar >= 0:
		dica = "Toque no componente de destino  ·  Esc cancela"
	elif ferramenta != "":
		dica = "Posicionando %s: toque numa célula livre. Logo à direita de outro componente, ele encaixa sozinho." % Dados.COMPONENTES[ferramenta]["nome"]
	if dica != "":
		var largura := Visual.largura_texto(dica, 13) + 30
		var r2 := Rect2(640 - largura / 2, 108, largura, 28)
		Visual.caixa(self, r2, Visual.CARTAO_CLARO, 14, Visual.DESTAQUE, 1)
		Visual.texto(self, Vector2(r2.position.x, r2.position.y + 19), dica, 13, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, r2.size.x)


func desenhar_topo() -> void:
	Visual.caixa(self, RET_TOPO, Visual.CARTAO, 14, Visual.BORDA, 1, 10)
	var cor_empresa: Color = empresa["cor"]
	Visual.caixa(self, Rect2(30, 18, 32, 32), cor_empresa, 8)
	Visual.texto(self, Vector2(30, 40), empresa["sigla"], 13, Visual.FUNDO, HORIZONTAL_ALIGNMENT_CENTER, 32)
	Visual.texto(self, Vector2(72, 32), empresa["nome"], 15, Visual.TEXTO)
	Visual.texto(self, Vector2(72, 49), empresa["setor"], 11, Visual.TEXTO_SUAVE)
	var fase_texto := "Preparação  ·  dia %d" % dia
	var progresso_dia := -1.0
	if fase == Fase.DIA:
		fase_texto = "Dia %d  ·  %s  ·  %ds" % [dia, evento["nome"], maxi(0, ceili(DURACAO_DIA - tempo_dia))]
		progresso_dia = clampf(tempo_dia / DURACAO_DIA, 0.0, 1.0)
	elif fase == Fase.RELATORIO or fase == Fase.FIM:
		fase_texto = "Dia %d encerrado" % dia
	var largura := minf(440.0, Visual.largura_texto(fase_texto, 14) + 36)
	var pilula := Rect2(450 - largura / 2, 17, largura, 34)
	var especial: bool = evento.get("especial", false) and fase == Fase.DIA
	Visual.caixa(self, pilula, Visual.CARTAO_CLARO, 17, Visual.CREDITOS if especial else Visual.TRANSPARENTE, 1)
	Visual.texto(self, Vector2(pilula.position.x, 39), fase_texto, 14, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, pilula.size.x)
	if progresso_dia >= 0.0:
		var trilho := Rect2(pilula.position.x + 18, 46, pilula.size.x - 36, 3)
		Visual.caixa(self, trilho, Visual.LINHA, 2)
		Visual.caixa(self, Rect2(trilho.position, Vector2(trilho.size.x * progresso_dia, 3)), Visual.DESTAQUE, 2)
	Visual.texto(self, Vector2(690, 29), "Caixa" if caixa >= 0.0 else "Caixa (no crédito, limite %s)" % Visual.dinheiro(-LIMITE_CREDITO), 11, Visual.TEXTO_SUAVE if caixa >= 0.0 else Visual.PERIGO)
	Visual.texto(self, Vector2(690, 50), Visual.dinheiro(caixa), 19, Visual.CREDITOS if caixa >= 0.0 else Visual.PERIGO)
	var cor_confianca := Visual.HUMANO if confianca > 50.0 else (Visual.CREDITOS if confianca > 25.0 else Visual.PERIGO)
	Visual.texto(self, Vector2(900, 30), "Confiança dos clientes  %d%%" % ceili(confianca), 11, Visual.TEXTO_SUAVE)
	var barra := Rect2(900, 38, 250, 8)
	Visual.caixa(self, barra, Visual.LINHA, 4)
	Visual.caixa(self, Rect2(barra.position, Vector2(maxf(8.0, barra.size.x * confianca / 100.0), 8)), cor_confianca, 4)
	Visual.caixa(self, RET_VELOCIDADE, Visual.CARTAO_CLARO, 10, Visual.BORDA_HOVER if hover(RET_VELOCIDADE) else Visual.TRANSPARENTE, 1)
	Visual.texto(self, Vector2(RET_VELOCIDADE.position.x, 40), "%dx" % int(velocidade), 14, Visual.DESTAQUE if velocidade > 1.0 else Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, RET_VELOCIDADE.size.x)
	Visual.caixa(self, RET_PAUSA, Visual.CARTAO_CLARO, 10, Visual.BORDA_HOVER if hover(RET_PAUSA) else Visual.TRANSPARENTE, 1)
	var c := RET_PAUSA.get_center()
	Visual.caixa(self, Rect2(c + Vector2(-7, -8), Vector2(5, 16)), Visual.TEXTO, 2)
	Visual.caixa(self, Rect2(c + Vector2(2, -8), Vector2(5, 16)), Visual.TEXTO, 2)


func estado_site(s) -> Color:
	if s.terminais().is_empty():
		return Visual.PERIGO
	var cor := Visual.HUMANO
	for id in s.terminais():
		var no: Dictionary = s.nos[id]
		if no["caido"] > 0.0:
			return Visual.PERIGO
		if no["carga"] / s.CAPACIDADE > 0.75:
			cor = Visual.CREDITOS
	return cor


func desenhar_abas() -> void:
	for i in empresa["sites"].size():
		var r := retangulo_aba(i)
		if i >= sites.size():
			var expansao: int = DIAS_EXPANSAO[i - 1] if i - 1 < DIAS_EXPANSAO.size() else 99
			Visual.caixa(self, r, Color(1, 1, 1, 0.02), 10, Visual.BORDA, 1)
			Visual.cadeado(self, r.position + Vector2(18, 20), Visual.BORDA_HOVER, 0.7)
			Visual.texto(self, r.position + Vector2(32, 22), "%s  ·  dia %d" % [empresa["sites"][i]["nome"], expansao], 12, Visual.TEXTO_SUAVE)
			continue
		var s = sites[i]
		var ativa: bool = i == site_atual
		var status := estado_site(s)
		var alerta: bool = status == Visual.PERIGO and int(tempo_anim * 3.0) % 2 == 0
		Visual.caixa(self, r, Visual.CARTAO_CLARO if ativa else Visual.CARTAO, 10, Visual.PERIGO if alerta else (Visual.DESTAQUE if ativa else Visual.BORDA), 2 if alerta or ativa else 1)
		draw_circle(r.position + Vector2(16, 17), 4.0, status, true, -1.0, true)
		Visual.texto(self, r.position + Vector2(28, 22), "%d  %s" % [i + 1, s.nome], 13, Visual.TEXTO if ativa else Visual.TEXTO_SUAVE)
	Visual.texto(self, Vector2(660, 86), "1 pacote na tela = %s requisições" % Visual.requisicoes(Dados.REQ_POR_PACOTE), 12, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT, 600)


func desenhar_painel() -> void:
	Visual.caixa(self, RET_PAINEL, Visual.CARTAO, 16, Visual.BORDA, 1, 12)
	var s = site()
	match selecao.get("tipo", ""):
		"no":
			if s.nos.has(selecao["id"]):
				desenhar_detalhes_no(s, selecao["id"])
		"aresta":
			Visual.texto(self, Vector2(40, 556), "Conexão", 18, Visual.TEXTO)
			if s.nos.has(selecao["de"]) and s.nos.has(selecao["para"]):
				Visual.texto(self, Vector2(40, 584), "%s ligado a %s" % [nome_no(s, selecao["de"]), nome_no(s, selecao["para"])], 15, Visual.DESTAQUE)
			Visual.paragrafo(self, Vector2(40, 612), "O tráfego segue por esta linha. Um componente com várias saídas divide igualmente entre elas, sem olhar a carga. Só o Load Balancer escolhe de forma inteligente.", 13, Visual.TEXTO_SUAVE, 860, 1.4, 2)
		_:
			Visual.texto(self, Vector2(36, 542), "Componentes", 14, Visual.TEXTO)
			Visual.texto(self, Vector2(132, 542), "toque num item e depois numa célula livre  ·  arraste do círculo à direita de um componente para conectar", 12, Visual.TEXTO_SUAVE)
	if not selecao.is_empty():
		Visual.caixa(self, RET_FECHAR_PAINEL, Visual.CARTAO_CLARO, 8, Visual.BORDA_HOVER if hover(RET_FECHAR_PAINEL) else Visual.TRANSPARENTE, 1)
		var c := RET_FECHAR_PAINEL.get_center()
		draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), Visual.TEXTO, 2.0, true)
		draw_line(c + Vector2(-5, 5), c + Vector2(5, -5), Visual.TEXTO, 2.0, true)
	for b in botoes_painel():
		if b.has("paleta"):
			desenhar_item_paleta(b)
		else:
			var principal: bool = b.get("principal", false)
			Visual.botao(self, b["rect"], b["rotulo"], Visual.PRINCIPAL if principal else Visual.DESTAQUE, hover(b["rect"]), b["ativo"], 14, principal)


func desenhar_item_paleta(b: Dictionary) -> void:
	var tipo: String = b["paleta"]
	var r: Rect2 = b["rect"]
	var dados: Dictionary = Dados.COMPONENTES[tipo]
	var cor: Color = dados["cor"]
	var custo := custo_componente(tipo)
	var pode := caixa >= custo
	var ativo := ferramenta == tipo
	Visual.caixa(self, r, Visual.com_alfa(cor, 0.14) if ativo else Visual.CARTAO_CLARO, 12, cor if ativo or hover(r) else Visual.BORDA, 2 if ativo else 1)
	var badge := Rect2(r.position + Vector2(10, 10), Vector2(30, 30))
	Visual.caixa(self, badge, Visual.com_alfa(cor, 0.16 if pode else 0.06), 8)
	Visual.icone(self, tipo, badge.get_center(), cor if pode else Visual.TEXTO_SUAVE, 0.8)
	Visual.texto(self, r.position + Vector2(48, 24), dados["nome"], 12, Visual.TEXTO if pode else Visual.TEXTO_SUAVE)
	Visual.texto(self, r.position + Vector2(48, 40), Visual.dinheiro(custo), 11, Visual.CREDITOS if pode else Visual.TEXTO_SUAVE)
	var linhas_resumo := Visual.quebrar(dados["resumo"], 9, 120)
	Visual.texto(self, r.position + Vector2(10, 60), linhas_resumo[0] + ("..." if linhas_resumo.size() > 1 else ""), 9, Visual.TEXTO_SUAVE)


func desenhar_detalhes_no(s, id: int) -> void:
	var no: Dictionary = s.nos[id]
	var tipo: String = no["tipo"]
	var cor: Color = Visual.DESTAQUE if tipo == "internet" else Dados.COMPONENTES[tipo]["cor"]
	var badge := Rect2(36, 536, 38, 38)
	Visual.caixa(self, badge, Visual.com_alfa(cor, 0.16), 10)
	Visual.icone(self, tipo, badge.get_center(), cor, 1.0)
	var nome := nome_no(s, id)
	Visual.texto(self, Vector2(86, 556), nome, 18, Visual.TEXTO)
	if tipo != "internet":
		Visual.texto(self, Vector2(90 + Visual.largura_texto(nome, 18), 556), "  nível %d/%d  ·  %s" % [no["nivel"], Dados.NIVEL_MAXIMO, s.nome], 13, Visual.TEXTO_SUAVE)
	var resumo := "Origem de todo o tráfego deste sistema: clientes e bots chegam por aqui." if tipo == "internet" else String(Dados.COMPONENTES[tipo]["resumo"])
	Visual.texto(self, Vector2(86, 574), resumo, 12, Visual.TEXTO_SUAVE)
	var nivel: int = no["nivel"] - 1
	var y := 606.0
	if tipo in Dados.TERMINAIS:
		var texto_torre := "Processa %d de carga/s  ·  carga atual %d%%" % [roundi(s.processamento(no)), int(100.0 * no["carga"] / s.CAPACIDADE)]
		if no["caido"] > 0.0:
			texto_torre = "FORA DO AR por mais %ds. Clientes enviados para cá são perdidos." % ceili(no["caido"])
		Visual.texto(self, Vector2(40, y), texto_torre, 14, Visual.PERIGO if no["caido"] > 0.0 else Visual.TEXTO)
		if tipo == "autoscale":
			Visual.texto(self, Vector2(40, y + 22), "Escala atual x%.1f (máximo x%.1f). Máquinas extras custam dinheiro por segundo." % [no["escala"], Dados.COMPONENTES["autoscale"]["escala_maxima"]], 12, Visual.TEXTO_SUAVE)
		elif no["nivel"] < Dados.NIVEL_MAXIMO:
			Visual.texto(self, Vector2(40, y + 22), "Melhorando: %d de carga/s" % roundi(Dados.COMPONENTES[tipo]["processamento"][nivel + 1]), 12, Visual.TEXTO_SUAVE)
	elif tipo == "lb":
		var explicacoes := ["Round-robin: um pedido para cada saída, em rodízio. Ainda manda tráfego para torre caída.", "Health Check ativo: pula torres fora do ar. Próximo nível: menor carga.", "Menor carga + Health Check: sempre a torre mais livre."]
		Visual.paragrafo(self, Vector2(40, y), explicacoes[nivel], 13, Visual.TEXTO, 840, 1.4, 2)
	elif tipo == "fila":
		Visual.texto(self, Vector2(40, y), "Capacidade %d  ·  libera %d por segundo  ·  %d esperando agora" % [s.capacidade_fila(no), roundi(s.vazao_fila(no)), no["fila"].size()], 14, Visual.TEXTO)
		Visual.texto(self, Vector2(40, y + 22), "Segura quando as torres de saída passam de 85%. Cliente que espera mais de 6s desiste.", 12, Visual.TEXTO_SUAVE)
	elif tipo == "internet":
		Visual.texto(self, Vector2(40, y), "Saídas: %d  ·  com mais de uma, o tráfego é dividido igualmente" % no["saidas"].size(), 14, Visual.TEXTO)
	else:
		var dados: Dictionary = Dados.COMPONENTES[tipo]
		var x := 40.0
		if dados.has("cache"):
			desenhar_barra_efeito(Vector2(x, y), "Clientes pelo cache", dados["cache"][nivel], Visual.HUMANO)
			x += 190.0
		var bloqueios: Dictionary = dados.get("bloqueio", {})
		for bot in Dados.BOTS:
			if bloqueios.has(bot):
				var chance: float = minf(s.LIMITE_BLOQUEIO, bloqueios[bot] * Dados.MULT_NIVEL[nivel]) * (1.0 - s.sofisticacao)
				desenhar_barra_efeito(Vector2(x, y), NOMES_BOTS[bot], chance, Dados.TIPOS_REQ[bot]["cor"])
				x += 170.0
		var falso: float = dados.get("falso", 0.0) * Dados.FALSO_NIVEL[nivel]
		if falso > 0.0:
			Visual.texto(self, Vector2(40, y + 34), "Erro com clientes reais: %s%%" % Visual.formatar_decimal(falso * 100.0 * (s.falso_geo if tipo == "geo" else 1.0)), 12, Visual.CREDITOS)


func desenhar_barra_efeito(pos: Vector2, rotulo: String, valor: float, cor: Color) -> void:
	Visual.texto(self, pos, rotulo, 11, cor)
	var trilho := Rect2(pos + Vector2(0, 8), Vector2(110, 6))
	Visual.caixa(self, trilho, Visual.LINHA, 3)
	Visual.caixa(self, Rect2(trilho.position, Vector2(maxf(6.0, trilho.size.x * valor), 6)), cor, 3)
	Visual.texto(self, pos + Vector2(118, 15), "%d%%" % roundi(valor * 100.0), 11, Visual.TEXTO)


func desenhar_lateral() -> void:
	Visual.caixa(self, RET_LATERAL, Visual.CARTAO, 16, Visual.BORDA, 1, 12)
	var x := 956.0
	if fase == Fase.DIA:
		Visual.texto(self, Vector2(x, 546), "Dia %d ao vivo" % dia, 14, Visual.TEXTO_SUAVE)
		var por_minuto := 0.0
		var receita := 0.0
		var prejuizo := 0.0
		var atendidos := 0
		var humanos := 0
		var bloqueados := 0
		var bots := 0
		var caidas := 0
		for s in sites:
			por_minuto += s.taxa_atual() * 60.0 * Dados.REQ_POR_PACOTE
			var e: Dictionary = s.estatisticas
			receita += e["receita"]
			prejuizo += e["prejuizo_queda"] + e["custo_nuvem"] + e["multas"]
			atendidos += e["servidos"]
			humanos += e["humanos"]
			bloqueados += s.total("bloqueados")
			bots += s.total("bots")
			for id in s.terminais():
				if s.nos[id]["caido"] > 0.0:
					caidas += 1
		var linhas := [
			["Tráfego agora", "%s req/min" % Visual.requisicoes(por_minuto), Visual.TEXTO],
			["Receita do dia", Visual.dinheiro(receita), Visual.HUMANO],
			["Prejuízo do dia", Visual.dinheiro(-prejuizo) if prejuizo > 0.5 else "R$ 0", Visual.PERIGO],
			["Clientes atendidos", "%d%%" % (roundi(100.0 * atendidos / humanos) if humanos > 0 else 100), Visual.HUMANO],
			["Bots bloqueados", "%d%%" % (roundi(100.0 * bloqueados / bots) if bots > 0 else 0), Visual.DESTAQUE],
			["Torres fora do ar", "%d" % caidas, Visual.PERIGO if caidas > 0 else Visual.TEXTO_SUAVE],
		]
		for k in linhas.size():
			var y := 574.0 + k * 22.0
			Visual.texto(self, Vector2(x, y), linhas[k][0], 12, Visual.TEXTO_SUAVE)
			Visual.texto(self, Vector2(x, y), linhas[k][1], 13, linhas[k][2], HORIZONTAL_ALIGNMENT_RIGHT, 288)
		return
	if fase != Fase.PREPARACAO:
		return
	var especial: bool = evento["especial"]
	Visual.texto(self, Vector2(x, 546), "Próximo: dia %d" % dia, 12, Visual.TEXTO_SUAVE)
	Visual.texto(self, Vector2(x, 568), evento["nome"], 17, Visual.CREDITOS if especial else Visual.TEXTO)
	var y2 := Visual.paragrafo(self, Vector2(x, 588), evento["explicacao"], 11, Visual.TEXTO_SUAVE, 288, 1.35, 3)
	Visual.paragrafo(self, Vector2(x, y2 + 2), "Dica: " + String(evento["dica"]), 11, Visual.DESTAQUE, 288, 1.35, 2)
	var previsto := taxa_do_dia() * 60.0 * Dados.REQ_POR_PACOTE
	Visual.botao(self, RET_INICIAR, "Iniciar dia %d  ·  %s req/min" % [dia, Visual.requisicoes(previsto)], Visual.PRINCIPAL, hover(RET_INICIAR), true, 15, true)


func desenhar_banner() -> void:
	if banner.is_empty():
		return
	var t: float = banner["tempo"]
	var duracao: float = banner["duracao"]
	var entrada := clampf(t / 0.35, 0.0, 1.0)
	var alfa := minf(entrada, clampf((duracao - t) / 0.4, 0.0, 1.0))
	var y := 180.0 - (1.0 - ease(entrada, 0.4)) * 60.0
	var r := Rect2(240, y, 800, 110)
	var especial: bool = banner["especial"]
	var cor := Visual.CREDITOS if especial else Visual.DESTAQUE
	if especial and int(t * 6.0) % 2 == 0:
		cor = Visual.PERIGO
	Visual.caixa(self, r, Visual.com_alfa(Visual.CARTAO, 0.96 * alfa), 18, Visual.com_alfa(cor, alfa), 2, 20)
	var titulo: String = banner["titulo"]
	Visual.texto(self, Vector2(r.position.x, y + 48), titulo.to_upper() if especial else titulo, 32, Visual.com_alfa(cor, alfa), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var linhas := Visual.quebrar(banner["sub"], 14, 740)
	for i in mini(2, linhas.size()):
		Visual.texto(self, Vector2(r.position.x, y + 76 + i * 19), linhas[i], 14, Visual.com_alfa(Visual.TEXTO, alfa), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func desenhar_relatorio() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Visual.SOBREPOSICAO)
	Visual.caixa(self, RET_CARTAO_RELATORIO, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	if relatorio["etapa"] == 1:
		desenhar_quiz()
		return
	var x := RET_CARTAO_RELATORIO.position.x + 30
	Visual.texto(self, Vector2(x, 84), "Fim do dia %d" % relatorio["dia"], 28, Visual.TEXTO)
	Visual.texto(self, Vector2(x + 200, 84), relatorio["evento"], 16, Visual.CREDITOS if relatorio["especial"] else Visual.TEXTO_SUAVE)
	var prejuizos: float = relatorio["queda"] + relatorio["nuvem"] + relatorio["multas"]
	var saldo: float = relatorio["receita"] - prejuizos + relatorio["aporte"]
	var valores := [
		["Receita", Visual.dinheiro(relatorio["receita"]), Visual.HUMANO],
		["Prejuízos", Visual.dinheiro(-prejuizos) if prejuizos > 0.5 else "R$ 0", Visual.PERIGO],
		["Aporte do conselho", Visual.dinheiro(relatorio["aporte"]), Visual.DESTAQUE],
		["Resultado do dia", Visual.dinheiro(saldo), Visual.HUMANO if saldo >= 0.0 else Visual.PERIGO],
	]
	for i in valores.size():
		var r := Rect2(x + i * 236, 104, 224, 64)
		Visual.caixa(self, r, Visual.CARTAO_CLARO, 12)
		Visual.texto(self, r.position + Vector2(14, 24), valores[i][0], 12, Visual.TEXTO_SUAVE)
		Visual.texto(self, r.position + Vector2(14, 50), valores[i][1], 20, valores[i][2])
	var humanos: int = relatorio["humanos"]
	var bots: int = relatorio["bots"]
	var metricas := [
		["Uptime", "%s%%" % Visual.formatar_decimal(100.0 * relatorio["uptime"])],
		["Clientes atendidos", "%d%%" % (roundi(100.0 * relatorio["servidos"] / humanos) if humanos > 0 else 100)],
		["Bots bloqueados", "%d%%" % (roundi(100.0 * relatorio["bloqueados"] / bots) if bots > 0 else 0)],
		["Confiança", "%d%%" % ceili(confianca)],
	]
	for i in metricas.size():
		Visual.texto(self, Vector2(x + i * 236, 196), metricas[i][0], 12, Visual.TEXTO_SUAVE)
		Visual.texto(self, Vector2(x + i * 236, 220), metricas[i][1], 18, Visual.TEXTO)
	Visual.texto(self, Vector2(x, 262), "Mandou bem", 17, Visual.HUMANO)
	var y := 292.0
	for elogio in relatorio["elogios"].slice(0, 5):
		draw_circle(Vector2(x + 5, y - 5), 3.5, Visual.HUMANO, true, -1.0, true)
		y = Visual.paragrafo(self, Vector2(x + 16, y), elogio, 13, Visual.TEXTO, 370, 1.4, 3) + 8.0
	var x2 := x + 420
	var problemas: Array = relatorio["problemas"]
	Visual.texto(self, Vector2(x2, 262), "Por que deu problema" if not problemas.is_empty() else "Nenhum problema grave hoje", 17, Visual.PERIGO if not problemas.is_empty() else Visual.HUMANO)
	for i in problemas.size():
		var pr: Dictionary = problemas[i]
		var topo := 296.0 + i * 76.0
		Visual.texto(self, Vector2(x2, topo + 12), pr["titulo"], 14, Visual.TEXTO)
		var link := retangulo_entender(i)
		Visual.caixa(self, link, Visual.com_alfa(Visual.DESTAQUE, 0.2 if hover(link) else 0.1), 8)
		Visual.texto(self, Vector2(link.position.x, link.position.y + 18), "Entender", 12, Visual.DESTAQUE, HORIZONTAL_ALIGNMENT_CENTER, link.size.x)
		Visual.paragrafo(self, Vector2(x2, topo + 32), pr["porque"], 11, Visual.TEXTO_SUAVE, 410, 1.3, 2)
		Visual.paragrafo(self, Vector2(x2, topo + 61), "Como resolver: " + String(pr["solucao"]), 11, Visual.HUMANO, 540, 1.3, 1)
	var rotulo := "Ir para o quiz do conselho" if not relatorio["quiz"].is_empty() else "Continuar para o dia %d" % (dia + 1)
	Visual.botao(self, RET_CONTINUAR, rotulo, Visual.PRINCIPAL, hover(RET_CONTINUAR), true, 15, true)


func desenhar_quiz() -> void:
	var quiz: Dictionary = relatorio["quiz"]
	var resposta: int = relatorio["resposta"]
	Visual.texto(self, Vector2(0, 110), "Quiz do conselho", 15, Visual.CREDITOS, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	Visual.texto(self, Vector2(0, 136), "Acerte e o conselho libera %s para sua equipe" % Visual.dinheiro(BONUS_QUIZ), 13, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	var linhas := Visual.quebrar(quiz["pergunta"], 22, 860)
	for i in linhas.size():
		Visual.texto(self, Vector2(0, 200 + i * 30), linhas[i], 22, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, 1280)
	for i in 3:
		var r := retangulo_opcao_quiz(i)
		var cor_borda := Visual.BORDA_HOVER if hover(r) and resposta < 0 else Visual.BORDA
		var fundo := Visual.CARTAO_CLARO
		var destaque := false
		if resposta >= 0:
			if i == quiz["correta"]:
				cor_borda = Visual.HUMANO
				fundo = Visual.com_alfa(Visual.HUMANO, 0.15)
				destaque = true
			elif i == resposta:
				cor_borda = Visual.PERIGO
				fundo = Visual.com_alfa(Visual.PERIGO, 0.15)
				destaque = true
		Visual.caixa(self, r, fundo, 12, cor_borda, 2 if destaque else 1)
		Visual.texto(self, r.position + Vector2(20, 36), "%d   %s" % [i + 1, quiz["opcoes"][i]], 17, Visual.TEXTO)
	if resposta >= 0:
		var acertou: bool = resposta == quiz["correta"]
		Visual.texto(self, Vector2(260, 532), "Acertou! +%s no caixa." % Visual.dinheiro(BONUS_QUIZ) if acertou else "Não foi dessa vez.", 17, Visual.HUMANO if acertou else Visual.PERIGO)
		Visual.paragrafo(self, Vector2(260, 560), "Por quê: " + String(quiz["explicacao"]), 14, Visual.TEXTO_SUAVE, 600, 1.4, 2)
		Visual.botao(self, RET_CONTINUAR, "Continuar para o dia %d" % (dia + 1), Visual.PRINCIPAL, hover(RET_CONTINUAR), true, 15, true)


func desenhar_fim() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Visual.SOBREPOSICAO)
	var cartao := Rect2(290, 120, 700, 520)
	Visual.caixa(self, cartao, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	var falencia := motivo_fim == "falencia"
	Visual.texto(self, Vector2(cartao.position.x, 196), "Falência" if falencia else "Os clientes foram embora", 40, Visual.PERIGO, HORIZONTAL_ALIGNMENT_CENTER, cartao.size.x)
	var explicacao := "O caixa estourou o limite de crédito. Torres travadas, multas e gasto de nuvem consumiram mais do que a empresa faturou. Na vida real, é aqui que o conselho troca o CTO." if falencia else "A confiança chegou a zero. Clientes perdidos, barrados por engano ou com contas invadidas migraram para a concorrência."
	Visual.paragrafo(self, Vector2(cartao.position.x + 50, 240), explicacao, 15, Visual.TEXTO_SUAVE, 600, 1.45, 4)
	var recorde: int = progresso["recordes"].get(empresa["id"], 0)
	var linhas := [
		["Dias completos", "%d" % (dia - 1)],
		["Receita total", Visual.dinheiro(totais["receita"])],
		["Prejuízo total", Visual.dinheiro(-totais["prejuizo"])],
		["Recorde na %s" % empresa["nome"], "dia %d" % recorde],
	]
	for i in linhas.size():
		var y := 360.0 + i * 36.0
		Visual.texto(self, Vector2(cartao.position.x + 80, y), linhas[i][0], 16, Visual.TEXTO_SUAVE)
		Visual.texto(self, Vector2(cartao.position.x + 80, y), linhas[i][1], 17, Visual.TEXTO, HORIZONTAL_ALIGNMENT_RIGHT, 540)
	Visual.botao(self, Rect2(330, 560, 200, 52), "Tentar de novo", Visual.PRINCIPAL, hover(Rect2(330, 560, 200, 52)), true, 16, true)
	Visual.botao(self, Rect2(540, 560, 200, 52), "Trocar empresa", Visual.DESTAQUE, hover(Rect2(540, 560, 200, 52)))
	Visual.botao(self, Rect2(750, 560, 200, 52), "Menu", Visual.DESTAQUE, hover(Rect2(750, 560, 200, 52)))


func desenhar_modal() -> void:
	if modal.is_empty():
		return
	draw_rect(Rect2(0, 0, 1280, 720), Visual.SOBREPOSICAO)
	match modal["tipo"]:
		"licao":
			desenhar_licao(modal["id"])
		"boas_vindas":
			desenhar_boas_vindas()
		"pausa":
			var cartao := Rect2(440, 210, 400, 330)
			Visual.caixa(self, cartao, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
			Visual.texto(self, Vector2(cartao.position.x, 290), "Pausado", 34, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, cartao.size.x)
			Visual.botao(self, Rect2(490, 330, 300, 52), "Continuar", Visual.PRINCIPAL, hover(Rect2(490, 330, 300, 52)), true, 17, true)
			Visual.botao(self, Rect2(490, 392, 300, 52), "Academia", Visual.DESTAQUE, hover(Rect2(490, 392, 300, 52)))
			Visual.botao(self, Rect2(490, 454, 300, 52), "Sair para o menu", Visual.DESTAQUE, hover(Rect2(490, 454, 300, 52)))
		"apagar":
			var cartao2 := Rect2(390, 220, 500, 260)
			Visual.caixa(self, cartao2, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
			Visual.texto(self, Vector2(cartao2.position.x, 284), "Apagar todos os seus dados?", 24, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, cartao2.size.x)
			Visual.paragrafo(self, Vector2(430, 322), "Seu apelido, recordes e lições serão removidos deste dispositivo. Não dá para desfazer.", 14, Visual.TEXTO_SUAVE, 420, 1.45, 3)
			Visual.botao(self, Rect2(450, 400, 180, 50), "Apagar", Visual.PERIGO, hover(Rect2(450, 400, 180, 50)))
			Visual.botao(self, Rect2(650, 400, 180, 50), "Cancelar", Visual.DESTAQUE, hover(Rect2(650, 400, 180, 50)))


func desenhar_licao(id: String) -> void:
	var licao: Dictionary = Dados.LICOES[id]
	var cartao := Rect2(240, 90, 800, 566)
	Visual.caixa(self, cartao, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	var x := cartao.position.x + 40
	var tem_icone := Dados.COMPONENTES.has(id)
	if tem_icone:
		var cor: Color = Dados.COMPONENTES[id]["cor"]
		Visual.caixa(self, Rect2(x, 120, 52, 52), Visual.com_alfa(cor, 0.16), 14)
		Visual.icone(self, id, Vector2(x + 26, 146), cor, 1.4)
	var deslocamento := 70.0 if tem_icone else 0.0
	Visual.texto(self, Vector2(x + deslocamento, 136), String(licao["categoria"]).to_upper(), 12, Visual.DESTAQUE)
	Visual.texto(self, Vector2(x + deslocamento, 166), licao["titulo"], 26, Visual.TEXTO)
	var y := Visual.paragrafo(self, Vector2(x, 222), licao["texto"], 16, Visual.TEXTO, 720, 1.5, 12)
	var caixa_real := Rect2(x, y + 6, 720, 100)
	Visual.caixa(self, caixa_real, Visual.CARTAO_CLARO, 12)
	Visual.texto(self, caixa_real.position + Vector2(18, 28), "No mundo real", 13, Visual.CREDITOS)
	Visual.paragrafo(self, caixa_real.position + Vector2(18, 52), licao["mundo_real"], 14, Visual.TEXTO_SUAVE, 684, 1.45, 3)
	Visual.botao(self, retangulo_botao_modal(), "Entendi", Visual.PRINCIPAL, hover(retangulo_botao_modal()), true, 17, true)


func desenhar_boas_vindas() -> void:
	var cartao := Rect2(200, 50, 880, 636)
	Visual.caixa(self, cartao, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	var x := cartao.position.x + 40
	var cor: Color = empresa["cor"]
	Visual.caixa(self, Rect2(x, 82, 56, 56), cor, 14)
	Visual.texto(self, Vector2(x, 118), empresa["sigla"], 20, Visual.FUNDO, HORIZONTAL_ALIGNMENT_CENTER, 56)
	Visual.texto(self, Vector2(x + 74, 104), "Você é o novo CTO da %s" % empresa["nome"], 26, Visual.TEXTO)
	Visual.texto(self, Vector2(x + 74, 130), empresa["setor"], 14, Visual.TEXTO_SUAVE)
	var y := Visual.paragrafo(self, Vector2(x, 176), empresa["descricao"], 15, Visual.TEXTO_SUAVE, 800, 1.45, 3)
	Visual.texto(self, Vector2(x, y + 14), "Como jogar", 17, Visual.TEXTO)
	var passos := [
		"Toque num componente da paleta e depois numa célula livre. Colocado logo à direita de outro, ele encaixa no fluxo sozinho.",
		"Arraste do círculo à direita de um componente até outro para conectar. Toque numa linha para remover a conexão.",
		"Clientes geram receita. Bots geram carga, multas e prejuízo. Cada componente explica o porquê no botão Por quê?.",
		"Torre travada custa dinheiro a cada segundo. Se o caixa ou a confiança zerarem, você está fora.",
	]
	y += 30.0
	for i in passos.size():
		Visual.caixa(self, Rect2(x, y - 15, 24, 24), Visual.com_alfa(Visual.DESTAQUE, 0.16), 7)
		Visual.texto(self, Vector2(x, y + 2), str(i + 1), 13, Visual.DESTAQUE, HORIZONTAL_ALIGNMENT_CENTER, 24)
		y = Visual.paragrafo(self, Vector2(x + 36, y + 1), passos[i], 14, Visual.TEXTO, 760, 1.4, 2) + 8.0
	Visual.texto(self, Vector2(x, y + 10), "Quem passa pela sua rede", 15, Visual.TEXTO)
	var colunas := 0
	for tipo in Dados.TIPOS_REQ:
		var px := x + colunas * 160.0
		Visual.caixa(self, Rect2(px, y + 26, 12, 12), Dados.TIPOS_REQ[tipo]["cor"], 3)
		Visual.texto(self, Vector2(px + 18, y + 37), Dados.TIPOS_REQ[tipo]["nome"], 12, Visual.TEXTO_SUAVE)
		colunas += 1
	Visual.botao(self, retangulo_botao_modal(), "Assumir o cargo", Visual.PRINCIPAL, hover(retangulo_botao_modal()), true, 18, true)


func desenhar_avisos() -> void:
	for i in avisos.size():
		var aviso: Dictionary = avisos[i]
		var t: float = aviso["tempo"]
		var alfa := clampf(minf(t / 0.2, (TEMPO_AVISO - t) / 0.5), 0.0, 1.0)
		var r := retangulo_aviso(i)
		var cor: Color = aviso["cor"]
		Visual.caixa(self, r, Visual.com_alfa(Visual.CARTAO_CLARO, alfa), 17, Visual.com_alfa(cor, alfa), 1, 8)
		Visual.texto(self, Vector2(r.position.x, r.position.y + 22), aviso["texto"], 14, Visual.com_alfa(Visual.TEXTO, alfa), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func desenhar_particulas() -> void:
	for p in particulas:
		var alfa: float = 1.0 - p["vida"] / p["duracao"]
		var tamanho := Vector2(7, 4).rotated(p["giro"])
		var c: Vector2 = p["pos"]
		draw_colored_polygon(PackedVector2Array([c - tamanho, c + Vector2(-tamanho.y, tamanho.x), c + tamanho, c + Vector2(tamanho.y, -tamanho.x)]), Visual.com_alfa(p["cor"], alfa))
