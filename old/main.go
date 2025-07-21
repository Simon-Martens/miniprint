package main

import (
	"os"
	"strings"
	"syscall"
)

func main() {
	if len(os.Args) <= 1 {
		println("You'll need to provide a text to be printed.")
		os.Exit(-22)
	}

	text := strings.Join(os.Args[1:], " ")

	var lines uint8 = 3
	fd, err := syscall.Open("/dev/usb/lp0", syscall.O_WRONLY|syscall.O_CREAT|syscall.O_TRUNC, 0666)
	if err != nil {
		println("Error opening printer device:", err.Error())
		os.Exit(-1)
	}
	syscall.Write(fd, []byte{esc, 'a', JustifyCenter})
	syscall.Write(fd, []byte(text+"\n"))
	syscall.Write(fd, []byte{esc, 'd', lines})
	syscall.Write(fd, []byte{gs, 'V', 'A', 0x00})
}
