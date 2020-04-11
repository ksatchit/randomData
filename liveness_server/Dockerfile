FROM ubuntu:16.04
RUN apt-get update \
    && apt-get install -y netcat-openbsd curl
COPY business_logic.sh webserver.sh / 
EXPOSE 8080
