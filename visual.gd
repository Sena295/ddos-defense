extends RefCounted

const FUNDO := Color("0a0e17")
const GRADE := Color(1, 1, 1, 0.03)
const CARTAO := Color("111827")
const CARTAO_CLARO := Color("182134")
const BORDA := Color("243047")
const BORDA_HOVER := Color("3b4a68")
const LINHA := Color("1e293d")
const TEXTO := Color("e5e7eb")
const TEXTO_SUAVE := Color("8b95a8")
const HUMANO := Color("34d399")
const BOT := Color("f87171")
const DESTAQUE := Color("38bdf8")
const CREDITOS := Color("fbbf24")
const PERIGO := Color("ef4444")
const PRINCIPAL := Color("10b981")
const SOMBRA := Color(0, 0, 0, 0.35)
const SOBREPOSICAO := Color(0.02, 0.03, 0.06, 0.82)
const TRANSPARENTE := Color(0, 0, 0, 0)
const MAX_CACHE_TEXTO := 4000



static func fonte() -> Font:
	return ThemeDB.fallback_font


static var cache_estilos: Dictionary = {}


static func caixa(ci: CanvasItem, r: Rect2, fundo: Color, raio := 12, borda := TRANSPARENTE, largura := 0, sombra := 0, detalhe := 8) -> void:
	var chave := "%s|%d|%s|%d|%d|%d" % [fundo.to_html(), raio, borda.to_html(), largura, sombra, detalhe]
	var estilo: StyleBoxFlat = cache_estilos.get(chave)
	if estilo == null:
		if cache_estilos.size() > MAX_CACHE_TEXTO:
			cache_estilos.clear()
		estilo = StyleBoxFlat.new()
		estilo.bg_color = fundo
		estilo.set_corner_radius_all(raio)
		estilo.corner_detail = detalhe
		estilo.border_color = borda
		estilo.set_border_width_all(largura)
		estilo.shadow_size = sombra
		estilo.shadow_color = SOMBRA
		estilo.shadow_offset = Vector2(0, sombra * 0.4)
		estilo.anti_aliasing = true
		cache_estilos[chave] = estilo
	ci.draw_style_box(estilo, r)


static var cache_linhas: Dictionary = {}
static var cache_larguras: Dictionary = {}


static func texto(ci: CanvasItem, pos: Vector2, conteudo: String, tamanho: int, cor: Color, alinhamento := HORIZONTAL_ALIGNMENT_LEFT, largura := -1.0) -> void:
	if conteudo == "":
		return
	var chave := "%d|%d|%d|%s" % [tamanho, alinhamento, roundi(largura), conteudo]
	var linha: TextLine = cache_linhas.get(chave)
	if linha == null:
		if cache_linhas.size() > MAX_CACHE_TEXTO:
			cache_linhas.clear()
		linha = TextLine.new()
		linha.add_string(conteudo, fonte(), tamanho)
		if largura > 0.0:
			linha.width = largura
			linha.alignment = alinhamento
		cache_linhas[chave] = linha
	linha.draw(ci.get_canvas_item(), pos - Vector2(0, linha.get_line_ascent()), cor)


