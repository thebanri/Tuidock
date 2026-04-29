package ssh

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"time"

	"docker-tui/docker"

	dockerclient "github.com/docker/docker/client"
	"golang.org/x/crypto/ssh"
)

type sshWrapper struct {
	docker.Service
	sshClient *ssh.Client
}

func (w *sshWrapper) Close() error {
	w.Service.Close()
	return w.sshClient.Close()
}

// NewRemoteDockerService creates a Docker service connected via SSH
func NewRemoteDockerService(host, port, user, password string) (docker.Service, error) {
	config := &ssh.ClientConfig{
		User: user,
		Auth: []ssh.AuthMethod{
			ssh.Password(password),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         5 * time.Second,
	}

	addr := fmt.Sprintf("%s:%s", host, port)
	sshClient, err := ssh.Dial("tcp", addr, config)
	if err != nil {
		return nil, fmt.Errorf("ssh dial error: %w", err)
	}

	httpClient := &http.Client{
		Transport: &http.Transport{
			DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
				return sshClient.Dial("unix", "/var/run/docker.sock")
			},
		},
	}

	cli, err := dockerclient.NewClientWithOpts(
		dockerclient.WithHTTPClient(httpClient),
		dockerclient.WithHost("http://localhost"),
		dockerclient.WithAPIVersionNegotiation(),
	)
	if err != nil {
		sshClient.Close()
		return nil, fmt.Errorf("docker client error: %w", err)
	}

	return &sshWrapper{
		Service:   docker.NewServiceFromClient(cli),
		sshClient: sshClient,
	}, nil
}
