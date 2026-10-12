extends Node2D

const Dados := preload("res://dados.gd")
const Textos := preload("res://textos.gd")
const Site := preload("res://site.gd")
const Visual := preload("res://visual.gd")
const Estado := preload("res://estado.gd")

enum Fase { PREPARACAO, DIA, RELATORIO, FIM }

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
const RECUPERACAO_CONFIANCA := 14.0
const BONUS_EXPANSAO := 900.0
const BONUS_QUIZ := 200.0
const DIAS_EXPANSAO := [4, 8]
const DIAS_SEM_HACKER := 2
const DIAS_RAMPA_HACKER := 4.0
const DIA_PRIMEIRA_ONDA := 8
const MULT_SITES := [1.0, 0.55, 0.45]
const FOCO_EXTRA := 0.15
const FOCO_EXTRA_HACKER := 0.08
const CRESCIMENTO_TORRE := 1.3
const REEMBOLSO := 0.5
const LIMITE_CREDITO := 1200.0
const VALOR_APORTE := 500.0
const MAX_INCIDENTES_DIA := 2
const ZOOM_MINIMO := 0.5
const ZOOM_MAXIMO := 1.25

const RET_TOPO := Rect2(20, 10, 1240, 48)
const RET_CANVAS := Rect2(20, 104, 1240, 410)
const RET_PAINEL := Rect2(20, 522, 910, 188)
const RET_LATERAL := Rect2(940, 522, 320, 188)
const RET_INICIAR := Rect2(956, 656, 288, 44)
const RET_PAUSA := Rect2(1212, 16, 40, 36)
const RET_VELOCIDADE := Rect2(1166, 16, 42, 36)
const RET_FECHAR_PAINEL := Rect2(890, 532, 30, 30)
const RET_CARTAO := Rect2(140, 36, 1000, 648)
const RET_CONTINUAR := Rect2(880, 618, 236, 48)
const RET_ZOOM_MENOS := Rect2(1150, 112, 32, 30)
const RET_ZOOM_MAIS := Rect2(1186, 112, 32, 30)
const RET_CENTRO := Rect2(1222, 112, 32, 30)

const NOMES_AMEACAS := {"volumetrico": "Inundação", "l7": "Imitador", "credencial": "Senhas", "scraper": "Copiador", "sqli": "SQLi", "xss": "XSS", "exploit": "Exploit", "ransomware": "Ransomware", "forca_bruta": "Força bruta"}
const DEFESA_AMEACA := {"volumetrico": "Anti-DDoS ou CDN", "l7": "WAF ou CAPTCHA", "credencial": "Login 2FA", "scraper": "Rate Limit", "sqli": "WAF, IDS/IPS e desafios de código", "xss": "WAF e desafios de código", "exploit": "Patches e IDS/IPS", "ransomware": "EDR, Patches e Backup", "forca_bruta": "Cofre de senhas, 2FA e Rate Limit"}

var principal
var empresa_id := ""
var empresa: Dictionary = {}
var fase := Fase.PREPARACAO
var modal: Dictionary = {}
var sites: Array = []
var site_atual := 0
var dia := 1
var evento: Dictionary = {}
var tempo_dia := 0.0
var caixa := 0.0
var confianca := 100.0
var velocidade := 1.0
var ferramenta := ""
var categoria := "borda"
var selecao: Dictionary = {}
var modo_conectar := -1
var arraste: Dictionary = {}
var mouse := Vector2.ZERO
var tempo_anim := 0.0
var banner: Dictionary = {}
var relatorio: Dictionary = {}
var elogios_dia: Array = []
var elogiados: Dictionary = {}
var totais := {"receita": 0.0, "prejuizo": 0.0, "dividendos": 0.0}
var motivo_fim := ""
var camera := Vector2.ZERO
var zoom := 0.8
var reforcos_ativos: Dictionary = {}
var incidentes_hoje: Dictionary = {}
var fila_incidentes: Array = []
var momento_phishing := -1.0
var hackers_dia := 0


func estado():
	return Estado.atual


func iniciar(id: String) -> void:
	empresa_id = id
	empresa = estado().empresa_dados(id)
	modal = {}
	selecao = {}
	ferramenta = ""
	modo_conectar = -1
	arraste = {}
	banner = {}
	velocidade = 1.0
	reforcos_ativos = {}
	site_atual = 0
	var salvo: Dictionary = estado().obter_operacao(id)
	if not salvo.is_empty() and restaurar(salvo):
		principal.avisar("Partida retomada no dia %d" % dia, Visual.DESTAQUE)
	else:
		nova_partida()
		modal = {"tipo": "boas_vindas"}
	centralizar()


func nova_partida() -> void:
	var primeiro: Dictionary = empresa["sites"][0]
	sites = [Site.new(primeiro["nome"], primeiro["foco"], MULT_SITES[0])]
	dia = 1
	caixa = empresa["caixa"]
	confianca = 100.0
	tempo_dia = 0.0
	elogios_dia = []
	elogiados = {}
	totais = {"receita": 0.0, "prejuizo": 0.0, "dividendos": 0.0}
	evento = evento_do_dia(dia)
	fase = Fase.PREPARACAO
	salvar_partida()


func restaurar(salvo: Dictionary) -> bool:
	if not salvo.has("sites") or salvo["sites"].is_empty():
		return false
	sites = []
	for dados_site in salvo["sites"]:
		sites.append(Site.de_dicionario(dados_site))
	dia = int(salvo.get("dia", 1))
	caixa = float(salvo.get("caixa", empresa["caixa"]))
	confianca = float(salvo.get("confianca", 100.0))
	elogiados = {}
	for chave in salvo.get("elogiados", []):
		elogiados[chave] = true
	totais = {"receita": float(salvo.get("receita", 0.0)), "prejuizo": float(salvo.get("prejuizo", 0.0)), "dividendos": float(salvo.get("dividendos", 0.0))}
	elogios_dia = []
	evento = evento_do_dia(dia)
	fase = Fase.PREPARACAO
	tempo_dia = 0.0
	return true


func salvar_partida() -> void:
	if fase == Fase.FIM:
		return
	var lista: Array = []
	for s in sites:
		lista.append(s.para_dicionario())
	estado().salvar_operacao(empresa_id, {"dia": dia, "caixa": caixa, "confianca": confianca, "sites": lista, "elogiados": elogiados.keys(), "receita": totais["receita"], "prejuizo": totais["prejuizo"], "dividendos": totais["dividendos"]})


func site():
	return sites[site_atual]


func pode_interagir() -> bool:
	return visible and modal.is_empty() and not principal.modal_aberto() and (fase == Fase.PREPARACAO or fase == Fase.DIA)


func _process(delta: float) -> void:
	if not visible:
		return
	mouse = get_local_mouse_position()
	tempo_anim += delta
	if not banner.is_empty():
		banner["tempo"] += delta
		if banner["tempo"] > banner["duracao"]:
			banner = {}
	if modal.is_empty() and not principal.modal_aberto() and (fase == Fase.PREPARACAO or fase == Fase.DIA):
		simular(minf(delta, DELTA_MAXIMO) * velocidade)
		if fila_incidentes.size() > 0 and modal.is_empty():
			modal = fila_incidentes.pop_front()
	if pode_interagir():
		var mover := Vector2.ZERO
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
			mover.x -= 1
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			mover.x += 1
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
			mover.y -= 1
		if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
			mover.y += 1
		if mover != Vector2.ZERO:
			camera += mover * 500.0 * delta / zoom
			limitar_camera()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and visible and pode_interagir() and fase == Fase.DIA:
		modal = {"tipo": "pausa"}


func simular(dt: float) -> void:
	for s in sites:
		s.atualizar(dt)
		coletar(s)
	if fase != Fase.DIA:
		return
	tempo_dia += dt
	if momento_phishing >= 0.0 and tempo_dia >= momento_phishing:
		momento_phishing = -1.0
		disparar_phishing()
	if tempo_dia >= DURACAO_DIA:
		for s in sites:
			s.gerando = false
	if caixa < -LIMITE_CREDITO:
		finalizar("falencia")
		return
	if caixa < 0.0 and not elogiados.has("aviso_credito"):
		elogiados["aviso_credito"] = true
		principal.avisar("Caixa negativo: usando o crédito do banco. Abaixo de %s é falência" % Visual.dinheiro(-LIMITE_CREDITO), Visual.PERIGO, "custo_queda")
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
	match ev["tipo"]:
		"queda":
			var custo: float = s.custo_queda / maxf(1.0, s.terminais().size())
			principal.avisar("%s: torre travou! Prejuízo de %s por segundo" % [s.nome, Visual.dinheiro(custo)], Visual.PERIGO, "escala_horizontal")
			estado().desbloquear_licao("escala_horizontal")
			estado().desbloquear_licao("custo_queda")
		"incidente":
			abrir_incidente(s, ev["incidente"], ev["no"])
		"primeira":
			match ev["motivo"]:
				"sem_saida":
					principal.avisar("%s: clientes sem caminho! Algum componente está sem saída" % s.nome, Visual.CREDITOS, "sem_saida")
					estado().desbloquear_licao("sem_saida")
				"falso_positivo":
					principal.avisar("%s: um filtro barrou um cliente real" % s.nome, Visual.CREDITOS, "falso_positivo")
					estado().desbloquear_licao("falso_positivo")
				"vazamento":
					principal.avisar("%s: conta invadida! Multa da LGPD e confiança em queda" % s.nome, Visual.PERIGO, "vazamento")
					estado().desbloquear_licao("vazamento")
				"xss":
					principal.avisar("%s: hackers picharam uma página com XSS" % s.nome, Visual.PERIGO, "xss")
					estado().desbloquear_licao("xss")
				"caido":
					var licao := "health_check" if not s.ids_do_tipo("lb").is_empty() else "escala_horizontal"
					principal.avisar("%s: clientes enviados para torre fora do ar" % s.nome, Visual.PERIGO, licao)
					estado().desbloquear_licao(licao)
				"fila_cheia", "paciencia":
					principal.avisar("%s: clientes desistiram na fila" % s.nome, Visual.CREDITOS, "fila")
					estado().desbloquear_licao("fila")