static func largura_texto(conteudo: String, tamanho: int) -> float:
	var chave := "%d|%s" % [tamanho, conteudo]
	if cache_larguras.has(chave):
		return cache_larguras[chave]
	if cache_larguras.size() > MAX_CACHE_TEXTO:
		cache_larguras.clear()
	var valor := fonte().get_string_size(conteudo, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	cache_larguras[chave] = valor
	return valor


static var cache_quebras: Dictionary = {}


static func quebrar(conteudo: String, tamanho: int, largura: float) -> PackedStringArray:
	var chave := "%d|%d|%s" % [tamanho, roundi(largura), conteudo]
	if cache_quebras.has(chave):
		return cache_quebras[chave]
	if cache_quebras.size() > MAX_CACHE_TEXTO:
		cache_quebras.clear()
	var resultado := quebrar_sem_cache(conteudo, tamanho, largura)
	cache_quebras[chave] = resultado
	return resultado


static func quebrar_sem_cache(conteudo: String, tamanho: int, largura: float) -> PackedStringArray:
	var linhas := PackedStringArray()
	var atual := ""
	for palavra in conteudo.split(" "):
		var tentativa := palavra if atual == "" else atual + " " + palavra
		if largura_texto(tentativa, tamanho) > largura and atual != "":
			linhas.append(atual)
			atual = palavra
		else:
			atual = tentativa
	if atual != "":
		linhas.append(atual)
	return linhas


static func paragrafo(ci: CanvasItem, pos: Vector2, conteudo: String, tamanho: int, cor: Color, largura: float, entrelinha := 1.45, max_linhas := 99) -> float:
	var y := pos.y
	var linhas := quebrar(conteudo, tamanho, largura)
	for i in mini(linhas.size(), max_linhas):
		texto(ci, Vector2(pos.x, y), linhas[i], tamanho, cor)
		y += tamanho * entrelinha
	return y


static func com_alfa(cor: Color, alfa: float) -> Color:
	var c := cor
	c.a *= alfa
	return c


static func botao(ci: CanvasItem, r: Rect2, rotulo: String, cor: Color, hover: bool, ativo := true, tamanho := 16, principal := false) -> void:
	if principal:
		caixa(ci, r, (cor.lightened(0.12) if hover else cor) if ativo else CARTAO_CLARO, 12, TRANSPARENTE, 0, 8 if ativo else 0)
		texto(ci, Vector2(r.position.x, r.get_center().y + tamanho * 0.36), rotulo, tamanho, Color("052e1f") if ativo else TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		return
	caixa(ci, r, CARTAO_CLARO if ativo else CARTAO, 12, cor if hover and ativo else BORDA, 1)
	texto(ci, Vector2(r.position.x, r.get_center().y + tamanho * 0.36), rotulo, tamanho, TEXTO if ativo else TEXTO_SUAVE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


static func estrela(ci: CanvasItem, c: Vector2, raio: float, cor: Color) -> void:
	var pontos := PackedVector2Array()
	for k in 10:
		var a := -PI / 2 + k * PI / 5
		var r := raio if k % 2 == 0 else raio * 0.45
		pontos.append(c + Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(pontos, cor)


static func robo(ci: CanvasItem, c: Vector2, cor: Color, s := 1.0, abatido := false) -> void:
	ci.draw_line(c + Vector2(0, -9) * s, c + Vector2(0, -14) * s, cor, 1.5 * s, true)
	ci.draw_circle(c + Vector2(0, -15) * s, 2.0 * s, cor, true, -1.0, true)
	caixa(ci, Rect2(c - Vector2(9, 9) * s, Vector2(18, 16) * s), cor, int(4 * s))
	var olho := Color("0a0e17")
	if abatido:
		for dx in [-4.0, 4.0]:
			var o := c + Vector2(dx, -2) * s
			ci.draw_line(o + Vector2(-2, -2) * s, o + Vector2(2, 2) * s, olho, 1.5 * s, true)
			ci.draw_line(o + Vector2(-2, 2) * s, o + Vector2(2, -2) * s, olho, 1.5 * s, true)
	else:
		ci.draw_circle(c + Vector2(-4, -2) * s, 2.0 * s, olho, true, -1.0, true)
		ci.draw_circle(c + Vector2(4, -2) * s, 2.0 * s, olho, true, -1.0, true)
	ci.draw_line(c + Vector2(-3, 3) * s, c + Vector2(3, 3) * s, olho, 1.2 * s, true)


static func cadeado(ci: CanvasItem, c: Vector2, cor: Color, s := 1.0, aberto := false) -> void:
	var desloc := -4.0 if aberto else 0.0
	ci.draw_arc(c + Vector2(desloc, -4) * s, 5.0 * s, PI, TAU, 12, cor, 2.0 * s, true)
	caixa(ci, Rect2(c + Vector2(-7, -4) * s, Vector2(14, 11) * s), cor, int(3 * s))


static func icone(ci: CanvasItem, tipo: String, c: Vector2, cor: Color, s := 1.0) -> void:
	match tipo:
		"internet":
			ci.draw_arc(c, 10 * s, 0.0, TAU, 32, cor, 2.0, true)
			ci.draw_line(c + Vector2(-10, 0) * s, c + Vector2(10, 0) * s, cor, 1.5, true)
			var elipse := PackedVector2Array()
			for k in 25:
				var a := TAU * k / 24.0
				elipse.append(c + Vector2(cos(a) * 4.5, sin(a) * 10) * s)
			ci.draw_polyline(elipse, cor, 1.5, true)
		"cdn":
			ci.draw_circle(c + Vector2(-5, 2) * s, 5 * s, cor, true, -1.0, true)
			ci.draw_circle(c + Vector2(2, -2) * s, 6.5 * s, cor, true, -1.0, true)
			ci.draw_circle(c + Vector2(8, 3) * s, 4 * s, cor, true, -1.0, true)
			ci.draw_rect(Rect2(c + Vector2(-5, 2) * s, Vector2(13, 5) * s), cor)
		"antiddos":
			ci.draw_arc(c + Vector2(0, 2) * s, 10 * s, PI, TAU, 20, cor, 2.5, true)
			ci.draw_line(c + Vector2(0, -8) * s, c + Vector2(0, 8) * s, cor, 2.0, true)
			ci.draw_arc(c + Vector2(-3, 8) * s, 3 * s, 0.0, PI, 8, cor, 2.0, true)
		"waf":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -11) * s, c + Vector2(9, -7) * s, c + Vector2(8, 3) * s,
				c + Vector2(0, 11) * s, c + Vector2(-8, 3) * s, c + Vector2(-9, -7) * s]), cor)
		"captcha":
			robo(ci, c + Vector2(0, 2) * s, cor, 0.8 * s)
		"rate":
			ci.draw_arc(c + Vector2(0, 4) * s, 10 * s, PI, TAU, 20, cor, 2.0, true)
			ci.draw_line(c + Vector2(0, 4) * s, c + Vector2(6, -4) * s, cor, 2.0, true)
			ci.draw_circle(c + Vector2(0, 4) * s, 2.5 * s, cor, true, -1.0, true)
		"mfa":
			caixa(ci, Rect2(c + Vector2(-6, -10) * s, Vector2(12, 20) * s), cor, int(3 * s))
			caixa(ci, Rect2(c + Vector2(-4, -7) * s, Vector2(8, 11) * s), Color("0a0e17"), int(2 * s))
			ci.draw_circle(c + Vector2(0, 7) * s, 1.3 * s, Color("0a0e17"), true, -1.0, true)
		"geo":
			ci.draw_arc(c, 10 * s, 0.0, TAU, 32, cor, 2.0, true)
			ci.draw_line(c + Vector2(-7, 7) * s, c + Vector2(7, -7) * s, cor, 2.5, true)
		"lb":
			var origem := c + Vector2(-8, 0) * s
			for dy in [-8.0, 0.0, 8.0]:
				var destino := c + Vector2(8, dy) * s
				ci.draw_line(origem, destino, cor, 2.0, true)
				ci.draw_circle(destino, 2.5 * s, cor, true, -1.0, true)
			ci.draw_circle(origem, 3.5 * s, cor, true, -1.0, true)
		"fila":
			for k in 3:
				caixa(ci, Rect2(c + Vector2(-10 + k * 7, -6) * s, Vector2(5, 12) * s), cor, int(2 * s))
			ci.draw_line(c + Vector2(-12, 9) * s, c + Vector2(12, 9) * s, cor, 1.5, true)
		"redis":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(2, -11) * s, c + Vector2(-6, 2) * s, c + Vector2(0, 2) * s,
				c + Vector2(-2, 11) * s, c + Vector2(7, -2) * s, c + Vector2(1, -2) * s]), cor)
		"servidor":
			for dy in [-6.0, 5.0]:
				ci.draw_rect(Rect2(c + Vector2(-9, dy - 4) * s, Vector2(18, 8) * s), cor, false, 1.5)
				ci.draw_circle(c + Vector2(5, dy) * s, 1.5 * s, cor, true, -1.0, true)
		"autoscale":
			for dx in [-6.0, 4.0]:
				ci.draw_rect(Rect2(c + Vector2(dx - 4, -6) * s, Vector2(8, 15) * s), cor, false, 1.5)
			ci.draw_line(c + Vector2(9, 0) * s, c + Vector2(9, -11) * s, cor, 2.0, true)
			ci.draw_line(c + Vector2(6, -8) * s, c + Vector2(9, -11) * s, cor, 2.0, true)
			ci.draw_line(c + Vector2(12, -8) * s, c + Vector2(9, -11) * s, cor, 2.0, true)
		"ips":
			ci.draw_arc(c, 10 * s, 0.0, TAU, 28, cor, 1.5, true)
			ci.draw_arc(c, 5 * s, 0.0, TAU, 20, cor, 1.5, true)
			ci.draw_line(c, c + Vector2(8, -6) * s, cor, 2.0, true)
			ci.draw_circle(c + Vector2(4, 3) * s, 1.8 * s, cor, true, -1.0, true)
		"backup":
			for dy in [-6.0, 0.0, 6.0]:
				caixa(ci, Rect2(c + Vector2(-9, dy - 2.5) * s, Vector2(18, 5) * s), cor, int(2 * s))
			ci.draw_arc(c + Vector2(9, 0) * s, 5 * s, -PI * 0.6, PI * 0.6, 10, cor, 1.5, true)
		"patch":
			var faixa := PackedVector2Array([c + Vector2(-11, 4) * s, c + Vector2(4, -11) * s, c + Vector2(11, -4) * s, c + Vector2(-4, 11) * s])
			ci.draw_colored_polygon(faixa, cor)
			for p in [Vector2(-2, -2), Vector2(2, 2), Vector2(2, -2), Vector2(-2, 2)]:
				ci.draw_circle(c + p * s, 1.0 * s, Color("0a0e17"), true, -1.0, true)
		"cofre":
			caixa(ci, Rect2(c - Vector2(10, 9) * s, Vector2(20, 18) * s), cor, int(3 * s))
			ci.draw_arc(c, 5 * s, 0.0, TAU, 16, Color("0a0e17"), 2.0, true)
			ci.draw_line(c, c + Vector2(3, -3) * s, Color("0a0e17"), 2.0, true)
		"treinamento":
			ci.draw_circle(c + Vector2(0, -5) * s, 4.5 * s, cor, true, -1.0, true)
			caixa(ci, Rect2(c + Vector2(-8, 1) * s, Vector2(16, 9) * s), cor, int(4 * s))
		"criptografia":
			ci.draw_arc(c + Vector2(-4, 0) * s, 5 * s, 0.0, TAU, 16, cor, 2.5, true)
			ci.draw_line(c + Vector2(1, 0) * s, c + Vector2(11, 0) * s, cor, 2.5, true)
			ci.draw_line(c + Vector2(7, 0) * s, c + Vector2(7, 4) * s, cor, 2.5, true)
			ci.draw_line(c + Vector2(10, 0) * s, c + Vector2(10, 4) * s, cor, 2.5, true)
		"siem":
			caixa(ci, Rect2(c + Vector2(-11, -8) * s, Vector2(22, 14) * s), cor, int(3 * s))
			ci.draw_line(c + Vector2(-7, 2) * s, c + Vector2(-3, -3) * s, Color("0a0e17"), 1.5, true)
			ci.draw_line(c + Vector2(-3, -3) * s, c + Vector2(1, 0) * s, Color("0a0e17"), 1.5, true)
			ci.draw_line(c + Vector2(1, 0) * s, c + Vector2(7, -5) * s, Color("0a0e17"), 1.5, true)
			ci.draw_line(c + Vector2(-4, 10) * s, c + Vector2(4, 10) * s, cor, 2.0, true)
		"edr":
			ci.draw_circle(c + Vector2(0, 1) * s, 6 * s, cor, true, -1.0, true)
			for lado in [-1.0, 1.0]:
				for dy in [-3.0, 1.0, 5.0]:
					ci.draw_line(c + Vector2(5 * lado, dy) * s, c + Vector2(10 * lado, dy - 2) * s, cor, 1.5, true)
			ci.draw_circle(c + Vector2(0, -6) * s, 3 * s, cor, true, -1.0, true)
		"honeypot":
			caixa(ci, Rect2(c + Vector2(-8, -4) * s, Vector2(16, 14) * s), cor, int(5 * s))
			caixa(ci, Rect2(c + Vector2(-6, -9) * s, Vector2(12, 4) * s), cor, int(2 * s))
			ci.draw_circle(c + Vector2(0, 3) * s, 2.5 * s, Color("0a0e17"), true, -1.0, true)
		"hacker":
			var capuz := PackedVector2Array([c + Vector2(0, -12) * s, c + Vector2(10, -2) * s, c + Vector2(10, 11) * s, c + Vector2(-10, 11) * s, c + Vector2(-10, -2) * s])
			ci.draw_colored_polygon(capuz, cor)
			ci.draw_circle(c + Vector2(0, 1) * s, 5.5 * s, Color("0a0e17"), true, -1.0, true)
			ci.draw_circle(c + Vector2(-2, 0) * s, 1.0 * s, Color("ef4444"), true, -1.0, true)
			ci.draw_circle(c + Vector2(2, 0) * s, 1.0 * s, Color("ef4444"), true, -1.0, true)


