# syntax=docker/dockerfile:1

FROM golang:1.24-bookworm AS build

RUN apt-get update \
    && apt-get install --yes --no-install-recommends protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.9 \
    && go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1

WORKDIR /src

COPY go.mod ./
COPY proto ./proto
COPY cmd ./cmd

RUN protoc \
    --go_out=. \
    --go_opt=module=example.com/proxyless-grpc-server \
    --go-grpc_out=. \
    --go-grpc_opt=module=example.com/proxyless-grpc-server \
    proto/helloworld/v1/helloworld.proto

RUN go env -w GOFLAGS=-mod=mod \
    && go mod tidy \
    && go mod download \
    && CGO_ENABLED=0 GOOS=linux go build \
       -mod=mod \
       -trimpath \
       -ldflags="-s -w" \
       -o /out/grpc-server \
       ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /out/grpc-server /grpc-server

EXPOSE 50051

USER nonroot:nonroot

ENTRYPOINT ["/grpc-server"]