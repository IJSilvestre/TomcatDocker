# Servidor Tomcat 9 + PostgreSQL 12 (Docker Compose)

## Estrutura
```
docker-compose.yml       # servicos tomcat, postgres e pgadmin
.env                     # senhas, portas e versoes (nao versionar)
webapps/                 # coloque o .war aqui -> deploy automatico
tomcat/Dockerfile        # Tomcat oficial + driver JDBC do Postgres
tomcat/conf/context.xml  # DataSource JNDI jdbc/VENDI (copiado para conf/ pelo entrypoint)
tomcat/conf/tomcat-users.xml  # usuario do Tomcat Manager
tomcat/docker-entrypoint.sh   # copia o Manager para webapps/ na subida
postgres/init/           # scripts .sql executados na 1a inicializacao
pgadmin/servers.json     # servidor Postgres pre-cadastrado no pgAdmin
restore-db.sh            # restaura um dump .backup no Postgres
```

## Subir
```bash
docker compose up -d --build
```

- Aplicacao: http://localhost:8080/<nome-do-war>
- pgAdmin: http://localhost:5050 (login `admin@local.dev` / `admin`, definidos no `.env`). O servidor "solocria (docker)" ja aparece cadastrado com a senha salva; basta expandir e abrir o Query Tool.
- Tomcat Manager: http://localhost:8080/manager (admin / admin - troque em `tomcat/conf/tomcat-users.xml`)
- Postgres (a partir do host): `localhost:5432`, banco `solocria`, usuario `appuser`. Se a porta estiver ocupada por outro projeto, ajuste `POSTGRES_PORT` no `.env`

## Deploy da aplicacao
Copie o `.war` para `webapps/`. O Tomcat detecta e faz o deploy sozinho.
Para ser a aplicacao raiz (http://localhost:8080/), renomeie para `ROOT.war`.

## Conexao com o banco a partir da aplicacao
Dentro da rede do Docker o host do banco e `postgres` (nao `localhost`).

Opcao 1 - JNDI (ja configurado em `tomcat/conf/context.xml`):
```java
DataSource ds = (DataSource) new InitialContext().lookup("java:comp/env/jdbc/VENDI");
```

Opcao 2 - variaveis de ambiente disponiveis no container:
`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_URL`
(`DB_URL` = `jdbc:postgresql://postgres:5432/solocria`).

## Restaurar o banco a partir de um dump
Coloque o arquivo `.backup` (formato custom do `pg_dump`) na raiz do projeto e rode:
```bash
./restore-db.sh solocria.backup
```
O script sobe o Postgres se preciso, cria o banco definido em `POSTGRES_DB` (padrao `solocria`),
copia o arquivo para o container e executa `pg_restore` com `--clean --if-exists --no-owner --no-privileges`.
Pode ser executado mais de uma vez; avisos de "already exists" sao esperados.

## Executar scripts SQL
- Pelo pgAdmin: Servers > solocria (docker) > Databases > solocria > botao direito > Query Tool.
- Pela linha de comando (arquivo na pasta do projeto):
```bash
docker compose exec -T postgres psql -U appuser -d solocria < meu-script.sql
```

## Comandos uteis
```bash
docker compose logs -f tomcat        # logs do Tomcat
docker compose exec postgres psql -U appuser -d solocria   # console do banco
docker compose down                  # para (mantem os dados)
docker compose down -v               # para e APAGA o volume do banco
```

## Observacoes
- Tomcat 9 usa Java EE 8 (`javax.servlet.*`). A imagem padrao e `9.0-jdk11-temurin`; se a aplicacao exigir Java 8, troque `TOMCAT_VERSION=9.0-jdk8-temurin` no `.env`.
- PostgreSQL 12 esta fora de suporte desde novembro/2024 (ultima versao 12.22). Use-o apenas por compatibilidade; planeje migrar para 14+ quando possivel.
- Troque `POSTGRES_PASSWORD` e a senha do manager antes de usar fora da maquina local.
