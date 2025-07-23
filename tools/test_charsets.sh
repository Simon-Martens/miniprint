#!/bin/bash

# Test script to print all PC437 and PC858 characters
# to see what's printable on the TM-T88IV

lines=3
esc='\x1b'
gs='\x1d'

echo "Testing PC437 character set..."

# Generate PC437 character set (all 256 characters)
pc437_chars=""
for i in {0..255}; do
    pc437_chars+=$(printf "\\$(printf '%03o' $i)")
done

# Print PC437 test
{
    printf "${esc}M\x01"      # Switch to Font B
    printf "${esc}a\x01"      # Center justify
    printf "=== PC437 CHARACTER SET TEST ===\n"
    printf "Characters 0-31 (control):\n"
    for i in {0..31}; do
        printf "\\$(printf '%03o' $i)"
    done
    printf "\n\nCharacters 32-127 (standard ASCII):\n"
    for i in {32..127}; do
        printf "\\$(printf '%03o' $i)"
    done
    printf "\n\nCharacters 128-255 (extended):\n"
    for i in {128..255}; do
        printf "\\$(printf '%03o' $i)"
        if [ $(($i % 16)) -eq 15 ]; then
            printf "\n"
        fi
    done
    printf "\n${esc}d\x$(printf '%02x' $lines)"  # Feed lines
    printf "${gs}VA\x00"     # Cut paper
} > /dev/usb/lp0

echo "PC437 test printed. Press Enter to continue with PC858..."
read

echo "Testing PC858 character set..."

# Generate UTF-8 text with PC858 characters and convert to PC858
pc858_test="=== PC858 CHARACTER SET TEST ===
Standard ASCII (32-127):
 !\"#\$%&'()*+,-./0123456789:;<=>?
@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_
\`abcdefghijklmnopqrstuvwxyz{|}~

Extended characters (128-255):
ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜø£Ø×ƒ
áíóúñÑªº¿®¬½¼¡«»░▒▓│┤ÁÂÀ©╣║╗╝¢¥┐
└┴┬├─┼ãÃ╚╔╩╦╠═╬¤ðÐÊËÈ€ÍÎÏ┘┌█▄¦Ì▀
ÓßÔÒõÕµþÞÚÛÙýÝ¯´­±‗¾¶§÷¸°¨·¹³²■ "

# Convert to PC858 and print
{
    printf "${esc}M\x01"      # Switch to Font B
    printf "${esc}a\x01"      # Center justify
    echo "$pc858_test" | iconv -f UTF-8 -t CP858//IGNORE 2>/dev/null
    printf "${esc}d\x$(printf '%02x' $lines)"  # Feed lines
    printf "${gs}VA\x00"     # Cut paper
} > /dev/usb/lp0

echo "Both character set tests printed!"
echo "Check the printed output to see which characters display correctly."