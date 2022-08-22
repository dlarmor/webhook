FROM        golang:alpine3.16 AS build
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

FROM        alpine:3.16
COPY        --from=build /usr/share/zoneinfo/Asia/Shanghai /usr/share/zoneinfo/Asia/Shanghai
ENV         TZ=Asia/Shanghai
COPY        --from=build /usr/local/bin/webhook /usr/local/bin/webhook
WORKDIR     /etc/webhook
VOLUME      ["/etc/webhook"]
EXPOSE      9000
ENTRYPOINT  ["/usr/local/bin/webhook"]