static func torre(ci: CanvasItem, r: Rect2, cor: Color, nivel: int, proporcao: float, caido: bool, tempo: float, escala := 1.0) -> void:
	var unidades := 2 + nivel
	var corpo := Rect2(r.position + Vector2(14, 10), Vector2(34, 52))
	var racks := 2 if escala > 1.25 else 1
	for k in racks:
		var deslocado := corpo
		deslocado.position.x += k * 6
		deslocado.position.y -= k * 4
		var cor_corpo := Color("2a1418") if caido else Color("1b2436")
		if k < racks - 1:
			cor_corpo = com_alfa(cor_corpo, 0.6)
		caixa(ci, deslocado, cor_corpo, 6, PERIGO if caido else com_alfa(cor, 0.5), 1)
	var alto := (corpo.size.y - 8) / unidades
	for u in unidades:
		var y := corpo.position.y + 4 + u * alto
		var slot := Rect2(corpo.position.x + 4, y + 1, corpo.size.x - 8, alto - 3)
		caixa(ci, slot, Color("0d1320"), 3)
		var piscar := sin(tempo * (6.0 + proporcao * 18.0) + u * 1.7) > 0.0
		var led := HUMANO
		if caido:
			led = PERIGO if piscar else Color("4b1d1d")
		elif proporcao > 0.75:
			led = CREDITOS if piscar else Color("5c4510")
		elif not piscar:
			led = Color("1f5f47")
		ci.draw_circle(Vector2(slot.position.x + 5, slot.get_center().y), 1.8, led, true, -1.0, true)
		ci.draw_line(Vector2(slot.position.x + 10, slot.get_center().y), Vector2(slot.end.x - 3, slot.get_center().y), Color("26314a"), 1.0)
	var barra := Rect2(r.position + Vector2(r.size.x - 22, 12), Vector2(7, 48))
	caixa(ci, barra, LINHA, 3)
	if not caido and proporcao > 0.0:
		var altura := maxf(4.0, barra.size.y * clampf(proporcao, 0.0, 1.0))
		caixa(ci, Rect2(barra.position.x, barra.end.y - altura, barra.size.x, altura), HUMANO.lerp(PERIGO, clampf(proporcao, 0.0, 1.0)), 3)


static func formatar_decimal(valor: float) -> String:
	var texto_valor := ""
	if valor >= 100.0:
		texto_valor = "%d" % roundi(valor)
	elif valor >= 10.0:
		texto_valor = "%.1f" % valor
	else:
		texto_valor = "%.2f" % valor
	return texto_valor.replace(".", ",")


static func dinheiro(mil: float) -> String:
	var negativo := mil < 0.0
	var v := absf(mil)
	var resultado := ""
	if v >= 1000000.0:
		resultado = "R$ %s bi" % formatar_decimal(v / 1000000.0)
	elif v >= 1000.0:
		resultado = "R$ %s mi" % formatar_decimal(v / 1000.0)
	else:
		resultado = "R$ %d mil" % roundi(v)
	return ("-" if negativo else "") + resultado


static func requisicoes(por_minuto: float) -> String:
	if por_minuto >= 1000000.0:
		return "%s mi" % formatar_decimal(por_minuto / 1000000.0)
	if por_minuto >= 1000.0:
		return "%d mil" % roundi(por_minuto / 1000.0)
	return "%d" % roundi(por_minuto)


static func elipse(ci: CanvasItem, c: Vector2, raio: Vector2, cor: Color) -> void:
	if raio.x < 1.0 or raio.y < 1.0 or cor.a <= 0.0:
		return
	var pontos := PackedVector2Array()
	for k in 20:
		var a := TAU * k / 20.0
		pontos.append(c + Vector2(cos(a) * raio.x, sin(a) * raio.y))
	ci.draw_colored_polygon(pontos, cor)


static func losango(ci: CanvasItem, c: Vector2, r: float, cor: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), cor)
	ci.draw_circle(c, r * 0.32, Color(0, 0, 0, 0.45), true, -1.0, true)


static func texto_mono(ci: CanvasItem, pos: Vector2, conteudo: String, tamanho: int, cor: Color, avanco := 0.0) -> void:
	var passo := avanco if avanco > 0.0 else tamanho * 0.62
	var f := fonte()
	for i in conteudo.length():
		var largura_char := f.get_char_size(conteudo.unicode_at(i), tamanho).x
		ci.draw_char(f, pos + Vector2(i * passo + (passo - largura_char) * 0.5, 0), conteudo[i], tamanho, cor)


