package main

import (
	"io"
	"os"

	"github.com/hennedo/escpos"
)

func main() {
	f, err := os.OpenFile("/dev/usb/lp2", os.O_WRONLY, 0644)
	if err != nil {
		println(err.Error())
	}

	socket := io.Writer(f)
	p := escpos.New(socket)

	p.Size(1, 1).Justify(escpos.JustifyCenter).Write("Unburdened by what has been")
	p.LineFeed()
	p.LineFeedD(13)

	p.Print()
}
