############################
# STEP 1 build UI
############################
FROM --platform=linux/amd64 node:16-alpine AS builder_node

# Install build dependencies
RUN apk add --update --no-cache git make

# Prepare working directory
RUN mkdir -p /code/_ui
WORKDIR /code

# Copy minimum set for npm install first, allows for better caching
COPY Makefile .
COPY _ui/package-lock.json ./_ui
COPY _ui/package.json ./_ui
RUN make _ui/node_modules

# Copy the rest of the files and build the UI
COPY _ui ./_ui
RUN make _ui/build

############################
# STEP 2 build server
############################
FROM --platform=linux/amd64 golang:1.18-alpine AS builder_golang

# Install build dependencies
RUN apk add --update --no-cache git make openssh-client

# Prepare working directory
RUN mkdir -p /code
WORKDIR /code

# Fetch dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the files and build the server
COPY . .
COPY --from=builder_node /code/_ui/build /code/_ui/build
RUN make build

############################
# STEP 3 build a small image to run it all
############################
FROM --platform=linux/amd64 scratch

# Copy TLS certificates
COPY --from=alpine:latest /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy our static executable
COPY --from=builder_golang /code/build/server /go/bin/react-go-server

EXPOSE 8080
ENTRYPOINT ["/go/bin/react-go-server"]