static func forma(ci: CanvasItem, tipo: String, c: Vector2, r: float, cor: Color) -> void:
	match tipo:
		"quadrado":
			caixa(ci, Rect2(c - Vector2(r, r), Vector2(r, r) * 2), cor, int(r * 0.45), TRANSPARENTE, 0, 0, 6)
		"hexagono":
			var hex := PackedVector2Array()
			for k in 6:
				var a := PI / 6 + k * TAU / 6
				hex.append(c + Vector2(cos(a), sin(a)) * r * 1.08)
			ci.draw_colored_polygon(hex, cor)
		"losango":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 1.2), c + Vector2(r * 1.2, 0), c + Vector2(0, r * 1.2), c + Vector2(-r * 1.2, 0)]), cor)
		"escudo":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r), c + Vector2(r, r * 0.2), c + Vector2(0, r * 1.15), c + Vector2(-r, r * 0.2)]), cor)
		_:
			ci.draw_circle(c, r, cor, true, -1.0, true)


static func logo(ci: CanvasItem, c: Vector2, r: float, spec: Dictionary, sigla := "") -> void:
	forma(ci, spec.get("forma", "circulo"), c, r, spec.get("cor", DESTAQUE))
	var icone_logo: String = spec.get("icone", "")
	if icone_logo == "":
		texto(ci, Vector2(c.x - r, c.y + r * 0.35), sigla, int(r * 0.9), spec.get("cor2", Color.WHITE), HORIZONTAL_ALIGNMENT_CENTER, r * 2)
		return
	simbolo(ci, icone_logo, c, spec.get("cor2", Color.WHITE), r / 12.0)


static func simbolo(ci: CanvasItem, tipo: String, c: Vector2, cor: Color, s := 1.0) -> void:
	match tipo:
		"carrinho":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-9, -6) * s, c + Vector2(-6, -6) * s, c + Vector2(-3, 4) * s, c + Vector2(7, 4) * s, c + Vector2(9, -3) * s, c + Vector2(-5, -3) * s]), cor, 2.0 * s, true)
			ci.draw_circle(c + Vector2(-2, 8) * s, 1.8 * s, cor, true, -1.0, true)
			ci.draw_circle(c + Vector2(6, 8) * s, 1.8 * s, cor, true, -1.0, true)
		"sacola":
			caixa(ci, Rect2(c + Vector2(-7, -3) * s, Vector2(14, 12) * s), cor, int(2 * s))
			ci.draw_arc(c + Vector2(0, -3) * s, 4 * s, PI, TAU, 10, cor, 2.0 * s, true)
		"aviao":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, 1) * s, c + Vector2(10, -3) * s, c + Vector2(10, 0) * s, c + Vector2(-10, 3) * s]), cor)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-1, -1) * s, c + Vector2(4, -9) * s, c + Vector2(6, -8) * s, c + Vector2(3, 0) * s]), cor)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-1, 2) * s, c + Vector2(4, 9) * s, c + Vector2(6, 8) * s, c + Vector2(3, 1) * s]), cor)
		"talher":
			ci.draw_line(c + Vector2(-4, -9) * s, c + Vector2(-4, 9) * s, cor, 2.0 * s, true)
			for dx in [-6.0, -4.0, -2.0]:
				ci.draw_line(c + Vector2(dx, -9) * s, c + Vector2(dx, -3) * s, cor, 1.2 * s, true)
			elipse(ci, c + Vector2(5, -4) * s, Vector2(2.5, 5) * s, cor)
			ci.draw_line(c + Vector2(5, 0) * s, c + Vector2(5, 9) * s, cor, 2.0 * s, true)
		"play":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -8) * s, c + Vector2(8, 0) * s, c + Vector2(-5, 8) * s]), cor)
		"banco":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -4) * s, c + Vector2(0, -10) * s, c + Vector2(10, -4) * s]), cor)
			for dx in [-7.0, -2.5, 2.5, 7.0]:
				ci.draw_rect(Rect2(c + Vector2(dx - 1.2, -3) * s, Vector2(2.4, 9) * s), cor)
			ci.draw_rect(Rect2(c + Vector2(-10, 6) * s, Vector2(20, 2.5) * s), cor)
		"moeda":
			ci.draw_arc(c, 9 * s, 0.0, TAU, 28, cor, 2.0 * s, true)
			texto(ci, c + Vector2(-9, 5) * s, "$", int(14 * s), cor, HORIZONTAL_ALIGNMENT_CENTER, 18 * s)
		"cartao":
			caixa(ci, Rect2(c + Vector2(-10, -7) * s, Vector2(20, 14) * s), cor, int(2 * s))
			ci.draw_rect(Rect2(c + Vector2(-10, -3) * s, Vector2(20, 3) * s), Color(0, 0, 0, 0.5))
		"cruz":
			ci.draw_rect(Rect2(c + Vector2(-3, -9) * s, Vector2(6, 18) * s), cor)
			ci.draw_rect(Rect2(c + Vector2(-9, -3) * s, Vector2(18, 6) * s), cor)
		"predio":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -3) * s, c + Vector2(0, -10) * s, c + Vector2(10, -3) * s]), cor)
			ci.draw_rect(Rect2(c + Vector2(-8, -2) * s, Vector2(16, 11) * s), cor)
			ci.draw_rect(Rect2(c + Vector2(-2, 3) * s, Vector2(4, 6) * s), Color(0, 0, 0, 0.5))
		"controle":
			caixa(ci, Rect2(c + Vector2(-10, -5) * s, Vector2(20, 11) * s), cor, int(5 * s))
			ci.draw_rect(Rect2(c + Vector2(-7, -1) * s, Vector2(5, 1.6) * s), Color(0, 0, 0, 0.55))
			ci.draw_rect(Rect2(c + Vector2(-5.2, -3) * s, Vector2(1.6, 5) * s), Color(0, 0, 0, 0.55))
			ci.draw_circle(c + Vector2(5, -1) * s, 1.4 * s, Color(0, 0, 0, 0.55), true, -1.0, true)
			ci.draw_circle(c + Vector2(7, 1.5) * s, 1.4 * s, Color(0, 0, 0, 0.55), true, -1.0, true)
		"antena":
			ci.draw_line(c + Vector2(0, -3) * s, c + Vector2(-5, 10) * s, cor, 2.0 * s, true)
			ci.draw_line(c + Vector2(0, -3) * s, c + Vector2(5, 10) * s, cor, 2.0 * s, true)
			ci.draw_circle(c + Vector2(0, -4) * s, 2.2 * s, cor, true, -1.0, true)
			ci.draw_arc(c + Vector2(0, -4) * s, 6 * s, -PI * 0.85, -PI * 0.15, 10, cor, 1.6 * s, true)
			ci.draw_arc(c + Vector2(0, -4) * s, 10 * s, -PI * 0.8, -PI * 0.2, 12, cor, 1.6 * s, true)
		"cerebro":
			for p in [Vector2(-4, -3), Vector2(4, -3), Vector2(-5, 3), Vector2(5, 3), Vector2(0, -6), Vector2(0, 4)]:
				ci.draw_circle(c + p * s, 4.2 * s, cor, true, -1.0, true)
			ci.draw_line(c + Vector2(0, -9) * s, c + Vector2(0, 8) * s, Color(0, 0, 0, 0.45), 1.5 * s, true)
		"balao":
			caixa(ci, Rect2(c + Vector2(-10, -8) * s, Vector2(20, 13) * s), cor, int(5 * s))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, 4) * s, c + Vector2(1, 4) * s, c + Vector2(-5, 10) * s]), cor)
		"raio":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(2, -11) * s, c + Vector2(-6, 2) * s, c + Vector2(0, 2) * s, c + Vector2(-2, 11) * s, c + Vector2(7, -2) * s, c + Vector2(1, -2) * s]), cor)
		"foguete":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -11) * s, c + Vector2(5, -2) * s, c + Vector2(5, 6) * s, c + Vector2(-5, 6) * s, c + Vector2(-5, -2) * s]), cor)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 2) * s, c + Vector2(-9, 9) * s, c + Vector2(-5, 7) * s]), cor)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(5, 2) * s, c + Vector2(9, 9) * s, c + Vector2(5, 7) * s]), cor)
			ci.draw_circle(c + Vector2(0, -2) * s, 2 * s, Color(0, 0, 0, 0.5), true, -1.0, true)
		"escudo":
			icone(ci, "waf", c, cor, s)
		"codigo":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-4, -7) * s, c + Vector2(-10, 0) * s, c + Vector2(-4, 7) * s]), cor, 2.2 * s, true)
			ci.draw_polyline(PackedVector2Array([c + Vector2(4, -7) * s, c + Vector2(10, 0) * s, c + Vector2(4, 7) * s]), cor, 2.2 * s, true)
			ci.draw_line(c + Vector2(2, -8) * s, c + Vector2(-2, 8) * s, cor, 2.0 * s, true)




