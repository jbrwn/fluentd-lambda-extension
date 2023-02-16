build:
	GOOS=linux GOARCH=amd64 go build -o bin/fluentd-lambda-extension main.go

build-GoExampleLogsApiExtensionLayer:
	GOOS=linux GOARCH=amd64 go build -o $(ARTIFACTS_DIR)/fluentd-lambda-extension main.go
	chmod +x $(ARTIFACTS_DIR)/fluentd-lambda-extension

run-GoExampleLogsApiExtensionLayer:
	go run main.go
