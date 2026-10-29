ARG TOMCAT_VERSION=9.0-jdk11-temurin
FROM tomcat:${TOMCAT_VERSION}

ARG PG_JDBC_VERSION=42.7.4

# Driver JDBC do PostgreSQL no classpath global do Tomcat (necessario para DataSource JNDI)
ADD https://repo1.maven.org/maven2/org/postgresql/postgresql/${PG_JDBC_VERSION}/postgresql-${PG_JDBC_VERSION}.jar \
    /usr/local/tomcat/lib/postgresql.jar
RUN chmod 644 /usr/local/tomcat/lib/postgresql.jar

# Context do manager liberando acesso a partir do host (por padrao so aceita 127.0.0.1)
COPY conf/manager-context.xml /usr/local/tomcat/manager-context.xml

# Entrypoint: garante o Tomcat Manager em webapps/ (que e um bind mount) e sobe o Tomcat
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["catalina.sh", "run"]