const CONTORNO := Color("161b29")
const LINHA_PERSONAGEM := Color("1c2131")


static func pintar_partes(ci: CanvasItem, pe: Vector2, u: float, partes: Array, direcao: int) -> void:
	var espessura := maxf(1.0, roundf(u * 0.6))
	var retangulos: Array = []
	for p in partes:
		var x: float = p[0]
		var w: float = p[2]
		if direcao < 0:
			x = -(x + w)
		retangulos.append(Rect2((pe + Vector2(x, p[1]) * u).round(), (Vector2(w, p[3]) * u).round()))
	for i in partes.size():
		if partes[i][5]:
			var cor: Color = partes[i][4]
			ci.draw_rect(retangulos[i].grow(espessura), cor.darkened(0.62).lerp(CONTORNO, 0.35))
	for i in partes.size():
		ci.draw_rect(retangulos[i], partes[i][4])


static func circulo_c(ci: CanvasItem, c: Vector2, r: float, cor: Color, o: float) -> void:
	ci.draw_circle(c, r + o, LINHA_PERSONAGEM, true, -1.0, true)
	ci.draw_circle(c, r, cor, true, -1.0, true)


static func elipse_c(ci: CanvasItem, c: Vector2, raio: Vector2, cor: Color, o: float) -> void:
	elipse(ci, c, raio + Vector2(o, o), LINHA_PERSONAGEM)
	elipse(ci, c, raio, cor)


static func capsula_c(ci: CanvasItem, a: Vector2, b: Vector2, r: float, cor: Color, o: float) -> void:
	ci.draw_line(a, b, LINHA_PERSONAGEM, (r + o) * 2.0, true)
	ci.draw_circle(a, r + o, LINHA_PERSONAGEM, true, -1.0, true)
	ci.draw_circle(b, r + o, LINHA_PERSONAGEM, true, -1.0, true)
	ci.draw_line(a, b, cor, r * 2.0, true)
	ci.draw_circle(a, r, cor, true, -1.0, true)
	ci.draw_circle(b, r, cor, true, -1.0, true)


static func poligono_c(ci: CanvasItem, pontos: PackedVector2Array, cor: Color, o: float) -> void:
	ci.draw_colored_polygon(pontos, cor)
	var fechado := pontos.duplicate()
	fechado.append(pontos[0])
	ci.draw_polyline(fechado, LINHA_PERSONAGEM, o * 1.6, true)


static func arco_pontos(c: Vector2, raio: Vector2, de: float, ate: float, passos := 14) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	for k in passos + 1:
		var a := deg_to_rad(lerpf(de, ate, float(k) / passos))
		pontos.append(c + Vector2(cos(a) * raio.x, sin(a) * raio.y))
	return pontos


