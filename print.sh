#!/bin/bash

# Convert UTF-8 to PC437 encoding
convert_to_pc437() {
    local input="$1"
    # Convert only non-ASCII Unicode characters to PC437 equivalents
    # Leave basic ASCII (including / and \) completely untouched
    echo "$input" | sed \
        -e 's/Ç/\o200/g' -e 's/ü/\o201/g' -e 's/é/\o202/g' -e 's/â/\o203/g' -e 's/ä/\o204/g' -e 's/à/\o205/g' -e 's/å/\o206/g' -e 's/ç/\o207/g' \
        -e 's/ê/\o210/g' -e 's/ë/\o211/g' -e 's/è/\o212/g' -e 's/ï/\o213/g' -e 's/î/\o214/g' -e 's/ì/\o215/g' -e 's/Ä/\o216/g' -e 's/Å/\o217/g' \
        -e 's/É/\o220/g' -e 's/æ/\o221/g' -e 's/Æ/\o222/g' -e 's/ô/\o223/g' -e 's/ö/\o224/g' -e 's/ò/\o225/g' -e 's/û/\o226/g' -e 's/ù/\o227/g' \
        -e 's/ÿ/\o230/g' -e 's/Ö/\o231/g' -e 's/Ü/\o232/g' -e 's/¢/\o233/g' -e 's/£/\o234/g' -e 's/¥/\o235/g' -e 's/₧/\o236/g' -e 's/ƒ/\o237/g' \
        -e 's/á/\o240/g' -e 's/í/\o241/g' -e 's/ó/\o242/g' -e 's/ú/\o243/g' -e 's/ñ/\o244/g' -e 's/Ñ/\o245/g' -e 's/ª/\o246/g' -e 's/º/\o247/g' \
        -e 's/¿/\o250/g' -e 's/⌐/\o251/g' -e 's/¬/\o252/g' -e 's/½/\o253/g' -e 's/¼/\o254/g' -e 's/¡/\o255/g' -e 's/«/\o256/g' -e 's/»/\o257/g' \
        -e 's/░/\o260/g' -e 's/▒/\o261/g' -e 's/▓/\o262/g' -e 's/│/\o263/g' -e 's/┤/\o264/g' -e 's/╡/\o265/g' -e 's/╢/\o266/g' -e 's/╖/\o267/g' \
        -e 's/╕/\o270/g' -e 's/╣/\o271/g' -e 's/║/\o272/g' -e 's/╗/\o273/g' -e 's/╝/\o274/g' -e 's/╜/\o275/g' -e 's/╛/\o276/g' -e 's/┐/\o277/g' \
        -e 's/└/\o300/g' -e 's/┴/\o301/g' -e 's/┬/\o302/g' -e 's/├/\o303/g' -e 's/─/\o304/g' -e 's/┼/\o305/g' -e 's/╞/\o306/g' -e 's/╟/\o307/g' \
        -e 's/╚/\o310/g' -e 's/╔/\o311/g' -e 's/╩/\o312/g' -e 's/╦/\o313/g' -e 's/╠/\o314/g' -e 's/═/\o315/g' -e 's/╬/\o316/g' -e 's/╧/\o317/g' \
        -e 's/╨/\o320/g' -e 's/╤/\o321/g' -e 's/╥/\o322/g' -e 's/╙/\o323/g' -e 's/╘/\o324/g' -e 's/╒/\o325/g' -e 's/╓/\o326/g' -e 's/╫/\o327/g' \
        -e 's/╪/\o330/g' -e 's/┘/\o331/g' -e 's/┌/\o332/g' -e 's/█/\o333/g' -e 's/▄/\o334/g' -e 's/▌/\o335/g' -e 's/▐/\o336/g' -e 's/▀/\o337/g' \
        -e 's/α/\o340/g' -e 's/β/\o341/g' -e 's/Γ/\o342/g' -e 's/π/\o343/g' -e 's/Σ/\o344/g' -e 's/σ/\o345/g' -e 's/μ/\o346/g' -e 's/τ/\o347/g' \
        -e 's/Φ/\o350/g' -e 's/Θ/\o351/g' -e 's/Ω/\o352/g' -e 's/δ/\o353/g' -e 's/∞/\o354/g' -e 's/φ/\o355/g' -e 's/ε/\o356/g' -e 's/∩/\o357/g' \
        -e 's/≡/\o360/g' -e 's/±/\o361/g' -e 's/≥/\o362/g' -e 's/≤/\o363/g' -e 's/⌠/\o364/g' -e 's/⌡/\o365/g' -e 's/÷/\o366/g' -e 's/≈/\o367/g' \
        -e 's/°/\o370/g' -e 's/∙/\o371/g' -e 's/·/\o372/g' -e 's/√/\o373/g' -e 's/ⁿ/\o374/g' -e 's/²/\o375/g' -e 's/■/\o376/g'
}

# Variable to hold the text to be printed
text=""

# Check if input is being piped (stdin is not a terminal)
if [ -p /dev/stdin ] || [ ! -t 0 ]; then
    # Read all of stdin into the 'text' variable
    # Using 'cat /dev/stdin' is a robust way to read all piped input
    text=$(cat /dev/stdin)
elif [ $# -gt 0 ]; then
    # If no pipe, check for command-line arguments
    text="$*"
else
    # No input from pipe or arguments
    echo "You'll need to provide text to be printed."
    echo "Usage: $0 <text to print>"
    echo "       cat <file> | $0"
    exit 22
fi

# If 'text' is still empty after checks (e.g., empty pipe input)
if [ -z "$text" ]; then
    echo "Error: No text provided to print."
    echo "Usage: $0 <text to print>"
    echo "       cat <file> | $0"
    exit 22
fi

echo "Printing: \"$text\""
lines=3 # This variable seems to control line feeds, keep its original value

# ESC and GS control codes
esc='\x1b'
gs='\x1d'

# Convert the determined text to PC437
art_output_pc437=$(convert_to_pc437 "$text")

# Write to printer
if [ -e /dev/usb/lp0 ]; then
    {
        printf "${esc}t\x00"     # Select PC437 character table
        printf "${esc}M\x01"     # Switch to Font B
        printf "%s\n" "$art_output_pc437"
        printf "${esc}d\x$(printf '%02x' $lines)" # Feed lines
        printf "${gs}VA\x00"     # Cut paper
    } > /dev/usb/lp0
else
    echo "Printer device /dev/usb/lp0 not found. Outputting to stdout instead:"
    printf "${esc}t\x00"     # Select PC437 character table
    printf "${esc}M\x01"     # Switch to Font B
    printf "%s\n" "$art_output_pc437"
    printf "${esc}d\x$(printf '%02x' $lines)" # Feed lines
    printf "${gs}VA\x00"     # Cut paper
fi
