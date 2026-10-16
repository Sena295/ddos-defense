extends RefCounted

const REQ_POR_PACOTE := 800
const ESCALA_PACOTE := 0.5
const DENSIDADE := 2.0

const TIPOS_REQ := {
	"humano": {"nome": "Cliente real", "cor": Color("34d399"), "carga": 4.0},
	"volumetrico": {"nome": "Bot de inundação", "cor": Color("f87171"), "carga": 8.0},
	"l7": {"nome": "Bot imitador", "cor": Color("fb923c"), "carga": 7.0},
	"credencial": {"nome": "Ladrão de senhas", "cor": Color("e879f9"), "carga": 5.0},
	"scraper": {"nome": "Robô copiador", "cor": Color("facc15"), "carga": 6.0},
	"sqli": {"nome": "Hacker: SQL Injection", "cor": Color("22d3ee"), "carga": 3.0, "hacker": true},
	"xss": {"nome": "Hacker: XSS", "cor": Color("a3e635"), "carga": 3.0, "hacker": true},
	"exploit": {"nome": "Hacker: exploit zero-day", "cor": Color("f43f5e"), "carga": 3.0, "hacker": true},
	"ransomware": {"nome": "Hacker: ransomware", "cor": Color("a855f7"), "carga": 3.0, "hacker": true},
	"forca_bruta": {"nome": "Hacker: força bruta", "cor": Color("e2e8f0"), "carga": 3.0, "hacker": true},
}
const BOTS := ["volumetrico", "l7", "credencial", "scraper"]
const HACKERS := ["sqli", "xss", "exploit", "ransomware", "forca_bruta"]
const AMEACAS := ["volumetrico", "l7", "credencial", "scraper", "sqli", "xss", "exploit", "ransomware", "forca_bruta"]

const COMPONENTES := {
	"cdn": {"nome": "CDN", "categoria": "borda", "cor": Color("60a5fa"), "custo": 450, "nivel": 0, "resumo": "Responde clientes pelo cache e absorve inundações", "cache": [0.3, 0.45, 0.6], "bloqueio": {"volumetrico": 0.35}, "falso": 0.0},
	"antiddos": {"nome": "Anti-DDoS", "categoria": "borda", "cor": Color("38bdf8"), "custo": 550, "nivel": 0, "resumo": "Lava o tráfego e descarta inundações de bots", "bloqueio": {"volumetrico": 0.7, "l7": 0.1, "scraper": 0.1}, "falso": 0.005},
	"geo": {"nome": "Geo-bloqueio", "categoria": "borda", "cor": Color("94a3b8"), "custo": 150, "nivel": 0, "resumo": "Barato, mas barra clientes viajando", "bloqueio": {"volumetrico": 0.4, "l7": 0.2, "credencial": 0.2, "scraper": 0.2, "sqli": 0.25, "xss": 0.25, "exploit": 0.25, "ransomware": 0.25, "forca_bruta": 0.25}, "falso": 0.04},
	"waf": {"nome": "Firewall WAF", "categoria": "filtro", "cor": Color("f59e0b"), "custo": 400, "nivel": 0, "resumo": "Lê cada requisição: bots espertos, SQLi e XSS", "bloqueio": {"volumetrico": 0.2, "l7": 0.55, "credencial": 0.4, "scraper": 0.4, "sqli": 0.6, "xss": 0.6, "exploit": 0.2, "forca_bruta": 0.2}, "falso": 0.01},
	"ips": {"nome": "IDS/IPS", "categoria": "filtro", "cor": Color("fb7185"), "custo": 500, "nivel": 1, "resumo": "Reconhece assinaturas de ataque e corta na hora", "bloqueio": {"exploit": 0.65, "sqli": 0.4, "xss": 0.3, "forca_bruta": 0.35, "ransomware": 0.35, "l7": 0.2, "volumetrico": 0.1}, "falso": 0.008},
	"captcha": {"nome": "CAPTCHA", "categoria": "filtro", "cor": Color("22d3ee"), "custo": 250, "nivel": 0, "resumo": "Robô guardião destrói bots, mas irrita clientes", "bloqueio": {"volumetrico": 0.5, "l7": 0.7, "credencial": 0.65, "scraper": 0.6, "forca_bruta": 0.5}, "falso": 0.07},
	"rate": {"nome": "Rate Limit", "categoria": "filtro", "cor": Color("a78bfa"), "custo": 200, "nivel": 0, "resumo": "Limita pedidos por IP: copiadores e força bruta", "bloqueio": {"volumetrico": 0.45, "l7": 0.15, "credencial": 0.3, "scraper": 0.65, "forca_bruta": 0.5}, "falso": 0.005},
	"mfa": {"nome": "Login 2FA", "categoria": "filtro", "cor": Color("e879f9"), "custo": 300, "nivel": 0, "resumo": "Senha vazada ou adivinhada não abre conta", "bloqueio": {"credencial": 0.85, "forca_bruta": 0.85}, "falso": 0.02},
	"lb": {"nome": "Load Balancer", "categoria": "infra", "cor": Color("c084fc"), "custo": 300, "nivel": 0, "resumo": "Divide o tráfego entre as torres"},
	"fila": {"nome": "Fila", "categoria": "infra", "cor": Color("2dd4bf"), "custo": 250, "nivel": 0, "resumo": "Segura picos e libera no ritmo das torres", "capacidade": [20, 35, 55], "vazao": [8.0, 14.0, 22.0]},
	"redis": {"nome": "Cache Redis", "categoria": "infra", "cor": Color("f472b6"), "custo": 300, "nivel": 0, "resumo": "Respostas prontas na memória, perto das torres", "cache": [0.25, 0.35, 0.45]},
	"servidor": {"nome": "Torre", "categoria": "infra", "cor": Color("94a3b8"), "custo": 400, "nivel": 0, "resumo": "Processa as requisições e gera receita", "processamento": [6.0, 9.0, 13.0]},
	"autoscale": {"nome": "Auto Scaling", "categoria": "infra", "cor": Color("34d399"), "custo": 900, "nivel": 1, "resumo": "Liga máquinas extras sozinho no pico (paga pelo uso)", "processamento": [8.0, 10.0, 12.0], "escala_maxima": 2.5},
	"backup": {"nome": "Backup", "categoria": "seguranca", "cor": Color("4ade80"), "custo": 350, "nivel": 0, "passivo": true, "resumo": "Torre sequestrada volta em segundos", "efeito": [4.0, 3.0, 2.0]},
	"patch": {"nome": "Patches", "categoria": "seguranca", "cor": Color("fbbf24"), "custo": 300, "nivel": 0, "passivo": true, "resumo": "Torres atualizadas: exploits falham", "efeito": [0.75, 0.85, 0.92]},
	"cofre": {"nome": "Cofre de senhas", "categoria": "seguranca", "cor": Color("f472b6"), "custo": 250, "nivel": 0, "passivo": true, "resumo": "Senhas fortes e únicas: força bruta falha", "efeito": [0.8, 0.88, 0.95]},
	"treinamento": {"nome": "Treinamento", "categoria": "seguranca", "cor": Color("38bdf8"), "custo": 300, "nivel": 0, "passivo": true, "resumo": "Equipe que reconhece phishing", "efeito": [0.7, 0.85, 0.95]},
	"criptografia": {"nome": "Criptografia", "categoria": "seguranca", "cor": Color("2dd4bf"), "custo": 400, "nivel": 1, "passivo": true, "resumo": "Dado vazado vira lixo ilegível: multas menores", "efeito": [0.5, 0.35, 0.2]},
	"siem": {"nome": "SIEM / SOC", "categoria": "seguranca", "cor": Color("818cf8"), "custo": 700, "nivel": 2, "passivo": true, "resumo": "Monitora tudo: todos os filtros ficam mais fortes", "efeito": [0.1, 0.15, 0.2]},
	"edr": {"nome": "EDR", "categoria": "seguranca", "cor": Color("f87171"), "custo": 600, "nivel": 2, "passivo": true, "resumo": "Antivírus inteligente nas torres: para ransomware", "efeito": [0.6, 0.72, 0.85]},
	"honeypot": {"nome": "Honeypot", "categoria": "seguranca", "cor": Color("facc15"), "custo": 450, "nivel": 3, "passivo": true, "resumo": "Isca que prende hackers longe das torres", "efeito": [0.25, 0.35, 0.45]},
}
const CATEGORIAS := [
	{"id": "borda", "nome": "Borda"},
	{"id": "filtro", "nome": "Filtros"},
	{"id": "infra", "nome": "Infraestrutura"},
	{"id": "seguranca", "nome": "Segurança"},
]
const TERMINAIS := ["servidor", "autoscale"]
const FILTROS := ["cdn", "antiddos", "waf", "ips", "captcha", "rate", "mfa", "geo", "redis"]
const PASSIVOS := ["backup", "patch", "cofre", "treinamento", "criptografia", "siem", "edr", "honeypot"]
const MULT_NIVEL := [1.0, 1.25, 1.45]
const FALSO_NIVEL := [1.0, 0.75, 0.5]
const NIVEL_MAXIMO := 3

