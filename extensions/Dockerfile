FROM public.ecr.aws/lambda/provided:al2 as build
# Install compiler
RUN yum install -y golang

ADD . .

# Build for arch ARM64
RUN GOOS=linux GOARCH=arm64 go build -o extensions/fluentd-lambda-extension-arm64 main.go
RUN chmod +x extensions/fluentd-lambda-extension-arm64

# Build for arch AMD64
RUN GOOS=linux GOARCH=amd64 go build -o extensions/fluentd-lambda-extension-amd64 main.go
RUN chmod +x extensions/fluentd-lambda-extension-amd64

# Move layerbinary to /opt
RUN mv extensions /opt/extensions

# Reduce image size
FROM public.ecr.aws/lambda/provided:al2
COPY --from=build /opt/extensions /opt/extensions
