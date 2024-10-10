FROM golang:1.22-alpine

WORKDIR /app

COPY src/go.mod ./src/go.sum ./

RUN go mod download

COPY src .

RUN go build -o gcp-file-sync

EXPOSE 18201

CMD ["./gcp-file-sync"]