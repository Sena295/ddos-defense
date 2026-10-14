extends RefCounted

const Dados := preload("res://dados.gd")

const LARGURA := 41
const ALTURA := 72
const CX := 20
const BASE := 69
const LARGURA_PET := 25
const ALTURA_PET := 22
const CX_PET := 12
const BASE_PET := 20
const CONTORNO := Color("1a1b26")
const MAX_CACHE := 800
const PASSOS := [[1, 0, -1, 0, 0], [0, 1, 0, 0, -1], [-1, 0, 1, 0, 0], [0, 0, 0, 1, -1]]
const NEON := Color("22d3ee")

static var cache: Dictionary = {}


static func quadro_atual(tempo: float, andando: bool, semente: float) -> int:
	if andando:
		return 1 + int(tempo * 9.0) % 4
	if fmod(tempo + semente, 3.9) < 0.14:
		return 5
	return 0


static func desenhar(ci: CanvasItem, pe: Vector2, escala: float, aparencia: Dictionary, equipados: Dictionary, tempo: float, andando: bool, direcao: int) -> void:
	var k := maxi(1, roundi(escala))
	var quadro := quadro_atual(tempo, andando, pe.x * 0.013)
	var tex := textura(aparencia, equipados, direcao, quadro, k)
	ci.draw_texture(tex, (pe - Vector2((CX + 0.5) * k, BASE * k)).round())


static func desenhar_pet(ci: CanvasItem, pe: Vector2, tipo: String, tempo: float, direcao: int, escala: float) -> void:
	var k := maxi(1, roundi(escala))
	var quadro := int(tempo * 6.0) % 2
	var chave := "pet|%s|%d|%d|%d" % [tipo, direcao, quadro, k]
	var tex: ImageTexture = cache.get(chave)
	if tex == null:
		var img := gerar_pet(tipo, quadro)
		tex = finalizar(img, direcao, k)
		guardar(chave, tex)
	ci.draw_texture(tex, (pe - Vector2((CX_PET + 0.5) * k, BASE_PET * k)).round())


static func textura(aparencia: Dictionary, equipados: Dictionary, direcao: int, quadro: int, k: int) -> ImageTexture:
	var chave := "%s|%s|%d|%d|%d" % [str(aparencia), str(equipados), direcao, quadro, k]
	var tex: ImageTexture = cache.get(chave)
	if tex == null:
		tex = finalizar(gerar(aparencia, equipados, quadro), direcao, k)
		guardar(chave, tex)
	return tex


static func guardar(chave: String, tex: ImageTexture) -> void:
	if cache.size() > MAX_CACHE:
		cache.clear()
	cache[chave] = tex


static func finalizar(img: Image, direcao: int, k: int) -> ImageTexture:
	if direcao < 0:
		img.flip_x()
	if k > 1:
		img.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


static func pintar(img: Image, grupos: Array, cx: int) -> void:
	for g in grupos:
		var retangulos: Array = g[1]
		if g[0]:
			for r in retangulos:
				img.fill_rect(Rect2i(cx + int(r[0]) - 1, int(r[1]) - 1, int(r[2]) + 2, int(r[3]) + 2), CONTORNO)
		for r in retangulos:
			var cor: Color = r[4]
			if cor.a < 1.0 and cor.a > 0.0:
				for x in range(cx + int(r[0]), cx + int(r[0]) + int(r[2])):
					for y in range(int(r[1]), int(r[1]) + int(r[3])):
						if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
							img.set_pixel(x, y, img.get_pixel(x, y).blend(cor))
			else:
				img.fill_rect(Rect2i(cx + int(r[0]), int(r[1]), int(r[2]), int(r[3])), cor)


static func cor_de(lista: Array, indice) -> Color:
	return lista[clampi(int(indice), 0, lista.size() - 1)]


