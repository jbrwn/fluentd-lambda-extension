# AWS Lambda - Logs API Extension for Fluentd
The provided code how to get a basic Logs API extension to send logs to Fluentd written in Golang up and running.

In this extension, we start by developing a simple extension and then add the ability to read logs from the Logs API. For more details on building an extension, please read the Extension API Developer Guide.

When the Lambda service sets up the execution environment, it runs the extension (`fluentd-lambda-extension`). This extension first registers as an extension and then subscribes to the Logs API to receive the logs via HTTP protocol. It starts an HTTP listener which receives the logs and processes them.

## System Compatible
- Architectures: `AMD64` & `ARM64`
- Runtimes: `All Linux`
- Function code with container and non-container

## Compile package and dependencies

To run this example, you will need to ensure that your build architecture matches that of the Lambda execution environment by compiling with `GOOS=linux` and (`GOARCH=amd64` or `GOARCH=arm64`).

Building and saving package into a `bin` directory:
```bash
$ cd fluentd-lambda-extension/extensions
$ GOOS=linux GOARCH=amd64 go build -o bin/fluentd-lambda-extension
$ chmod +x bin/fluentd-lambda-extension
```

## Layer Setup - by Terraform
```hcl
resource "aws_lambda_function" "example" {
  layers = [
    module.lambda_layer_extension.lambda_layer_arn,
  ]

  environment {
    variables = {
      FLUENTD_HOST = module.instance.private_ip[0]
    }
  }
}
```

## Layer Setup - by Manually
### ZIP file manually setup
The extensions .zip file should contain a root directory called `extensions/`, where the extension executables are located.

Creating zip package for the extension:
```bash
$ chmod +x extensions/bin/fluentd-lambda-extension
$ cd extensions/bin && mkdir extensions
$ mv fluentd-lambda-extension extensions
$ zip -r extension.zip extensions
```

Publish a new layer using the `extension.zip`. The output of the following command should provides you a layer arn.
```bash
aws lambda publish-layer-version \
 --layer-name "fluentd-lambda-extension" \
 --region <use your region> \
 --zip-file  "fileb://extension.zip"
```
Note the LayerVersionArn that is produced in the output.
e.g. `"LayerVersionArn": "arn:aws:lambda:<region>:123456789012:layer:fluentd-lambda-extension:1"`

Add the newly created layer version to a Lambda function.
```bash
aws lambda update-function-configuration --region <use your region> --function-name <your function name> --layers <LayerVersionArn from previous step>
```

### Docker manually setup
```
FROM 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/fluentd-lambda-extension:v1 as extensions-layer
COPY --from=extensions-layer /opt/extensions/fluentd-lambda-extension-{amd64, arm64} /opt/extensions/
```

## Lambda Function Environment variables support
- `FLUENTD_HOST`: fluentd host, which lambda will send log to, default: `localhost`
- `FLUENTD_PORT`: fluent port, which lambda using to connect, default: `24224`
- `FLUENTD_TAG_SUFFIX`: log suffix, default: `es.log`

Example: if `function-test.es.log` is fluentd tag key, then `es.log` is `FLUENTD_TAG_SUFFIX`

Sample log line:
```sh
2022-09-30 03:25:03.000000000 +0000 fluentd-lambda-extension-examples.es.log: {"function_name":"fluentd-lambda-extension-examples","msg":"{\"record\":\"Finished test extensions. Well done!\\n\",\"time\":\"2022-09-30T03:25:02.224Z\",\"type\":\"function\"}"}
2022-09-30 03:25:03.000000000 +0000 fluentd-lambda-extension-examples.es.log: {"function_name":"fluentd-lambda-extension-examples","msg":"{\"record\":{\"requestId\":\"9df595ac-df7f-43b6-b97b-dcdfa6838fda\",\"status\":\"success\"},\"time\":\"2022-09-30T03:25:02.224Z\",\"type\":\"platform.runtimeDone\"}"}
2022-09-30 03:30:51.000000000 +0000 fluentd-lambda-extension-examples.es.log: {"function_name":"fluentd-lambda-extension-examples","msg":"{\"record\":{\"requestId\":\"9df595ac-df7f-43b6-b97b-dcdfa6838fda\"},\"time\":\"2022-09-30T03:25:03.224Z\",\"type\":\"platform.end\"}"}
2022-09-30 03:30:51.000000000 +0000 fluentd-lambda-extension-examples.es.log: {"function_name":"fluentd-lambda-extension-examples","msg":"{\"record\":{\"metrics\":{\"billedDurationMs\":1002,\"durationMs\":1001.22,\"maxMemoryUsedMB\":50,\"memorySizeMB\":2048},\"requestId\":\"9df595ac-df7f-43b6-b97b-dcdfa6838fda\"},\"time\":\"2022-09-30T03:25:03.224Z\",\"type\":\"platform.report\"}"}
```

## Notes
When deploying the Lambda function, be sure to include configure environment variables that the extension will leverage for communicating with the Fluentd endpoint(`FLUENTD_HOST`). This endpoint must be reachable from the Lambda function. This meant, `Lambda need to connect your VPC`.

## References

- https://github.com/aws-samples/aws-lambda-extensions
- https://github.com/fluent/fluent-logger-golang/
