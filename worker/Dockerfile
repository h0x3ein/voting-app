# syntax=docker/dockerfile:1.7

########## Builder ##########
FROM golang:1.23-bookworm AS build
WORKDIR /src

# 1) Cache deps efficiently
COPY go.mod go.sum ./
RUN go mod download

# 2) Copy the rest
COPY . .

# 3) Build static, strip symbols, inject version info (optional)
# Set these at build time: --build-arg VERSION=1.0.0 --build-arg COMMIT=$(git rev-parse --short HEAD)
ARG VERSION=dev
ARG COMMIT=unknown
ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64
RUN go build -trimpath \
    -ldflags="-s -w -X main.version=${VERSION} -X main.commit=${COMMIT}" \
    -o /out/worker ./cmd/worker 2>/dev/null || \
    go build -trimpath \
    -ldflags="-s -w -X main.version=${VERSION} -X main.commit=${COMMIT}" \
    -o /out/worker ./main.go

########## Runtime ##########
# Distroless 'static' contains only minimal runtime and CA certs for TLS.
FROM gcr.io/distroless/static:nonroot
WORKDIR /app

# Copy the static binary
COPY --from=build /out/worker /app/worker

# (Optional) document port
EXPOSE 8080

# Runs as nonroot by default in this image
ENTRYPOINT ["/app/worker"]
