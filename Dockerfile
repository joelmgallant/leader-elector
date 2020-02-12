############################
# STEP 1 build executable binary
############################
FROM golang:1.13 as builder

ADD leader-elector /go/src/github.com/gleez/leader-elector
# RUN cd /go/src/github.com/gleez/leader-elector \
#  && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-w' -o leader-elector example/main.go

RUN cd /go/src/github.com/gleez/leader-elector \
 && COMMIT_SHA=$(git rev-parse --short HEAD) \
 && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-s -w  \
    -X github.com/gleez/leader-elector/Version=0.6 \
    -X github.com/gleez/leader-elector/Revision=${COMMIT_SHA}" \
    -v -a -tags netgo -installsuffix netgo -o leader-elector example/main.go
    
############################
# STEP 2 build a certs image
############################

# Alpine certs
FROM alpine:3.10 as alpine

RUN apk add -U --no-cache ca-certificates

# Create appuser
RUN adduser -D -g '' appuser


############################
# STEP 3 build a release image
############################

FROM scratch
MAINTAINER Sandeep Sangamreddi <sandeepone@gmail.com>

# Import the Certificate-Authority certificates for enabling HTTPS.
COPY --from=alpine /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Import the user and group files from the builder.
COPY --from=alpine /etc/passwd /etc/passwd

# Add the binary
COPY --from=builder /go/src/github.com/gleez/leader-elector /usr/bin/

USER appuser

EXPOSE 4040
ADD run.sh /run.sh

ENTRYPOINT ["/run.sh"]
# ENTRYPOINT [ "leader-elector", "--id=$(hostname)" ]
