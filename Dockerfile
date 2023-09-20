FROM        golang:alpine3.17 AS build
WORKDIR     /project
RUN         apk add --update tzdata
RUN         apk add --update -t build-deps curl libc-dev gcc libgcc
ENV         GOPROXY=https://goproxy.cn/,direct
ENV         GO111MODULE=on
ADD         go.mod .
ADD         go.sum .
RUN         go mod download
COPY        . .
RUN         go build -ldflags="-s -w" -o /usr/local/bin/webhook && \
            apk del --purge build-deps && \
            rm -rf /var/cache/apk/* && \
            rm -rf /project
RUN         ls /usr/share/zoneinfo/

FROM        python:alpine3.17
RUN         apk update && apk upgrade && apk add --no-cache curl jq openssh-client bash bash-doc bash-completion && rm -rf /var/cache/apk/*
RUN         /bin/bash
COPY        --from=build /usr/share/zoneinfo/Asia/Shanghai /usr/share/zoneinfo/Asia/Shanghai
ENV         TZ=Asia/Shanghai
COPY        --from=build /usr/local/bin/webhook /usr/local/bin/webhook
WORKDIR     /etc/webhook
VOLUME      ["/etc/webhook"]
EXPOSE      9000
ENTRYPOINT  ["/usr/local/bin/webhook"]
