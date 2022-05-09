FROM alpine:latest

ENV ENV /etc/profile

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk update
RUN apk add mdp

RUN mkdir -p /data

WORKDIR /data

ENTRYPOINT ["/bin/sh"]
