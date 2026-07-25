Aluno(a): André da Silva Rodrigues
Turma: ITEAM - Noturno
Data: 24/07/2026
Aplicação usada: docker/getting-started-app — To-Do em Node.js

## 1. Como executar este projeto

```bash
git clone https://github.com/Andr3Rodrigues/meu-projeto-docker.git
cd meu-projeto-docker
cp .env.example .env
docker compose up -d --build
```

Acesse: http://localhost:3000

Para derrubar: `docker compose down` (mantém dados) ou `docker compose down -v` (apaga dados).

## 2. Imagem e Dockerfile multi-stage

Estágios utilizados: `builder` (instala as dependências com `npm install`) e o estágio final (runtime enxuto, só com `node_modules` + código-fonte).
Imagem base: `node:20-alpine`
Usuário de execução: `appuser`, não-root
Tamanho final da imagem: 238MB (disk usage) / 58,2MB (content size)

Por que o multi-stage ajuda? O estágio de build pode conter ferramentas e arquivos temporários usados só para instalar dependências, mas a imagem final leva apenas o `node_modules` e o código já prontos — isso reduz o tamanho da imagem e a superfície de ataque, já que nada do processo de build fica exposto no container em produção.

Print 1 — build + `docker images`
![docker images](docs/imagens/2%20-%20docker%20images.png)

Print 2 — aplicação rodando com tarefas cadastradas
![App rodando](docs/imagens/1%20-%20local3030%20atividades.png)

## 3. Volumes e persistência

Volume usado: `todo-db` (execução avulsa) / `todo-mysql-data` (compose) → montado em `/etc/todos` (SQLite) ou `/var/lib/mysql` (MySQL)

Print 3 — SEM volume: dados perdidos ao recriar o container
![Sem volume - vazio](docs/imagens/4%20-%202.1%20Tela%20Vazia.png)

Print 4 — COM volume: dados preservados
![Com volume - preservado](docs/imagens/7%20-%202.2%20-%20subida%20com%20mesmo%20volume.png)!

Diferença entre `docker compose down` e `docker compose down -v`: o primeiro remove containers e rede mas mantém os volumes (dados preservados); o segundo remove também os volumes, mas apagando os dados do banco.

## 4. Rede

Rede criada: `todo-net`
Serviços conectados: `app` e `db`
A porta do banco está exposta ao host? Não — o serviço `db` não tem `ports:` no compose.yaml, apenas está na rede interna `todo-net`, então só o serviço `app` consegue acessá-lo.

Por que o app consegue chamar o host `mysql` / `db` sem saber o IP? Porque o Docker fornece um DNS interno para cada rede definida por usuário: cada container é resolvido pelo nome do serviço (ou pelo `--network-alias`), então o app só precisa apontar `MYSQL_HOST=mysql` (ou `db`, no Compose) e o Docker resolve isso para o IP correto internamente.

Print 5 — `docker network inspect`
![Network inspect](docs/imagens/10%20-%203.1%20rede%20mysql.png)

Print 6 — dados dentro do MySQL (`select * from todo_items;`)
![Select MySQL](docs/imagens/13%20-%203.1%20saida%20tarefas.png)

## 5. Docker Compose

Serviços: `app`, `db`
Rede: `todo-net` · Volume: `todo-mysql-data`
Healthcheck em: `db` · `depends_on` com: `condition: service_healthy`
Variáveis sensíveis: carregadas via `.env` (não versionado). Modelo em `.env.example`.

Print 7 — `docker compose ps`
![Compose ps](docs/imagens/15%20-%204.1%20redes%20app%20e%20db.png)

## 6. Integração Contínua (GitHub Actions)

Arquivo do workflow: `.github/workflows/ci.yml`
Gatilhos: `push` e `pull_request`
O que o pipeline faz:
1. Valida o `compose.yaml` (`docker compose config`)
2. Builda a imagem do serviço `app`
3. Sobe a stack (`docker compose up -d`)
4. Aguarda a app responder e testa criar uma tarefa via API (smoke test)
5. Derruba a stack (`docker compose down -v`)

Print 8 — execução verde
![Actions verde](docs/imagens/20%20-%205.1%20-%20Git%20Actions%201.png) 

