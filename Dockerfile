FROM public.ecr.aws/lambda/provided:al2 as build
# Install compiler
RUN yum install -y golang

ADD . .

# Build binary
RUN go build -o bin/fluentd-lambda-extension -v ./extensions
RUN chmod +x bin/fluentd-lambda-extension

# Move layerbinary to /opt
RUN mkdir -pv /opt/extensions && mv bin/fluentd-lambda-extension /opt/extensions

# Reduce image size
FROM public.ecr.aws/lambda/provided:al2
COPY --from=build /opt/extensions /opt/extensions
