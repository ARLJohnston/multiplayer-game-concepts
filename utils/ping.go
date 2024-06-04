package main

import (
	"fmt"
	"net"
	"os"
)

func main() {
	// The message to be sent
	message := []byte("Hello, World!")

	// Resolve the UDP address
	udpAddr, err := net.ResolveUDPAddr("udp", "localhost:5050")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to resolve address: %v\n", err)
		os.Exit(1)
	}

	// Create a UDP connection
	conn, err := net.DialUDP("udp", nil, udpAddr)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to dial UDP: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close()

	// Send the message
	_, err = conn.Write(message)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to send message: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Message sent successfully")
}