## 7. Quebra proposital do CI

O que eu quebrei: troquei a rota `/items` por `/itemsss` (inexistente) no step "Aguardar a aplicação responder" do workflow de CI.
Erro que apareceu no log: `A aplicacao nao subiu a tempo`, seguido de `exit 1`, porque o `curl -sf` para `/itemsss` retornava erro em todas as 30 tentativas.
Como o CI reagiu: o pipeline parou no step "Aguardar a aplicação responder", antes de chegar ao smoke test, evitando que um erro de rota passasse despercebido.
Como eu corrigi: segui a indicaçã do material e voltei a URL para `/items`, fiz commit e push na mesma branch (`quebra-proposital`), e o mesmo Pull Request passou a ficar verde.

Link do Pull Request: [cole aqui a URL do seu PR]

Print 9 — execução vermelha + log do erro
![Actions vermelho](docs/imagens/21%20-%206.1%20Quebra%20Proposital%20Pull%20Request2.png)

## 8. Dificuldades e aprendizados

Durante a atividade enfrentei alguns bloqueios de ambiente no Windows: o Firewall bloqueou o Docker inicialmente e precisei liberar via linha de comando; o grupo `docker-users` não tinha sido criado na instalação e precisei reparar o Docker Desktop; e na Parte 4 o Compose entrou em conflito com uma rede `todo-net` criada manualmente na Parte 3, resolvido removendo a rede antiga antes do `docker compose up`. 
A atividade deixou mais claro como containers, redes e volumes são recursos independentes do processo da aplicação, e como pequenos detalhes de permissão de usuário dentro da imagem afetam a execução.

## 9. Checklist de autoavaliação

- [x] Dockerfile multi-stage funcionando
- [x] .dockerignore presente
- [x] Container não roda como root
- [x] Volume nomeado + persistência demonstrada
- [x] Rede nomeada + banco não exposto ao host
- [x] compose.yaml sobe tudo com um comando
- [x] .env no .gitignore e .env.example versionado
- [x] CI verde
- [x] PR com CI vermelho documentado
- [x] Todos os 9 prints no README

## Evidências complementares

Prints adicionais tirados durante o processo (não obrigatórios, mas documentam cada etapa em detalhe):

![Container recriado do zero](docs/imagens/3%20-%202.1%20container%20do%20zero.png)
![Volume nomeado criado](docs/imagens/5%20-%202.2%20volume%20nomeado.png)
![Cadastro de atividades](docs/imagens/6%20-%202.2%20cadastro%20atividades.png)
![Subida com mesmo volume](docs/imagens/7%20-%202.2%20subida%20com%20mesmo%20volume.png)
![docker volume ls](docs/imagens/9%20-%202.2%20docker%20volume%20ls.png)
![Saída JSON /items](docs/imagens/11%20-%203.1%20saida%20json%20TODO.png)
![Saída JSON MySQL](docs/imagens/12%20-%203.1%20saida%20json%20MYSQL.png)
![Saída do exit no MySQL](docs/imagens/14%20-%203.1%20exit.png)
![Compose down sem volume](docs/imagens/16%20-%204.1%20derrubar%20sem%20apagar%20volume.png)
![Atividades intactas pós recarregar](docs/imagens/17%20-%204.1%20-%20Atividades%20intactas%20pos%20recarregar.png)
![Compose down -v](docs/imagens/18%20-%204.1%20-%20derrubar%20com%20volume.png)
![Atividades vazias após down -v](docs/imagens/19%20-%204.1%20-%20atividades%20vazias.png)
![Workflow file no GitHub](docs/imagens/20%20-%205.1%20Git%20Actions%202.png)
![Diff da quebra proposital](docs/imagens/21%20-%206.1%20Quebra%20Proposital%20Pull%20Request%20.png)
![PR vermelho detalhado](docs/imagens/21%20-%206.1%20Quebra%20Proposital%20Pull%20Request3.png)
![Correção aplicada](docs/imagens/22%20-%206.1%20Quebra%20Proposital%20Correção%201.png)
![PR verde após correção](docs/imagens/23%20-%206.1%20Quebra%20Proposital%20Correção%202.png)
