# syntax=docker/dockerfile:1.7

########## Builder ##########
FROM golang:1.23-bookworm AS build
WORKDIR /src

# Cache deps
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build a small static binary
ENV CGO_ENABLED=0
RUN go build -ldflags="-s -w" -o /out/worker ./main.go

########## Runtime ##########
FROM gcr.io/distroless/static:nonroot
WORKDIR /app
COPY --from=build /out/worker /app/worker
EXPOSE 8080
ENTRYPOINT ["/app/worker"]