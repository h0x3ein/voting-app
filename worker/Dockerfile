FROM golang:1.23-bookworm 

WORKDIR /build

COPY go.mod go.sum ./

RUN go mod download

COPY . . 

RUN go build -o worker main.go

CMD ["/build/worker"]