static func gerar(aparencia: Dictionary, equipados: Dictionary, quadro: int) -> Image:
	var img := Image.create(LARGURA, ALTURA, false, Image.FORMAT_RGBA8)
	var pele := cor_de(Dados.CORES_PELE, aparencia.get("pele", 0))
	var cab := cor_de(Dados.CORES_CABELO, aparencia.get("cor_cabelo", 0))
	var roupa := cor_de(Dados.CORES_ROUPA, aparencia.get("cor_roupa", 0))
	var cabelo := clampi(int(aparencia.get("cabelo", 0)), 0, Dados.ESTILOS_CABELO.size() - 1)
	var estilo := clampi(int(aparencia.get("roupa", 0)), 0, 2)
	var olhar := clampi(int(aparencia.get("olhos", 0)), 0, 2)
	var fem := int(aparencia.get("corpo", 0)) == 1
	var veste: String = equipados.get("roupa", "")
	var chapeu: String = equipados.get("chapeu", "")
	var rosto: String = equipados.get("acessorio", "")
	var capuz_alto := veste == "capuz_hacker"
	var df := 0
	var lf := 0
	var db := 0
	var lb := 0
	var b := 0
	if quadro >= 1 and quadro <= 4:
		var p: Array = PASSOS[quadro - 1]
		df = p[0]
		lf = p[1]
		db = p[2]
		lb = p[3]
		b = p[4]
	var pele_s := pele.darkened(0.16)
	var pele_l := pele.lightened(0.1)
	var cab_s := cab.darkened(0.25)
	var cab_l := cab.lightened(0.22)
	var calca := Color("35507e")
	var tenis := Color("eef0f3")
	var sola := Color("aab1bd")
	var listra := roupa
	var tronco := roupa
	var manga := roupa
	var punho := Color(0, 0, 0, 0)
	match veste:
		"terno":
			tronco = Color("262c38")
			manga = tronco
			calca = Color("262c38")
			tenis = Color("16181d")
			sola = Color("0b0c0f")
			listra = tenis
			punho = Color("f8fafc")
		"jaleco":
			tronco = Color("f3f5f8")
			manga = tronco
			calca = Color("4b5563")
		"capuz_hacker":
			tronco = Color("23262f")
			manga = tronco
			calca = Color("2a2f3a")
			listra = NEON
			punho = tronco.darkened(0.3)
		"capuz":
			punho = roupa.darkened(0.25)
		"xadrez":
			tronco = Color("b4232a")
			manga = tronco
			punho = Color("7f1d1d")
		"jaqueta":
			tronco = Color("454f33")
			manga = tronco
			punho = Color("2d3321")
		"camiseta_dev":
			tronco = Color("22262f")
			manga = tronco
			listra = Color("34d399")
		_:
			if estilo == 1:
				punho = Color("f8fafc")
	var tronco_s := tronco.darkened(0.2)
	var tronco_l := tronco.lightened(0.12)
	var braco_nu: bool = veste == "" and estilo == 2
	var manga_curta: bool = veste == "" and estilo == 0
	var g: Array = []
	g.append([false, [[-9, 68, 19, 2, Color(0, 0, 0, 0.22)], [-7, 70, 15, 1, Color(0, 0, 0, 0.14)]]])
	match cabelo:
		1:
			if not capuz_alto:
				g.append([true, [[-11, 13 + b, 7, 24, cab_s]]])
		3:
			g.append([true, [[-11, 5 + b, 21, 11, cab], [-12, 8 + b, 23, 6, cab], [-12, 14 + b, 6, 9, cab]]])
		4:
			if not capuz_alto and chapeu == "":
				g.append([true, [[-6, 3 + b, 6, 1, cab], [-7, 4 + b, 8, 5, cab], [-6, 9 + b, 6, 1, cab]]])
		7:
			g.append([true, [[-12, 13 + b, 4, 3, cab], [-13, 16 + b, 4, 12, cab_s], [-12, 28 + b, 3, 3, cab_s]]])
	var x_braco_tras := -8 if fem else -9
	var x_braco_frente := 6 if fem else 7
	var sb := -db
	var sf := -df
	var braco_tras: Array = []
	if braco_nu:
		braco_tras.append([x_braco_tras + sb, 34 + b, 2, 11, pele_s])
	elif manga_curta:
		braco_tras.append([x_braco_tras + sb, 34 + b, 2, 5, roupa.darkened(0.25)])
		braco_tras.append([x_braco_tras + sb, 39 + b, 2, 6, pele_s])
	else:
		braco_tras.append([x_braco_tras + sb, 34 + b, 2, 11, manga.darkened(0.25)])
	braco_tras.append([x_braco_tras + sb, 45 + b, 2, 2, pele_s])
	g.append([true, braco_tras])
	var x_tras := -4 if fem else -5
	var largura_perna := 3 if fem else 4
	g.append([true, [[x_tras + db, 48, largura_perna, 16 - lb, calca.darkened(0.18)]]])
	g.append([true, [[x_tras - 1 + db, 64 - lb, largura_perna + 2, 3, tenis.darkened(0.08)], [x_tras - 1 + db, 67 - lb, largura_perna + 2, 1, sola]]])
	g.append([true, [[1 + df, 48, largura_perna, 16 - lf, calca]]])
	var sapato_frente := [[df, 64 - lf, largura_perna + 2, 3, tenis], [df, 67 - lf, largura_perna + 2, 1, sola]]
	g.append([true, sapato_frente])
	g.append([false, [[1 + df, 65 - lf, 3, 1, listra], [1 + df, 49, 1, 14 - lf, calca.lightened(0.08)]]])
	var corpo: Array = []
	var detalhes: Array = []
	if fem:
		corpo = [[-4, 33 + b, 8, 1, tronco], [-6, 34 + b, 12, 7, tronco], [-5, 41 + b, 10, 4, tronco], [-6, 45 + b, 12, 4, tronco]]
		detalhes = [[4, 34 + b, 2, 7, tronco_s], [3, 41 + b, 2, 4, tronco_s], [4, 45 + b, 2, 4, tronco_s], [-6, 34 + b, 1, 5, tronco_l]]
	else:
		corpo = [[-5, 33 + b, 10, 1, tronco], [-7, 34 + b, 14, 14, tronco]]
		detalhes = [[5, 34 + b, 2, 14, tronco_s], [-7, 34 + b, 1, 8, tronco_l]]
		if veste != "jaleco" and veste != "terno":
			detalhes.append([-6, 47 + b, 12, 1, Color("3b2f2a")])
			detalhes.append([0, 47 + b, 2, 1, Color("c9a227")])
	if veste == "jaleco":
		corpo.append([-7, 34 + b, 14, 22, tronco])
		detalhes.append([5, 34 + b, 2, 22, tronco_s])
	g.append([true, corpo])
	match veste:
		"terno":
			detalhes += [[-2, 33 + b, 4, 3, Color("f8fafc")], [-1, 36 + b, 2, 2, Color("f8fafc")], [-1, 34 + b, 3, 1, Color("dc2626")], [0, 35 + b, 1, 7, Color("dc2626")], [-3, 34 + b, 1, 8, Color("3a4252")], [2, 34 + b, 1, 8, Color("3a4252")], [-4, 43 + b, 1, 1, Color("6b7280")]]
		"jaleco":
			detalhes += [[-2, 33 + b, 4, 6, roupa], [-3, 34 + b, 1, 7, Color("c3cad5")], [2, 34 + b, 1, 7, Color("c3cad5")], [3, 39 + b, 1, 3, Color("2563eb")], [-5, 44 + b, 3, 1, Color("c3cad5")], [0, 41 + b, 1, 15, Color("d7dce4")]]
		"capuz":
			detalhes += [[-4, 41 + b, 8, 3, tronco_s], [-2, 33 + b, 1, 4, Color("f8fafc")], [1, 33 + b, 1, 4, Color("f8fafc")], [-6, 46 + b, 12, 2, tronco_s]]
		"capuz_hacker":
			detalhes += [[-1, 37 + b, 3, 1, NEON], [-2, 38 + b, 5, 2, NEON], [-1, 38 + b, 1, 1, tronco], [1, 38 + b, 1, 1, tronco], [-1, 40 + b, 1, 1, NEON], [1, 40 + b, 1, 1, NEON], [-4, 43 + b, 8, 3, tronco_s], [-2, 33 + b, 1, 4, NEON], [1, 33 + b, 1, 4, NEON]]
		"xadrez":
			for x in [-6, -3, 3]:
				detalhes.append([x, 34 + b, 1, 14, Color("7f1d1d")])
			for y in [36, 40, 44]:
				detalhes.append([-7, y + b, 14, 1, Color("7f1d1d")])
			detalhes += [[-2, 34 + b, 4, 14, Color("2b303b")], [-1, 38 + b, 2, 1, Color("e5e7eb")]]
		"jaqueta":
			detalhes += [[-4, 33 + b, 8, 1, Color("f97316")], [0, 34 + b, 1, 12, Color("9ca3af")], [-7, 46 + b, 14, 2, Color("2d3321")], [-5, 37 + b, 3, 2, Color("2d3321")]]
		"camiseta_dev":
			detalhes += [[-2, 33 + b, 4, 1, pele_s], [-4, 40 + b, 1, 1, listra], [-3, 39 + b, 1, 1, listra], [-3, 41 + b, 1, 1, listra], [1, 38 + b, 1, 1, listra], [0, 39 + b, 1, 2, listra], [-1, 41 + b, 1, 1, listra], [3, 39 + b, 1, 1, listra], [4, 40 + b, 1, 1, listra], [3, 41 + b, 1, 1, listra]]
		_:
			match estilo:
				1:
					detalhes += [[-3, 33 + b, 2, 2, Color("f8fafc")], [1, 33 + b, 2, 2, Color("f8fafc")], [0, 37 + b, 1, 1, tronco_l], [0, 41 + b, 1, 1, tronco_l], [0, 45 + b, 1, 1, tronco_l]]
				2:
					var ombro := 6 if fem else 7
					detalhes += [[-ombro, 34 + b, 3, 2, pele], [ombro - 3, 34 + b, 3, 2, pele], [-1, 33 + b, 3, 2, pele_s]]
				_:
					detalhes += [[-2, 33 + b, 4, 1, pele_s]]
					if fem:
						detalhes.append([-1, 34 + b, 2, 1, pele_s])
	g.append([false, detalhes])
	if veste == "capuz":
		g.append([true, [[-6, 30 + b, 12, 3, tronco_s]]])
	g.append([false, [[-2, 31 + b, 4, 2, pele_s]]])
	g.append([true, [[-10, 19 + b, 2, 4, pele]]])
	g.append([false, [[-10, 20 + b, 1, 2, pele_s]]])
	g.append([true, [[-5, 11 + b, 10, 1, pele], [-7, 12 + b, 14, 1, pele], [-8, 13 + b, 16, 15, pele], [-7, 28 + b, 15, 1, pele], [-5, 29 + b, 12, 1, pele], [-3, 30 + b, 8, 1, pele], [8, 21 + b, 1, 2, pele]]])
	var rosto_det: Array = [[-6, 13 + b, 3, 1, pele_l], [5, 22 + b, 1, 1, pele_s], [-6, 28 + b, 3, 1, pele_s]]
	var olho := Color("1b1a26")
	var esclera := Color("ffffff")
	if quadro == 5:
		rosto_det += [[-4, 21 + b, 2, 1, olho], [2, 21 + b, 2, 1, olho]]
	elif olhar == 1:
		rosto_det += [[-5, 20 + b, 1, 1, olho], [-4, 19 + b, 1, 1, olho], [-3, 20 + b, 1, 1, olho], [1, 20 + b, 1, 1, olho], [2, 19 + b, 1, 1, olho], [3, 20 + b, 1, 1, olho]]
	else:
		var topo_olho := 20 if olhar == 2 else 19
		var altura_olho := 2 if olhar == 2 else 3
		rosto_det += [[-4, topo_olho + b, 2, altura_olho, esclera], [-3, 20 + b, 1, 2, olho], [2, topo_olho + b, 2, altura_olho, esclera], [3, 20 + b, 1, 2, olho]]
	var sobrancelha := cab_s if cabelo != 5 else pele.darkened(0.4)
	var y_sobr := 18 if olhar == 2 else 17
	rosto_det += [[-4, y_sobr + b, 3, 1, sobrancelha], [2, y_sobr + b, 3, 1, sobrancelha]]
	if fem:
		rosto_det += [[-5, 18 + b, 1, 1, olho], [4, 18 + b, 1, 1, olho], [-6, 23 + b, 2, 1, pele.lerp(Color("ff6b8a"), 0.35)], [4, 23 + b, 2, 1, pele.lerp(Color("ff6b8a"), 0.35)]]
	var boca := Color("c0405a") if fem else pele.darkened(0.45)
	if olhar == 1:
		rosto_det += [[0, 24 + b, 1, 1, boca], [1, 25 + b, 3, 1, boca], [4, 24 + b, 1, 1, boca]]
	elif olhar == 2:
		rosto_det += [[1, 25 + b, 3, 1, boca]]
	else:
		rosto_det += [[1, 25 + b, 3, 1, boca], [4, 24 + b, 1, 1, boca]]
	g.append([false, rosto_det])
	if capuz_alto:
		g.append([true, [[-2, 14 + b, 9, 2, cab]]])
		if cabelo == 1:
			g.append([true, [[6, 14 + b, 2, 12, cab]]])
	else:
		g += cabelo_frente(cabelo, cab, cab_s, cab_l, pele, b)
	if capuz_alto:
		g.append([true, [[-9, 6 + b, 16, 1, tronco], [-10, 7 + b, 18, 7, tronco], [-11, 14 + b, 6, 18, tronco], [7, 11 + b, 2, 6, tronco]]])
		g.append([false, [[-5, 14 + b, 12, 1, tronco.darkened(0.45)], [-10, 16 + b, 1, 12, NEON], [-8, 8 + b, 5, 1, tronco_l]]])
	else:
		match chapeu:
			"bone":
				g.append([true, [[-6, 6 + b, 12, 1, Color("2563eb")], [-8, 7 + b, 16, 1, Color("2563eb")], [-9, 8 + b, 18, 6, Color("2563eb")], [5, 13 + b, 8, 2, Color("1d4ed8")]]])
				g.append([false, [[-1, 5 + b, 2, 1, Color("1d4ed8")], [-2, 9 + b, 3, 2, Color("f8fafc")], [-9, 8 + b, 2, 6, Color("1e40af")]]])
			"bone_tras":
				g.append([true, [[-6, 6 + b, 12, 1, Color("111827")], [-8, 7 + b, 16, 1, Color("111827")], [-9, 8 + b, 18, 6, Color("111827")], [-15, 12 + b, 7, 2, Color("111827")]]])
				g.append([false, [[2, 9 + b, 3, 2, NEON], [-1, 5 + b, 2, 1, Color("374151")]]])
			"gorro":
				g.append([true, [[-2, 1 + b, 4, 3, Color("f8fafc")]]])
				g.append([true, [[-7, 4 + b, 14, 1, Color("dc2626")], [-9, 5 + b, 18, 7, Color("dc2626")], [-9, 12 + b, 18, 3, Color("fca5a5")]]])
				g.append([false, [[-6, 6 + b, 1, 5, Color("b91c1c")], [-2, 6 + b, 1, 5, Color("b91c1c")], [2, 6 + b, 1, 5, Color("b91c1c")], [6, 6 + b, 1, 5, Color("b91c1c")]]])
	match rosto:
		"oculos_hacker":
			g.append([false, [[-5, 19 + b, 11, 2, Color("111827")], [-8, 19 + b, 3, 1, Color("111827")], [-4, 19 + b, 1, 1, Color("22c55e")], [2, 19 + b, 1, 1, Color("22c55e")]]])
		"oculos_nerd":
			g.append([false, [[-5, 18 + b, 4, 4, Color("1f2937")], [1, 18 + b, 4, 4, Color("1f2937")], [-4, 19 + b, 2, 2, Color("dbeafe")], [2, 19 + b, 2, 2, Color("dbeafe")], [-3, 20 + b, 1, 1, olho], [3, 20 + b, 1, 1, olho], [-1, 19 + b, 2, 1, Color("1f2937")], [-8, 19 + b, 3, 1, Color("1f2937")]]])
		"headset":
			g.append([true, [[-9, 9 + b, 2, 9, Color("111827")], [-11, 17 + b, 4, 7, Color("1f2937")]]])
			g.append([false, [[-7, 26 + b, 8, 1, Color("111827")], [1, 26 + b, 1, 1, Color("ef4444")], [-10, 19 + b, 2, 3, Color("ef4444")]]])
		"fone_grande":
			g.append([true, [[-7, 6 + b, 14, 2, Color("e5e7eb")], [-9, 8 + b, 2, 8, Color("e5e7eb")], [-13, 15 + b, 6, 10, Color("e5e7eb")]]])
			g.append([false, [[-12, 17 + b, 4, 6, Color("a855f7")], [-6, 6 + b, 4, 1, Color("ffffff")]]])
		"mascara_led":
			g.append([true, [[-8, 16 + b, 16, 12, Color("15161c")], [-7, 28 + b, 15, 1, Color("15161c")], [-5, 29 + b, 12, 1, Color("15161c")], [-3, 30 + b, 8, 1, Color("15161c")], [8, 21 + b, 1, 2, Color("15161c")]]])
			var led := NEON
			g.append([false, [[-5, 18 + b, 1, 1, led], [-3, 18 + b, 1, 1, led], [-4, 19 + b, 1, 1, led], [-5, 20 + b, 1, 1, led], [-3, 20 + b, 1, 1, led], [1, 18 + b, 1, 1, led], [3, 18 + b, 1, 1, led], [2, 19 + b, 1, 1, led], [1, 20 + b, 1, 1, led], [3, 20 + b, 1, 1, led], [-3, 25 + b, 1, 1, led], [-1, 25 + b, 1, 1, led], [1, 25 + b, 1, 1, led], [3, 25 + b, 1, 1, led], [-2, 26 + b, 1, 1, led], [0, 26 + b, 1, 1, led], [2, 26 + b, 1, 1, led]]])
		"bandana":
			g.append([true, [[-8, 24 + b, 16, 4, Color("1f2937")], [-7, 28 + b, 15, 1, Color("1f2937")], [-5, 29 + b, 12, 1, Color("1f2937")], [-3, 30 + b, 8, 1, Color("1f2937")], [-12, 24 + b, 3, 2, Color("1f2937")]]])
			g.append([false, [[-5, 25 + b, 1, 1, Color("f8fafc")], [-1, 26 + b, 1, 1, Color("f8fafc")], [3, 25 + b, 1, 1, Color("f8fafc")], [5, 27 + b, 1, 1, Color("f8fafc")], [-3, 28 + b, 1, 1, Color("f8fafc")], [1, 29 + b, 1, 1, Color("f8fafc")]]])
	var braco_frente: Array = []
	if braco_nu:
		braco_frente.append([x_braco_frente + sf, 34 + b, 2, 11, pele])
	elif manga_curta:
		braco_frente.append([x_braco_frente + sf, 34 + b, 2, 5, roupa])
		braco_frente.append([x_braco_frente + sf, 39 + b, 2, 6, pele])
	else:
		braco_frente.append([x_braco_frente + sf, 34 + b, 2, 11, manga])
		if punho.a > 0.0:
			braco_frente.append([x_braco_frente + sf, 44 + b, 2, 1, punho])
	braco_frente.append([x_braco_frente + sf, 45 + b, 2, 2, pele])
	g.append([true, braco_frente])
	if veste == "xadrez":
		g.append([false, [[x_braco_frente + sf, 37 + b, 2, 1, Color("7f1d1d")], [x_braco_frente + sf, 41 + b, 2, 1, Color("7f1d1d")]]])
	elif veste == "jaqueta":
		g.append([false, [[x_braco_frente + sf, 36 + b, 1, 2, Color("f97316")]]])
	pintar(img, g, CX)
	return img


