#!/bin/sh
set -e
CATALINA_HOME=${CATALINA_HOME:-/usr/local/tomcat}
CUSTOM_CONF="$CATALINA_HOME/conf-custom"

# Copia as configuracoes customizadas (montadas de ./tomcat/conf) para conf/.
# Usamos copia em vez de bind mount de arquivo unico porque, no macOS, editar o arquivo
# no host recria o inode e o container passa a ver o arquivo antigo (ou nenhum).
if [ -d "$CUSTOM_CONF" ]; then
  for f in context.xml tomcat-users.xml server.xml web.xml logging.properties; do
    [ -f "$CUSTOM_CONF/$f" ] && cp "$CUSTOM_CONF/$f" "$CATALINA_HOME/conf/$f"
  done
fi

# A imagem oficial vem com webapps/ vazio (ROOT e manager ficam em webapps.dist).
# Como webapps/ e um bind mount do host, copiamos o manager na subida se ele nao existir.
if [ ! -d "$CATALINA_HOME/webapps/manager" ] && [ -d "$CATALINA_HOME/webapps.dist/manager" ]; then
  cp -r "$CATALINA_HOME/webapps.dist/manager" "$CATALINA_HOME/webapps/manager"
  if [ -f "$CUSTOM_CONF/manager-context.xml" ]; then
    cp "$CUSTOM_CONF/manager-context.xml" "$CATALINA_HOME/webapps/manager/META-INF/context.xml"
  else
    cp "$CATALINA_HOME/manager-context.xml" "$CATALINA_HOME/webapps/manager/META-INF/context.xml"
  fi
fi

exec "$@"
