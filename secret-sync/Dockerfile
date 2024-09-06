FROM golang:1.22-alpine

WORKDIR /app

COPY src/go.mod ./src/go.sum ./

RUN go mod download

COPY src .

RUN go build -o sync

EXPOSE 18200

CMD ["./sync"]