static func avatar(ci: CanvasItem, pe: Vector2, escala: float, aparencia: Dictionary, equipados: Dictionary, tempo := 0.0, andando := false, direcao := 1) -> void:
	const Dados := preload("res://dados.gd")
	var s := escala * 0.98
	var d := 1.0 if direcao >= 0 else -1.0
	var P := func(x, y): return pe + Vector2(float(x) * d, float(y)) * s
	var R := func(x, y, w, h): return Rect2(pe + Vector2((float(x) if d > 0 else -float(x) - float(w)), float(y)) * s, Vector2(float(w), float(h)) * s)
	var o := maxf(1.0, 1.15 * s)
	var pele: Color = Dados.CORES_PELE[clampi(int(aparencia.get("pele", 0)), 0, Dados.CORES_PELE.size() - 1)]
	var cor_cabelo: Color = Dados.CORES_CABELO[clampi(int(aparencia.get("cor_cabelo", 0)), 0, Dados.CORES_CABELO.size() - 1)]
	var cor_roupa: Color = Dados.CORES_ROUPA[clampi(int(aparencia.get("cor_roupa", 0)), 0, Dados.CORES_ROUPA.size() - 1)]
	var cabelo := clampi(int(aparencia.get("cabelo", 0)), 0, Dados.ESTILOS_CABELO.size() - 1)
	var estilo_roupa := clampi(int(aparencia.get("roupa", 0)), 0, 2)
	var olhar := clampi(int(aparencia.get("olhos", 0)), 0, 2)
	var feminino := int(aparencia.get("corpo", 0)) == 1
	var vestimenta: String = equipados.get("roupa", "")
	var chapeu: String = equipados.get("chapeu", "")
	var acessorio: String = equipados.get("acessorio", "")
	var fase := sin(tempo * 10.0) if andando else 0.0
	var b := absf(fase) * 1.5 if andando else sin(tempo * 2.4) * 0.35
	var balanco := fase * 3.5
	var piscar := fmod(tempo + pe.x * 0.013, 3.9) < 0.12
	var pele_sombra := pele.darkened(0.14)
	var branco := Color("f8fafc")
	var calca := Color("3a4766")
	var sapato := Color("262b3a")
	var tronco := cor_roupa
	var manga := cor_roupa
	if vestimenta == "terno":
		tronco = Color("273142")
		manga = tronco
		calca = Color("273142")
		sapato = Color("15171c")
	elif vestimenta == "jaleco":
		tronco = Color("f1f5f9")
		manga = tronco
		calca = Color("4b5563")
	var braco_nu: bool = estilo_roupa == 2 and vestimenta == ""
	var meia_largura := 8.5 if feminino else 10.0
	var raio_perna := 3.1 if feminino else 3.7
	var raio_braco := 2.6 if feminino else 3.1
	var x_perna := 3.6 if feminino else 4.4
	var centro_cabeca := Vector2(0, -47 - b)
	var raio_cabeca := 13.5
	elipse(ci, pe, Vector2(12, 3.4) * s, Color(0, 0, 0, 0.22))
	var cab := cor_cabelo
	var cab_escuro := cor_cabelo.darkened(0.18)
	var c0: Vector2 = P.call(centro_cabeca.x, centro_cabeca.y)
	if vestimenta == "capuz":
		caixa(ci, R.call(-12, -57 - b, 8, 24), tronco.darkened(0.2), int(5 * s), LINHA_PERSONAGEM, int(o))
	match cabelo:
		1:
			var cabelo_atras: Rect2 = R.call(-15.5, -56 - b, 15, 30)
			caixa(ci, cabelo_atras, cab_escuro, int(6 * s), LINHA_PERSONAGEM, int(o))
		3:
			circulo_c(ci, P.call(-2, -51 - b), 17.0 * s, cab, o)
			for k in 7:
				var ang := deg_to_rad(150.0 + k * 40.0)
				circulo_c(ci, P.call(-2 + cos(ang) * 16.0, -51 - b + sin(ang) * 15.0), 5.0 * s, cab, o)
		4:
			circulo_c(ci, P.call(-3, -63 - b), 6.0 * s, cab, o)
		7:
			capsula_c(ci, P.call(-14, -52 - b), P.call(-17, -33 - b + balanco * 0.3), 4.0 * s, cab_escuro, o)
	capsula_c(ci, P.call(-meia_largura + 0.5, -31 - b), P.call(-meia_largura - 1.5 - balanco * 0.6, -19 - b), raio_braco * s, pele_sombra if braco_nu else manga.darkened(0.14), o)
	circulo_c(ci, P.call(-meia_largura - 1.5 - balanco * 0.6, -17.5 - b), 3.0 * s, pele_sombra, o)
	var pe_tras: Vector2 = P.call(-x_perna - balanco, -4)
	capsula_c(ci, P.call(-x_perna, -16), pe_tras, raio_perna * s, calca.darkened(0.12), o)
	elipse_c(ci, pe_tras + Vector2(1.5 * d, 1.5) * s, Vector2(4.8, 2.8) * s, sapato, o)
	var pe_frente: Vector2 = P.call(x_perna + balanco, -4)
	capsula_c(ci, P.call(x_perna, -16), pe_frente, raio_perna * s, calca, o)
	elipse_c(ci, pe_frente + Vector2(1.5 * d, 1.5) * s, Vector2(4.8, 2.8) * s, sapato, o)
	ci.draw_line(pe_frente + Vector2(-2.5, 3.6) * s, pe_frente + Vector2(5.5 * d, 3.6) * s if d > 0 else pe_frente + Vector2(-5.5, 3.6) * s, branco, 1.0 * s)
	var comprimento := 27.0 if vestimenta == "jaleco" else 21.0
	var tronco_rect: Rect2 = R.call(-meia_largura, -35 - b, meia_largura * 2, comprimento)
	caixa(ci, tronco_rect, tronco, int(7 * s), LINHA_PERSONAGEM, int(o))
	var sombra_tronco: Rect2 = R.call(meia_largura * 0.3, -33 - b, meia_largura * 0.6, comprimento - 4)
	caixa(ci, sombra_tronco, Color(0, 0, 0, 0.1), int(4 * s))
	if feminino and vestimenta == "":
		caixa(ci, R.call(-meia_largura - 1, -20 - b, meia_largura * 2 + 2, 6), tronco.darkened(0.08), int(3 * s), LINHA_PERSONAGEM, int(o))
	elif vestimenta == "":
		ci.draw_line(P.call(-meia_largura + 1, -16.5 - b), P.call(meia_largura - 1, -16.5 - b), calca.darkened(0.35), 1.6 * s)
	match vestimenta:
		"terno":
			ci.draw_colored_polygon(PackedVector2Array([P.call(-4, -35 - b), P.call(4, -35 - b), P.call(0, -24 - b)]), branco)
			ci.draw_colored_polygon(PackedVector2Array([P.call(-1, -32 - b), P.call(1, -32 - b), P.call(1.4, -23 - b), P.call(0, -21 - b), P.call(-1.4, -23 - b)]), Color("dc2626"))
			ci.draw_line(P.call(-4, -35 - b), P.call(0, -24 - b), LINHA_PERSONAGEM, o)
			ci.draw_line(P.call(4, -35 - b), P.call(0, -24 - b), LINHA_PERSONAGEM, o)
		"jaleco":
			ci.draw_colored_polygon(PackedVector2Array([P.call(-3.5, -35 - b), P.call(3.5, -35 - b), P.call(0, -26 - b)]), cor_roupa)
			ci.draw_line(P.call(-3.5, -35 - b), P.call(0, -26 - b), Color("94a3b8"), 1.4 * s)
			ci.draw_line(P.call(3.5, -35 - b), P.call(0, -26 - b), Color("94a3b8"), 1.4 * s)
			ci.draw_line(P.call(0, -26 - b), P.call(0, -10 - b), Color("cbd5e1"), 1.2 * s)
			ci.draw_line(P.call(5, -30 - b), P.call(5, -27 - b), Color("2563eb"), 1.4 * s)
		"capuz":
			caixa(ci, R.call(-5, -24 - b, 10, 5), tronco.darkened(0.15), int(2 * s))
			ci.draw_line(P.call(-2, -34 - b), P.call(-2, -29 - b), branco, 1.2 * s)
			ci.draw_line(P.call(2, -34 - b), P.call(2, -29 - b), branco, 1.2 * s)
		_:
			match estilo_roupa:
				1:
					ci.draw_colored_polygon(PackedVector2Array([P.call(-4.5, -35 - b), P.call(0, -32 - b), P.call(-2, -30 - b)]), branco)
					ci.draw_colored_polygon(PackedVector2Array([P.call(4.5, -35 - b), P.call(0, -32 - b), P.call(2, -30 - b)]), branco)
					for k in 3:
						ci.draw_circle(P.call(0, -29 + k * 4 - b), 0.8 * s, tronco.lightened(0.5), true, -1.0, true)
				2:
					ci.draw_colored_polygon(arco_pontos(P.call(0, -35 - b), Vector2(5, 4) * s, 0, 180, 10), pele)
				_:
					ci.draw_colored_polygon(arco_pontos(P.call(0, -35 - b), Vector2(3.5, 2.5) * s, 0, 180, 10), pele_sombra)
	caixa(ci, R.call(-2.5, -39 - b, 5, 5), pele_sombra, int(1 * s))
	circulo_c(ci, P.call(-11.5, -46 - b), 3.2 * s, pele, o)
	ci.draw_circle(P.call(-11.5, -46 - b), 1.4 * s, pele_sombra, true, -1.0, true)
	elipse_c(ci, c0, Vector2(raio_cabeca, raio_cabeca - 0.5) * s, pele, o)
	elipse(ci, P.call(5.5, -44 - b), Vector2(7, 9) * s, Color(0, 0, 0, 0.04))
	var olho_e: Vector2 = P.call(-2.5, -47 - b)
	var olho_d: Vector2 = P.call(5.5, -47 - b)
	var escuro := Color("2a2018")
	if olhar == 1:
		for olho in [olho_e, olho_d]:
			ci.draw_polyline(PackedVector2Array([olho + Vector2(-2.2, 0.8) * s, olho + Vector2(0, -1.2) * s, olho + Vector2(2.2, 0.8) * s]), escuro, 1.5 * s, true)
	elif piscar:
		for olho in [olho_e, olho_d]:
			ci.draw_line(olho + Vector2(-2, 0.5) * s, olho + Vector2(2, 0.5) * s, escuro, 1.4 * s, true)
	else:
		for olho in [olho_e, olho_d]:
			elipse(ci, olho, Vector2(2.1, 2.9) * s, escuro)
			ci.draw_circle(olho + Vector2(0.7 * d, -1.1) * s, 0.9 * s, branco, true, -1.0, true)
	if feminino and olhar != 1:
		for olho in [olho_e, olho_d]:
			ci.draw_line(olho + Vector2(1.6 * d, -2.2) * s, olho + Vector2(3.2 * d, -3.4) * s, escuro, 1.1 * s, true)
	var sobrancelha := cab_escuro if cabelo != 5 else pele.darkened(0.45)
	var y_sobr := -52.0 if olhar != 2 else -51.0
	var incl := 0.0 if olhar != 2 else 1.0
	ci.draw_line(P.call(-5, y_sobr - b - incl * 0.0), P.call(-0.5, y_sobr - b + incl), sobrancelha, 1.6 * s, true)
	ci.draw_line(P.call(3.5, y_sobr - b + incl), P.call(8, y_sobr - b - incl * 0.0), sobrancelha, 1.6 * s, true)
	ci.draw_line(P.call(2, -44.5 - b), P.call(2.8, -43 - b), pele.darkened(0.25), 1.2 * s, true)
	elipse(ci, P.call(-5.5, -42.5 - b), Vector2(2.4, 1.4) * s, Color(1, 0.45, 0.5, 0.35 if feminino else 0.18))
	elipse(ci, P.call(8.5, -42.5 - b), Vector2(2.0, 1.3) * s, Color(1, 0.45, 0.5, 0.35 if feminino else 0.18))
	var boca := Color("b4485e") if feminino else pele.darkened(0.48)
	if olhar == 1:
		ci.draw_colored_polygon(arco_pontos(P.call(2, -40.5 - b), Vector2(3, 2.6) * s, 0, 180, 10), Color("8f2d3f"))
	elif olhar == 2:
		ci.draw_line(P.call(0.5, -40 - b), P.call(4, -40 - b), boca, 1.3 * s, true)
	else:
		ci.draw_polyline(PackedVector2Array([P.call(-0.5, -40.5 - b), P.call(2, -39.3 - b), P.call(4.5, -40.5 - b)]), boca, 1.4 * s, true)
	desenhar_cabelo_frente(ci, P, s, o, cabelo, cab, cab_escuro, b, c0, raio_cabeca, d)
	match chapeu:
		"bone":
			poligono_c(ci, arco_pontos(P.call(0, -51 - b), Vector2(14.2, 11) * s, 180, 360, 16), Color("2563eb"), o)
			poligono_c(ci, PackedVector2Array([P.call(9, -52 - b), P.call(20, -51 - b), P.call(19, -48.5 - b), P.call(9, -49 - b)]), Color("1d4ed8"), o)
			ci.draw_circle(P.call(0, -61 - b), 1.4 * s, Color("93c5fd"), true, -1.0, true)
		"gorro":
			poligono_c(ci, arco_pontos(P.call(0, -52 - b), Vector2(14.5, 12) * s, 180, 360, 16), Color("dc2626"), o)
			caixa(ci, R.call(-14.5, -55 - b, 29, 5), branco, int(2 * s), LINHA_PERSONAGEM, int(o))
			circulo_c(ci, P.call(0, -65 - b), 3.4 * s, branco, o)
	match acessorio:
		"oculos_hacker":
			for olho in [olho_e, olho_d]:
				var lente := Rect2(olho - Vector2(3.2, 2.6) * s, Vector2(6.4, 5.2) * s)
				caixa(ci, lente, Color("0f172a"), int(2 * s), Color("0f172a"), 1)
				ci.draw_line(lente.position + Vector2(1.2, 1.2) * s, lente.position + Vector2(3, 1.2) * s, Color("22c55e"), 1.0 * s)
			ci.draw_line(olho_e + Vector2(3.2 * d, -0.5) * s, olho_d + Vector2(-3.2 * d, -0.5) * s, Color("0f172a"), 1.4 * s)
			ci.draw_line(olho_e + Vector2(-3.2 * d, -0.5) * s, P.call(-11, -47 - b), Color("0f172a"), 1.2 * s)
		"headset":
			ci.draw_polyline(arco_pontos(c0, Vector2(15, 15) * s, 195, 345, 14), Color("111827"), 2.2 * s, true)
			circulo_c(ci, P.call(-12.5, -46 - b), 4.0 * s, Color("1f2937"), o)
			ci.draw_line(P.call(-12, -43 - b), P.call(0, -39 - b), Color("111827"), 1.4 * s, true)
			ci.draw_circle(P.call(0.5, -39 - b), 1.4 * s, Color("ef4444"), true, -1.0, true)
	capsula_c(ci, P.call(meia_largura - 0.5, -31 - b), P.call(meia_largura + 1.5 + balanco * 0.6, -19 - b), raio_braco * s, pele if braco_nu else manga, o)
	if vestimenta == "" and estilo_roupa == 0:
		capsula_c(ci, P.call(meia_largura + 0.3 + balanco * 0.3, -25.5 - b), P.call(meia_largura + 1.5 + balanco * 0.6, -19 - b), (raio_braco - 0.2) * s, pele, 0.0)
	circulo_c(ci, P.call(meia_largura + 1.5 + balanco * 0.6, -17.5 - b), 3.0 * s, pele, o)