func abrir_incidente(s, tipo: String, no_id: int) -> void:
	estado().desbloquear_licao(Textos.INCIDENTES[tipo]["licao"])
	if incidentes_hoje.get(tipo, false) or incidentes_hoje.size() >= MAX_INCIDENTES_DIA:
		principal.avisar("%s: %s" % [s.nome, Textos.INCIDENTES[tipo]["titulo"]], Visual.PERIGO, Textos.INCIDENTES[tipo]["licao"])
		return
	incidentes_hoje[tipo] = true
	var opcoes: Array = range(Textos.INCIDENTES[tipo]["opcoes"].size())
	opcoes.shuffle()
	fila_incidentes.append({"tipo": "incidente", "incidente": tipo, "site": sites.find(s), "no": no_id, "ordem": opcoes, "escolha": -1})


func escolher_incidente(posicao: int) -> void:
	if modal.get("tipo", "") != "incidente" or modal["escolha"] >= 0:
		return
	var indice: int = modal["ordem"][posicao]
	var dados: Dictionary = Textos.INCIDENTES[modal["incidente"]]["opcoes"][indice]
	var s = sites[modal["site"]] if modal["site"] >= 0 and modal["site"] < sites.size() else site()
	var certa = dados["certa"]
	var resultado: String = dados["resultado"]
	if typeof(certa) == TYPE_STRING and certa == "backup":
		if s.nivel_passivo("backup") > 0:
			certa = true
			s.restaurar(modal["no"], 0.5)
		else:
			certa = false
			resultado = dados["resultado_sem"]
			if s.nos.has(modal["no"]):
				s.nos[modal["no"]]["caido"] += 5.0
	modal["escolha"] = posicao
	modal["certa"] = certa
	modal["resultado"] = resultado
	caixa += float(dados.get("dinheiro", 0.0))
	confianca = clampf(confianca + float(dados.get("confianca", 0.0)), 0.0, 100.0)
	if certa:
		estado().somar("incidentes_certos")
		estado().ganhar_xp(int(dados.get("xp", 50)))
		elogiar("incidente_%s" % modal["incidente"], "Resposta a incidente correta. Conter, corrigir e comunicar é o que separa um susto de um desastre.")
	if s.nos.has(modal["no"]) and certa and modal["incidente"] != "ransomware":
		s.restaurar(modal["no"], 3.0)


func disparar_phishing() -> void:
	var s = sites[randi() % sites.size()]
	var resistencia: float = s.efeito_passivo("treinamento")
	if randf() < resistencia:
		principal.avisar("%s: um funcionário reconheceu o phishing e reportou. O treinamento funcionou!" % s.nome, Visual.HUMANO, "treinamento")
		elogiar("phishing_bloqueado", "Equipe treinada reconheceu o phishing. Pessoas atentas são a melhor defesa contra engenharia social.")
		return
	var torres: Array = s.terminais()
	if torres.is_empty():
		return
	var alvo: int = torres[randi() % torres.size()]
	s.comprometer(alvo, "ransomware")
	s.eventos = s.eventos.filter(func(e): return e.get("incidente", "") != "ransomware")
	abrir_incidente(s, "phishing", alvo)


func elogiar(id: String, texto_elogio: String) -> void:
	if elogiados.has(id):
		return
	elogiados[id] = true
	elogios_dia.append(texto_elogio)
	principal.avisar("Mandou bem! " + texto_elogio.get_slice(".", 0) + ".", Visual.HUMANO)
	principal.confete(Vector2(640, 140), 40)
	if id == "escala_horizontal":
		estado().somar("escala_horizontal")


func evento_do_dia(numero: int) -> Dictionary:
	var id := "normal"
	var eventos: Array = empresa["eventos"]
	var ameacas: Array = empresa["ameacas"]
	var hackers: Array = empresa["hackers"]
	if numero > 1:
		if numero % 7 == 0:
			id = hackers[(numero / 7 - 1) % hackers.size()]
		elif numero % 5 == 0:
			id = ameacas[(numero / 5 - 1) % ameacas.size()]
		elif numero % 4 == 0 and numero >= DIA_PRIMEIRA_ONDA and (numero - 1) % 7 != 0:
			id = hackers[(numero / 4) % hackers.size()]
		elif numero % 3 == 0:
			id = eventos[(numero / 3 - 1) % eventos.size()]
	var resultado: Dictionary = Dados.EVENTOS[id].duplicate(true)
	resultado["id"] = id
	var mix: Dictionary = empresa["mix"].duplicate()
	var rampa := rampa_hacker(numero)
	for tipo in Dados.HACKERS:
		if mix.has(tipo):
			mix[tipo] = mix[tipo] * rampa
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
	if foco in Dados.HACKERS:
		mix[foco] = mix.get(foco, 0.0) + FOCO_EXTRA_HACKER * rampa_hacker(dia)
	elif foco != "":
		mix[foco] = mix.get(foco, 0.0) + FOCO_EXTRA
	return mix


func rampa_hacker(numero: int) -> float:
	return clampf(float(numero - DIAS_SEM_HACKER) / DIAS_RAMPA_HACKER, 0.0, 1.0)


func iniciar_dia() -> void:
	if fase != Fase.PREPARACAO:
		return
	var sof := minf(SOFISTICACAO_MAXIMA, SOFISTICACAO_POR_DIA * (dia - 1))
	var peso := 1.0 + PESO_POR_DIA * maxi(0, dia - DIA_INICIO_PESO)
	var crescimento := 1.0 + CRESCIMENTO_EMPRESA * (dia - 1)
	for i in sites.size():
		sites[i].configurar_dia(taxa_do_dia(), mix_site(i), sof, peso, empresa["receita"] * crescimento, empresa["custo_queda"] * crescimento * sites[i].multiplicador, evento.get("falso_geo", 1.0), estado().codigo_seguro(), reforcos_ativos.duplicate())
	tempo_dia = 0.0
	hackers_dia = 0
	incidentes_hoje = {}
	fila_incidentes = []
	momento_phishing = randf_range(8.0, 24.0) if evento.get("phishing", false) else -1.0
	fase = Fase.DIA
	ferramenta = ""
	modo_conectar = -1
	banner = {"titulo": evento["nome"], "sub": evento["explicacao"], "tempo": 0.0, "duracao": 3.4, "especial": evento["especial"], "hacker": evento.get("hacker", false)}
	if evento.has("licao"):
		if estado().desbloquear_licao(evento["licao"]):
			principal.avisar("Nova lição: %s" % Textos.LICOES[evento["licao"]]["titulo"], Visual.DESTAQUE, evento["licao"])


func fim_do_dia() -> void:
	fase = Fase.RELATORIO
	ferramenta = ""
	modo_conectar = -1
	arraste = {}
	var r := {"dia": dia, "evento": evento["nome"], "especial": evento["especial"], "hacker": evento.get("hacker", false), "receita": 0.0, "queda": 0.0, "nuvem": 0.0, "multas": 0.0,
		"humanos": 0, "servidos": 0, "bots": 0, "bloqueados": 0, "quedas": 0, "caido": 0.0, "tempo_total": 0.0,
		"credenciais": 0, "vazamentos": 0, "hackers": 0, "hackers_bloqueados": 0, "invasoes": 0, "honeypot": 0, "etapa": 0, "resposta": -1, "quiz": {}}
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
		r["hackers"] += s.total_tipos("bots", Dados.HACKERS)
		r["hackers_bloqueados"] += s.total_tipos("bloqueados", Dados.HACKERS)
		r["invasoes"] += s.total("invasoes")
		r["honeypot"] += e["honeypot"]
	var aporte := APORTE_BASE + APORTE_POR_DIA * dia
	caixa += aporte
	r["aporte"] = aporte
	confianca = minf(100.0, confianca + RECUPERACAO_CONFIANCA)
	r["uptime"] = 1.0 - r["caido"] / maxf(1.0, r["tempo_total"])
	var lucro: float = r["receita"] - r["queda"] - r["nuvem"] - r["multas"]
	r["lucro"] = lucro
	r["dividendo"] = estado().registrar_dia(empresa_id, dia, lucro)
	totais["dividendos"] += r["dividendo"]
	var est = estado()
	est.somar("hackers_bloqueados", r["hackers_bloqueados"])
	est.somar("bots_bloqueados", r["bloqueados"] - r["hackers_bloqueados"])
	est.somar("clientes_atendidos", r["servidos"] * Dados.REQ_POR_PACOTE / 400)
	if r["quedas"] == 0:
		est.somar("dias_sem_queda")
	if r["hacker"]:
		est.somar("ondas_hacker")
	r["elogios"] = conquistas_do_dia(r)
	r["problemas"] = diagnosticar()
	if dia % 2 == 0:
		r["quiz"] = sortear_quiz()
	relatorio = r
	reforcos_ativos = {}


func conquistas_do_dia(r: Dictionary) -> Array:
	var lista: Array = elogios_dia.duplicate()
	if r["quedas"] == 0:
		lista.append("Nenhuma torre caiu hoje. Uptime de 100% é exatamente o que o conselho quer ver.")
	if r["humanos"] > 0 and float(r["servidos"]) / r["humanos"] >= 0.97:
		lista.append("%d%% dos clientes atendidos. Experiência impecável." % roundi(100.0 * r["servidos"] / r["humanos"]))
	if r["bots"] >= 10 and float(r["bloqueados"]) / r["bots"] >= 0.85:
		lista.append("%d%% das ameaças bloqueadas. Suas camadas de defesa estão afiadas." % roundi(100.0 * r["bloqueados"] / r["bots"]))
	if r["hacker"] and r["invasoes"] == 0:
		lista.append("Os hackers tentaram %d vezes e não entraram nenhuma. Muralha!" % r["hackers"])
	if r["honeypot"] > 0:
		lista.append("%d hackers caíram no seu honeypot e perderam tempo atacando a isca." % r["honeypot"])
	if r["especial"] and r["quedas"] == 0 and not r["hacker"]:
		lista.append("Você segurou %s sem cair. É nessas horas que um bom CTO se paga." % r["evento"])
	if lista.is_empty():
		lista.append("Você manteve a empresa de pé. Cada dia no ar é aprendizado.")
	return lista


