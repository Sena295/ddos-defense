# DDoS Defense

Jogo de estratégia, simulação e cibersegurança em que você anda por uma cidade isométrica no estilo Habbo, aceita contratos, compra empresas, funda a sua própria startup e monta a arquitetura que mantém tudo no ar contra picos de tráfego, bots e ondas de hackers. Feito em Godot 4 com GDScript.

**Jogar no navegador:** https://sena295.github.io/ddos-defense/

**Versão Windows:** baixe o zip em [Releases](https://github.com/Sena295/ddos-defense/releases/tag/ultima-versao), extraia e abra `DDoS-Defense.exe`.

## O que tem no jogo

### Cidade Tech
- Mapa isométrico livre, com ruas, calçadas, praça com fonte, árvores, postes, carros circulando e moradores andando e dando dicas.
- Guia no cartão da missão que leva automaticamente ao próximo prédio e abre a atividade ao chegar.
- Personagens em pixel art com contorno, que andam e olham para os lados. Crie o seu: pele, cabelo, cor do cabelo, roupa, cor da roupa e olhar.
- Ande com WASD ou setas, ou clique no chão ou num prédio: o personagem encontra o caminho sozinho.
- 15 empresas fictícias e prédios de missões, aprendizado, compras e infraestrutura. Metade dos lotes antes vazios agora tem negócios com nome próprio; os outros continuam disponíveis para construir.

### Progresso
- **Contas locais** com PIN opcional (guardado só como hash), várias contas no mesmo aparelho e salvamento automático.
- **Código de backup** para copiar, baixar e importar o progresso em outro aparelho.
- **Missões principais** em sequência, que ensinam o jogo, e **3 missões diárias** que mudam todo dia.
- **Sequência de dias jogando**, com bônus crescente na carteira.
- **7 níveis de carreira**, de Estagiário a Lenda Cyber. Os níveis liberam componentes e empresas.
- **3 especializações:** Operador de sistemas, Hacker ético e Empreendedor. Ações reais no jogo aumentam a especialização e liberam bônus de lucro, pentest ou renda dos imóveis.
- **Economia:** contratos pagam 10% do lucro, empresas compradas pagam 20% e a sua startup paga 30%.
- **Loja Tech:** óculos hacker, headset, boné, gorro, moletom, jaleco, terno, gato e robô de estimação, além de reforços para usar nas operações (seguro cibernético, equipe de plantão, pentest e consultoria).
- **Startup própria:** escolha nome, setor, forma, cores e símbolo do logo. O prédio aparece na cidade com a sua marca.
- **Imobiliária:** compre terrenos para criar negócios ou junte dinheiro para adquirir um dos 12 prédios prontos. Os imóveis prontos custam mais e pagam 75% a mais de aluguel por localização. O painel mostra o prazo estimado para recuperar o preço; a renda entra depois de cada dia de operação concluído.

### Operação das empresas
- **21 componentes em 4 abas:** Borda (CDN, Anti-DDoS, Geo-bloqueio), Filtros (WAF, IDS/IPS, CAPTCHA, Rate Limit, Login 2FA), Infraestrutura (Load Balancer, Fila, Cache Redis, Torre, Auto Scaling) e Segurança (Backup, Patches, Cofre de senhas, Treinamento, Criptografia, SIEM/SOC, EDR, Honeypot).
- **Tráfego de verdade:** clientes, bots de inundação, imitadores, ladrões de senha e copiadores, além dos hackers de SQL Injection, XSS, exploit, ransomware e força bruta.
- **Ondas de hackers**, gangue de ransomware, phishing, zero-day e ataques hacktivistas, que ficam mais fortes com o passar dos dias.
- **Incidentes de segurança:** quando um ataque passa, o jogo pausa e você escolhe a resposta: isolar, restaurar backup, pagar resgate, comunicar a ANPD... Cada escolha ensina algo.
- Vários sistemas por empresa, eventos como Black Friday e PIX, multas da LGPD, linha de crédito e falência.

### Aprendizado
- **Academia Cyber** com 40 lições sobre componentes, conceitos e ataques.
- **Café Dev:** três cursos curtos sobre redes, defesa em camadas e código seguro, com pergunta, explicação e recompensa única. Há um café público na cidade e os cafés construídos também dão acesso aos cursos.
- **Beco Hacker:** 16 desafios de código seguro em Python, JavaScript, PHP, Java, Bash, SQL, C e Go. Ache a linha vulnerável e escolha a correção. Cada 3 desafios sobem o nível de código seguro das suas empresas.
- **Hub ZeroSec:** negocie auditorias autorizadas para três empresas fictícias. Uma proposta maior paga mais, exige uma sequência maior e dá menos tempo. Cada empresa aceita uma tentativa por dia e paga uma vez. Ao concluir, o relatório explica a defesa recomendada.
- Relatório diário com "mandou bem" e "por que deu problema", quiz do conselho e dicas dos moradores da cidade.

## Controles

| Ação | PC | Celular |
|---|---|---|
| Andar na cidade | WASD ou setas | Toque no chão |
| Entrar num prédio | E, ou clique no prédio | Toque no prédio ou no botão verde |
| Missões / Perfil | M / Esc | Botões no canto |
| Instalar componente | Clique na paleta e depois numa célula | Toque na paleta e depois numa célula |
| Conectar | Arraste do círculo de saída até outro componente | Arraste, ou botão Conectar |
| Mover a câmera da operação | Arraste o fundo, roda do mouse dá zoom | Arraste o fundo |
| Iniciar o dia / Pausar / Velocidade | Espaço / P / F

## Privacidade

O jogo não tem servidor e não coleta dados. Contas e progresso ficam só no seu dispositivo. O PIN é guardado como hash. Todas as empresas, bancos e marcas do jogo são fictícias e criadas para fins educacionais; valores e números são simulações simplificadas. Use o que aprender aqui apenas para defender sistemas.

## Desempenho

Perfis novos no navegador e no celular começam em modo leve: menos moradores e carros, com limite de 30 quadros por segundo. O Perfil permite alternar o modo. A cidade reaproveita a seleção de objetos estáticos visíveis enquanto a câmera quase não se move e pausa a animação do mapa atrás dos painéis. O mapa ainda precisa ser medido em dispositivos lentos reais.

## Desenvolvimento

O planejamento por etapas está em [ETAPAS.md](ETAPAS.md), as decisões técnicas em [MEMORIA.md](MEMORIA.md) e o contexto para continuidade em [HANDOFF_CLAUDE.md](HANDOFF_CLAUDE.md).
Os testes de integração estão em `tests/testes_integracao.gd` e rodam no GitHub Actions antes de publicar.

## Rodar o projeto

1. Instale o [Godot 4.7](https://godotengine.org/download).
2. Abra o Godot, clique em Importar e escolha o arquivo `project.godot`.
3. Aperte F5.

## Estrutura

| Arquivo | Conteúdo |
|---|---|
| `main.gd` | Roteador das telas |
| `estado.gd` | Contas, salvamento, economia, missões, sequência, itens, empresas e backup |
| `inicio.gd` / `editor_avatar.gd` | Carregamento, login, cadastro, PIN e criação do personagem |
| `mundo.gd` | Cidade isométrica, caminhos, moradores, carros e minimapa |
| `paineis.gd` | Missões, loja, academia, beco hacker, empresas, bolsa, sede, startup e backup |
| `operacao.gd` / `site.gd` | Operação das empresas e simulação do tráfego |
| `dados.gd` / `textos.gd` | Empresas, componentes, eventos, missões, lições, quiz, desafios e incidentes |
| `visual.gd` / `topo.gd` | Desenho, personagens em pixel art, avisos e lições |

## Publicação

A cada push na branch `main`, o GitHub Actions (`.github/workflows/publicar.yml`) exporta o jogo para Web e Windows, publica a versão Web no GitHub Pages e atualiza o zip do Windows nas Releases.