static func desenhar_cabelo_frente(ci: CanvasItem, P: Callable, s: float, o: float, cabelo: int, cab: Color, cab_escuro: Color, b: float, c0: Vector2, raio: float, d: float) -> void:
	var brilho := Color(cab.lightened(0.22), 0.65)
	match cabelo:
		0:
			var pontos := arco_pontos(P.call(0, -47 - b), Vector2(raio + 1.2, raio + 1.2) * s, 160 if d > 0 else 20, 380 if d > 0 else -200, 18)
			pontos.append(P.call(9, -52 - b))
			pontos.append(P.call(4, -54 - b))
			pontos.append(P.call(-1, -52 - b))
			pontos.append(P.call(-6, -53 - b))
			pontos.append(P.call(-10, -48 - b))
			poligono_c(ci, pontos, cab, o)
			ci.draw_polyline(arco_pontos(P.call(-1, -50 - b), Vector2(8, 7) * s, 230 if d > 0 else -50, 290 if d > 0 else -110, 6), brilho, 1.1 * s, true)
		1:
			var pontos2 := arco_pontos(P.call(0, -47 - b), Vector2(raio + 1.5, raio + 1.5) * s, 150 if d > 0 else 30, 390 if d > 0 else -210, 18)
			pontos2.append(P.call(13, -40 - b))
			pontos2.append(P.call(10, -53 - b))
			pontos2.append(P.call(2, -55 - b))
			pontos2.append(P.call(-7, -52 - b))
			pontos2.append(P.call(-11, -38 - b))
			poligono_c(ci, pontos2, cab, o)
			ci.draw_polyline(arco_pontos(P.call(-1, -50 - b), Vector2(8, 7) * s, 230 if d > 0 else -50, 290 if d > 0 else -110, 6), brilho, 1.1 * s, true)
		2:
			poligono_c(ci, PackedVector2Array([P.call(-6, -58 - b), P.call(-2, -67 - b), P.call(2, -62 - b), P.call(5, -68 - b), P.call(7, -59 - b), P.call(4, -55 - b), P.call(-3, -55 - b)]), cab, o)
			ci.draw_polyline(arco_pontos(c0, Vector2(raio - 0.5, raio - 0.5) * s, 200 if d > 0 else -20, 250 if d > 0 else -70, 6), cab_escuro, 2.5 * s, true)
		3:
			var pontos3 := arco_pontos(P.call(-1, -50 - b), Vector2(raio + 2.5, raio + 1) * s, 175 if d > 0 else 5, 365 if d > 0 else -185, 16)
			pontos3.append(P.call(8, -51 - b))
			pontos3.append(P.call(-9, -50 - b))
			poligono_c(ci, pontos3, cab, o)
			for ponto in [[-6, -57], [0, -60], [6, -57], [-10, -53], [2, -55]]:
				ci.draw_arc(P.call(ponto[0], ponto[1] - b), 2.0 * s, PI, TAU, 6, brilho, 1.0 * s, true)
		4, 7:
			var pontos4 := arco_pontos(P.call(0, -47 - b), Vector2(raio + 1, raio + 1) * s, 165 if d > 0 else 15, 375 if d > 0 else -195, 18)
			pontos4.append(P.call(8, -51 - b))
			pontos4.append(P.call(2, -54 - b))
			pontos4.append(P.call(-5, -52 - b))
			pontos4.append(P.call(-11, -46 - b))
			poligono_c(ci, pontos4, cab, o)
			ci.draw_polyline(arco_pontos(P.call(-1, -50 - b), Vector2(8, 7) * s, 230 if d > 0 else -50, 290 if d > 0 else -110, 6), brilho, 1.1 * s, true)
			if cabelo == 7:
				ci.draw_circle(P.call(-13, -51 - b), 2.0 * s, Color("ec4899"), true, -1.0, true)
			else:
				var laco: Vector2 = P.call(-2, -57.5 - b)
				caixa(ci, Rect2(laco - Vector2(3, 1) * s, Vector2(6, 2) * s), Color("ec4899"), int(1 * s))
		5:
			ci.draw_polyline(arco_pontos(P.call(-2, -52 - b), Vector2(5, 4) * s, 200 if d > 0 else -20, 260 if d > 0 else -80, 5), Color(1, 1, 1, 0.45), 1.6 * s, true)
		6:
			var pontos6 := arco_pontos(P.call(0, -47 - b), Vector2(raio + 1.3, raio + 1.6) * s, 165 if d > 0 else 15, 375 if d > 0 else -195, 18)
			pontos6.append(P.call(12, -50 - b))
			pontos6.append(P.call(4, -55 - b))
			pontos6.append(P.call(-4, -56 - b))
			pontos6.append(P.call(-11, -47 - b))
			poligono_c(ci, pontos6, cab, o)
			ci.draw_line(P.call(-4, -61 - b), P.call(-2, -56 - b), cab_escuro, 1.3 * s, true)
			ci.draw_polyline(arco_pontos(P.call(2, -51 - b), Vector2(7, 6) * s, 235 if d > 0 else -55, 300 if d > 0 else -120, 6), brilho, 1.1 * s, true)