func diagnosticar() -> Array:
	var problemas: Array = []
	for s in sites:
		var e: Dictionary = s.estatisticas
		var perdidos: Dictionary = e["perdidos"]
		var invasoes: Dictionary = e["invasoes"]
		if invasoes.get("ransomware", 0) > 0:
			problemas.append({"titulo": "%s: ransomware sequestrou torres %d vez(es)" % [s.nome, invasoes["ransomware"]],
				"porque": "O ransomware chegou às torres sem EDR para detectar o comportamento e sem patches para fechar a porta de entrada.",
				"solucao": "EDR e Patches na aba Segurança, e Backup para restaurar sem pagar resgate.", "licao": "ransomware"})
		if invasoes.get("sqli", 0) + invasoes.get("xss", 0) > 0:
			problemas.append({"titulo": "%s: %d ataques de SQLi/XSS passaram" % [s.nome, invasoes.get("sqli", 0) + invasoes.get("xss", 0)],
				"porque": "As consultas e páginas da aplicação ainda aceitam texto malicioso. Filtros de rede ajudam, mas a correção definitiva está no código.",
				"solucao": "WAF e IDS/IPS na frente, e resolva desafios no Beco Hacker para subir o código seguro.", "licao": "codigo_seguro"})
		if invasoes.get("exploit", 0) + invasoes.get("forca_bruta", 0) > 0:
			problemas.append({"titulo": "%s: torres invadidas %d vez(es)" % [s.nome, invasoes.get("exploit", 0) + invasoes.get("forca_bruta", 0)],
				"porque": "Exploits aproveitam software desatualizado e força bruta adivinha senhas fracas.",
				"solucao": "Patches e IDS/IPS contra exploits; Cofre de senhas, 2FA e Rate Limit contra força bruta.", "licao": "exploit"})
		if e["quedas"] > 0 and invasoes.is_empty():
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
		if falsos >= maxi(6, roundi(e["humanos"] * 0.03)):
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
		if e["vazamentos"] > 0 and invasoes.get("sqli", 0) == 0:
			problemas.append({"titulo": "%s: %d contas invadidas" % [s.nome, e["vazamentos"]],
				"porque": "Ladrões de senha chegaram às torres. Cada invasão gerou multa da LGPD (%s) e derrubou a confiança." % Visual.dinheiro(e["multas"]),
				"solucao": "Login 2FA no caminho, com WAF e CAPTCHA antes.", "licao": "vazamento"})
		var bots_total: int = s.total_tipos("bots", Dados.BOTS)
		var chegaram_total: int = s.total_tipos("chegaram", Dados.BOTS)
		if bots_total >= 20 and float(chegaram_total) / bots_total > 0.3:
			var pior_bot := ""
			var maior_bot := 0
			for tipo in Dados.BOTS:
				if e["chegaram"].get(tipo, 0) > maior_bot:
					maior_bot = e["chegaram"][tipo]
					pior_bot = tipo
			problemas.append({"titulo": "%s: %d%% dos bots chegaram às torres" % [s.nome, roundi(100.0 * chegaram_total / bots_total)],
				"porque": "O tipo que mais passou foi %s. Cada filtro é bom contra um tipo de ameaça diferente." % String(Dados.TIPOS_REQ[pior_bot]["nome"]).to_lower(),
				"solucao": "contra esse tipo, use %s." % DEFESA_AMEACA[pior_bot], "licao": "defesa_profundidade"})
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
	var usados: Array = estado().perfil.get("quiz_usados", [])
	var disponiveis: Array = []
	for i in Textos.QUIZ.size():
		if not i in usados:
			disponiveis.append(i)
	if disponiveis.is_empty():
		usados.clear()
		disponiveis = range(Textos.QUIZ.size())
	var escolhido: int = disponiveis[randi() % disponiveis.size()]
	usados.append(escolhido)
	return Textos.QUIZ[escolhido]


func responder_quiz(opcao: int) -> void:
	if fase != Fase.RELATORIO or relatorio["quiz"].is_empty() or relatorio["resposta"] >= 0:
		return
	relatorio["resposta"] = opcao
	if opcao == relatorio["quiz"]["correta"]:
		caixa += BONUS_QUIZ
		estado().somar("quiz_acertos")
		estado().ganhar_xp(30)
		principal.avisar("Resposta certa! O conselho liberou %s" % Visual.dinheiro(BONUS_QUIZ), Visual.HUMANO)
		principal.confete(Vector2(640, 300), 50)


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
		principal.avisar("Expansão! Novo sistema: %s. O conselho investiu %s" % [novo["nome"], Visual.dinheiro(BONUS_EXPANSAO)], Visual.DESTAQUE, "multi_site")
		estado().desbloquear_licao("multi_site")
		principal.confete(Vector2(640, 90), 40)
	evento = evento_do_dia(dia)
	fase = Fase.PREPARACAO
	selecao = {}
	salvar_partida()


func finalizar(motivo: String) -> void:
	fase = Fase.FIM
	motivo_fim = motivo
	ferramenta = ""
	modo_conectar = -1
	arraste = {}
	modal = {}
	fila_incidentes = []
	estado().estado_empresa(empresa_id)["temporadas"] = int(estado().estado_empresa(empresa_id)["temporadas"]) + 1
	estado().limpar_operacao(empresa_id)


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


func nivel_necessario(tipo: String) -> int:
	return int(Dados.COMPONENTES[tipo].get("nivel", 0))


func colocar(tipo: String, celula: Vector2i) -> void:
	var s = site()
	if estado().nivel() < nivel_necessario(tipo):
		principal.avisar("%s desbloqueia quando você for %s" % [Dados.COMPONENTES[tipo]["nome"], Dados.NIVEIS[nivel_necessario(tipo)]["titulo"]], Visual.CREDITOS)
		return
	if not s.celula_valida(celula) or s.no_na_celula(celula) >= 0:
		principal.avisar("Escolha uma célula livre da grade", Visual.CREDITOS)
		return
	var custo := custo_componente(tipo)
	if caixa < custo:
		principal.avisar("Caixa insuficiente: %s custa %s" % [Dados.COMPONENTES[tipo]["nome"], Visual.dinheiro(custo)], Visual.PERIGO)
		return
	var id: int = s.adicionar_no(tipo, celula)
	caixa -= custo
	s.nos[id]["investido"] = float(custo)
	var nome_tipo: String = Dados.COMPONENTES[tipo]["nome"]
	ferramenta = ""
	selecao = {}
	if tipo in Dados.PASSIVOS:
		principal.avisar("%s ativo: protege o sistema %s inteiro, sem precisar de conexão" % [nome_tipo, s.nome], Visual.HUMANO)
	elif encaixar(s, id):
		principal.avisar("%s instalado e encaixado no fluxo. Toque nele para ver detalhes" % nome_tipo, Visual.HUMANO)
	else:
		principal.avisar("%s instalado. Agora conecte a entrada e a saída" % nome_tipo, Visual.DESTAQUE)
	estado().somar("componente_%s" % tipo)
	estado().somar("componentes_instalados")
	if estado().desbloquear_licao(tipo):
		principal.avisar("Nova lição: %s" % Textos.LICOES[tipo]["titulo"], Visual.DESTAQUE, tipo)
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
	if anterior < 0 or not s.tem_saida(anterior) or s.pode_conectar(anterior, novo) != "":
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
		principal.avisar("Caixa insuficiente para melhorar", Visual.PERIGO)
		return
	caixa -= custo
	no["nivel"] += 1
	no["investido"] += custo
	if no["tipo"] == "lb" and no["nivel"] == 2:
		estado().desbloquear_licao("health_check")
	checar_elogios()


func vender(id: int) -> void:
	var s = site()
	if id == s.id_internet or not s.nos.has(id):
		return
	var valor := roundi(s.nos[id]["investido"] * REEMBOLSO)
	caixa += valor
	s.remover_no(id)
	selecao = {}
	principal.avisar("Componente vendido por %s" % Visual.dinheiro(valor), Visual.TEXTO_SUAVE)


func limpar_saidas(id: int) -> void:
	var s = site()
	if not s.nos.has(id):
		return
	for destino in s.nos[id]["saidas"].duplicate():
		s.desconectar(id, destino)
	principal.avisar("Saídas removidas. Sem saída, o tráfego fica sem caminho", Visual.CREDITOS)


func remover_aresta(de: int, para: int) -> void:
	site().desconectar(de, para)
	selecao = {}


func tentar_conectar(a: int, b: int) -> void:
	var erro: String = site().conectar(a, b)
	if erro != "":
		principal.avisar(erro, Visual.PERIGO)
		return
	principal.avisar("%s ligado a %s" % [nome_no(site(), a), nome_no(site(), b)], Visual.HUMANO)
	checar_elogios()


func nome_no(s, id: int) -> String:
	var tipo: String = s.nos[id]["tipo"]
	return "Internet" if tipo == "internet" else String(Dados.COMPONENTES[tipo]["nome"])


func aportar() -> void:
	if not estado().gastar(VALOR_APORTE):
		principal.avisar("Sua carteira não tem %s" % Visual.dinheiro(VALOR_APORTE), Visual.PERIGO)
		return
	caixa += VALOR_APORTE
	principal.avisar("Você investiu %s da sua carteira no caixa da %s" % [Visual.dinheiro(VALOR_APORTE), empresa["nome"]], Visual.CREDITOS)


func ativar_reforco(id: String) -> void:
	if fase != Fase.PREPARACAO or reforcos_ativos.get(id, false):
		return
	if not estado().usar_reforco(id):
		principal.avisar("Compre esse reforço na Loja Tech", Visual.CREDITOS)
		return
	if id == "consultoria":
		var s = site()
		var alvo := -1
		for nid in s.nos:
			var no: Dictionary = s.nos[nid]
			if no["tipo"] != "internet" and no["nivel"] < Dados.NIVEL_MAXIMO and (alvo < 0 or no["nivel"] < s.nos[alvo]["nivel"]):
				alvo = nid
		if alvo >= 0:
			s.nos[alvo]["nivel"] += 1
			principal.avisar("Consultoria melhorou %s para o nível %d" % [nome_no(s, alvo), s.nos[alvo]["nivel"]], Visual.HUMANO)
		return
	reforcos_ativos[id] = true
	principal.avisar("%s ativado para o próximo dia" % Dados.ITENS[id]["nome"], Visual.HUMANO)


