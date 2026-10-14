extends RefCounted
const Sprites := preload("res://sprites.gd")

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


static func avatar(ci: CanvasItem, pe: Vector2, escala: float, aparencia: Dictionary, equipados: Dictionary, tempo := 0.0, andando := false, direcao := 1) -> void:
	Sprites.desenhar(ci, pe, escala, aparencia, equipados, tempo, andando, direcao)


static func semicirculo(c: Vector2, r: float, de: float, ate: float) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	for k in 17:
		var a := lerpf(de, ate, k / 16.0)
		pontos.append(c + Vector2(cos(a), sin(a)) * r)
	return pontos


static func pet(ci: CanvasItem, pe: Vector2, tipo: String, tempo: float, direcao := 1, escala := 1.0) -> void:
	Sprites.desenhar_pet(ci, pe, tipo, tempo, direcao, escala)


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
