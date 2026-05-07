FROM alpine:3.20

RUN apk add --no-cache bash curl jq

COPY start.sh /usr/src/start.sh
RUN chmod +x /usr/src/start.sh

CMD ["/bin/bash", "/usr/src/start.sh"]