func checar_elogios() -> void:
	for s in sites:
		var tem_ips := false
		var tem_waf := false
		for id in s.nos:
			var no: Dictionary = s.nos[id]
			var tipo: String = no["tipo"]
			var saidas: Array = no["saidas"]
			if tipo == "ips":
				tem_ips = true
			if tipo == "waf":
				tem_waf = true
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
			if tipo == "backup":
				elogiar("backup", "Backup instalado. Ransomware perde o poder quando você pode restaurar tudo.")
			if tipo == "siem":
				elogiar("siem", "SIEM no ar. Agora você enxerga ataques que passariam despercebidos.")
			if tipo == "honeypot":
				elogiar("honeypot", "Honeypot armado. Hackers vão perder tempo atacando uma isca.")
		if tem_ips and tem_waf:
			elogiar("waf_ips", "WAF e IDS/IPS juntos. Um lê a aplicação, o outro reconhece assinaturas de ataque.")


func centralizar() -> void:
	var s = site()
	var minimo := Vector2(INF, INF)
	var maximo := Vector2(-INF, -INF)
	for id in s.nos:
		var r: Rect2 = s.retangulo_no(id)
		minimo = minimo.min(r.position)
		maximo = maximo.max(r.end)
	var largura := maxf(400.0, maximo.x - minimo.x + 120.0)
	zoom = clampf(RET_CANVAS.size.x / largura, 0.7, 1.0)
	camera = minimo - Vector2(60, 60)
	limitar_camera()


func limitar_camera() -> void:
	var visivel: Vector2 = RET_CANVAS.size / zoom
	var mundo: Vector2 = site().tamanho_mundo()
	camera.x = clampf(camera.x, -80.0, maxf(-80.0, mundo.x - visivel.x + 80.0))
	camera.y = clampf(camera.y, -80.0, maxf(-80.0, mundo.y - visivel.y + 80.0))


func para_mundo(p: Vector2) -> Vector2:
	return (p - RET_CANVAS.position) / zoom + camera


func aplicar_zoom(fator: float, ancora: Vector2) -> void:
	var antes := para_mundo(ancora)
	zoom = clampf(zoom * fator, ZOOM_MINIMO, ZOOM_MAXIMO)
	camera = antes - (ancora - RET_CANVAS.position) / zoom
	limitar_camera()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or principal.modal_aberto():
		return
	if event is InputEventMouseButton:
		var e := make_input_local(event) as InputEventMouseButton
		if e.pressed and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			if RET_CANVAS.has_point(e.position) and pode_interagir():
				aplicar_zoom(1.1 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1, e.position)
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
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var m := make_input_local(event) as InputEventMouseMotion
		arrastar(m.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		tecla(event.keycode)


func cancelar() -> void:
	if ferramenta != "" or modo_conectar >= 0:
		ferramenta = ""
		modo_conectar = -1
	else:
		selecao = {}


func tecla(codigo: Key) -> void:
	if not modal.is_empty():
		var tipo_modal: String = modal["tipo"]
		if tipo_modal == "incidente":
			if modal["escolha"] < 0 and codigo >= KEY_1 and codigo <= KEY_4 and codigo - KEY_1 < modal["ordem"].size():
				escolher_incidente(codigo - KEY_1)
			elif modal["escolha"] >= 0 and (codigo == KEY_SPACE or codigo == KEY_ENTER or codigo == KEY_ESCAPE):
				modal = {}
			return
		if codigo == KEY_ESCAPE or codigo == KEY_SPACE or codigo == KEY_ENTER or codigo == KEY_P:
			modal = {}
		return
	match fase:
		Fase.RELATORIO:
			if codigo == KEY_SPACE or codigo == KEY_ENTER:
				continuar_relatorio()
			elif relatorio.get("etapa", 0) == 1 and codigo >= KEY_1 and codigo <= KEY_3:
				responder_quiz(codigo - KEY_1)
		Fase.FIM:
			if codigo == KEY_SPACE or codigo == KEY_ENTER:
				nova_partida()
				centralizar()
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
	centralizar()


func pressionar(pos: Vector2) -> void:
	if not modal.is_empty():
		clicar_modal(pos)
		return
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
	if RET_ZOOM_MAIS.has_point(pos):
		aplicar_zoom(1.15, RET_CANVAS.get_center())
		return
	if RET_ZOOM_MENOS.has_point(pos):
		aplicar_zoom(1.0 / 1.15, RET_CANVAS.get_center())
		return
	if RET_CENTRO.has_point(pos):
		centralizar()
		return
	for i in sites.size():
		if retangulo_aba(i).has_point(pos):
			trocar_site(i)
			return
	if RET_CANVAS.has_point(pos):
		arraste = {"inicio": pos, "alvo": alvo_em(para_mundo(pos)), "ativo": false, "camera": camera}
		return
	if fase == Fase.PREPARACAO and RET_INICIAR.has_point(pos):
		iniciar_dia()
		return
	for b in botoes_lateral():
		if b["rect"].has_point(pos):
			if b["ativo"]:
				b["acao"].call()
			return
	if not selecao.is_empty() and RET_FECHAR_PAINEL.has_point(pos):
		selecao = {}
		return
	for b in botoes_painel():
		if b["rect"].has_point(pos):
			if b["ativo"]:
				b["acao"].call()
			return


func arrastar(pos: Vector2) -> void:
	if arraste.is_empty():
		return
	if not arraste["ativo"] and pos.distance_to(arraste["inicio"]) > 10.0:
		arraste["ativo"] = true
	if arraste["ativo"] and arraste["alvo"].get("tipo", "") in ["celula", "aresta"] and ferramenta == "":
		camera = arraste["camera"] - (pos - arraste["inicio"]) / zoom
		limitar_camera()


func soltar(pos: Vector2) -> void:
	if arraste.is_empty():
		return
	var dados_arraste := arraste
	arraste = {}
	if not pode_interagir():
		return
	var alvo: Dictionary = dados_arraste["alvo"]
	if not dados_arraste["ativo"]:
		clicar_canvas(alvo)
		return
	var mundo_pos := para_mundo(pos)
	match alvo.get("tipo", ""):
		"porta":
			var destino: int = site().no_em(mundo_pos)
			if destino >= 0 and destino != alvo["id"]:
				tentar_conectar(alvo["id"], destino)
		"no":
			if not site().mover_no(alvo["id"], site().celula_em(mundo_pos)):
				principal.avisar("Só dá para mover para uma célula livre", Visual.CREDITOS)


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


func retangulo_categoria(indice: int) -> Rect2:
	return Rect2(32 + indice * 132, 530, 124, 26)


func retangulo_paleta(indice: int) -> Rect2:
	return Rect2(32 + (indice % 4) * 222, 564 + (indice / 4) * 72, 214, 66)


func itens_categoria() -> Array:
	var lista: Array = []
	for tipo in Dados.COMPONENTES:
		if Dados.COMPONENTES[tipo]["categoria"] == categoria:
			lista.append(tipo)
	return lista


func selecionar_categoria(id: String) -> void:
	categoria = id
	ferramenta = ""


func selecionar_ferramenta(tipo: String) -> void:
	if estado().nivel() < nivel_necessario(tipo):
		principal.avisar("%s desbloqueia quando você for %s" % [Dados.COMPONENTES[tipo]["nome"], Dados.NIVEIS[nivel_necessario(tipo)]["titulo"]], Visual.CREDITOS)
		return
	ferramenta = "" if ferramenta == tipo else tipo
	selecao = {}
	modo_conectar = -1


func iniciar_conexao(id: int) -> void:
	modo_conectar = id


func abrir_licao(id: String) -> void:
	principal.abrir_licao(id)


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
			for k in Dados.CATEGORIAS.size():
				var cat: Dictionary = Dados.CATEGORIAS[k]
				botoes.append({"rect": retangulo_categoria(k), "categoria": cat["id"], "rotulo": cat["nome"], "ativo": true, "acao": selecionar_categoria.bind(cat["id"])})
			var itens := itens_categoria()
			for k in itens.size():
				botoes.append({"rect": retangulo_paleta(k), "paleta": itens[k], "ativo": true, "acao": selecionar_ferramenta.bind(itens[k])})
	return botoes


func botoes_lateral() -> Array:
	var botoes: Array = []
	if fase != Fase.PREPARACAO or not pode_interagir():
		return botoes
	botoes.append({"rect": Rect2(956, 616, 140, 32), "rotulo": "Aportar %s" % Visual.dinheiro(VALOR_APORTE), "ativo": estado().dinheiro() >= VALOR_APORTE, "acao": aportar})
	var x := 1104.0
	for id in ["seguro", "plantao", "pentest", "consultoria"]:
		var qtd: int = estado().reforcos(id)
		if qtd <= 0 and not reforcos_ativos.get(id, false):
			continue
		if x > 1220.0:
			break
		botoes.append({"rect": Rect2(x, 616, 34, 32), "reforco": id, "quantidade": qtd, "ativo": not reforcos_ativos.get(id, false), "acao": ativar_reforco.bind(id)})
		x += 38.0
	return botoes


func clicar_modal(pos: Vector2) -> void:
	match modal["tipo"]:
		"boas_vindas":
			if Rect2(470, 616, 340, 52).has_point(pos):
				modal = {}
		"pausa":
			if Rect2(490, 300, 300, 52).has_point(pos):
				modal = {}
			elif Rect2(490, 362, 300, 52).has_point(pos):
				sair_para_cidade()
			elif Rect2(490, 424, 300, 52).has_point(pos):
				modal = {"tipo": "recomecar"}
		"recomecar":
			if Rect2(450, 400, 180, 50).has_point(pos):
				estado().limpar_operacao(empresa_id)
				nova_partida()
				centralizar()
				modal = {}
			elif Rect2(650, 400, 180, 50).has_point(pos):
				modal = {}
		"incidente":
			if modal["escolha"] < 0:
				for i in modal["ordem"].size():
					if retangulo_opcao_incidente(i).has_point(pos):
						escolher_incidente(i)
						return
			elif Rect2(540, 616, 200, 44).has_point(pos):
				modal = {}


func sair_para_cidade() -> void:
	if fase == Fase.DIA:
		var salvo: Dictionary = estado().obter_operacao(empresa_id)
		if not salvo.is_empty():
			restaurar(salvo)
	elif fase == Fase.PREPARACAO:
		salvar_partida()
	modal = {}
	principal.voltar_mundo()


func retangulo_opcao_incidente(indice: int) -> Rect2:
	return Rect2(260, 290 + indice * 58, 760, 52)


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
	if Rect2(330, 560, 300, 52).has_point(pos):
		principal.voltar_mundo()
	elif Rect2(650, 560, 300, 52).has_point(pos):
		nova_partida()
		centralizar()


func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(0, 0, 1280, 720), Visual.FUNDO)
	for x in range(0, 1281, 40):
		draw_line(Vector2(x, 0), Vector2(x, 720), Visual.GRADE, 1.0)
	for y in range(0, 721, 40):
		draw_line(Vector2(0, y), Vector2(1280, y), Visual.GRADE, 1.0)
	draw_set_transform(RET_CANVAS.position - camera * zoom, 0.0, Vector2(zoom, zoom))
	desenhar_site()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(0, 0, 1280, RET_CANVAS.position.y), Visual.FUNDO)
	draw_rect(Rect2(0, RET_CANVAS.end.y, 1280, 720 - RET_CANVAS.end.y), Visual.FUNDO)
	draw_rect(Rect2(0, 0, RET_CANVAS.position.x, 720), Visual.FUNDO)
	draw_rect(Rect2(RET_CANVAS.end.x, 0, 1280 - RET_CANVAS.end.x, 720), Visual.FUNDO)
	Visual.caixa(self, RET_CANVAS, Visual.TRANSPARENTE, 14, Visual.BORDA, 1)
	desenhar_controles_canvas()
	desenhar_dica_interacao()
	desenhar_topo()
	desenhar_abas()
	desenhar_painel()
	desenhar_lateral()
	desenhar_banner()
	if fase == Fase.RELATORIO:
		desenhar_relatorio()
	elif fase == Fase.FIM:
		desenhar_fim()
	desenhar_modal()