const NIVEIS := [
	{"xp": 0, "titulo": "Estagiário"},
	{"xp": 600, "titulo": "Dev Júnior"},
	{"xp": 1800, "titulo": "Dev Pleno"},
	{"xp": 4200, "titulo": "Dev Sênior"},
	{"xp": 8000, "titulo": "Especialista em Segurança"},
	{"xp": 14000, "titulo": "CISO"},
	{"xp": 22000, "titulo": "Lenda Cyber"},
]

const ICONES_LOGO := ["carrinho", "sacola", "aviao", "talher", "play", "banco", "moeda", "cartao", "cruz", "predio", "controle", "antena", "cerebro", "balao", "raio", "foguete", "escudo", "codigo"]
const FORMAS_LOGO := ["circulo", "quadrado", "hexagono", "losango", "escudo"]
const CORES_LOGO := [Color("facc15"), Color("fb923c"), Color("ef4444"), Color("ec4899"), Color("a78bfa"), Color("6366f1"), Color("3b82f6"), Color("06b6d4"), Color("10b981"), Color("84cc16"), Color("f8fafc"), Color("1e293b")]

const EMPRESAS := [
	{"id": "mercadonet", "nome": "MercadoNet", "sigla": "MN", "setor": "E-commerce", "cor": Color("facc15"), "logo": {"forma": "circulo", "cor": Color("facc15"), "cor2": Color("1e3a8a"), "icone": "carrinho"},
		"dificuldade": 1, "preco": 5000.0, "nivel": 0, "contrato": true, "receita": 8.0, "custo_queda": 60.0, "caixa": 1600.0,
		"descricao": "O maior marketplace do país. Milhões de produtos, vendedores e uma Black Friday que derruba os despreparados.",
		"mix": {"humano": 0.66, "volumetrico": 0.18, "l7": 0.06, "scraper": 0.1, "sqli": 0.02, "xss": 0.02},
		"eventos": ["black_friday", "promocao", "natal"], "ameacas": ["ddos_volumetrico", "scraping_massivo", "ataque_l7"], "hackers": ["onda_hackers", "phishing", "zero_day"],
		"sites": [{"nome": "Loja", "foco": ""}, {"nome": "Pagamentos", "foco": "credencial"}, {"nome": "Portal do Vendedor", "foco": "scraper"}]},
	{"id": "shoppa", "nome": "NexoMall", "sigla": "NM", "setor": "Marketplace mobile", "cor": Color("fb923c"), "logo": {"forma": "quadrado", "cor": Color("fb923c"), "cor2": Color("ffffff"), "icone": "sacola"},
		"dificuldade": 1, "preco": 5000.0, "nivel": 0, "contrato": true, "receita": 7.0, "custo_queda": 55.0, "caixa": 1600.0,
		"descricao": "Compras pelo app com promoções relâmpago a cada hora. O tráfego vem em ondas gigantes e sem aviso.",
		"mix": {"humano": 0.62, "volumetrico": 0.18, "l7": 0.12, "scraper": 0.08, "xss": 0.02},
		"eventos": ["festival_1111", "promocao_relampago", "black_friday"], "ameacas": ["ataque_l7", "ddos_volumetrico", "scraping_massivo"], "hackers": ["phishing", "onda_hackers", "zero_day"],
		"sites": [{"nome": "Vitrine", "foco": ""}, {"nome": "Checkout", "foco": "l7"}, {"nome": "Chat de lojas", "foco": "xss"}]},
	{"id": "voaja", "nome": "VoaJá", "sigla": "VJ", "setor": "Viagens", "cor": Color("38bdf8"), "logo": {"forma": "losango", "cor": Color("38bdf8"), "cor2": Color("0c4a6e"), "icone": "aviao"},
		"dificuldade": 2, "preco": 6250.0, "nivel": 0, "contrato": true, "receita": 10.0, "custo_queda": 70.0, "caixa": 1600.0,
		"descricao": "Passagens e hotéis. Concorrentes usam robôs para copiar seus preços o dia inteiro, e todo feriadão é um pico.",
		"mix": {"humano": 0.56, "volumetrico": 0.14, "l7": 0.05, "scraper": 0.25, "sqli": 0.02},
		"eventos": ["feriadao", "passagem_promo", "ferias"], "ameacas": ["scraping_massivo", "ddos_volumetrico", "ataque_l7"], "hackers": ["zero_day", "phishing", "onda_hackers"],
		"sites": [{"nome": "Busca de voos", "foco": "scraper"}, {"nome": "Reservas", "foco": "l7"}, {"nome": "Hotéis", "foco": "sqli"}]},
	{"id": "pixelforge", "nome": "PixelForge", "sigla": "PF", "setor": "Games online", "cor": Color("8b5cf6"), "logo": {"forma": "hexagono", "cor": Color("8b5cf6"), "cor2": Color("f5f3ff"), "icone": "controle"},
		"dificuldade": 2, "preco": 8750.0, "nivel": 1, "contrato": false, "receita": 6.0, "custo_queda": 65.0, "caixa": 1600.0,
		"descricao": "Estúdio de jogos online. Jogadores rivais alugam botnets para derrubar servidores no meio de torneios.",
		"mix": {"humano": 0.62, "volumetrico": 0.22, "l7": 0.06, "credencial": 0.06, "forca_bruta": 0.04},
		"eventos": ["lancamento_jogo", "torneio", "evento_ao_vivo"], "ameacas": ["ddos_volumetrico", "credential_stuffing", "ataque_l7"], "hackers": ["onda_hackers", "hacktivistas", "phishing"],
		"sites": [{"nome": "Servidores do jogo", "foco": "volumetrico"}, {"nome": "Loja do jogo", "foco": "credencial"}, {"nome": "Chat", "foco": "xss"}]},
	{"id": "rangoja", "nome": "RangoJá", "sigla": "RJ", "setor": "Delivery", "cor": Color("f43f5e"), "logo": {"forma": "circulo", "cor": Color("f43f5e"), "cor2": Color("ffffff"), "icone": "talher"},
		"dificuldade": 2, "preco": 7500.0, "nivel": 1, "contrato": false, "receita": 6.0, "custo_queda": 65.0, "caixa": 1600.0,
		"descricao": "App de delivery. Almoço e jantar de sexta são picos brutais, e restaurantes não perdoam pedido perdido.",
		"mix": {"humano": 0.64, "volumetrico": 0.16, "l7": 0.08, "scraper": 0.06, "credencial": 0.06, "sqli": 0.02},
		"eventos": ["almoco", "jantar_sexta", "final_campeonato"], "ameacas": ["ddos_volumetrico", "credential_stuffing", "ataque_l7"], "hackers": ["phishing", "onda_hackers", "zero_day"],
		"sites": [{"nome": "App de pedidos", "foco": ""}, {"nome": "Pagamentos", "foco": "credencial"}, {"nome": "Restaurantes", "foco": "l7"}]},
	{"id": "flixplay", "nome": "FlixPlay", "sigla": "FP", "setor": "Streaming", "cor": Color("ef4444"), "logo": {"forma": "quadrado", "cor": Color("ef4444"), "cor2": Color("111827"), "icone": "play"},
		"dificuldade": 2, "preco": 11250.0, "nivel": 2, "contrato": false, "receita": 5.0, "custo_queda": 75.0, "caixa": 1700.0,
		"descricao": "Streaming de séries e esportes ao vivo. Na final do campeonato, o país inteiro dá play no mesmo segundo.",
		"mix": {"humano": 0.72, "volumetrico": 0.14, "l7": 0.04, "scraper": 0.02, "credencial": 0.08},
		"eventos": ["final_campeonato", "lancamento_serie", "ferias"], "ameacas": ["ddos_volumetrico", "credential_stuffing", "ataque_l7"], "hackers": ["phishing", "zero_day", "onda_hackers"],
		"sites": [{"nome": "Player de vídeo", "foco": ""}, {"nome": "Contas", "foco": "credencial"}, {"nome": "Ao vivo", "foco": "volumetrico"}]},
	{"id": "socialhub", "nome": "SocialHub", "sigla": "SO", "setor": "Rede social", "cor": Color("3b82f6"), "logo": {"forma": "circulo", "cor": Color("3b82f6"), "cor2": Color("ffffff"), "icone": "balao"},
		"dificuldade": 2, "preco": 13750.0, "nivel": 2, "contrato": false, "receita": 5.0, "custo_queda": 70.0, "caixa": 1700.0,
		"descricao": "Rede social com milhões de perfis. Contas falsas, golpes por mensagem e scripts maliciosos nos posts.",
		"mix": {"humano": 0.62, "volumetrico": 0.14, "l7": 0.08, "credencial": 0.08, "xss": 0.06, "scraper": 0.02},
		"eventos": ["viral", "eleicao", "show_ao_vivo"], "ameacas": ["credential_stuffing", "ataque_l7", "ddos_volumetrico"], "hackers": ["hacktivistas", "phishing", "onda_hackers"],
		"sites": [{"nome": "Feed", "foco": ""}, {"nome": "Mensagens", "foco": "xss"}, {"nome": "Contas", "foco": "credencial"}]},
	{"id": "saudemais", "nome": "SaúdeMais", "sigla": "S+", "setor": "Saúde", "cor": Color("10b981"), "logo": {"forma": "circulo", "cor": Color("10b981"), "cor2": Color("ffffff"), "icone": "cruz"},
		"dificuldade": 3, "preco": 17500.0, "nivel": 3, "contrato": false, "receita": 9.0, "custo_queda": 100.0, "caixa": 1800.0,
		"descricao": "Rede de hospitais. Gangues de ransomware adoram hospitais porque cada minuto parado coloca vidas em risco.",
		"mix": {"humano": 0.6, "volumetrico": 0.1, "l7": 0.05, "credencial": 0.07, "ransomware": 0.08, "exploit": 0.06, "sqli": 0.04},
		"eventos": ["vacinacao", "plantao", "telemedicina"], "ameacas": ["credential_stuffing", "ddos_volumetrico", "ataque_l7"], "hackers": ["ransomware_gang", "phishing", "zero_day"],
		"sites": [{"nome": "Prontuário eletrônico", "foco": "ransomware"}, {"nome": "Agendamento", "foco": "l7"}, {"nome": "Telemedicina", "foco": "volumetrico"}]},
	{"id": "neuroai", "nome": "NeuroAI", "sigla": "NA", "setor": "Inteligência artificial", "cor": Color("ec4899"), "logo": {"forma": "hexagono", "cor": Color("ec4899"), "cor2": Color("ffffff"), "icone": "cerebro"},
		"dificuldade": 3, "preco": 20000.0, "nivel": 3, "contrato": false, "receita": 9.0, "custo_queda": 85.0, "caixa": 1800.0,
		"descricao": "Startup de IA com o modelo mais usado do momento. Todo mundo quer roubar os dados de treino e abusar da API.",
		"mix": {"humano": 0.58, "volumetrico": 0.1, "l7": 0.1, "scraper": 0.12, "sqli": 0.05, "xss": 0.05},
		"eventos": ["lancamento_modelo", "viral", "hackathon"], "ameacas": ["scraping_massivo", "ataque_l7", "ddos_volumetrico"], "hackers": ["onda_hackers", "zero_day", "phishing"],
		"sites": [{"nome": "Chat de IA", "foco": "l7"}, {"nome": "API", "foco": "scraper"}, {"nome": "Dados de treino", "foco": "sqli"}]},
	{"id": "telenova", "nome": "TeleNova", "sigla": "TN", "setor": "Telecom", "cor": Color("06b6d4"), "logo": {"forma": "circulo", "cor": Color("06b6d4"), "cor2": Color("083344"), "icone": "antena"},
		"dificuldade": 3, "preco": 25000.0, "nivel": 3, "contrato": false, "receita": 8.0, "custo_queda": 110.0, "caixa": 1900.0,
		"descricao": "Operadora de internet e celular. Tráfego gigante e equipamentos de rede que viram alvo de exploits.",
		"mix": {"humano": 0.65, "volumetrico": 0.2, "l7": 0.04, "exploit": 0.06, "forca_bruta": 0.05},
		"eventos": ["reveillon", "final_campeonato", "lancamento_celular"], "ameacas": ["ddos_volumetrico", "ataque_l7", "credential_stuffing"], "hackers": ["zero_day", "onda_hackers", "hacktivistas"],
		"sites": [{"nome": "Rede móvel", "foco": "volumetrico"}, {"nome": "App do cliente", "foco": "credencial"}, {"nome": "Fibra", "foco": "exploit"}]},
	{"id": "govdigital", "nome": "GovDigital", "sigla": "GD", "setor": "Governo", "cor": Color("2563eb"), "logo": {"forma": "escudo", "cor": Color("2563eb"), "cor2": Color("fde047"), "icone": "predio"},
		"dificuldade": 3, "preco": 22500.0, "nivel": 4, "contrato": false, "receita": 7.0, "custo_queda": 95.0, "caixa": 1800.0,
		"descricao": "Portal de serviços públicos. Hacktivistas querem derrubar, golpistas querem os dados de milhões de cidadãos.",
		"mix": {"humano": 0.55, "volumetrico": 0.2, "xss": 0.06, "exploit": 0.06, "sqli": 0.05, "credencial": 0.08},
		"eventos": ["imposto_renda", "eleicao", "beneficio"], "ameacas": ["ddos_volumetrico", "credential_stuffing", "ataque_l7"], "hackers": ["hacktivistas", "zero_day", "phishing"],
		"sites": [{"nome": "Portal do cidadão", "foco": ""}, {"nome": "Impostos", "foco": "credencial"}, {"nome": "Benefícios", "foco": "sqli"}]},
	{"id": "laranja", "nome": "Banco Laranja", "sigla": "BL", "setor": "Banco", "cor": Color("f97316"), "logo": {"forma": "quadrado", "cor": Color("f97316"), "cor2": Color("1e3a8a"), "icone": "banco"},
		"dificuldade": 3, "preco": 35000.0, "nivel": 4, "contrato": false, "receita": 11.0, "custo_queda": 110.0, "caixa": 1800.0,
		"descricao": "Um dos maiores bancos do país. Ladrões de senha tentam entrar 24 horas por dia e cada conta invadida vira multa e manchete.",
		"mix": {"humano": 0.6, "volumetrico": 0.14, "l7": 0.08, "scraper": 0.02, "credencial": 0.14, "forca_bruta": 0.03, "sqli": 0.02},
		"eventos": ["dia_pagamento", "pix_pico", "fraude"], "ameacas": ["credential_stuffing", "ddos_volumetrico", "ataque_l7"], "hackers": ["phishing", "onda_hackers", "zero_day"],
		"sites": [{"nome": "Internet Banking", "foco": "credencial"}, {"nome": "PIX", "foco": "l7"}, {"nome": "Cartões", "foco": "sqli"}]},
	{"id": "rubro", "nome": "Banco Rubro", "sigla": "BR", "setor": "Banco", "cor": Color("dc2626"), "logo": {"forma": "circulo", "cor": Color("dc2626"), "cor2": Color("ffffff"), "icone": "moeda"},
		"dificuldade": 3, "preco": 32500.0, "nivel": 4, "contrato": false, "receita": 10.0, "custo_queda": 100.0, "caixa": 1800.0,
		"descricao": "Banco internacional com agências no mundo todo. Ataques chegam de vários países e a fiscalização é rígida.",
		"mix": {"humano": 0.6, "volumetrico": 0.16, "l7": 0.08, "scraper": 0.02, "credencial": 0.13, "exploit": 0.03},
		"eventos": ["dia_pagamento", "fraude", "pix_pico"], "ameacas": ["ddos_volumetrico", "credential_stuffing", "ataque_l7"], "hackers": ["zero_day", "phishing", "ransomware_gang"],
		"sites": [{"nome": "App do banco", "foco": "credencial"}, {"nome": "Empresas", "foco": "l7"}, {"nome": "Investimentos", "foco": "forca_bruta"}]},
	{"id": "prisma", "nome": "Prisma Bank", "sigla": "PB", "setor": "Banco digital", "cor": Color("a78bfa"), "logo": {"forma": "hexagono", "cor": Color("a78bfa"), "cor2": Color("1e1b4b"), "icone": "cartao"},
		"dificuldade": 3, "preco": 30000.0, "nivel": 4, "contrato": false, "receita": 9.0, "custo_queda": 95.0, "caixa": 1800.0,
		"descricao": "Banco 100% digital com conta global e cripto. Clientes viajam o tempo todo, então bloquear países custa caro.",
		"mix": {"humano": 0.58, "volumetrico": 0.12, "l7": 0.12, "scraper": 0.02, "credencial": 0.14, "forca_bruta": 0.03},
		"eventos": ["viagem_internacional", "cripto_pico", "fraude"], "ameacas": ["credential_stuffing", "ataque_l7", "ddos_volumetrico"], "hackers": ["phishing", "onda_hackers", "zero_day"],
		"sites": [{"nome": "App", "foco": "credencial"}, {"nome": "Câmbio", "foco": "l7"}, {"nome": "Cripto", "foco": "forca_bruta"}]},
	{"id": "criptovault", "nome": "CriptoVault", "sigla": "CV", "setor": "Exchange de cripto", "cor": Color("eab308"), "logo": {"forma": "losango", "cor": Color("eab308"), "cor2": Color("0f172a"), "icone": "moeda"},
		"dificuldade": 3, "preco": 45000.0, "nivel": 5, "contrato": false, "receita": 12.0, "custo_queda": 130.0, "caixa": 2000.0,
		"descricao": "Corretora de criptomoedas. Os hackers mais habilidosos do mundo querem esvaziar as carteiras dos clientes.",
		"mix": {"humano": 0.5, "volumetrico": 0.12, "l7": 0.1, "credencial": 0.12, "forca_bruta": 0.08, "sqli": 0.05, "exploit": 0.03},
		"eventos": ["cripto_pico", "halving", "listagem"], "ameacas": ["credential_stuffing", "ataque_l7", "ddos_volumetrico"], "hackers": ["onda_hackers", "phishing", "zero_day"],
		"sites": [{"nome": "Exchange", "foco": ""}, {"nome": "Carteiras", "foco": "forca_bruta"}, {"nome": "API de trading", "foco": "exploit"}]},
]

