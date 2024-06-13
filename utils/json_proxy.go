package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net"
	"os"
	"time"
)

func main() {
	targetPtr := flag.String("target", ":6969", "The port to send data to")

	flag.Parse()

	target := *targetPtr

	data := map[string]interface{}{
		"guid": "12345a",
		"position": map[string]interface{}{
			"x": 100.0,
			"y": 100.0,
		},
	}

	jsonData, err := json.Marshal(data)
	if err != nil {
		fmt.Printf("could not marshal json")
		os.Exit(1)
	}

	udpAddr, err := net.ResolveUDPAddr("udp", target)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to resolve address: %v\n", err)
		os.Exit(1)
	}

	conn, err := net.DialUDP("udp", nil, udpAddr)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to dial UDP: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close()

	for {
		_, err = conn.Write(jsonData)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Failed to send message: %v\n", err)
			os.Exit(1)
		}
		time.Sleep(1 * time.Second)
	}
}