func mouse_mundo() -> Vector2:
	return para_mundo(mouse)


func hover(r: Rect2) -> bool:
	return r.has_point(mouse)


func desenhar_controles_canvas() -> void:
	for item in [[RET_ZOOM_MENOS, "-"], [RET_ZOOM_MAIS, "+"], [RET_CENTRO, "o"]]:
		var r: Rect2 = item[0]
		Visual.caixa(self, r, Visual.CARTAO_CLARO, 8, Visual.BORDA_HOVER if hover(r) else Visual.BORDA, 1)
		if item[1] == "o":
			draw_arc(r.get_center(), 6.0, 0.0, TAU, 16, Visual.TEXTO, 1.5, true)
			draw_circle(r.get_center(), 1.8, Visual.TEXTO, true, -1.0, true)
		else:
			Visual.texto(self, Vector2(r.position.x, r.position.y + 22), item[1], 18, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	Visual.texto(self, Vector2(RET_ZOOM_MENOS.position.x - 330, 132), "arraste o fundo para mover  ·  roda do mouse dá zoom", 11, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT, 320)


func desenhar_site() -> void:
	var s = site()
	var mostrando_grade: bool = ferramenta != "" or (arraste.get("ativo", false) and arraste["alvo"].get("tipo", "") == "no")
	var m := mouse_mundo()
	for cx in s.COLUNAS:
		for cy in s.LINHAS:
			var r := Rect2(s.centro_celula(Vector2i(cx, cy)) - s.TAMANHO_NO / 2, s.TAMANHO_NO)
			Visual.caixa(self, r, Color(1, 1, 1, 0.035 if mostrando_grade else 0.012), 12, Color(1, 1, 1, 0.06) if mostrando_grade else Visual.TRANSPARENTE, 1 if mostrando_grade else 0, 0, 4)
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
		var tipo: String = p["tipo"]
		var cor_p: Color = Dados.TIPOS_REQ[tipo]["cor"]
		if tipo in Dados.HACKERS:
			Visual.losango(self, p["pos"], 6.0, cor_p)
		else:
			draw_rect(Rect2(p["pos"] - Vector2(3.5, 3.5), Vector2(7, 7)), cor_p)
	for id in s.nos:
		desenhar_no(s, id, m)
	if evento.get("hacker", false) and fase == Fase.DIA and s.gerando:
		var internet: Vector2 = s.centro_no(s.id_internet) + Vector2(0, -58)
		var flutuar := sin(tempo_anim * 3.0) * 4.0
		Visual.caixa(self, Rect2(internet + Vector2(-20, -20 + flutuar), Vector2(40, 40)), Color("1a0b10"), 12, Visual.PERIGO, 2)
		Visual.icone(self, "hacker", internet + Vector2(0, flutuar), Color("334155"), 1.3)
	for efeito in s.efeitos:
		desenhar_efeito(efeito)
	desenhar_interacao(s, m)


func desenhar_no(s, id: int, m: Vector2) -> void:
	var no: Dictionary = s.nos[id]
	var tipo: String = no["tipo"]
	var r: Rect2 = s.retangulo_no(id)
	var cor: Color = Visual.DESTAQUE if tipo == "internet" else Dados.COMPONENTES[tipo]["cor"]
	var terminal: bool = tipo in Dados.TERMINAIS
	var passivo: bool = tipo in Dados.PASSIVOS
	var caido: bool = no["caido"] > 0.0
	var proporcao: float = no["carga"] / s.CAPACIDADE
	if terminal and not caido and proporcao > 0.85:
		r.position += Vector2(sin(tempo_anim * 45.0), cos(tempo_anim * 38.0)) * 1.5
	var selecionado: bool = selecao.get("tipo", "") == "no" and selecao["id"] == id
	var em_conexao := modo_conectar == id
	var borda := Visual.BORDA_HOVER if r.has_point(m) and pode_interagir() else Visual.BORDA
	if no["pulso"] > 0.0:
		borda = borda.lerp(cor, no["pulso"] * 0.8)
	if caido:
		borda = Visual.PERIGO
	if selecionado or em_conexao:
		borda = cor
	if passivo:
		var aura := 0.5 + 0.5 * sin(tempo_anim * 2.0 + id)
		Visual.caixa(self, r.grow(4), Visual.com_alfa(cor, 0.06 + 0.06 * aura), 16)
	Visual.caixa(self, r, Color("1f1216") if caido else Visual.CARTAO, 12, borda, 2 if selecionado or em_conexao or caido else 1, 6)
	if terminal:
		Visual.torre(self, r, cor, no["nivel"], proporcao, caido, tempo_anim, no["escala"])
		var rotulo := ""
		if caido:
			rotulo = ("SEQUESTRADA %ds" if no["sequestro"] == "ransomware" else ("INVADIDA %ds" if no["sequestro"] == "invasao" else "OFFLINE %ds")) % ceili(no["caido"])
		elif tipo == "autoscale":
			rotulo = "x%.1f  %d%%" % [no["escala"], int(proporcao * 100)]
		else:
			rotulo = "Torre  %d%%" % int(proporcao * 100)
		Visual.texto(self, Vector2(r.position.x, r.end.y - 6), rotulo, 10, Visual.PERIGO if caido else Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		if no["sequestro"] != "" and caido:
			Visual.cadeado(self, r.get_center() + Vector2(0, -6), Color("a855f7"), 1.3)
		elif s.nivel_passivo("patch") == 0 and s.nivel_passivo("edr") == 0:
			Visual.caixa(self, Rect2(r.end.x - 20, r.position.y + 4, 16, 14), Visual.com_alfa(Visual.PERIGO, 0.25), 4)
			Visual.texto(self, Vector2(r.end.x - 20, r.position.y + 15), "!", 11, Visual.PERIGO, HORIZONTAL_ALIGNMENT_CENTER, 16)
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
	if s.tem_entrada(id):
		draw_circle(s.porta_entrada(id), 3.5, Visual.BORDA_HOVER, true, -1.0, true)
	if s.tem_saida(id):
		var porta: Vector2 = s.porta_saida(id)
		var perto: bool = pode_interagir() and porta.distance_to(m) <= 14.0
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
	if no["tipo"] in Dados.PASSIVOS:
		return "protege o sistema"
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
					draw_rect(Rect2(fragmento - Vector2(3, 3), Vector2(6, 6)), Visual.com_alfa(cor_bot, 1.0 - q))
		"bloqueio":
			draw_arc(pos, 6.0 + p * 14.0, -PI / 2, PI / 2, 16, Visual.com_alfa(cor, 1.0 - p), 3.0, true)
			var cor_bot2: Color = e["cor_bot"]
			for k in 5:
				var angulo2 := semente + k * TAU / 5.0
				var fragmento2 := pos + Vector2(cos(angulo2), sin(angulo2)) * (3.0 + p * 18.0)
				draw_rect(Rect2(fragmento2 - Vector2(2, 2), Vector2(4, 4)), Visual.com_alfa(cor_bot2, 1.0 - p))
		"absorver":
			draw_arc(pos, 2.0 + 16.0 * (1.0 - p), 0.0, TAU, 24, Visual.com_alfa(cor, 1.0 - p), 2.0, true)
		"cache":
			var c := pos + Vector2(0, -16.0 * p)
			draw_polyline(PackedVector2Array([c + Vector2(-5, 0), c + Vector2(-1, 4), c + Vector2(6, -5)]), Visual.com_alfa(cor, 1.0 - p), 2.5, true)
		"perdido":
			var a := Visual.com_alfa(cor, 1.0 - p)
			draw_line(pos + Vector2(-5, -5), pos + Vector2(5, 5), a, 2.0, true)
			draw_line(pos + Vector2(-5, 5), pos + Vector2(5, -5), a, 2.0, true)
		"queda", "invasao":
			for k in 12:
				var angulo3 := semente + k * TAU / 12.0
				var direcao := Vector2(cos(angulo3), sin(angulo3))
				var inicio := pos + direcao * (10.0 + p * 30.0)
				var cor_faisca := Color("fbbf24").lerp(Color("ef4444"), p) if e["tipo"] == "queda" else cor
				draw_line(inicio, inicio + direcao * 8.0, Visual.com_alfa(cor_faisca, 1.0 - p), 2.0, true)
			for k in 3:
				var fumaca := pos + Vector2(-12 + k * 12, -20 - p * 40.0 - k * 6)
				draw_circle(fumaca, 6.0 + p * 10.0, Color(0.6, 0.6, 0.65, 0.35 * (1.0 - p)), true, -1.0, true)
			if e.has("texto"):
				Visual.texto(self, pos + Vector2(-80, -56 - 16.0 * p), e["texto"], 13, Visual.com_alfa(cor, 1.0 - p), HORIZONTAL_ALIGNMENT_CENTER, 160)
		"dinheiro":
			var valor: float = e["valor"]
			var texto_valor := ("+" if valor > 0.0 else "") + Visual.dinheiro(valor)
			var cor_dinheiro := Visual.HUMANO if valor > 0.0 else Visual.PERIGO
			Visual.texto(self, pos + Vector2(-60, -28.0 * p), texto_valor, 12, Visual.com_alfa(cor_dinheiro, 1.0 - p * p), HORIZONTAL_ALIGNMENT_CENTER, 120)
		"vazamento":
			Visual.cadeado(self, pos + Vector2(0, -18.0 * p), Visual.com_alfa(cor, 1.0 - p), 1.2, true)
			Visual.texto(self, pos + Vector2(-70, -30 - 18.0 * p), e.get("texto", "Conta invadida!"), 12, Visual.com_alfa(cor, 1.0 - p), HORIZONTAL_ALIGNMENT_CENTER, 140)
		"honeypot":
			Visual.icone(self, "honeypot", pos + Vector2(0, -10.0 * p), Visual.com_alfa(cor, 1.0 - p), 1.0)
			Visual.texto(self, pos + Vector2(-60, -24 - 10.0 * p), "Preso na isca!", 11, Visual.com_alfa(cor, 1.0 - p), HORIZONTAL_ALIGNMENT_CENTER, 120)


func desenhar_interacao(s, m: Vector2) -> void:
	if not pode_interagir():
		return
	if ferramenta != "" and RET_CANVAS.has_point(mouse):
		var celula: Vector2i = s.celula_em(m)
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
			var destino: int = s.no_em(m)
			var cor_linha := Visual.DESTAQUE
			if destino >= 0 and destino != alvo["id"]:
				var valido: bool = s.pode_conectar(alvo["id"], destino) == ""
				cor_linha = Visual.HUMANO if valido else Visual.PERIGO
				Visual.caixa(self, s.retangulo_no(destino).grow(4), Visual.TRANSPARENTE, 14, cor_linha, 2)
			draw_line(inicio, m, cor_linha, 2.5, true)
			draw_circle(m, 5.0, cor_linha, true, -1.0, true)
		elif alvo.get("tipo", "") == "no":
			var celula2: Vector2i = s.celula_em(m)
			if s.celula_valida(celula2):
				var ocupante: int = s.no_na_celula(celula2)
				var ok: bool = ocupante < 0 or ocupante == alvo["id"]
				Visual.caixa(self, Rect2(s.centro_celula(celula2) - s.TAMANHO_NO / 2, s.TAMANHO_NO), Visual.TRANSPARENTE, 12, Visual.HUMANO if ok else Visual.PERIGO, 2)


func desenhar_dica_interacao() -> void:
	if not pode_interagir():
		return
	var dica := ""
	if modo_conectar >= 0:
		dica = "Toque no componente de destino  ·  Esc cancela"
	elif ferramenta != "":
		if ferramenta in Dados.PASSIVOS:
			dica = "Posicionando %s: toque em qualquer célula livre. Ele protege o sistema inteiro." % Dados.COMPONENTES[ferramenta]["nome"]
		else:
			dica = "Posicionando %s: toque numa célula livre. Logo à direita de outro componente, ele encaixa sozinho." % Dados.COMPONENTES[ferramenta]["nome"]
	if dica != "":
		var largura := Visual.largura_texto(dica, 13) + 30
		var r2 := Rect2(640 - largura / 2, 108, largura, 28)
		Visual.caixa(self, r2, Visual.CARTAO_CLARO, 14, Visual.DESTAQUE, 1)
		Visual.texto(self, Vector2(r2.position.x, r2.position.y + 19), dica, 13, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, r2.size.x)


func desenhar_topo() -> void:
	Visual.caixa(self, RET_TOPO, Visual.CARTAO, 14, Visual.BORDA, 1, 10)
	Visual.logo(self, Vector2(46, 34), 15.0, empresa["logo"], empresa["sigla"])
	Visual.texto(self, Vector2(72, 32), empresa["nome"], 15, Visual.TEXTO)
	Visual.texto(self, Vector2(72, 49), empresa["setor"], 11, Visual.TEXTO_SUAVE)
	var fase_texto := "Preparação  ·  dia %d" % dia
	var progresso_dia := -1.0
	if fase == Fase.DIA:
		fase_texto = "Dia %d  ·  %s  ·  %ds" % [dia, evento["nome"], maxi(0, ceili(DURACAO_DIA - tempo_dia))]
		progresso_dia = clampf(tempo_dia / DURACAO_DIA, 0.0, 1.0)
	elif fase == Fase.RELATORIO or fase == Fase.FIM:
		fase_texto = "Dia %d encerrado" % dia
	var largura := minf(420.0, Visual.largura_texto(fase_texto, 14) + 36)
	var pilula := Rect2(440 - largura / 2, 17, largura, 34)
	var especial: bool = evento.get("especial", false) and fase == Fase.DIA
	var cor_pilula := Visual.PERIGO if evento.get("hacker", false) else Visual.CREDITOS
	Visual.caixa(self, pilula, Visual.CARTAO_CLARO, 17, cor_pilula if especial else Visual.TRANSPARENTE, 1)
	Visual.texto(self, Vector2(pilula.position.x, 39), fase_texto, 14, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, pilula.size.x)
	if progresso_dia >= 0.0:
		var trilho := Rect2(pilula.position.x + 18, 46, pilula.size.x - 36, 3)
		Visual.caixa(self, trilho, Visual.LINHA, 2)
		Visual.caixa(self, Rect2(trilho.position, Vector2(trilho.size.x * progresso_dia, 3)), Visual.DESTAQUE, 2)
	Visual.texto(self, Vector2(670, 29), "Caixa da empresa" if caixa >= 0.0 else "Caixa (no crédito)", 11, Visual.TEXTO_SUAVE if caixa >= 0.0 else Visual.PERIGO)
	Visual.texto(self, Vector2(670, 50), Visual.dinheiro(caixa), 18, Visual.CREDITOS if caixa >= 0.0 else Visual.PERIGO)
	Visual.texto(self, Vector2(810, 29), "Sua carteira", 11, Visual.TEXTO_SUAVE)
	Visual.texto(self, Vector2(810, 50), Visual.dinheiro(estado().dinheiro()), 15, Visual.HUMANO)
	var cor_confianca := Visual.HUMANO if confianca > 50.0 else (Visual.CREDITOS if confianca > 25.0 else Visual.PERIGO)
	Visual.texto(self, Vector2(930, 30), "Confiança  %d%%" % ceili(confianca), 11, Visual.TEXTO_SUAVE)
	var barra := Rect2(930, 38, 220, 8)
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
	var codigo: int = estado().codigo_seguro()
	Visual.texto(self, Vector2(660, 86), "1 pacote = %s req  ·  código seguro %d/5" % [Visual.requisicoes(Dados.REQ_POR_PACOTE), codigo], 12, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT, 600)


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
	if not selecao.is_empty():
		Visual.caixa(self, RET_FECHAR_PAINEL, Visual.CARTAO_CLARO, 8, Visual.BORDA_HOVER if hover(RET_FECHAR_PAINEL) else Visual.TRANSPARENTE, 1)
		var c := RET_FECHAR_PAINEL.get_center()
		draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), Visual.TEXTO, 2.0, true)
		draw_line(c + Vector2(-5, 5), c + Vector2(5, -5), Visual.TEXTO, 2.0, true)
	for b in botoes_painel():
		if b.has("paleta"):
			desenhar_item_paleta(b)
		elif b.has("categoria"):
			var ativa: bool = b["categoria"] == categoria
			var r: Rect2 = b["rect"]
			Visual.caixa(self, r, Visual.com_alfa(Visual.DESTAQUE, 0.16) if ativa else Visual.CARTAO_CLARO, 13, Visual.DESTAQUE if ativa else (Visual.BORDA_HOVER if hover(r) else Visual.TRANSPARENTE), 1)
			Visual.texto(self, Vector2(r.position.x, r.position.y + 18), b["rotulo"], 12, Visual.TEXTO if ativa else Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		else:
			var principal_botao: bool = b.get("principal", false)
			Visual.botao(self, b["rect"], b["rotulo"], Visual.PRINCIPAL if principal_botao else Visual.DESTAQUE, hover(b["rect"]), b["ativo"], 14, principal_botao)
	if selecao.is_empty() and pode_interagir():
		Visual.texto(self, Vector2(570, 548), "toque no item e depois numa célula livre", 11, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT, 350)


func desenhar_item_paleta(b: Dictionary) -> void:
	var tipo: String = b["paleta"]
	var r: Rect2 = b["rect"]
	var dados: Dictionary = Dados.COMPONENTES[tipo]
	var cor: Color = dados["cor"]
	var custo := custo_componente(tipo)
	var bloqueado: bool = estado().nivel() < nivel_necessario(tipo)
	var pode: bool = caixa >= custo and not bloqueado
	var ativo := ferramenta == tipo
	Visual.caixa(self, r, Visual.com_alfa(cor, 0.14) if ativo else (Visual.CARTAO if bloqueado else Visual.CARTAO_CLARO), 12, cor if ativo or (hover(r) and not bloqueado) else Visual.BORDA, 2 if ativo else 1)
	var badge := Rect2(r.position + Vector2(10, 10), Vector2(30, 30))
	Visual.caixa(self, badge, Visual.com_alfa(cor, 0.16 if pode else 0.06), 8)
	if bloqueado:
		Visual.cadeado(self, badge.get_center() + Vector2(0, 2), Visual.TEXTO_SUAVE, 0.8)
	else:
		Visual.icone(self, tipo, badge.get_center(), cor if pode else Visual.TEXTO_SUAVE, 0.8)
	Visual.texto(self, r.position + Vector2(48, 24), dados["nome"], 12, Visual.TEXTO if pode else Visual.TEXTO_SUAVE)
	if bloqueado:
		Visual.texto(self, r.position + Vector2(48, 40), "Nível: %s" % Dados.NIVEIS[nivel_necessario(tipo)]["titulo"], 10, Visual.CREDITOS)
	else:
		Visual.texto(self, r.position + Vector2(48, 40), Visual.dinheiro(custo), 11, Visual.CREDITOS if pode else Visual.TEXTO_SUAVE)
	var linhas_resumo := Visual.quebrar(dados["resumo"], 9, 192)
	Visual.texto(self, r.position + Vector2(10, 58), linhas_resumo[0] + ("..." if linhas_resumo.size() > 1 else ""), 9, Visual.TEXTO_SUAVE)


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
	var resumo := "Origem de todo o tráfego deste sistema: clientes, bots e hackers chegam por aqui." if tipo == "internet" else String(Dados.COMPONENTES[tipo]["resumo"])
	Visual.texto(self, Vector2(86, 574), resumo, 12, Visual.TEXTO_SUAVE)
	var nivel: int = no["nivel"] - 1
	var y := 606.0
	if tipo in Dados.TERMINAIS:
		var texto_torre := "Processa %d de carga/s  ·  carga atual %d%%" % [roundi(s.processamento(no)), int(100.0 * no["carga"] / s.CAPACIDADE)]
		if no["caido"] > 0.0:
			texto_torre = "FORA DO AR por mais %ds. Clientes enviados para cá são perdidos." % ceili(no["caido"])
		Visual.texto(self, Vector2(40, y), texto_torre, 14, Visual.PERIGO if no["caido"] > 0.0 else Visual.TEXTO)
		var sem_protecao: bool = s.nivel_passivo("patch") == 0 and s.nivel_passivo("edr") == 0
		var protecao := "Sem Patches nem EDR neste sistema: exploits e ransomware entram fácil." if sem_protecao else "Protegida por %s." % ", ".join(nomes_passivos(s))
		Visual.texto(self, Vector2(40, y + 22), protecao, 12, Visual.CREDITOS if sem_protecao else Visual.TEXTO_SUAVE)
	elif tipo in Dados.PASSIVOS:
		var efeito: float = Dados.COMPONENTES[tipo]["efeito"][nivel]
		var descricoes := {"backup": "Torre sequestrada ou invadida volta em %ds em vez de 8 a 10s." % roundi(efeito), "patch": "Exploits falham %d%% das vezes nas torres." % roundi(efeito * 100), "cofre": "Força bruta falha %d%% das vezes." % roundi(efeito * 100),
			"treinamento": "Funcionários reconhecem %d%% dos phishings." % roundi(efeito * 100), "criptografia": "Multas de vazamento caem para %d%% do valor." % roundi(efeito * 100), "siem": "Todos os filtros deste sistema ficam %d%% mais fortes." % roundi(efeito * 100),
			"edr": "Ransomware é parado %d%% das vezes nas torres." % roundi(efeito * 100), "honeypot": "%d%% dos hackers que chegam às torres caem na isca." % roundi(efeito * 100)}
		Visual.texto(self, Vector2(40, y), descricoes.get(tipo, ""), 14, Visual.TEXTO)
		Visual.texto(self, Vector2(40, y + 22), "Defesa passiva: vale para o sistema %s inteiro e não precisa de conexão." % s.nome, 12, Visual.TEXTO_SUAVE)
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
			desenhar_barra_efeito(Vector2(x, y), "Cache", dados["cache"][nivel], Visual.HUMANO)
			x += 150.0
		for ameaca in Dados.AMEACAS:
			var chance: float = s.chance_bloqueio(tipo, nivel, ameaca)
			if chance <= 0.0:
				continue
			if x > 790.0:
				break
			desenhar_barra_efeito(Vector2(x, y), NOMES_AMEACAS[ameaca], chance, Dados.TIPOS_REQ[ameaca]["cor"])
			x += 150.0
		var falso: float = dados.get("falso", 0.0) * Dados.FALSO_NIVEL[nivel]
		if falso > 0.0:
			Visual.texto(self, Vector2(40, y + 34), "Erro com clientes reais: %s%%" % Visual.formatar_decimal(falso * 100.0 * (s.falso_geo if tipo == "geo" else 1.0)), 12, Visual.CREDITOS)


func nomes_passivos(s) -> Array:
	var lista: Array = []
	for tipo in Dados.PASSIVOS:
		if s.nivel_passivo(tipo) > 0:
			lista.append(Dados.COMPONENTES[tipo]["nome"])
	return lista


func desenhar_barra_efeito(pos: Vector2, rotulo: String, valor: float, cor: Color) -> void:
	Visual.texto(self, pos, rotulo, 11, cor)
	var trilho := Rect2(pos + Vector2(0, 8), Vector2(96, 6))
	Visual.caixa(self, trilho, Visual.LINHA, 3)
	Visual.caixa(self, Rect2(trilho.position, Vector2(maxf(6.0, trilho.size.x * valor), 6)), cor, 3)
	Visual.texto(self, pos + Vector2(102, 15), "%d%%" % roundi(valor * 100.0), 11, Visual.TEXTO)


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
		var hackers := 0
		var hackers_bloq := 0
		var caidas := 0
		for s in sites:
			por_minuto += s.taxa_atual() * 60.0 * Dados.REQ_POR_PACOTE
			var e: Dictionary = s.estatisticas
			receita += e["receita"]
			prejuizo += e["prejuizo_queda"] + e["custo_nuvem"] + e["multas"]
			atendidos += e["servidos"]
			var finalizados: int = e["servidos"]
			for motivo in e["perdidos"]:
				finalizados += int(e["perdidos"][motivo])
			humanos += finalizados
			hackers += s.total_tipos("bots", Dados.HACKERS)
			hackers_bloq += s.total_tipos("bloqueados", Dados.HACKERS)
			for id in s.terminais():
				if s.nos[id]["caido"] > 0.0:
					caidas += 1
		var linhas := [
			["Tráfego agora", "%s req/min" % Visual.requisicoes(por_minuto), Visual.TEXTO],
			["Receita do dia", Visual.dinheiro(receita), Visual.HUMANO],
			["Prejuízo do dia", Visual.dinheiro(-prejuizo) if prejuizo > 0.5 else "R$ 0", Visual.PERIGO],
			["Clientes atendidos", "%d%%" % (roundi(100.0 * atendidos / humanos) if humanos > 0 else 100), Visual.HUMANO],
			["Hackers barrados", "%d de %d" % [hackers_bloq, hackers], Visual.DESTAQUE],
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
	Visual.texto(self, Vector2(x, 566), evento["nome"], 16, (Visual.PERIGO if evento.get("hacker", false) else Visual.CREDITOS) if especial else Visual.TEXTO)
	Visual.paragrafo(self, Vector2(x, 584), evento["explicacao"], 10, Visual.TEXTO_SUAVE, 288, 1.3, 2)
	for b in botoes_lateral():
		var r: Rect2 = b["rect"]
		if b.has("reforco"):
			var ativo_r: bool = reforcos_ativos.get(b["reforco"], false)
			Visual.caixa(self, r, Visual.com_alfa(Visual.HUMANO, 0.25) if ativo_r else Visual.CARTAO_CLARO, 8, Visual.HUMANO if ativo_r else (Visual.BORDA_HOVER if hover(r) else Visual.BORDA), 1)
			var letras := {"seguro": "SG", "plantao": "PL", "pentest": "PT", "consultoria": "CS"}
			Visual.texto(self, Vector2(r.position.x, r.position.y + 15), letras[b["reforco"]], 11, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
			Visual.texto(self, Vector2(r.position.x, r.position.y + 28), "x%d" % b["quantidade"], 9, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
			if hover(r):
				Visual.texto(self, Vector2(956, 610), Dados.ITENS[b["reforco"]]["nome"], 10, Visual.HUMANO)
		else:
			Visual.botao(self, r, b["rotulo"], Visual.CREDITOS, hover(r), b["ativo"], 11)
	var previsto := taxa_do_dia() * Dados.DENSIDADE * 60.0 * Dados.REQ_POR_PACOTE
	Visual.botao(self, RET_INICIAR, "Iniciar dia %d  ·  %s req/min" % [dia, Visual.requisicoes(previsto)], Visual.PRINCIPAL, hover(RET_INICIAR), true, 14, true)


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
	var hacker: bool = banner.get("hacker", false)
	var cor := Visual.PERIGO if hacker else (Visual.CREDITOS if especial else Visual.DESTAQUE)
	if especial and int(t * 6.0) % 2 == 0:
		cor = Visual.PERIGO if not hacker else Color("a855f7")
	Visual.caixa(self, r, Visual.com_alfa(Color("120a12") if hacker else Visual.CARTAO, 0.96 * alfa), 18, Visual.com_alfa(cor, alfa), 2, 20)
	if hacker:
		Visual.icone(self, "hacker", Vector2(r.position.x + 60, y + 55), Visual.com_alfa(Color("334155"), alfa), 2.2)
		Visual.icone(self, "hacker", Vector2(r.end.x - 60, y + 55), Visual.com_alfa(Color("334155"), alfa), 2.2)
	var titulo: String = banner["titulo"]
	Visual.texto(self, Vector2(r.position.x, y + 48), titulo.to_upper() if especial else titulo, 32, Visual.com_alfa(cor, alfa), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	var linhas := Visual.quebrar(banner["sub"], 14, 560 if hacker else 740)
	for i in mini(2, linhas.size()):
		Visual.texto(self, Vector2(r.position.x, y + 76 + i * 19), linhas[i], 14, Visual.com_alfa(Visual.TEXTO, alfa), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func desenhar_relatorio() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Visual.SOBREPOSICAO)
	Visual.caixa(self, RET_CARTAO, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	if relatorio["etapa"] == 1:
		desenhar_quiz()
		return
	var x := RET_CARTAO.position.x + 30
	Visual.texto(self, Vector2(x, 84), "Fim do dia %d" % relatorio["dia"], 28, Visual.TEXTO)
	Visual.texto(self, Vector2(x + 200, 84), relatorio["evento"], 16, (Visual.PERIGO if relatorio["hacker"] else Visual.CREDITOS) if relatorio["especial"] else Visual.TEXTO_SUAVE)
	var prejuizos: float = relatorio["queda"] + relatorio["nuvem"] + relatorio["multas"]
	var valores := [
		["Receita", Visual.dinheiro(relatorio["receita"]), Visual.HUMANO],
		["Prejuízos e multas", Visual.dinheiro(-prejuizos) if prejuizos > 0.5 else "R$ 0", Visual.PERIGO],
		["Aporte do conselho", Visual.dinheiro(relatorio["aporte"]), Visual.DESTAQUE],
		["Seus dividendos", "+" + Visual.dinheiro(relatorio["dividendo"]), Visual.CREDITOS],
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
		["Ameaças bloqueadas", "%d%%" % (roundi(100.0 * relatorio["bloqueados"] / bots) if bots > 0 else 0)],
		["Hackers barrados", "%d de %d" % [relatorio["hackers_bloqueados"], relatorio["hackers"]]],
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
	Visual.texto(self, Vector2(0, 136), "Acerte e o conselho libera %s para a empresa" % Visual.dinheiro(BONUS_QUIZ), 13, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, 1280)
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
	var explicacao := "O caixa estourou o limite de crédito. Torres travadas, multas e gasto de nuvem consumiram mais do que a empresa faturou." if falencia else "A confiança chegou a zero. Clientes perdidos, barrados por engano, com contas invadidas ou com dados vazados migraram para a concorrência."
	Visual.paragrafo(self, Vector2(cartao.position.x + 50, 240), explicacao, 15, Visual.TEXTO_SUAVE, 600, 1.45, 4)
	var recorde: int = estado().estado_empresa(empresa_id)["recorde"]
	var linhas := [
		["Dias completos", "%d" % (dia - 1)],
		["Receita total da empresa", Visual.dinheiro(totais["receita"])],
		["Dividendos para sua carteira", "+" + Visual.dinheiro(totais["dividendos"])],
		["Recorde na %s" % empresa["nome"], "dia %d" % recorde],
	]
	for i in linhas.size():
		var y := 350.0 + i * 36.0
		Visual.texto(self, Vector2(cartao.position.x + 80, y), linhas[i][0], 16, Visual.TEXTO_SUAVE)
		Visual.texto(self, Vector2(cartao.position.x + 80, y), linhas[i][1], 17, Visual.TEXTO, HORIZONTAL_ALIGNMENT_RIGHT, 540)
	Visual.botao(self, Rect2(330, 560, 300, 52), "Voltar para a cidade", Visual.DESTAQUE, hover(Rect2(330, 560, 300, 52)))
	Visual.botao(self, Rect2(650, 560, 300, 52), "Nova temporada aqui", Visual.PRINCIPAL, hover(Rect2(650, 560, 300, 52)), true, 16, true)


func desenhar_modal() -> void:
	if modal.is_empty():
		return
	draw_rect(Rect2(0, 0, 1280, 720), Visual.SOBREPOSICAO)
	match modal["tipo"]:
		"boas_vindas":
			desenhar_boas_vindas()
		"pausa":
			var cartao := Rect2(440, 190, 400, 330)
			Visual.caixa(self, cartao, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
			Visual.texto(self, Vector2(cartao.position.x, 262), "Pausado", 34, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, cartao.size.x)
			Visual.botao(self, Rect2(490, 300, 300, 52), "Continuar", Visual.PRINCIPAL, hover(Rect2(490, 300, 300, 52)), true, 17, true)
			Visual.botao(self, Rect2(490, 362, 300, 52), "Voltar para a cidade", Visual.DESTAQUE, hover(Rect2(490, 362, 300, 52)))
			Visual.botao(self, Rect2(490, 424, 300, 52), "Recomeçar esta empresa", Visual.DESTAQUE, hover(Rect2(490, 424, 300, 52)))
			if fase == Fase.DIA:
				Visual.texto(self, Vector2(cartao.position.x, 500), "Sair no meio do dia: o dia atual não conta.", 12, Visual.TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, cartao.size.x)
		"recomecar":
			var cartao2 := Rect2(390, 220, 500, 260)
			Visual.caixa(self, cartao2, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
			Visual.texto(self, Vector2(cartao2.position.x, 284), "Recomeçar do dia 1?", 24, Visual.TEXTO, HORIZONTAL_ALIGNMENT_CENTER, cartao2.size.x)
			Visual.paragrafo(self, Vector2(430, 322), "A arquitetura desta empresa volta ao início. Sua carteira, nível e itens continuam.", 14, Visual.TEXTO_SUAVE, 420, 1.45, 3)
			Visual.botao(self, Rect2(450, 400, 180, 50), "Recomeçar", Visual.PERIGO, hover(Rect2(450, 400, 180, 50)))
			Visual.botao(self, Rect2(650, 400, 180, 50), "Cancelar", Visual.DESTAQUE, hover(Rect2(650, 400, 180, 50)))
		"incidente":
			desenhar_incidente()


func desenhar_incidente() -> void:
	var dados: Dictionary = Textos.INCIDENTES[modal["incidente"]]
	var cartao := Rect2(220, 80, 840, 590)
	Visual.caixa(self, cartao, Color("140c12"), 22, Visual.PERIGO, 2, 24)
	var pulso := 0.6 + 0.4 * sin(tempo_anim * 6.0)
	Visual.caixa(self, Rect2(cartao.position + Vector2(36, 32), Vector2(56, 56)), Visual.com_alfa(Visual.PERIGO, 0.2 * pulso), 14)
	Visual.icone(self, "hacker", cartao.position + Vector2(64, 60), Color("475569"), 1.7)
	Visual.texto(self, cartao.position + Vector2(112, 52), "INCIDENTE DE SEGURANÇA", 13, Visual.PERIGO)
	Visual.texto(self, cartao.position + Vector2(112, 84), dados["titulo"], 28, Visual.TEXTO)
	var s_nome: String = sites[modal["site"]].nome if modal["site"] >= 0 and modal["site"] < sites.size() else empresa["nome"]
	Visual.paragrafo(self, cartao.position + Vector2(40, 136), String(dados["descricao"]) % s_nome, 16, Visual.TEXTO, 760, 1.45, 3)
	var ordem: Array = modal["ordem"]
	for i in ordem.size():
		var opcao: Dictionary = dados["opcoes"][ordem[i]]
		var r := retangulo_opcao_incidente(i)
		var borda := Visual.BORDA_HOVER if hover(r) and modal["escolha"] < 0 else Visual.BORDA
		var fundo := Visual.CARTAO_CLARO
		if modal["escolha"] == i:
			borda = Visual.HUMANO if modal["certa"] else Visual.PERIGO
			fundo = Visual.com_alfa(borda, 0.15)
		Visual.caixa(self, r, fundo, 12, borda, 2 if modal["escolha"] == i else 1)
		Visual.texto(self, r.position + Vector2(18, 32), "%d   %s" % [i + 1, opcao["texto"]], 15, Visual.TEXTO)
	if modal["escolha"] >= 0:
		var y := 290.0 + ordem.size() * 58 + 12
		Visual.texto(self, Vector2(260, y + 4), "Resposta certa!" if modal["certa"] else "Não foi a melhor escolha.", 17, Visual.HUMANO if modal["certa"] else Visual.PERIGO)
		Visual.paragrafo(self, Vector2(260, y + 30), modal["resultado"], 14, Visual.TEXTO_SUAVE, 760, 1.4, 3)
		Visual.botao(self, Rect2(540, 616, 200, 44), "Continuar", Visual.PRINCIPAL, hover(Rect2(540, 616, 200, 44)), true, 16, true)
	else:
		Visual.texto(self, Vector2(260, 630), "O jogo está pausado. Escolha com calma: cada opção ensina algo.", 12, Visual.TEXTO_SUAVE)


func desenhar_boas_vindas() -> void:
	var cartao := Rect2(200, 50, 880, 636)
	Visual.caixa(self, cartao, Visual.CARTAO, 22, Visual.BORDA, 1, 24)
	var x := cartao.position.x + 40
	Visual.logo(self, Vector2(x + 28, 110), 28.0, empresa["logo"], empresa["sigla"])
	var papel := "dono" if estado().eh_dono(empresa_id) else "CTO contratado"
	Visual.texto(self, Vector2(x + 74, 104), "Você é o %s da %s" % [papel, empresa["nome"]], 26, Visual.TEXTO)
	Visual.texto(self, Vector2(x + 74, 130), "%s  ·  você recebe %d%% do lucro de cada dia" % [empresa["setor"], roundi(estado().participacao(empresa_id) * 100)], 14, Visual.TEXTO_SUAVE)
	var y := Visual.paragrafo(self, Vector2(x, 176), empresa["descricao"], 15, Visual.TEXTO_SUAVE, 800, 1.45, 3)
	Visual.texto(self, Vector2(x, y + 14), "Como jogar", 17, Visual.TEXTO)
	var passos := [
		"Escolha uma aba da paleta (Borda, Filtros, Infraestrutura, Segurança), toque num item e depois numa célula livre.",
		"Arraste do círculo à direita de um componente até outro para conectar. Defesas da aba Segurança não precisam de conexão.",
		"Hackers aparecem como losangos. Quando um ataque passa, você decide como responder ao incidente.",
		"Arraste o fundo para mover a câmera e use a roda do mouse ou os botões para dar zoom.",
	]
	y += 30.0
	for i in passos.size():
		Visual.caixa(self, Rect2(x, y - 15, 24, 24), Visual.com_alfa(Visual.DESTAQUE, 0.16), 7)
		Visual.texto(self, Vector2(x, y + 2), str(i + 1), 13, Visual.DESTAQUE, HORIZONTAL_ALIGNMENT_CENTER, 24)
		y = Visual.paragrafo(self, Vector2(x + 36, y + 1), passos[i], 14, Visual.TEXTO, 760, 1.4, 2) + 8.0
	Visual.texto(self, Vector2(x, y + 10), "Quem passa pela sua rede", 15, Visual.TEXTO)
	var colunas := 0
	for tipo in ["humano", "volumetrico", "l7", "credencial", "scraper", "sqli", "exploit", "ransomware"]:
		var px := x + (colunas % 4) * 200.0
		var py := y + 26 + (colunas / 4) * 22
		if tipo in Dados.HACKERS:
			Visual.losango(self, Vector2(px + 6, py + 6), 6.0, Dados.TIPOS_REQ[tipo]["cor"])
		else:
			Visual.caixa(self, Rect2(px, py, 12, 12), Dados.TIPOS_REQ[tipo]["cor"], 3)
		Visual.texto(self, Vector2(px + 18, py + 11), Dados.TIPOS_REQ[tipo]["nome"], 12, Visual.TEXTO_SUAVE)
		colunas += 1
	Visual.botao(self, Rect2(470, 616, 340, 52), "Assumir o cargo", Visual.PRINCIPAL, hover(Rect2(470, 616, 340, 52)), true, 18, true)