static func cabelo_frente(cabelo: int, cab: Color, cab_s: Color, cab_l: Color, pele: Color, b: int) -> Array:
	var g: Array = []
	var topo := [[-5, 9 + b, 10, 1, cab], [-7, 10 + b, 14, 1, cab], [-9, 11 + b, 18, 3, cab]]
	match cabelo:
		0:
			g.append([true, topo + [[-9, 14 + b, 4, 5, cab], [-2, 14 + b, 9, 2, cab]]])
			g.append([false, [[-4, 10 + b, 5, 1, cab_l], [-8, 13 + b, 2, 1, cab_l], [3, 15 + b, 4, 1, cab_s]]])
		1:
			g.append([true, topo + [[-9, 14 + b, 4, 8, cab], [-3, 14 + b, 10, 2, cab], [6, 14 + b, 2, 12, cab]]])
			g.append([false, [[-4, 10 + b, 5, 1, cab_l], [6, 16 + b, 1, 9, cab_s], [-8, 13 + b, 2, 1, cab_l]]])
		2:
			g.append([true, [[-1, 3 + b, 3, 1, cab], [-2, 4 + b, 4, 9, cab]]])
			g.append([false, [[-1, 5 + b, 1, 6, cab_l], [-8, 12 + b, 16, 3, pele.lerp(cab, 0.45)], [-9, 15 + b, 3, 4, pele.lerp(cab, 0.45)]]])
		3:
			g.append([true, [[-9, 8 + b, 18, 6, cab], [-6, 14 + b, 12, 1, cab]]])
			var pontos := [[-8, 9], [-4, 8], [0, 9], [4, 8], [7, 10], [-6, 12], [-1, 12], [3, 12], [-10, 11], [-11, 16], [-10, 20]]
			var textura: Array = []
			for pt in pontos:
				textura.append([pt[0], pt[1] + b, 1, 1, cab_l])
			g.append([false, textura])
		4:
			g.append([true, topo + [[-9, 14 + b, 4, 5, cab], [-3, 14 + b, 9, 2, cab]]])
			g.append([false, [[-6, 9 + b, 6, 1, Color("ec4899")], [-4, 10 + b, 5, 1, cab_l]]])
		5:
			g.append([false, [[-3, 12 + b, 3, 1, pele.lightened(0.28)]]])
		6:
			g.append([true, [[-5, 8 + b, 11, 1, cab], [-7, 9 + b, 15, 1, cab], [-9, 10 + b, 18, 4, cab], [-9, 14 + b, 4, 5, cab], [0, 14 + b, 8, 2, cab], [3, 16 + b, 4, 1, cab]]])
			g.append([false, [[-4, 9 + b, 1, 3, cab_s], [0, 9 + b, 4, 1, cab_l], [-8, 12 + b, 2, 1, cab_l]]])
		7:
			g.append([true, topo + [[-9, 14 + b, 4, 4, cab], [-3, 14 + b, 10, 2, cab]]])
			g.append([false, [[-11, 13 + b, 2, 2, Color("ec4899")], [-4, 10 + b, 5, 1, cab_l]]])
	return g


