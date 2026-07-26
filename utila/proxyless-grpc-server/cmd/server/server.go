package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"

	helloworldv1 "example.com/proxyless-grpc-server/gen/helloworld/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"
)

const listenAddress = ":50051"

type greeterServer struct {
	helloworldv1.UnimplementedGreeterServer
	hostname string
}

func (s *greeterServer) SayHello(
	_ context.Context,
	request *helloworldv1.HelloRequest,
) (*helloworldv1.HelloReply, error) {
	name := request.GetName()
	if name == "" {
		name = "world"
	}

	log.Printf("SayHello request received: name=%q", name)

	return &helloworldv1.HelloReply{
		Message: fmt.Sprintf("Hello %s, from %s", name, s.hostname),
	}, nil
}

func main() {
	hostname, err := os.Hostname()
	if err != nil {
		log.Fatalf("get hostname: %v", err)
	}

	listener, err := net.Listen("tcp", listenAddress)
	if err != nil {
		log.Fatalf("listen on %s: %v", listenAddress, err)
	}

	grpcServer := grpc.NewServer()

	helloworldv1.RegisterGreeterServer(
		grpcServer,
		&greeterServer{hostname: hostname},
	)

	// Cloud Service Mesh uses the standard gRPC health-checking protocol
	// to decide whether this backend should receive requests.
	healthServer := health.NewServer()
	healthpb.RegisterHealthServer(grpcServer, healthServer)
	healthServer.SetServingStatus(
		"",
		healthpb.HealthCheckResponse_SERVING,
	)
	healthServer.SetServingStatus(
		helloworldv1.Greeter_ServiceDesc.ServiceName,
		healthpb.HealthCheckResponse_SERVING,
	)

	shutdownSignals := make(chan os.Signal, 1)
	signal.Notify(
		shutdownSignals,
		syscall.SIGINT,
		syscall.SIGTERM,
	)

	go func() {
		<-shutdownSignals
		log.Print("shutdown signal received")

		healthServer.SetServingStatus(
			"",
			healthpb.HealthCheckResponse_NOT_SERVING,
		)
		healthServer.SetServingStatus(
			helloworldv1.Greeter_ServiceDesc.ServiceName,
			healthpb.HealthCheckResponse_NOT_SERVING,
		)

		grpcServer.GracefulStop()
	}()

	log.Printf(
		"gRPC server %q listening on %s",
		hostname,
		listenAddress,
	)

	if err := grpcServer.Serve(listener); err != nil &&
		!errors.Is(err, grpc.ErrServerStopped) {
		log.Fatalf("serve gRPC: %v", err)
	}
}
