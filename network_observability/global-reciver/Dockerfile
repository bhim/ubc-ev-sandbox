FROM golang:1.24.5-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /receiver .


FROM alpine:3.19

RUN apk --no-cache add ca-certificates

WORKDIR /app
COPY --from=builder /receiver .

ENV HOST_ADDRESS=0.0.0.0:6060
EXPOSE 6060

ENTRYPOINT ["./receiver"]
