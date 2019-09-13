FROM ubuntu:16.04
LABEL maintainer="ksatchit"
RUN apt-get update || true \
    && apt-get install -y git
COPY chaos_collector.sh /
