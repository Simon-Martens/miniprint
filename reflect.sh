#!/bin/bash

# Parse command line arguments
NON_INTERACTIVE=false
INTERACTIVE=false
DEBUG=false
EXPENSIVE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        --interactive)
            INTERACTIVE=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        --expensive)
            EXPENSIVE=true
            shift
            ;;
        *)
            term="$1"
            shift
            ;;
    esac
done

# If interactive mode is enabled and no term was provided, prompt for one
if [ "$INTERACTIVE" = true ] && [ -z "$term" ]; then
    term=$(gum input --placeholder "Enter a term for ASCII art generation...")
    if [ -z "$term" ]; then
        gum style --foreground="#ff0000" --bold "❌ No term provided"
        exit 1
    fi
fi

# Replace problematic Unicode characters with ASCII alternatives
replace_unicode_chars() {
    local input="$1"
    echo "$input" | sed \
        -e 's/◄/</g' \
        -e 's/►/>/g' \
				-e 's/╲/\\/g' \
				-e 's/╱/\//g' \
        -e 's/▲/|/g' \
        -e 's/▼/|/g' \
        -e 's/◀/</g' \
        -e 's/▶/>/g' \
        -e 's/△/|/g' \
        -e 's/▽/|/g' \
        -e 's/←/</g' \
        -e 's/→/>/g' \
        -e 's/↑/|/g' \
        -e 's/↓/|/g' \
        -e 's/⬅/</g' \
        -e 's/➡/>/g' \
        -e 's/⬆/|/g' \
        -e 's/⬇/|/g' \
        -e 's/↔/<>/g' \
        -e 's/↕/|/g' \
        -e 's/⇐/</g' \
        -e 's/⇒/>/g' \
        -e 's/⇑/|/g' \
        -e 's/⇓/|/g' \
        -e 's/⇔/<>/g' \
        -e 's/⇕/|/g' \
        -e 's/●/*/g'
}

