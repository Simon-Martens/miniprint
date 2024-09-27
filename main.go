package main

import (
	"io"
	"os"
	"strings"

	"github.com/hennedo/escpos"
)

func main() {
	if len(os.Args) <= 1 {
		println("You'll need to provide a text to be printed.")
		os.Exit(-22)
	}

	text := strings.Join(os.Args[1:], " ")

	f, err := os.OpenFile("/dev/usb/lp2", os.O_WRONLY, 0644)
	if err != nil {
		println(err.Error())
	}

	socket := io.Writer(f)
	p := escpos.New(socket)

	p.Size(1, 1).Justify(escpos.JustifyCenter).WriteWEU(text)
	p.LineFeed()
	p.LineFeedD(3)

	p.PrintAndCut()
}
