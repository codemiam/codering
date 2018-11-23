# ---
# In development, let's have OpenWhisk run using docker-compose,
# inside a docker-aware, s6-powered Alpine layer.
# ---

FROM alpine:3.8

LABEL org.label-schema.vendor = "Jean-Denis Vauguet <jd@vauguet.fr>"
LABEL org.label-schema.name = "codering-x (development)"
LABEL org.label-schema.description = "An OpenWhisk cluster for codering's runtimes"
LABEL org.label-schema.usage = "https://github.com/codemiam/codering/"
LABEL org.label-schema.url = "https://github.com/codemiam/codering/"
LABEL org.label-schema.vcs-url = "https://github.com/codemiam/codering/"

# Process management
# Inspired by https://github.com/just-containers/base-alpine/blob/master/Dockerfile but using a recent Alpine
RUN apk add --no-cache curl && \
    curl -L -s https://github.com/just-containers/s6-overlay/releases/download/v1.18.1.5/s6-overlay-amd64.tar.gz | tar xvzf - -C / && \
    apk del --no-cache curl

# Dependencies
RUN apk update && \
    apk add curl make git openjdk8
RUN curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Services
RUN mkdir /etc/{cont-finish.d,cont-init.d,fix-attrs.d,services.d}
COPY services.d* /etc/services.d/

WORKDIR /home/ow/
ENTRYPOINT [ "/init" ]