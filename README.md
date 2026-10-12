# DDoS Defense

Jogo isométrico de defesa contra ataques DDoS, feito em Godot 4 com GDScript.

**Jogar no navegador:** https://sena295.github.io/ddos-defense/

**Versão Windows:** baixe o zip em [Releases](https://github.com/Sena295/ddos-defense/releases/tag/ultima-versao), extraia e abra `DDoS-Defense.exe`.

## Como jogar

Requisições chegam pela esquerda. Humanos (verde) geram créditos e um pouco de carga. Bots (vermelho) geram muita carga. Cloudflare e CAPTCHA filtram parte dos bots (e às vezes barram um humano por engano). Quem passa chega ao Load Balancer, que distribui o tráfego entre os servidores S1, S2 e S3 em round-robin.

Se qualquer servidor chegar a 100% de carga, a partida acaba. O tráfego e a proporção de bots crescem sem parar: o objetivo é resistir o máximo de tempo e bater o recorde.

| Ação | PC | Celular |
|---|---|---|
| Bloquear um bot antes do Load Balancer (+2 créditos) | Clique no cubo vermelho | Toque no cubo vermelho |
| Upgrade Cloudflare (+5% de bloqueio, até 95%) | Tecla 1 ou botão | Botão |
| Upgrade CAPTCHA (+6% de bloqueio, até 90%) | Tecla 2 ou botão | Botão |
| Upgrade Servidores (+2 de processamento por segundo) | Tecla 3 ou botão | Botão |
| Resfriar (corta pela metade a carga atual) | Tecla 4 ou botão | Botão |
| Pausar | P, Esc ou botão de pausa | Botão de pausa |

Clicar em um humano faz você perder o cliente. No celular, jogue com a tela deitada.

## Rodar o projeto

1. Instale o [Godot 4.7](https://godotengine.org/download).
2. Abra o Godot, clique em Importar e escolha o arquivo `project.godot`.
3. Aperte F5.

## Publicação

A cada push na branch `main`, o GitHub Actions (`.github/workflows/publicar.yml`) exporta o jogo para Web e Windows, publica a versão Web na branch `gh-pages` (GitHub Pages) e atualiza o zip do Windows nas Releases.