static func gerar_pet(tipo: String, quadro: int) -> Image:
	var img := Image.create(LARGURA_PET, ALTURA_PET, false, Image.FORMAT_RGBA8)
	var g: Array = []
	var p := quadro
	g.append([false, [[-6, 19, 13, 2, Color(0, 0, 0, 0.2)]]])
	if tipo == "pet_gato":
		var cor := Color("9aa3b2")
		g.append([true, [[-8, 7 - p, 2, 6, cor.darkened(0.15)]]])
		g.append([true, [[-6, 11, 10, 6, cor], [-5, 17, 2, 2, cor], [1, 17, 2, 2, cor]]])
		g.append([true, [[2, 4, 7, 7, cor], [2, 2, 2, 2, cor], [7, 2, 2, 2, cor]]])
		g.append([false, [[4, 7, 1, 1, Color("22c55e")], [7, 7, 1, 1, Color("22c55e")], [6, 9, 1, 1, Color("f9a8d4")], [-4, 12, 6, 1, cor.darkened(0.25)], [-4, 14, 6, 1, cor.darkened(0.25)]]])
	else:
		var cor2 := Color("22d3ee")
		g.append([false, [[0, 1 - p, 1, 3, Color("94a3b8")]]])
		g.append([true, [[-1, 0 - p, 3, 1, Color("ef4444")]]])
		g.append([true, [[-5, 4, 11, 8, cor2], [-4, 12, 9, 4, cor2.darkened(0.25)], [-4, 16, 3, 3, Color("334155")], [2, 16, 3, 3, Color("334155")]]])
		g.append([false, [[-3, 6, 7, 4, Color("0f172a")], [-2, 7, 1, 2, NEON], [2, 7, 1, 2, NEON]]])
	pintar(img, g, CX_PET)
	return img
