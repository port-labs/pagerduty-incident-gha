# Use the Alpine Linux base image
FROM alpine:latest

RUN apk update && \
    apk add --no-cache jq \
    curl \ 
    git \
    openssh-client \
    bash 

COPY *.sh /
RUN chmod +x /*.sh

ENTRYPOINT ["/entrypoint.sh"]