const SETORES_STARTUP := [
	{"setor": "E-commerce", "base": "mercadonet"},
	{"setor": "Fintech", "base": "prisma"},
	{"setor": "Saúde", "base": "saudemais"},
	{"setor": "Games", "base": "pixelforge"},
	{"setor": "Inteligência artificial", "base": "neuroai"},
	{"setor": "Rede social", "base": "socialhub"},
]
const CUSTO_STARTUP := 8000.0
const DINHEIRO_INICIAL := 1000.0
const PARTICIPACAO := {"contrato": 0.1, "dono": 0.2, "propria": 0.3}

const EVENTOS := {
	"normal": {"nome": "Dia normal", "multiplicador": 1.0, "mix": {}, "especial": false,
		"explicacao": "Tráfego comum. Aproveite para montar a base: filtros na entrada e capacidade nas torres.", "dica": "Bons arquitetos constroem antes do pico, não durante."},
	"black_friday": {"nome": "Black Friday", "multiplicador": 2.6, "mix": {"humano": 0.25, "scraper": 0.05}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "O tráfego real multiplica e cada minuto vale uma fortuna. Cair hoje é manchete.", "dica": "CDN, cache e torres extras com Load Balancer."},
	"promocao": {"nome": "Promoção do dia", "multiplicador": 1.8, "mix": {"humano": 0.15, "l7": 0.05}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Uma oferta viralizou. Clientes reais e bots tentando comprar o estoque inteiro.", "dica": "WAF segura os bots compradores."},
	"natal": {"nome": "Semana do Natal", "multiplicador": 2.0, "mix": {"humano": 0.2}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Todo mundo comprando presente na última hora.", "dica": "Capacidade extra paga a si mesma hoje."},
	"festival_1111": {"nome": "Festival 11.11", "multiplicador": 2.8, "mix": {"humano": 0.25, "l7": 0.05}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "O maior dia de vendas do ano para marketplaces de app.", "dica": "Fila antes das torres transforma o pico em fluxo constante."},
	"promocao_relampago": {"nome": "Promoção relâmpago", "multiplicador": 2.2, "mix": {"humano": 0.2, "l7": 0.1}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Milhares de clientes clicam no mesmo segundo e bots tentam furar a fila.", "dica": "Fila e WAF."},
	"feriadao": {"nome": "Feriadão", "multiplicador": 2.0, "mix": {"humano": 0.2}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Todo mundo procurando passagem para o mesmo destino.", "dica": "Cache Redis responde buscas repetidas."},
	"passagem_promo": {"nome": "Passagem em promoção", "multiplicador": 1.8, "mix": {"scraper": 0.2, "humano": 0.1}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Seu preço baixo chamou a atenção dos robôs copiadores da concorrência.", "dica": "Rate Limit corta copiadores sem barrar clientes."},
	"ferias": {"nome": "Férias escolares", "multiplicador": 1.7, "mix": {"humano": 0.15}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Semanas de tráfego alto e constante.", "dica": "Auto Scaling acompanha a demanda sem você pagar o ano inteiro."},
	"almoco": {"nome": "Pico do almoço", "multiplicador": 2.0, "mix": {"humano": 0.2}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Meio-dia: o país inteiro com fome ao mesmo tempo.", "dica": "Mais torres e Load Balancer."},
	"jantar_sexta": {"nome": "Jantar de sexta", "multiplicador": 2.4, "mix": {"humano": 0.25}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "O pico mais forte da semana para delivery.", "dica": "Auto Scaling e fila."},
	"final_campeonato": {"nome": "Final do campeonato", "multiplicador": 3.0, "mix": {"humano": 0.3}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Todo mundo dá play no mesmo segundo para ver o jogo.", "dica": "CDN é obrigatória: vídeo deve sair do cache."},
	"lancamento_serie": {"nome": "Lançamento de série", "multiplicador": 2.2, "mix": {"humano": 0.2}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "A temporada mais esperada do ano estreou à meia-noite.", "dica": "CDN e cache."},
	"dia_pagamento": {"nome": "Dia do pagamento", "multiplicador": 2.2, "mix": {"humano": 0.2, "credencial": 0.05}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Salário caiu: todo mundo abre o app ao mesmo tempo, e golpistas também.", "dica": "Torres extras e 2FA."},
	"pix_pico": {"nome": "Pico do PIX", "multiplicador": 2.0, "mix": {"humano": 0.15}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Transferências instantâneas não podem esperar nem um segundo.", "dica": "Load Balancer com Health Check."},
	"fraude": {"nome": "Onda de fraudes", "multiplicador": 1.5, "mix": {"credencial": 0.35}, "especial": true, "licao": "vazamento",
		"explicacao": "Uma lista com milhões de senhas vazou na internet e criminosos estão testando todas no seu login.", "dica": "Login 2FA é a melhor defesa."},
	"viagem_internacional": {"nome": "Temporada de viagens", "multiplicador": 1.6, "mix": {"humano": 0.15}, "especial": true, "falso_geo": 4.0, "licao": "geo",
		"explicacao": "Seus clientes estão no exterior. Geo-bloqueio hoje barra os próprios clientes.", "dica": "Desligue ou evite o Geo-bloqueio nesta data."},
	"cripto_pico": {"nome": "Cripto disparou", "multiplicador": 2.0, "mix": {"humano": 0.1, "l7": 0.1}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "O preço subiu e todo mundo quer comprar agora, inclusive robôs de negociação.", "dica": "WAF e torres extras."},
	"lancamento_jogo": {"nome": "Lançamento do jogo", "multiplicador": 2.6, "mix": {"humano": 0.25}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Milhões de jogadores entram no mesmo minuto para jogar a nova temporada.", "dica": "Fila de entrada e muitas torres."},
	"torneio": {"nome": "Torneio mundial", "multiplicador": 2.0, "mix": {"volumetrico": 0.2, "humano": 0.1}, "especial": true, "licao": "antiddos",
		"explicacao": "Rivais contratam botnets para derrubar o servidor do time adversário.", "dica": "Anti-DDoS na entrada."},
	"evento_ao_vivo": {"nome": "Evento ao vivo no jogo", "multiplicador": 2.2, "mix": {"humano": 0.2, "xss": 0.04}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Um show dentro do jogo reúne todo mundo no mesmo servidor.", "dica": "Auto Scaling."},
	"vacinacao": {"nome": "Campanha de vacinação", "multiplicador": 2.2, "mix": {"humano": 0.25}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Todo mundo tentando agendar a vacina no primeiro minuto.", "dica": "Fila para o agendamento."},
	"plantao": {"nome": "Plantão lotado", "multiplicador": 1.8, "mix": {"humano": 0.15, "ransomware": 0.04}, "especial": true, "licao": "backup",
		"explicacao": "Hospital cheio e criminosos sabem que agora a pressão para pagar resgate é máxima.", "dica": "Backup e EDR."},
	"telemedicina": {"nome": "Pico de telemedicina", "multiplicador": 2.0, "mix": {"humano": 0.2}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Consultas por vídeo explodiram durante um surto de gripe.", "dica": "Torres extras."},
	"imposto_renda": {"nome": "Prazo do imposto", "multiplicador": 2.4, "mix": {"humano": 0.25, "credencial": 0.05}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Último dia para entregar a declaração: todo mundo deixou para a última hora.", "dica": "Fila e muitas torres."},
	"eleicao": {"nome": "Dia de eleição", "multiplicador": 2.0, "mix": {"volumetrico": 0.15, "xss": 0.06, "humano": 0.1}, "especial": true, "licao": "antiddos",
		"explicacao": "Hacktivistas querem derrubar o sistema para causar desconfiança.", "dica": "Anti-DDoS e WAF."},
	"beneficio": {"nome": "Liberação de benefício", "multiplicador": 2.2, "mix": {"humano": 0.2, "sqli": 0.04}, "especial": true, "licao": "sqli",
		"explicacao": "Milhões consultando o benefício e golpistas tentando extrair dados do banco.", "dica": "WAF e código seguro."},
	"reveillon": {"nome": "Réveillon", "multiplicador": 2.8, "mix": {"humano": 0.3}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Meia-noite: todo mundo manda mensagem ao mesmo tempo.", "dica": "Capacidade máxima."},
	"lancamento_celular": {"nome": "Lançamento de celular", "multiplicador": 2.0, "mix": {"humano": 0.2}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Todo mundo quer ativar o celular novo no mesmo dia.", "dica": "Load Balancer e torres."},
	"halving": {"nome": "Halving do Bitcoin", "multiplicador": 2.4, "mix": {"humano": 0.15, "forca_bruta": 0.05}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Evento histórico: volume de negociação recorde e hackers de olho nas carteiras.", "dica": "Cofre de senhas e 2FA."},
	"listagem": {"nome": "Listagem de moeda nova", "multiplicador": 2.0, "mix": {"humano": 0.15, "l7": 0.1}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Uma moeda nova estreou e robôs de negociação disputam cada ordem.", "dica": "WAF e Rate Limit."},
	"lancamento_modelo": {"nome": "Lançamento do modelo", "multiplicador": 2.4, "mix": {"humano": 0.2, "scraper": 0.08}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "A nova versão da IA saiu e todo mundo quer testar, inclusive concorrentes copiando respostas.", "dica": "Rate Limit e torres."},
	"viral": {"nome": "Post viral", "multiplicador": 2.2, "mix": {"humano": 0.2, "xss": 0.03}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Algo viralizou e o país inteiro está compartilhando ao mesmo tempo.", "dica": "CDN e cache."},
	"hackathon": {"nome": "Hackathon público", "multiplicador": 1.6, "mix": {"sqli": 0.08, "xss": 0.08}, "especial": true, "ataque": true, "licao": "codigo_seguro",
		"explicacao": "Milhares de programadores testando sua API. Nem todos têm boas intenções.", "dica": "WAF, IDS/IPS e código seguro."},
	"show_ao_vivo": {"nome": "Show ao vivo", "multiplicador": 2.4, "mix": {"humano": 0.25}, "especial": true, "licao": "pico_sazonal",
		"explicacao": "Uma transmissão ao vivo com milhões de comentários por minuto.", "dica": "Fila e Auto Scaling."},
	"ddos_volumetrico": {"nome": "Ataque DDoS volumétrico", "multiplicador": 1.9, "mix": {"volumetrico": 0.4}, "especial": true, "ataque": true, "licao": "antiddos",
		"explicacao": "Uma botnet com milhares de dispositivos invadidos está inundando seu site para derrubá-lo pela força bruta.", "dica": "Anti-DDoS e CDN na entrada."},
	"ataque_l7": {"nome": "Ataque de camada 7", "multiplicador": 1.6, "mix": {"l7": 0.35}, "especial": true, "ataque": true, "licao": "waf",
		"explicacao": "Bots que imitam navegadores reais pedem páginas pesadas. Filtros simples não percebem.", "dica": "WAF e CAPTCHA."},
	"credential_stuffing": {"nome": "Credential stuffing", "multiplicador": 1.5, "mix": {"credencial": 0.35}, "especial": true, "ataque": true, "licao": "mfa",
		"explicacao": "Robôs testam senhas vazadas de outros sites no seu login, milhares por minuto.", "dica": "Login 2FA, WAF e CAPTCHA."},
	"scraping_massivo": {"nome": "Scraping em massa", "multiplicador": 1.5, "mix": {"scraper": 0.35}, "especial": true, "ataque": true, "licao": "rate",
		"explicacao": "Robôs copiam todo o seu catálogo e preços para a concorrência, pesando nas torres.", "dica": "Rate Limit e WAF."},
	"onda_hackers": {"nome": "Onda de hackers", "multiplicador": 1.5, "mix": {"sqli": 0.06, "xss": 0.05, "exploit": 0.05, "ransomware": 0.03, "forca_bruta": 0.05}, "especial": true, "ataque": true, "hacker": true, "licao": "ips",
		"explicacao": "Um grupo de hackers escolheu sua empresa como alvo e vai testar SQL Injection, XSS, exploits, ransomware e força bruta.", "dica": "WAF, IDS/IPS, Patches, EDR e Backup."},
	"ransomware_gang": {"nome": "Gangue de ransomware", "multiplicador": 1.3, "mix": {"ransomware": 0.1, "exploit": 0.06}, "especial": true, "ataque": true, "hacker": true, "licao": "ransomware",
		"explicacao": "Criminosos tentam sequestrar suas torres e cobrar resgate em cripto para devolver os dados.", "dica": "EDR, Patches e principalmente Backup."},
	"phishing": {"nome": "Campanha de phishing", "multiplicador": 1.1, "mix": {"credencial": 0.08}, "especial": true, "ataque": true, "hacker": true, "phishing": true, "licao": "phishing",
		"explicacao": "E-mails falsos estão chegando para seus funcionários. Basta um clique para os criminosos entrarem pela porta da frente.", "dica": "Treinamento da equipe e Backup."},
	"zero_day": {"nome": "Zero-day divulgado", "multiplicador": 1.3, "mix": {"exploit": 0.16}, "especial": true, "ataque": true, "hacker": true, "licao": "exploit",
		"explicacao": "Uma falha grave no software das torres foi divulgada hoje e hackers do mundo inteiro estão explorando.", "dica": "Patches e IDS/IPS."},
	"hacktivistas": {"nome": "Ataque hacktivista", "multiplicador": 1.8, "mix": {"volumetrico": 0.3, "xss": 0.07}, "especial": true, "ataque": true, "hacker": true, "licao": "xss",
		"explicacao": "Um grupo com motivação política quer tirar seu site do ar e pichar suas páginas com XSS.", "dica": "Anti-DDoS e WAF."},
}

const ITENS := {
	"oculos_hacker": {"nome": "Óculos hacker", "tipo": "acessorio", "preco": 300.0, "descricao": "Lentes escuras com reflexo de terminal."},
	"headset": {"nome": "Headset gamer", "tipo": "acessorio", "preco": 450.0, "descricao": "Para atender o plantão com estilo."},
	"bone": {"nome": "Boné dev", "tipo": "chapeu", "preco": 250.0, "descricao": "Clássico de hackathon."},
	"gorro": {"nome": "Gorro", "tipo": "chapeu", "preco": 250.0, "descricao": "Data center é sempre gelado."},
	"bone_tras": {"nome": "Boné para trás", "tipo": "chapeu", "preco": 350.0, "descricao": "Aba virada e logo neon. Modo foco ativado."},
	"oculos_nerd": {"nome": "Óculos de dev", "tipo": "acessorio", "preco": 250.0, "descricao": "Armação redonda para revisar pull request."},
	"fone_grande": {"nome": "Fone over-ear", "tipo": "acessorio", "preco": 550.0, "descricao": "Cancelamento de ruído para codar em paz."},
	"bandana": {"nome": "Bandana", "tipo": "acessorio", "preco": 400.0, "descricao": "Estilo de quem vive no Beco Hacker."},
	"mascara_led": {"nome": "Máscara LED", "tipo": "acessorio", "preco": 1800.0, "descricao": "Máscara com painel de LED. Ícone dos hackers éticos da cidade."},
	"camiseta_dev": {"nome": "Camiseta </>", "tipo": "roupa", "preco": 350.0, "descricao": "A camiseta oficial de todo dev."},
	"xadrez": {"nome": "Camisa xadrez", "tipo": "roupa", "preco": 450.0, "descricao": "Flanela aberta por cima da camiseta. Clássico do escritório tech."},
	"jaqueta": {"nome": "Jaqueta bomber", "tipo": "roupa", "preco": 900.0, "descricao": "Verde-oliva com forro laranja."},
	"capuz_hacker": {"nome": "Moletom neon", "tipo": "roupa", "preco": 1600.0, "descricao": "Capuz levantado e caveira neon. Estilo hacker de rua."},
	"capuz": {"nome": "Moletom com capuz", "tipo": "roupa", "preco": 600.0, "descricao": "O uniforme oficial de quem defende a rede."},
	"jaleco": {"nome": "Jaleco de laboratório", "tipo": "roupa", "preco": 800.0, "descricao": "Para pesquisadores de malware."},
	"terno": {"nome": "Terno de CEO", "tipo": "roupa", "preco": 1500.0, "descricao": "Para a reunião com o conselho."},
	"pet_gato": {"nome": "Gato hacker", "tipo": "pet", "preco": 2000.0, "descricao": "Anda atrás de você pela cidade."},
	"pet_robo": {"nome": "Robô de estimação", "tipo": "pet", "preco": 2500.0, "descricao": "Um mini robô guardião do CAPTCHA."},
	"seguro": {"nome": "Seguro cibernético", "tipo": "reforco", "preco": 900.0, "descricao": "Durante um dia, multas e resgates não saem do caixa."},
	"plantao": {"nome": "Equipe de plantão", "tipo": "reforco", "preco": 500.0, "descricao": "Durante um dia, torres caídas voltam na metade do tempo."},
	"pentest": {"nome": "Pentest", "tipo": "reforco", "preco": 700.0, "descricao": "Durante um dia, todos os filtros ficam 15% mais fortes contra hackers."},
	"consultoria": {"nome": "Consultoria", "tipo": "reforco", "preco": 600.0, "descricao": "Um especialista melhora de graça o componente de menor nível."},
}

const MISSOES := [
	{"id": "m_cidade", "titulo": "Bem-vindo à Cidade Tech", "descricao": "Ande até a Central de Missões (prédio amarelo, a oeste da sua sede).", "contador": "visitou_missoes", "alvo": 1, "dinheiro": 200.0, "xp": 50},
	{"id": "m_contrato", "titulo": "Seu primeiro contrato", "descricao": "Entre no prédio da MercadoNet, NexoMall ou VoaJá e complete 1 dia de operação.", "contador": "dias_operados", "alvo": 1, "dinheiro": 300.0, "xp": 100, "requer": "m_cidade"},
	{"id": "m_waf", "titulo": "Defesa básica", "descricao": "Instale um Firewall WAF em qualquer sistema.", "contador": "componente_waf", "alvo": 1, "dinheiro": 200.0, "xp": 80, "requer": "m_contrato"},
	{"id": "m_licoes", "titulo": "Estudar faz parte", "descricao": "Leia 3 lições na Academia Cyber ou no botão Por quê?.", "contador": "licoes_lidas", "alvo": 3, "dinheiro": 200.0, "xp": 80, "requer": "m_contrato"},
	{"id": "m_lab", "titulo": "Primeiro bug encontrado", "descricao": "Resolva 1 desafio no Beco Hacker (laboratório de código).", "contador": "desafios_resolvidos", "alvo": 1, "dinheiro": 300.0, "xp": 120, "requer": "m_waf"},
	{"id": "m_escala", "titulo": "Escala horizontal", "descricao": "Monte um Load Balancer ligado a 2 torres.", "contador": "escala_horizontal", "alvo": 1, "dinheiro": 300.0, "xp": 100, "requer": "m_waf"},
	{"id": "m_loja", "titulo": "Visual de respeito", "descricao": "Compre qualquer item na Loja Tech.", "contador": "itens_comprados", "alvo": 1, "dinheiro": 150.0, "xp": 60, "requer": "m_lab"},
	{"id": "m_backup", "titulo": "Plano B", "descricao": "Instale um Backup (aba Segurança da paleta).", "contador": "componente_backup", "alvo": 1, "dinheiro": 250.0, "xp": 100, "requer": "m_escala"},
	{"id": "m_onda", "titulo": "Sobrevivente", "descricao": "Complete um dia de ataque de hackers.", "contador": "ondas_hacker", "alvo": 1, "dinheiro": 600.0, "xp": 200, "requer": "m_backup"},
	{"id": "m_incidente", "titulo": "Resposta a incidentes", "descricao": "Escolha a resposta certa em um incidente de segurança.", "contador": "incidentes_certos", "alvo": 1, "dinheiro": 400.0, "xp": 150, "requer": "m_backup"},
	{"id": "m_compra", "titulo": "Investidor", "descricao": "Compre sua primeira empresa (no prédio dela ou na Bolsa Tech).", "contador": "empresas_compradas", "alvo": 1, "dinheiro": 500.0, "xp": 200, "requer": "m_onda"},
	{"id": "m_startup", "titulo": "Fundador", "descricao": "Compre um terreno e funde sua startup nele.", "contador": "empresa_criada", "alvo": 1, "dinheiro": 800.0, "xp": 300, "requer": "m_compra"},
	{"id": "m_cacador", "titulo": "Caçador de bugs", "descricao": "Resolva 6 desafios de código.", "contador": "desafios_resolvidos", "alvo": 6, "dinheiro": 900.0, "xp": 350, "requer": "m_lab"},
	{"id": "m_uptime", "titulo": "Uptime de elite", "descricao": "Termine 3 dias sem nenhuma torre cair.", "contador": "dias_sem_queda", "alvo": 3, "dinheiro": 700.0, "xp": 250, "requer": "m_escala"},
	{"id": "m_muralha", "titulo": "Muralha", "descricao": "Bloqueie 500 ataques de hackers.", "contador": "hackers_bloqueados", "alvo": 500, "dinheiro": 1200.0, "xp": 400, "requer": "m_onda"},
	{"id": "m_magnata", "titulo": "Magnata", "descricao": "Seja dono de 3 empresas.", "contador": "empresas_proprias", "alvo": 3, "dinheiro": 3000.0, "xp": 600, "requer": "m_compra"},
	{"id": "m_terreno", "titulo": "Dono de terra", "descricao": "Compre um terreno no Bairro Sul ou no Distrito Neon (veja a Imobiliária).", "contador": "terrenos_comprados", "alvo": 1, "dinheiro": 400.0, "xp": 150, "requer": "m_onda"},
	{"id": "m_pentest", "titulo": "Hacker do bem", "descricao": "Faça 3 pentests autorizados em câmeras ou caixas eletrônicos da cidade.", "contador": "pentests", "alvo": 3, "dinheiro": 600.0, "xp": 220, "requer": "m_lab"},
	{"id": "m_construtor", "titulo": "Construtor", "descricao": "Construa 2 imóveis nos seus terrenos.", "contador": "construcoes", "alvo": 2, "dinheiro": 900.0, "xp": 300, "requer": "m_terreno"},
	{"id": "m_lenda", "titulo": "Lenda", "descricao": "Chegue ao dia 15 em qualquer empresa.", "contador": "maior_dia", "alvo": 15, "dinheiro": 5000.0, "xp": 1000, "requer": "m_uptime"},
]

const DIARIAS := [
	{"id": "d_dias", "titulo": "Plantão do dia", "descricao": "Complete 2 dias de operação.", "contador": "dias_operados", "alvo": 2, "dinheiro": 250.0, "xp": 80},
	{"id": "d_hackers", "titulo": "Caça aos hackers", "descricao": "Bloqueie 120 ataques de hackers.", "contador": "hackers_bloqueados", "alvo": 120, "dinheiro": 300.0, "xp": 100},
	{"id": "d_bots", "titulo": "Exterminador de bots", "descricao": "Bloqueie 300 bots.", "contador": "bots_bloqueados", "alvo": 300, "dinheiro": 250.0, "xp": 80},
	{"id": "d_lab", "titulo": "Desafio do dia", "descricao": "Resolva 1 desafio de código.", "contador": "desafios_resolvidos", "alvo": 1, "dinheiro": 300.0, "xp": 120},
	{"id": "d_uptime", "titulo": "Zero quedas", "descricao": "Termine 1 dia sem nenhuma torre cair.", "contador": "dias_sem_queda", "alvo": 1, "dinheiro": 300.0, "xp": 100},
	{"id": "d_quiz", "titulo": "Conselho satisfeito", "descricao": "Acerte 1 quiz do conselho.", "contador": "quiz_acertos", "alvo": 1, "dinheiro": 200.0, "xp": 80},
	{"id": "d_construir", "titulo": "Obras", "descricao": "Instale 4 componentes.", "contador": "componentes_instalados", "alvo": 4, "dinheiro": 200.0, "xp": 70},
	{"id": "d_pentest", "titulo": "Pentest do dia", "descricao": "Faça 1 pentest autorizado na cidade.", "contador": "pentests", "alvo": 1, "dinheiro": 300.0, "xp": 100},
	{"id": "d_ctf", "titulo": "Arena CTF", "descricao": "Acerte 2 perguntas na Arena CTF.", "contador": "ctf_acertos", "alvo": 2, "dinheiro": 250.0, "xp": 90},
	{"id": "d_clientes", "titulo": "Cliente feliz", "descricao": "Atenda 1.000 clientes.", "contador": "clientes_atendidos", "alvo": 1000, "dinheiro": 300.0, "xp": 90},
]


const CONSTRUCOES := {
	"cafe": {"nome": "Café Dev", "custo": 2500.0, "renda": 120.0, "xp": 0, "nivel": 0, "altura": 72.0, "cor": Color("f97316"), "parede": Color("f6e7d5"), "descricao": "Café e tomada para todo mundo. Rende um pouco todo dia."},
	"loja_hardware": {"nome": "Loja de Hardware", "custo": 4000.0, "renda": 200.0, "xp": 0, "nivel": 1, "altura": 84.0, "cor": Color("84cc16"), "parede": Color("eef6dc"), "descricao": "Placas de vídeo, teclados mecânicos e cabos. Clientes fiéis."},
	"coworking": {"nome": "Coworking", "custo": 5500.0, "renda": 280.0, "xp": 0, "nivel": 1, "altura": 116.0, "cor": Color("0ea5e9"), "parede": Color("e2ebf3"), "descricao": "Mesas alugadas para devs e startups. Renda estável."},
	"escola": {"nome": "Escola de Programação", "custo": 7000.0, "renda": 260.0, "xp": 40, "nivel": 2, "altura": 104.0, "cor": Color("a855f7"), "parede": Color("efe7fb"), "descricao": "Forma novos talentos. Rende dinheiro e experiência todo dia."},
	"datacenter_p": {"nome": "Mini Data Center", "custo": 9500.0, "renda": 520.0, "xp": 0, "nivel": 2, "altura": 90.0, "cor": Color("38bdf8"), "parede": Color("cfd8e3"), "descricao": "Aluga servidores para outras empresas. A melhor renda da cidade."},
}

const CARREIRAS := {
	"operador": {"nome": "Operador de sistemas", "descricao": "Mantenha sites no ar. Cada 3 dias de operação elevam sua especialização.", "bonus": "Até 15% a mais sobre sua parte no lucro."},
	"hacker": {"nome": "Hacker ético", "descricao": "Teste sistemas da cidade com permissão. Cada 3 pentests elevam sua especialização.", "bonus": "Até 30% a mais nas recompensas de pentest."},
	"empreendedor": {"nome": "Empreendedor", "descricao": "Compre terrenos e construa negócios. Cada 2 construções elevam sua especialização.", "bonus": "Até 30% a mais na renda dos imóveis."},
}

const CURSOS_CAFE := [
	{"id": "fundamentos_rede", "nome": "Como uma requisição chega ao site", "resumo": "CDN, borda, balanceador e servidor explicados no caminho do cliente.", "licao": "cdn", "pergunta": "Por que distribuir requisições entre vários servidores?", "opcoes": ["Para esconder falhas", "Para dividir a carga e manter o serviço disponível", "Para desligar o firewall"], "correta": 1, "explicacao": "O balanceador reparte o tráfego entre as máquinas. Se uma falha, as outras podem continuar atendendo.", "xp": 60},
	{"id": "defesa_em_camadas", "nome": "Defesa em camadas", "resumo": "Veja por que WAF, rate limit e backup resolvem problemas diferentes.", "licao": "waf", "pergunta": "Um WAF substitui um backup?", "opcoes": ["Sim, bloqueia qualquer problema", "Sim, se houver CAPTCHA", "Não, prevenção e recuperação têm funções diferentes"], "correta": 2, "explicacao": "O WAF tenta impedir pedidos maliciosos. O backup recupera dados quando a prevenção não bastou ou houve uma falha.", "xp": 80},
	{"id": "codigo_seguro", "nome": "Código seguro no dia a dia", "resumo": "Validação, atualização e testes com autorização.", "licao": "sqli", "pergunta": "Qual prática reduz o risco de injeção em consultas?", "opcoes": ["Concatenar a entrada do usuário", "Usar consultas parametrizadas", "Esconder a página de login"], "correta": 1, "explicacao": "Consultas parametrizadas separam dados de instruções. A entrada do usuário não vira parte do comando.", "xp": 100},
]

const LOTES := [
	{"id": "lote_centro", "nome": "Terreno do Centro", "area": Rect2i(38, 16, 5, 4), "preco": 4000.0, "bairro": "Centro"},
	{"id": "lote_s1", "nome": "Terreno S1", "area": Rect2i(1, 32, 4, 4), "preco": 2500.0, "bairro": "Bairro Sul"},
	{"id": "lote_s2", "nome": "Terreno S2", "area": Rect2i(6, 32, 4, 4), "preco": 2500.0, "bairro": "Bairro Sul"},
	{"id": "lote_s3", "nome": "Terreno S3", "area": Rect2i(1, 38, 4, 4), "preco": 2200.0, "bairro": "Bairro Sul"},
	{"id": "lote_s4", "nome": "Terreno S4", "area": Rect2i(6, 38, 4, 4), "preco": 2200.0, "bairro": "Bairro Sul"},
	{"id": "lote_s5", "nome": "Terreno S5", "area": Rect2i(16, 32, 4, 4), "preco": 3500.0, "bairro": "Bairro Sul"},
	{"id": "lote_s6", "nome": "Terreno S6", "area": Rect2i(21, 32, 4, 4), "preco": 3500.0, "bairro": "Bairro Sul"},
	{"id": "lote_s7", "nome": "Terreno S7", "area": Rect2i(16, 38, 4, 4), "preco": 3200.0, "bairro": "Bairro Sul"},
	{"id": "lote_s8", "nome": "Terreno S8", "area": Rect2i(21, 38, 4, 4), "preco": 3200.0, "bairro": "Bairro Sul"},
	{"id": "lote_s9", "nome": "Terreno S9", "area": Rect2i(32, 32, 4, 4), "preco": 3000.0, "bairro": "Bairro Sul"},
	{"id": "lote_s10", "nome": "Terreno S10", "area": Rect2i(37, 32, 4, 4), "preco": 3000.0, "bairro": "Bairro Sul"},
	{"id": "lote_s11", "nome": "Terreno S11", "area": Rect2i(32, 38, 4, 4), "preco": 2800.0, "bairro": "Bairro Sul"},
	{"id": "lote_s12", "nome": "Terreno S12", "area": Rect2i(37, 38, 4, 4), "preco": 2800.0, "bairro": "Bairro Sul"},
	{"id": "lote_s13", "nome": "Terreno S13", "area": Rect2i(47, 32, 4, 4), "preco": 4200.0, "bairro": "Bairro Sul"},
	{"id": "lote_s14", "nome": "Terreno S14", "area": Rect2i(52, 32, 4, 4), "preco": 4200.0, "bairro": "Bairro Sul"},
	{"id": "lote_s15", "nome": "Terreno S15", "area": Rect2i(57, 32, 4, 4), "preco": 4200.0, "bairro": "Bairro Sul"},
	{"id": "lote_s16", "nome": "Terreno S16", "area": Rect2i(47, 38, 4, 4), "preco": 3900.0, "bairro": "Bairro Sul"},
	{"id": "lote_s17", "nome": "Terreno S17", "area": Rect2i(52, 38, 4, 4), "preco": 3900.0, "bairro": "Bairro Sul"},
	{"id": "lote_s18", "nome": "Terreno S18", "area": Rect2i(57, 38, 4, 4), "preco": 3900.0, "bairro": "Bairro Sul"},
	{"id": "lote_n1", "nome": "Terreno Neon 1", "area": Rect2i(47, 17, 4, 4), "preco": 6000.0, "bairro": "Distrito Neon"},
	{"id": "lote_n2", "nome": "Terreno Neon 2", "area": Rect2i(52, 17, 4, 4), "preco": 6000.0, "bairro": "Distrito Neon"},
	{"id": "lote_n3", "nome": "Terreno Neon 3", "area": Rect2i(57, 17, 4, 4), "preco": 6000.0, "bairro": "Distrito Neon"},
	{"id": "lote_n4", "nome": "Terreno Neon 4", "area": Rect2i(47, 23, 4, 4), "preco": 5500.0, "bairro": "Distrito Neon"},
	{"id": "lote_n5", "nome": "Terreno Neon 5", "area": Rect2i(52, 23, 4, 4), "preco": 5500.0, "bairro": "Distrito Neon"},
	{"id": "lote_n6", "nome": "Terreno Neon 6", "area": Rect2i(57, 23, 4, 4), "preco": 5500.0, "bairro": "Distrito Neon"},
]

const DISPOSITIVOS := [
	{"id": "cam_centro", "nome": "Câmera de trânsito", "tipo": "camera", "pos": Vector2(12.5, 10.5), "recompensa": 300.0},
	{"id": "atm_praca", "nome": "Caixa eletrônico", "tipo": "atm", "pos": Vector2(28.5, 6.5), "recompensa": 400.0},
	{"id": "cam_sede", "nome": "Câmera da avenida", "tipo": "camera", "pos": Vector2(31.5, 20.5), "recompensa": 300.0},
	{"id": "semaforo", "nome": "Semáforo inteligente", "tipo": "semaforo", "pos": Vector2(15.5, 24.5), "recompensa": 350.0},
	{"id": "cam_leste", "nome": "Câmera do viaduto", "tipo": "camera", "pos": Vector2(43.5, 9.5), "recompensa": 300.0},
	{"id": "atm_neon", "nome": "Caixa eletrônico neon", "tipo": "atm", "pos": Vector2(46.5, 20.5), "recompensa": 450.0},
	{"id": "painel_neon", "nome": "Painel de LED", "tipo": "semaforo", "pos": Vector2(46.5, 5.5), "recompensa": 400.0},
	{"id": "cam_sul", "nome": "Câmera do bairro", "tipo": "camera", "pos": Vector2(31.5, 36.5), "recompensa": 300.0},
	{"id": "atm_sul", "nome": "Caixa eletrônico do bairro", "tipo": "atm", "pos": Vector2(12.5, 40.5), "recompensa": 350.0},
]

const CODIGOS_BREACH := ["1C", "55", "BD", "E9", "7A", "FF"]

const CORES_PELE := [Color("f9d7b5"), Color("eab98f"), Color("c98f63"), Color("a26a42"), Color("7a4a2a"), Color("4e2f1b")]
const CORES_CABELO := [Color("1f1a17"), Color("4a2f1b"), Color("8d5a2b"), Color("d6a85c"), Color("e5e7eb"), Color("ef4444"), Color("3b82f6"), Color("22c55e"), Color("a855f7"), Color("f472b6")]
const CORES_ROUPA := [Color("3b82f6"), Color("10b981"), Color("ef4444"), Color("f59e0b"), Color("8b5cf6"), Color("111827"), Color("e5e7eb"), Color("ec4899")]
const ESTILOS_CABELO := ["curto", "longo", "moicano", "cacheado", "coque", "careca", "social", "rabo"]
const ESTILOS_ROUPA := ["camiseta", "camisa", "regata"]
const OLHOS := ["normal", "feliz", "focado"]

const NOMES_ALEATORIOS := ["Root", "Pinguim", "Byte", "Sudo", "Kernel", "Nuvem", "Firewall", "Ping", "Cache", "Pixel", "Docker", "Lambda"]
const NOMES_NPC := ["Ana", "Bruno", "Carla", "Diego", "Elisa", "Fábio", "Gabi", "Hugo", "Iara", "João", "Lia", "Marcos"]


static func empresa_por_id(id: String) -> Dictionary:
	for e in EMPRESAS:
		if e["id"] == id:
			return e
	return {}


static func nivel_por_xp(xp: int) -> int:
	var nivel := 0
	for i in NIVEIS.size():
		if xp >= NIVEIS[i]["xp"]:
			nivel = i
	return nivel
