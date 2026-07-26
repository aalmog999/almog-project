package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	helloworldv1 "example.com/proxyless-grpc-client/gen/helloworld/v1"
	"google.golang.org/grpc"
	xdscreds "google.golang.org/grpc/credentials/xds"
	"google.golang.org/grpc/credentials/insecure"
	_ "google.golang.org/grpc/xds"
)

const (
	defaultTarget          = "xds:///grpc-server.utila.svc.cluster.local:50051"
	defaultName            = "Cloud Service Mesh"
	defaultRequestInterval = 5 * time.Second
	defaultRequestTimeout  = 10 * time.Second
)

func main() {
	target := getenv("GRPC_TARGET", defaultTarget)
	name := getenv("HELLO_NAME", defaultName)
	interval := getenvDuration("REQUEST_INTERVAL", defaultRequestInterval)
	timeout := getenvDuration("REQUEST_TIMEOUT", defaultRequestTimeout)

	credentials, err := xdscreds.NewClientCredentials(
		xdscreds.ClientOptions{
			FallbackCreds: insecure.NewCredentials(),
		},
	)
	if err != nil {
		log.Fatalf("create xDS credentials: %v", err)
	}

	connection, err := grpc.NewClient(
		target,
		grpc.WithTransportCredentials(credentials),
	)
	if err != nil {
		log.Fatalf("create gRPC client for %q: %v", target, err)
	}
	defer connection.Close()

	client := helloworldv1.NewGreeterClient(connection)

	ctx, stop := signal.NotifyContext(
		context.Background(),
		syscall.SIGINT,
		syscall.SIGTERM,
	)
	defer stop()

	log.Printf(
		"gRPC client started: target=%q interval=%s",
		target,
		interval,
	)

	callSayHello(ctx, client, name, timeout)

	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			log.Print("shutdown signal received")
			return
		case <-ticker.C:
			callSayHello(ctx, client, name, timeout)
		}
	}
}

func callSayHello(
	parent context.Context,
	client helloworldv1.GreeterClient,
	name string,
	timeout time.Duration,
) {
	ctx, cancel := context.WithTimeout(parent, timeout)
	defer cancel()

	response, err := client.SayHello(
		ctx,
		&helloworldv1.HelloRequest{Name: name},
		grpc.WaitForReady(true),
	)
	if err != nil {
		log.Printf("SayHello failed: %v", err)
		return
	}

	log.Printf("SayHello response: %s", response.GetMessage())
}

func getenv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func getenvDuration(key string, fallback time.Duration) time.Duration {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}

	duration, err := time.ParseDuration(value)
	if err != nil {
		log.Fatalf("%s must be a valid duration: %v", key, err)
	}

	return duration
}
