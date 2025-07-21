#!/bin/bash

if [ $# -eq 0 ]; then
    echo "You'll need to provide a text to be printed."
		echo "Usage: $0 <text to print>"
    exit 22
fi

echo "Printing: $*" 
text="$*"
lines=3

# ESC and GS control codes
esc='\x1b'
gs='\x1d'

# Write to printer
{
    printf "${esc}a\x01"      # Center justify
    printf "%s\n" "$text"
    printf "${esc}d\x$(printf '%02x' $lines)"  # Feed lines
    printf "${gs}VA\x00"     # Cut paper
} > /dev/usb/lp0
