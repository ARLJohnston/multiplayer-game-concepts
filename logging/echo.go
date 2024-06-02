package main

import (
	"flag"
	"fmt"
	"io"
	"net"
)

func main() {
	targetPtr := flag.String("target", ":5050", "The port to listen to")

	flag.Parse()

	target := *targetPtr

	udp_addr, err := net.ResolveUDPAddr("udp", target)

	listener, err := net.ListenUDP("udp", udp_addr)
	if err != nil {
		fmt.Println(err)
		return
	}
	defer listener.Close()

	fmt.Println("Listening on: ", target)

	for {
		p := make([]byte, 1024)
		nn, raddr, err := listener.ReadFromUDP(p)
		if err != nil {
			fmt.Printf("Read err  %v", err)
			continue
		}

		msg := p[:nn]
		fmt.Printf("Received %v %s\n", raddr, msg)
	}
}
