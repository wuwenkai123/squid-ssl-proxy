# Author: Satish Gaikwad <satish@satishweb.com>
FROM alpine:latest
LABEL MAINTAINER scout

ARG SQUID_VERSION=6.12-r0
ARG AWSCLI_VERSION=2.22.10-r0
ARG SQUID_PROXY_PORT=3128
ARG SQUID_PROXY_SSLBUMP_PORT=4128

#set enviromental values for certificate CA generation
ENV CERT_CN=squid.local \
    CERT_ORG=squid \
    CERT_OU=squid \
    CERT_COUNTRY=US \
    SQUID_PROXY_PORT=3128 \
    SQUID_PROXY_SSLBUMP_PORT=4128
RUN apk update 
# Add squid and other packages
RUN apk add --no-cache \
    squid=${SQUID_VERSION} \
    aws-cli=${AWSCLI_VERSION} \
    openssl \
    gettext \
    ca-certificates && \
    update-ca-certificates && \
    rm -rf /etc/squid/squid.conf
RUN apk add --no-cache shadow && \
    usermod -u 1002 squid && \
    groupmod -g 1002 squid

# Add config file
ADD conf/squid.sample.conf /templates/squid.sample.conf
ADD conf/openssl.extra.cnf /etc/ssl
# Add scripts and make them executable

ADD scripts/entrypoint.sh /entrypoint
RUN chmod u+x /entrypoint && \
    mkdir -p /etc/squid-cert /var/cache/squid/ /var/log/squid/ && \
    chown -R squid:squid /etc/squid-cert /var/cache/squid/ /var/log/squid/ && \
    cat /etc/ssl/openssl.extra.cnf >> /etc/ssl/openssl.cnf
EXPOSE 3128
EXPOSE 4128

# Healthcheck
HEALTHCHECK CMD netstat -an | grep ${SQUID_PROXY_PORT} > /dev/null; if [ 0 != $? ]; then exit 1; fi;

# Run the command on container startup
ENTRYPOINT ["/entrypoint"]
CMD ["squid", "-NYCd", "1", "-f", "/etc/squid/squid.conf"]