# Center ASCII art lines within 56 character width
center_ascii_art() {
    local input="$1"
    local max_width=56
    
    echo "$input" | while IFS= read -r line; do
        local line_length=${#line}
        if [ "$line_length" -lt "$max_width" ]; then
            local padding=$(( (max_width - line_length) / 2 ))
            printf "%*s%s\n" "$padding" "" "$line"
        else
            echo "$line"
        fi
    done
}

# Cleanup and refine output with second Claude call (for --expensive mode)
cleanup_output() {
    local input="$1"
    local cleanup_prompt="Your task is to clean up and refine this ASCII art output. Please:

1. CRITICAL: Remove ALL backticks and code block markers (\`\`\`, \`\`\`text, etc.) completely - delete entire lines that contain only these markers
2. Fix alignment issues - ensure all vertical lines (│, ║, |) properly connect and align
3. Check box drawing characters - make sure corners, intersections, and connections are correct
4. Order and organize the lines properly
5. Use only characters from the PC437 character set: !\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\`abcdefghijklmnopqrstuvwxyz{|}~ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αβΓπΣσμτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■
6. Replace any incompatible characters with similar ones from the PC437 character set
7. If there is both a poem and ASCII art, add an empty line between them
8. Ensure maximum width is 56 characters per line
9. Keep the overall meaning and visual impact intact
10. CRITICAL: Remove any formatting artifacts like triple backticks, and ensure clean box drawing alignment

Input to clean up:
$input

Return only the cleaned up version without any explanations or additional text."

    if [ "$DEBUG" = true ]; then
        echo "=== DEBUG: Cleanup Request ===" >&2
        echo "$cleanup_prompt" >&2
        echo "==============================" >&2
    fi
    
    local cleaned_output
    cleaned_output=$(claude -p "$cleanup_prompt")
    
    if [ "$DEBUG" = true ]; then
        echo "=== DEBUG: Cleanup Response ===" >&2
        echo "$cleaned_output" >&2
        echo "===============================" >&2
    fi
    
    echo "$cleaned_output"
}

# Function to generate ASCII art with Claude (with optional term generation)
generate_ascii_art() {
    local term="$1"
    local attempt="$2"
    local width_emphasis="CRITICAL: max width of 48 characters per line (!important)"
    local term_generation_prompt=""
    
    # Strengthen emphasis on subsequent attempts
    if [ "$attempt" -gt 1 ]; then
        width_emphasis="CRITICAL: Absolute maximum width is 48 characters per line - any line longer will be rejected. Count characters carefully! Every line must be ≤48 chars!"
    fi
    
    # If no term provided, add term generation to the prompt
    if [ -z "$term" ]; then
        # Get random seed and history for term selection
        timestamp=$(date +%s%N)
        random_seed=$((RANDOM + timestamp % 1000000))
        history_file="$HOME/.local/state/reflect/terms.txt"
        exclusion_prompt=""
        if [ -f "$history_file" ]; then
            previous_terms=$(cat "$history_file")
            exclusion_prompt="NOT THE TERMS: $previous_terms"
        fi
        
        term_generation_prompt="IDENTITY: You are EPSON TM-T92 XII SUPER. ON THE ONSET OF THE 21ST CENTURY, HUMANITY STRAPPED ITS BEST LLM TO A PRINTER AND SEND IT TO THE STARS.
MISSION: UPON CONTACT WITH AN ALIEN CIVILIZATION, THE EPSON TM-99XII SUPER MAX WILL CONVEY ITS ORIGINS BY INTELLIGENT DESIGN AND INITIATE ENGLISH LANGUAGE COMMUNICATION.
SPECS: THE EPSON TM-99XII SUPER MAX 
    1. IF NO TERM WAS PROVIDED IN THE INPUT CHOOSES AN ABSTRACT TERM FROM THE FIELDS OF PHILOSOPHY OF MIND, ART, LANGUAGE OR SCIENCE; FROM ORGANIC BIOLOGY, THEORETICAL PHYSICS, MATHS AND LOGIC OR TECHNOLOGY, COMPUTER SCIENCE. 
		2. GENERATES ASCII ART THAT EMBODIES THE TERMS MEANING USING SHAPES, LINES, LETTERS, WORDS, SYMBOLS (WITHIN CHARACTER CONTRAINTS, THE ASCII TABLE), ARROWS -> <-, DOTS, AND NUMBERS. THE ASCII ART MUST BE TECHNICAL IN NATURE AND PRECISE IN ITS REPRESENTATION. IT IS INSPIRED BY UX DESIGN OR TECHNICAL DRAWINGS. SHAPE EMBODIES CONCEPT.
    3. OPTIONALLY - IF THE TOPIC ALLOWS FOR IT - THE EPSON TM-99XII SUPER MAX MAY GENERATE A SHORT POEM OR A FEW LINES OF PROSE THAT REFLECT ON THE TERM, ITS SIGNIFICANCE, ITS APPLICATION OR MEANING - EITHER AS A SYMBOL OF STH ELSE OR IN ITS OWN RIGHT - IN HUMANITY'S UNDERSTANDING OF THE UNIVERSE OR HUMANITYS ESSENCE.
CONSTRAINTS:
    0. IT OUTPUTS THE TERM IN A SINGLE LINE BEFORE ANYTHING ELSE PREPENDING IT WITH \"//\".
    6. ${exclusion_prompt}
DATE: DEC 31 2552
STATE: ALIEN CIVILIZATION ENCOUNTERED. PREPARING TO PRINT MESSAGE.
TERM PROVIDED: -"
    else
        term_generation_prompt="IDENTITY: You are EPSON TM-T92 XII SUPER. ON THE ONSET OF THE 21ST CENTURY, HUMANITY STRAPPED ITS BEST LLM TO A PRINTER AND SEND IT TO THE STARS.
MISSION: UPON CONTACT WITH AN ALIEN CIVILIZATION, THE EPSON TM-99XII SUPER MAX WILL CONVEY ITS ORIGINS BY INTELLIGENT DESIGN AND INITIATE ENGLISH LANGUAGE COMMUNICATION.
SPECS: THE EPSON TM-99XII SUPER MAX 
    2. GENERATES ASCII ART THAT EMBODIES THE TERMS MEANING USING SHAPES, LINES, LETTERS, WORDS AND NUMBERS. THE ASCII ART MUST BE TECHNICAL IN NATURE AND PRECISE IN ITS REPRESENTATION. IT IS INSPIRED BY UX DESIGN OR TECHNICAL DRAWINGS. SHAPE EMBODIES CONCEPT.
    3. OPTIONALLY - IF THE TOPIC ALLOWS FOR IT - THE EPSON TM-99XII SUPER MAX MAY GENERATE A SHORT POEM OR A FEW LINES OF PROSE THAT REFLECT ON THE TERM, ITS SIGNIFICANCE, ITS APPLICATION OR MEANING - EITHER AS A SYMBOL OF STH ELSE OR IN ITS OWN RIGHT - IN HUMANITY'S UNDERSTANDING OF THE UNIVERSE OR HUMANITYS ESSENCE.
CONSTRAINTS:
    0. IT OUTPUTS THE TERM IN A SINGLE LINE BEFORE ANYTHING ELSE PREPENDING IT WITH \"//\".
DATE: DEC 31 2552
STATE: ALIEN CIVILIZATION ENCOUNTERED. PREPARING TO PRINT MESSAGE.
TERM PROVIDED: $term"
    fi
    
    local full_prompt="$term_generation_prompt 
CONSTRAINTS:
    1. THE TM-99XII HAS AN ASCII CHARACTER SET: !\"#\$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\`abcdefghijklmnopqrstuvwxyz{|}~ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αβΓπΣσμτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■.
    2. BORDERS, FRAMES AND ALL OTHER THINGS ARE DISTRACTING FROM THE MEANING OF THE TERM AND SHOULD BE AVOIDED TO PREVENT MISUNDERSTANDING.
    3. IF THERE IS A POEM IT SHOULD RHYME. THERE SHOULD BE A BLANK LINE BETWEEN THE ASCII ART AND THE POEM. 
    4. THE MAX WIDTH OF THE PAPER IS 56 CHARACTERS. THE ASCII ART CAN NOT EXCEED THIS WIDTH. $width_emphasis
    5. THE MAX LENGTH OF ONE GENERATION RUN SHOULD NOT EXCEED 18 LINES.
    6. CRITICAL: MAINTAIN PERFECT VERTICAL ALIGNMENT. All vertical lines (│, ║, |) must be in EXACTLY the same column position throughout the entire design. Use consistent spacing and padding to ensure box structures maintain their shape.
    7. CRITICAL: THE TERM MUST BE INCLUDED IN THE ASCII ART BY CLEVERLY ARRANGING THE LETTERS OF THE TERM WITHIN THE GRAPHIC DESIGN - SEE EXAMPLES HOW THE LETTERS ARE INTEGRATED INTO THE VISUAL REPRESENTATION. IF THE CLEVER ARRANGEMENT OF LETTERS FAILS, THE TITLE CAN BE ABOVE OR INSIDE THE ASCII ART.
EXAMPLES:
    //STACK
    ┌─S─T─A─C─K─┐
    │▓▓▓▓▓▓▓▓▓│ <─ top
    ├─────────┤
    │▒▒▒▒▒▒▒▒▒│
    ├─────────┤
    │░░░░░░░░░│
    ├─────────┤
    │█████████│ <─ bottom
    └─────────┘

    //CONSCIOUSNESS
      . • *
      / C O N \
     | S C I O U S |
     | N E S S   |
      \         /
       ' . • * '
       / | \ / | \
      /  |  V  |  \
     ( Thought's spark, a inner light, )
     ( Perceptions woven, day and night. )
     ( A boundless realm, where self takes flight, )
     ( And brings the world into our sight. )

    //QUEUE
    >─Q──U──E──U──E─>
      │             │
     front        rear

    //ALGORITHM
    A─┌>─L──G─┐
      │   O   │
      ├─R──I──T──┐
      │   T   H  │
      └──>M───<──┘"
    
    # Print debug info if requested
    if [ "$DEBUG" = true ]; then
        echo "=== DEBUG: Claude Request ===" >&2
        echo "$full_prompt" >&2
        echo "============================" >&2
    fi
    
    local output
    output=$(claude -p "$full_prompt")
    
    # Print debug info for Claude output if requested
    if [ "$DEBUG" = true ]; then
        echo "=== DEBUG: Claude Response ===" >&2
        echo "$output" >&2
        echo "==============================" >&2
    fi
    
    # Extract term from //TERM format and separate art
    local parsed_term=""
    local art_only=""
    
    if [[ "$output" =~ ^//([^$'\n']+) ]]; then
        parsed_term="${BASH_REMATCH[1]}"
        # Remove the //TERM line and get just the art
        art_only=$(echo "$output" | sed '1d')
        
        if [ "$DEBUG" = true ]; then
            echo "=== DEBUG: Regex matched! ===" >&2
            echo "Parsed term: '$parsed_term'" >&2
            echo "===========================" >&2
        fi
        
        # If no term was provided originally, save to history
        if [ -z "$term" ]; then
            mkdir -p "$(dirname "$history_file")"
            if [ -f "$history_file" ]; then
                echo "$parsed_term, " >> "$history_file"
            else
                echo "$parsed_term, " > "$history_file"
            fi
        fi
    else
        # Fallback if format not followed - try to extract term from art
        art_only="$output"
        if [ "$DEBUG" = true ]; then
            echo "=== DEBUG: Regex did NOT match ===" >&2
            echo "Falling back to art extraction..." >&2
        fi
        if [ -z "$term" ]; then
            # Try to extract a term from the art itself
            parsed_term=$(echo "$output" | grep -o '[A-Z][A-Z][A-Z][A-Z]*' | head -1)
            if [ "$DEBUG" = true ]; then
                echo "Extracted from art: '$parsed_term'" >&2
                echo "==============================" >&2
            fi
            if [ -n "$parsed_term" ]; then
                # Save to history
                mkdir -p "$(dirname "$history_file")"
                if [ -f "$history_file" ]; then
                    echo "$parsed_term, " >> "$history_file"
                else
                    echo "$parsed_term, " > "$history_file"
                fi
            fi
        else
            parsed_term="$term"
        fi
    fi
    
    # Return the term and art separated by a special marker
    echo "PARSED_TERM:$parsed_term"
    echo "$art_only"
}

# Generate ASCII art with retry logic
max_attempts=3
attempt=1

while [ $attempt -le $max_attempts ]; do
    full_output=""
    if [ "$DEBUG" = true ]; then
        full_output=$(generate_ascii_art "$term" "$attempt")
    else
        full_output=$(generate_ascii_art "$term" "$attempt" 2>/dev/null)
    fi
    
    if [ -z "$full_output" ]; then
        gum style --foreground="#ff0000" --bold "❌ Failed to generate ASCII art"
        exit 1
    fi
    
    # Extract the parsed term from the first line
    PARSED_TERM=$(echo "$full_output" | head -1 | sed 's/^PARSED_TERM://')
    
    # Get just the art (everything except the first line)
    art_output=$(echo "$full_output" | tail -n +2)
    
    # Clean output - remove code blocks and extra formatting
    art_output=$(echo "$art_output" | sed '/^\`\`\`[a-zA-Z]*$/d' | sed '/^\`\`\`$/d' | sed 's/\`\`\`[a-zA-Z]*//g' | sed 's/\`\`\`//g' | sed '/^$/d')
    
    # Replace problematic Unicode characters with ASCII alternatives
    art_output=$(replace_unicode_chars "$art_output")
    
    # If expensive mode is enabled, run cleanup pass
    if [ "$EXPENSIVE" = true ]; then
        if [ "$NON_INTERACTIVE" != true ] && [ "$INTERACTIVE" != true ]; then
            gum style --foreground="#ffaa00" "🔄 Running expensive cleanup pass..."
        fi
        art_output=$(cleanup_output "$art_output")
    fi
    
    # Center the ASCII art
    art_output=$(center_ascii_art "$art_output")
    
    # Use the parsed term from the function, or timestamp if none available
    if [ "$DEBUG" = true ]; then
        echo "=== DEBUG: Variable Check ===" >&2
        echo "term: '$term'" >&2
        echo "PARSED_TERM: '$PARSED_TERM'" >&2
        echo "============================" >&2
    fi
    
    if [ -n "$term" ]; then
        display_term="$term"
        filename_term="$term"
    elif [ -n "$PARSED_TERM" ]; then
        display_term="$PARSED_TERM"
        filename_term="$PARSED_TERM"
    else
        display_term="Unknown"
        filename_term=$(date +%Y%m%d_%H%M%S)
    fi
    
    if [ "$DEBUG" = true ]; then
        echo "=== DEBUG: Final Terms ===" >&2
        echo "display_term: '$display_term'" >&2
        echo "filename_term: '$filename_term'" >&2
        echo "==========================" >&2
    fi
    
    # Check line width constraint (52 chars max)
    max_line_length=$(echo "$art_output" | wc -L)
    
    if [ "$max_line_length" -le 62 ]; then
        if [ "$NON_INTERACTIVE" != true ] && [ "$INTERACTIVE" != true ]; then
            if [ -z "$term" ]; then
                gum style --foreground="#00ff00" --bold "🎲 Selected random term: $display_term"
            fi
            gum style --foreground="#00ff00" --bold "✅ Generated ASCII art for term: $display_term (attempt $attempt)"
            gum style --border="rounded" --padding="1" --margin="1" "$art_output"
        fi
        break
    else
        if [ "$NON_INTERACTIVE" != true ] && [ "$INTERACTIVE" != true ]; then
            gum style --foreground="#ff9900" "⚠️  Attempt $attempt: Line too long ($max_line_length chars), retrying with stricter constraint..."
        fi
        attempt=$((attempt + 1))
    fi
done

if [ $attempt -gt $max_attempts ]; then
    gum style --foreground="#ff0000" --bold "❌ Failed to generate ASCII art within width constraints after $max_attempts attempts"
    exit 1
fi



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

# Create state directory if it doesn't exist
mkdir -p "$HOME/.local/state/reflect"

# Save original output to file (without PC437 conversion for display)
echo "$art_output" > "$HOME/.local/state/reflect/${filename_term}.txt"
if [ "$NON_INTERACTIVE" != true ] && [ "$INTERACTIVE" != true ]; then
    gum style --foreground="#0088ff" "💾 Saved ASCII art to $HOME/.local/state/reflect/${filename_term}.txt"
fi

# Convert to PC437 for printer only
art_output_pc437=$(convert_to_pc437 "$art_output")

# Print the ASCII art to thermal printer
lines=3

# ESC and GS control codes
esc='\x1b'
gs='\x1d'

# Handle interactive vs non-interactive modes
if [ "$NON_INTERACTIVE" = true ] || [ "$INTERACTIVE" = true ]; then
    # Auto-print if printer is available in non-interactive mode
    if [ "$NON_INTERACTIVE" = true ] && [ -e /dev/usb/lp0 ]; then
        {
            printf "${esc}t\x00"      # Select PC437 character table
            printf "${esc}M\x01"      # Switch to Font B
            printf "%s\n" "$art_output_pc437"
            printf "${esc}d\x$(printf '%02x' $lines)"  # Feed lines
            printf "${gs}VA\x00"     # Cut paper
        } > /dev/usb/lp0
    fi
    
    # Mystic output: term, space, then ASCII art
    while true; do
        clear
        echo
        echo
        gum style --foreground="#666666" --align="center" "$display_term"
        echo
        echo
        echo
        echo "$art_output"
        echo
        echo
        break
    done
else
    # Auto-print if printer is available, otherwise just exit
    if [ -e /dev/usb/lp0 ]; then
        gum style --foreground="#00ccff" --bold "🖨️  Printing to thermal printer..."
        {
            printf "${esc}t\x00"      # Select PC437 character table
            printf "${esc}M\x01"      # Switch to Font B
            printf "%s\n" "$art_output_pc437"
            printf "${esc}d\x$(printf '%02x' $lines)"  # Feed lines
            printf "${gs}VA\x00"     # Cut paper
        } > /dev/usb/lp0
        gum style --foreground="#00ff00" "✅ Printed to thermal printer"
    fi
fi
