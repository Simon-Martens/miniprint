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
	fd, _ := syscall.Open("/dev/usb/lp2", syscall.O_WRONLY|syscall.O_CREAT|syscall.O_TRUNC, 0666)
	syscall.Write(fd, []byte{esc, 'a', JustifyCenter})
	syscall.Write(fd, []byte(text+"\n"))
	syscall.Write(fd, []byte{esc, 'd', lines})
	syscall.Write(fd, []byte{gs, 'V', 'A', 0x00})

	// if err != nil {
	// 	println(err.Error())
	// }
	//
	// defer f.Close()
	// l := io.Writer(f)
	// p := New(l)
	//
	// fmt.Printf("Overall: %d", len([]byte(text)))
	//
	// i, err := p.Write(text)
	// if err != nil {
	// 	fmt.Println(err)
	// }
	//
	// fmt.Printf("Written: %d", i)
	//
	// if err != nil {
	// 	fmt.Println(err)
	// }
	// p.Print()
	// p.Print()
	// p.LineFeed()
	// p.Print()
	// p.Cut()
}
