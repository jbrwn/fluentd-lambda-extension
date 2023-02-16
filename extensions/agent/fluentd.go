package agent

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/fluent/fluent-logger-golang/fluent"
	log "github.com/sirupsen/logrus"
)

var logger = log.WithFields(log.Fields{"agent": "logsApiAgent"})

const (
	MaxRetries = 3
)

type FluentdLogger struct {
	svc          *fluent.Fluent
	functionName string
	tag          string
}

func GetEnv(key, fallback string) string {
	value, present := os.LookupEnv(key)
	if !present {
		return fallback
	}
	return value
}

func NewFluentdLogger() (*FluentdLogger, error) {
	functionName := strings.ToLower(os.Getenv("AWS_LAMBDA_FUNCTION_NAME"))
	fluentdHost := GetEnv("FLUENTD_HOST", "localhost")
	fluentdTagSuffix := GetEnv("FLUENTD_TAG_SUFFIX", "es.log")
	fluentdPort, err := strconv.Atoi(GetEnv("FLUENTD_PORT", "24224"))
	if err != nil {
		logger.Fatal(err)
	}

	fmt.Printf("Sending logs to host: %s, port: %d", fluentdHost, fluentdPort)

	f, err := fluent.New(fluent.Config{
		FluentPort: fluentdPort,
		FluentHost: fluentdHost,
		TagPrefix:  functionName,
		MaxRetry:   MaxRetries,
	})

	if err != nil {
		logger.Fatal(err)
	}

	return &FluentdLogger{
		svc:          f,
		functionName: functionName,
		tag:          fluentdTagSuffix,
	}, nil
}

func (l *FluentdLogger) PushLog(log string) error {
	var data = map[string]string{
		"function_name": l.functionName,
		"msg":           log,
	}
	err := l.svc.Post(l.tag, data)
	if err != nil {
		logger.Fatal(err)
	}
	return nil
}

func (l *FluentdLogger) Shutdown() error {
	return l.svc.Close()
}
