FROM golang:1.14.3 as builder

WORKDIR /app
COPY . /app

RUN CGO_ENABLED=1 GO111MODULES=on go build -ldflags="-s -w" .

FROM golang:1.14.3

WORKDIR /app
COPY --from=builder /app/postgrees-live /app