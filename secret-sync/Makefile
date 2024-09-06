service_name = "sync"
version = "2.0.0"
org = "devopsrob"

go_test:
	go test ./src -v
go_build:
	go build ./src -o $(service_name)
docker_build:
	docker buildx build --platform linux/amd64,linux/arm64 -t $(org)/$(service_name):$(version) . --push
tag:
	docker tag  $(org)/$(service_name):$(version) $(org)/$(service_name):$(version)
push:
	docker push  $(org)/$(service_name):$(version)
deploy: docker_build tag push