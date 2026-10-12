# DDoS Defense

Jogo de estratégia em que você monta a arquitetura que mantém um site no ar durante ataques DDoS. Feito em Godot 4 com GDScript.

**Jogar no navegador:** https://sena295.github.io/ddos-defense/

**Versão Windows:** baixe o zip em [Releases](https://github.com/Sena295/ddos-defense/releases/tag/ultima-versao), extraia e abra `DDoS-Defense.exe`.

## Como jogar

O tráfego sai da Internet, passa pelos 4 slots da esquerda para a direita, chega ao Load Balancer e termina nos servidores. Você decide o que instalar em cada slot e em que ordem.

| Componente | O que faz | Troca |
|---|---|---|
| CDN / Cache | Atende parte dos usuários pelo cache, sem passar pelos servidores | Não filtra bots |
| Firewall WAF | Bloqueia bots e quase nunca barra humanos | Mais caro |
| CAPTCHA | Bloqueia muitos bots | Barra alguns usuários reais |
| Rate Limit | Corta o excesso de requisições por IP | Mais fraco, porém barato |
| Load Balancer | Distribui o tráfego entre os servidores (Round-robin, Menor carga e Health Check) | Sem ele, só o S1 recebe tráfego |
| Servidores | Até 5, cada um com 3 níveis de processamento | Ficam mais caros a cada compra |

- Usuários atendidos dão créditos. Bots só geram carga.
- Servidor acima de 100% cai por alguns segundos e quem chegar nele é perdido.
- Humanos perdidos (barrados por engano ou enviados para servidor caído) derrubam a reputação. Se ela chegar a 0, o site sai do ar.
- Cada onda traz mais tráfego. Algumas são picos de usuários reais e outras são ataques de botnet.
- Entre as ondas, o painel de recomendações explica o que deu errado e qual componente ajudaria.

## Controles

| Ação | PC | Celular |
|---|---|---|
| Selecionar slot, Load Balancer ou servidor | Clique | Toque |
| Comprar, melhorar, mover ou remover | Botões do painel | Botões do painel |
| Iniciar onda | Espaço ou botão | Botão |
| Pausar | P, Esc ou botão | Botão |
| Velocidade 1x/2x | F ou botão | Botão |

No celular, jogue com a tela deitada.

## Rodar o projeto

1. Instale o [Godot 4.7](https://godotengine.org/download).
2. Abra o Godot, clique em Importar e escolha o arquivo `project.godot`.
3. Aperte F5.

## Publicação

A cada push na branch `main`, o GitHub Actions (`.github/workflows/publicar.yml`) exporta o jogo para Web e Windows, publica a versão Web na branch `gh-pages` (GitHub Pages) e atualiza o zip do Windows nas Releases.