static func semicirculo(c: Vector2, r: float, de: float, ate: float) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	for k in 17:
		var a := lerpf(de, ate, k / 16.0)
		pontos.append(c + Vector2(cos(a), sin(a)) * r)
	return pontos


static func pet(ci: CanvasItem, pe: Vector2, tipo: String, tempo: float, direcao := 1, escala := 1.0) -> void:
	var u := 1.6 * escala
	var pulo := roundf(absf(sin(tempo * 9.0)) * 1.5)
	elipse(ci, pe, Vector2(5, 1.8) * u, Color(0, 0, 0, 0.25))
	var partes: Array = []
	if tipo == "pet_gato":
		var cor := Color("94a3b8")
		var rabo := roundf(sin(tempo * 5.0))
		partes.append([-6, -9 - pulo + rabo, 2, 4, cor.darkened(0.15), true])
		partes.append([-5, -6 - pulo, 8, 4, cor, true])
		partes.append([-4, -2 - pulo, 2, 2, cor.darkened(0.15), true])
		partes.append([1, -2 - pulo, 2, 2, cor.darkened(0.15), true])
		partes.append([1, -10 - pulo, 5, 5, cor, true])
		partes.append([1, -11 - pulo, 1, 1, cor, true])
		partes.append([5, -11 - pulo, 1, 1, cor, true])
		partes.append([-3, -6 - pulo, 3, 1, cor.darkened(0.25), false])
		partes.append([3, -8 - pulo, 1, 1, Color("22c55e"), false])
		partes.append([5, -8 - pulo, 1, 1, Color("22c55e"), false])
		partes.append([4, -6 - pulo, 1, 1, Color("f9a8d4"), false])
	else:
		var cor2 := Color("22d3ee")
		partes.append([0, -15 - pulo, 1, 3, Color("94a3b8"), false])
		partes.append([-1, -16 - pulo, 3, 1, Color("ef4444"), true])
		partes.append([-4, -12 - pulo, 8, 6, cor2, true])
		partes.append([-3, -6 - pulo, 6, 3, cor2.darkened(0.25), true])
		partes.append([-3, -2 - pulo, 2, 2, Color("334155"), true])
		partes.append([1, -2 - pulo, 2, 2, Color("334155"), true])
		partes.append([0, -10 - pulo, 1, 2, Color("0f172a"), false])
		partes.append([2, -10 - pulo, 1, 2, Color("0f172a"), false])
	pintar_partes(ci, pe, u, partes, direcao)


static func palco(ci: CanvasItem, r: Rect2, raio := 18) -> void:
	var parede := Color("b7cbe0")
	var piso := Color("e4d2ab")
	caixa(ci, r, parede, raio)
	for k in int(r.size.x / 24.0):
		ci.draw_rect(Rect2(r.position.x + 12 + k * 24, r.position.y + raio, 2, r.size.y * 0.62 - raio), Color(1, 1, 1, 0.12))
	var y_chao := r.position.y + r.size.y * 0.62
	var janela := Rect2(r.position.x + r.size.x * 0.62, r.position.y + r.size.y * 0.12, r.size.x * 0.26, r.size.y * 0.24)
	ci.draw_rect(janela.grow(3), Color("8aa3bb"))
	ci.draw_rect(janela, Color("dbeafe"))
	ci.draw_rect(Rect2(janela.position + Vector2(janela.size.x * 0.5 - 1, 0), Vector2(3, janela.size.y)), Color("8aa3bb"))
	ci.draw_rect(Rect2(janela.position + Vector2(0, janela.size.y * 0.5 - 1), Vector2(janela.size.x, 3)), Color("8aa3bb"))
	var chao := Rect2(r.position.x, y_chao, r.size.x, r.end.y - y_chao)
	caixa(ci, chao, piso, raio)
	ci.draw_rect(Rect2(chao.position, Vector2(chao.size.x, minf(raio, chao.size.y))), piso)
	var esquerda := r.position.x
	var direita := r.end.x
	for k in range(-12, 13):
		var x0 := r.position.x + r.size.x * 0.5 + k * 44.0
		for sentido in [1.0, -1.0]:
			var a := Vector2(x0, y_chao)
			var b := Vector2(x0 + sentido * 2.0 * chao.size.y, chao.end.y)
			if b.x > direita:
				b = a.lerp(b, (direita - a.x) / (b.x - a.x))
			if b.x < esquerda:
				b = a.lerp(b, (esquerda - a.x) / (b.x - a.x))
			if a.x < esquerda or a.x > direita:
				continue
			ci.draw_line(a, b, piso.darkened(0.12), 1.0)
	ci.draw_rect(Rect2(r.position.x, y_chao - 6, r.size.x, 6), Color("8aa3bb"))
