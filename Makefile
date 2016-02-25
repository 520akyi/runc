RUNC_TEST_IMAGE=runc_test
PROJECT=github.com/opencontainers/runc
TEST_DOCKERFILE=script/test_Dockerfile
BUILDTAGS=
export GOPATH:=$(CURDIR)/Godeps/_workspace:$(GOPATH)

all:
	go build -tags netgo -installsuffix netgo -ldflags "-linkmode external -extldflags -static" -tags "$(BUILDTAGS)" -o share-mnt .

vet:
	go get golang.org/x/tools/cmd/vet

lint: vet
	go vet ./...
	go fmt ./...

runctestimage:
	docker build -t $(RUNC_TEST_IMAGE) -f $(TEST_DOCKERFILE) .

test: runctestimage
	docker run -e TESTFLAGS --privileged --rm -v $(CURDIR):/go/src/$(PROJECT) $(RUNC_TEST_IMAGE) make localtest

shell: runctestimage
	docker run -it -e TESTFLAGS --privileged --pid=host --rm -v /run:/host/run -v $(CURDIR):/go/src/$(PROJECT) $(RUNC_TEST_IMAGE) bash

localtest:
	go test -tags "$(BUILDTAGS)" ${TESTFLAGS} -v ./...

install:
	cp runc /usr/local/bin/runc

clean:
	rm runc

validate: vet
	script/validate-gofmt
	go vet ./...

ci: validate localtest
