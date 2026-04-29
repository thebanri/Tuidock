package main

import (
	"fmt"
	"os"

	"docker-tui/docker"
	"docker-tui/ui"

	tea "github.com/charmbracelet/bubbletea"
)

func main() {
	ds, err := docker.NewLocalDockerService()
	if err != nil {
		fmt.Printf("Error connecting to local docker daemon: %v\n", err)
		// We don't exit immediately because they might want to use SSH only
	}

	m := ui.NewAppModel(ds)
	p := tea.NewProgram(m, tea.WithAltScreen())

	if _, err := p.Run(); err != nil {
		fmt.Printf("Error running TUI: %v\n", err)
		os.Exit(1)
	}
}
