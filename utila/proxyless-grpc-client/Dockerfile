# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM golang:1.24-bookworm AS build

ARG PROTOC_GEN_GO_VERSION=v1.36.9
ARG PROTOC_GEN_GO_GRPC_VERSION=v1.5.1
ARG TARGETOS
ARG TARGETARCH

RUN apt-get update \
    && apt-get install --yes --no-install-recommends protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@${PROTOC_GEN_GO_VERSION} \
    && go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@${PROTOC_GEN_GO_GRPC_VERSION}

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY proto ./proto

RUN protoc \
    --go_out=. \
    --go_opt=module=example.com/proxyless-grpc-client \
    --go-grpc_out=. \
    --go-grpc_opt=module=example.com/proxyless-grpc-client \
    proto/helloworld/v1/helloworld.proto

COPY cmd ./cmd

RUN go mod tidy

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/grpc-client \
    ./cmd/client

FROM --platform=$TARGETPLATFORM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /out/grpc-client /grpc-client

USER nonroot:nonroot

ENTRYPOINT ["/grpc-client"]
