#!/bin/bash

# Configuration
MAX_WIDTH=56  # Maximum width for ASCII art and footer

# Parse command line arguments
NON_INTERACTIVE=false
DEBUG=false
EXPENSIVE=false
CLAUDE_POEM=false
USE_CLAUDE=false
DISPLAY_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --non-interactive)
            NON_INTERACTIVE=true
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
        --claude-poem)
            CLAUDE_POEM=true
            shift
            ;;
        --claude)
            USE_CLAUDE=true
            shift
            ;;
        --display)
            if [[ -n "$2" && "$2" != --* ]]; then
                DISPLAY_FILE="$2"
                shift 2
            else
                DISPLAY_FILE="SELECT"
                shift
            fi
            ;;
        *)
            term="$1"
            shift
            ;;
    esac
done

# Function definitions (needed early for --display functionality)

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

# ESC and GS control codes
esc='\x1b'
gs='\x1d'
lines=3

# Generate footer with EP TM-99XIISM branding and modified date
generate_footer() {
    local max_width=$MAX_WIDTH
    local left_text="EP TM-99XIISM * PRTECTED"
    local current_date=$(date +"%m/%d/2552T%H:%MH")
    local right_text="$current_date"
    
    # Calculate padding needed between left and right text
    local left_length=${#left_text}
    local right_length=${#right_text}
    local total_content_length=$((left_length + right_length))
    local padding_needed=$((max_width - total_content_length))
    
    # Ensure minimum padding of 1 space
    if [ $padding_needed -lt 1 ]; then
        padding_needed=1
    fi
    
    # Generate the padding spaces
    local padding=$(printf "%*s" $padding_needed "")
    
    # Create the footer line
    echo "${left_text}${padding}${right_text}"
}

# Function to print to thermal printer
print_to_printer() {
    local content="$1"
    local content_pc437=$(convert_to_pc437 "$content")
    
    if [ -e /dev/usb/lp0 ]; then
        gum style --foreground="#00ccff" --bold "🖨️  Printing to thermal printer..."
        {
            printf "${esc}t\x00"      # Select PC437 character table
            printf "${esc}M\x01"      # Switch to Font B
            printf "%s\n" "$content_pc437"
            printf "${esc}d\x$(printf '%02x' $lines)"  # Feed lines
            printf "${gs}VA\x00"     # Cut paper
        } > /dev/usb/lp0
        gum style --foreground="#00ff00" "✅ Printed to thermal printer"
    else
        gum style --foreground="#ff9900" "⚠️  Printer not found at /dev/usb/lp0"
    fi
}

# Handle --display flag
if [ -n "$DISPLAY_FILE" ]; then
    state_dir="$HOME/.local/state/reflect"
    
    # Create state directory if it doesn't exist
    mkdir -p "$state_dir"
    
    # Check if there are any files in the state directory
    if ! ls "$state_dir"/*.txt >/dev/null 2>&1; then
        gum style --foreground="#ff0000" --bold "❌ No cached files found in $state_dir"
        exit 1
    fi
    
    # Handle file selection
    if [ "$DISPLAY_FILE" = "SELECT" ]; then
        # Use gum filter to select from available files
        # Create a temporary file to store the mapping between display names and actual filenames
        temp_mapping=$(mktemp)
        
        # Build list of files for selection, handling spaces properly
        while IFS= read -r -d '' filepath; do
            basename_with_ext=$(basename "$filepath")
            display_name="${basename_with_ext%.txt}"
            echo "$display_name|$filepath" >> "$temp_mapping"
        done < <(find "$state_dir" -name "*.txt" -print0 2>/dev/null)
        
        if [ ! -s "$temp_mapping" ]; then
            rm "$temp_mapping"
            gum style --foreground="#ff0000" --bold "❌ No cached files found"
            exit 1
        fi
        
        # Show only the display names for selection
        selected_display=$(cut -d'|' -f1 "$temp_mapping" | gum filter --placeholder="Select a cached term...")
        
        if [ -z "$selected_display" ]; then
            rm "$temp_mapping"
            gum style --foreground="#ff9900" "No file selected"
            exit 0
        fi
        
        # Get the actual file path
        file_path=$(grep "^$selected_display|" "$temp_mapping" | cut -d'|' -f2)
        selected_file="$selected_display"
        rm "$temp_mapping"
        
        if [ ! -f "$file_path" ]; then
            gum style --foreground="#ff0000" --bold "❌ File not found: $file_path"
            exit 1
        fi
    else
        # Use provided filename, trim spaces
        trimmed_filename=$(echo "$DISPLAY_FILE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        file_path="$state_dir/${trimmed_filename}.txt"
        
        # If exact match doesn't exist, try to find files with spaces
        if [ ! -f "$file_path" ]; then
            # Look for files that might have spaces before/after the name
            found_file=$(find "$state_dir" -name "*.txt" -exec basename {} .txt \; 2>/dev/null | grep -F "$trimmed_filename" | head -1)
            if [ -n "$found_file" ]; then
                file_path="$state_dir/${found_file}.txt"
            fi
        fi
        
        if [ ! -f "$file_path" ]; then
            gum style --foreground="#ff0000" --bold "❌ File not found: $file_path"
            gum style --foreground="#666666" "Looked for: $state_dir/${trimmed_filename}.txt"
            exit 1
        fi
        
        selected_file="$trimmed_filename"
    fi
    
    # Read the file content
    art_content=$(cat "$file_path")
    
    # Display loop
    while true; do
        echo
        echo
        gum style --foreground="#666666" --align="center" "$selected_file"
        echo
        echo
        echo
        echo "$art_content"
        echo
        echo
        
        gum style --foreground="#888888" \
            "• Press any key to exit" \
            "• 'e' to edit with nvim" \
            "• 'r' to refine with expensive cleanup" \
            "• 'p' to print to thermal printer" \
            "• 'f' to add footer"
        read -n 1 -r choice
        echo
        
        case $choice in
            e|E)
                # Edit with nvim
                temp_file=$(mktemp)
                echo "$art_content" > "$temp_file"
                nvim "$temp_file"
                art_content=$(cat "$temp_file")
                rm "$temp_file"
                
                # Save the edited content back to the file
                echo "$art_content" > "$file_path"
                gum style --foreground="#0088ff" "💾 Saved changes to $file_path"
                ;;
            r|R)
                # Run expensive cleanup on current content
                gum style --foreground="#ffaa00" "🔄 Running expensive cleanup pass..."
                art_content=$(cleanup_output "$art_content")
                
                # Save the refined content back to the file
                echo "$art_content" > "$file_path"
                gum style --foreground="#0088ff" "💾 Saved refined version to $file_path"
                ;;
            p|P)
                # Convert to PC437 and print
                print_to_printer "$art_content"
                break
                ;;
            f|F)
                # Add footer and save to file
                footer=$(generate_footer)
                art_content="$art_content


$footer"
                echo "$art_content" > "$file_path"
                gum style --foreground="#0088ff" "📄 Added footer and saved to $file_path"
                ;;
            *)
                break
                ;;
        esac
    done
    
    exit 0
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
        -e 's/╭/|/g' \
        -e 's/╰/-/g' \
        -e 's/╯/-/g' \
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
        -e 's/╮/|/g' \
        -e 's/↔/<>/g' \
        -e 's/↕/|/g' \
        -e 's/⇐/</g' \
        -e 's/⇒/>/g' \
        -e 's/╭/-/g' \
        -e 's/⇑/|/g' \
        -e 's/⇓/|/g' \
        -e 's/⇔/<>/g' \
        -e 's/⇕/|/g' \
        -e 's/◦/*/g' \
        -e 's/●/*/g'
}

# Center ASCII art lines within configured character width
center_ascii_art() {
    local input="$1"
    local max_width=$MAX_WIDTH
    
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
8. Ensure maximum width is $MAX_WIDTH characters per line
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
    
    # Escape backslashes and quotes in the cleanup prompt
    local escaped_cleanup_prompt=$(printf '%s\n' "$cleanup_prompt" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    
    local cleaned_output
    if [ "$USE_CLAUDE" = true ]; then
        if [ "$NON_INTERACTIVE" != true ]; then
            cleaned_output=$(gum spin --spinner dot --title "Cleaning up output..." -- claude -p "$escaped_cleanup_prompt")
        else
            cleaned_output=$(claude -p "$escaped_cleanup_prompt")
        fi
    else
        if [ "$NON_INTERACTIVE" != true ]; then
            cleaned_output=$(gum spin --spinner dot --title "Cleaning up output..." -- gemini -m gemini-2.5-flash -p "$escaped_cleanup_prompt")
        else
            cleaned_output=$(gemini -m gemini-2.5-flash -p "$escaped_cleanup_prompt")
        fi
    fi
    
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
    local width_emphasis="CRITICAL: max width of $((MAX_WIDTH - 8)) characters per line (!important)"
    local term_generation_prompt=""
    
    # Strengthen emphasis on subsequent attempts
    if [ "$attempt" -gt 1 ]; then
        width_emphasis="CRITICAL: Absolute maximum width is $((MAX_WIDTH - 8)) characters per line - any line longer will be rejected. Count characters carefully! Every line must be ≤$((MAX_WIDTH - 8)) chars!"
    fi
    
    # Set poem generation instruction based on flag
    poem_instruction=""
    if [ "$CLAUDE_POEM" = true ]; then
        poem_instruction="3. THE EPSON TM-99XII SUPER MAX ONLY GENERATES ASCII ART. NO POEMS OR PROSE."
    else
        poem_instruction="3. OPTIONALLY - IF THE TOPIC ALLOWS FOR IT - THE EPSON TM-99XII SUPER MAX MAY GENERATE A SHORT POEM (1-5 lines) OR A FEW LINES OF PROSE THAT REFLECT ON THE TERM, ITS SIGNIFICANCE, ITS APPLICATION OR MEANING - EITHER AS A SYMBOL OF STH ELSE OR IN ITS OWN RIGHT - IN HUMANITY'S UNDERSTANDING OF THE UNIVERSE OR HUMANITYS ESSENCE."
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
		2. GENERATES ASCII ART THAT EMBODIES THE TERMS MEANING USING SHAPES USING A DIVERSE SET OF THE AVAILABLE CHARSET. THE ASCII ART MUST BE TECHNICAL IN NATURE AND PRECISE IN ITS REPRESENTATION OR CREATIVE AND ORGANIC IN NATURE. IT IS INSPIRED BY UX DESIGN, TECHNICAL DRAWINGS, TERMINAL AESTHETICS, BUT IF USEFUL REPRESENTATIONAL. SHAPE EMBODIES CONCEPT. USE MORE THEN LINES AND ARROWS.
		$poem_instruction
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
    $poem_instruction
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
    4. THE MAX WIDTH OF THE PAPER IS $MAX_WIDTH CHARACTERS. THE ASCII ART CAN NOT EXCEED THIS WIDTH. $width_emphasis
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
    
    # Escape backslashes and quotes in the prompt
    local escaped_prompt=$(printf '%s\n' "$full_prompt" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    
    local output
    if [ "$USE_CLAUDE" = true ]; then
        if [ "$NON_INTERACTIVE" != true ]; then
            output=$(gum spin --spinner dot --title "Generating ASCII art..." -- claude -p "$escaped_prompt")
        else
            output=$(claude -p "$escaped_prompt")
        fi
    else
        if [ "$NON_INTERACTIVE" != true ]; then
            output=$(gum spin --spinner dot --title "Generating ASCII art..." -- gemini -m gemini-2.5-flash -p "$escaped_prompt")
        else
            output=$(gemini -m gemini-2.5-flash -p "$escaped_prompt")
        fi
    fi
    
    # Print debug info for Claude output if requested
    if [ "$DEBUG" = true ]; then
        echo "=== DEBUG: Claude Response ===" >&2
        echo "$output" >&2
        echo "==============================" >&2
    fi
    
    # First remove cached credentials before parsing
    output=$(echo "$output" | sed 's/cached credentials\.//g')
    
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
    
    # Clean output - remove //HEADER lines, code blocks and extra formatting
    art_output=$(echo "$art_output" | sed '/^\/\/.*$/d' | sed '/^\`\`\`[a-zA-Z]*$/d' | sed '/^\`\`\`$/d' | sed 's/\`\`\`[a-zA-Z]*//g' | sed 's/\`\`\`//g' | sed '/^$/d')
    
    # Replace problematic Unicode characters with ASCII alternatives
    art_output=$(replace_unicode_chars "$art_output")
    
    # If expensive mode is enabled, run cleanup pass
    if [ "$EXPENSIVE" = true ]; then
        if [ "$NON_INTERACTIVE" != true ]; then
            gum style --foreground="#ffaa00" "🔄 Running expensive cleanup pass..."
        fi
        art_output=$(cleanup_output "$art_output")
    fi
    
    # Center the ASCII art
    art_output=$(center_ascii_art "$art_output")
    
    # Generate Claude poem if flag is set
    if [ "$CLAUDE_POEM" = true ]; then
        # Create poem prompt
        poem_prompt="Generate a short poem (1-5 lines) that reflects on the term '$parsed_term' and complements this ASCII art:

$art_output

The poem should be thoughtful and capture the essence or meaning of the term. Keep it concise and poetic."
        
        # Get poem from Claude
        claude_poem=""
        if [ "$NON_INTERACTIVE" != true ]; then
            claude_poem=$(gum spin --spinner dot --title "Generating poem..." -- claude -p "$poem_prompt")
        else
            claude_poem=$(claude -p "$poem_prompt")
        fi
        
        # Add poem to art output with empty line separator
        if [ -n "$claude_poem" ]; then
            art_output="$art_output

$claude_poem"
        fi
    fi
    
    # Use the parsed term from the function, or timestamp if none available
    if [ "$DEBUG" = true ]; then
        echo "=== DEBUG: Variable Check ===" >&2
        echo "term: '$term'" >&2
        echo "PARSED_TERM: '$PARSED_TERM'" >&2
        echo "============================" >&2
    fi
    
    if [ -n "$term" ]; then
        display_term="$term"
        filename_term=$(echo "$term" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    elif [ -n "$PARSED_TERM" ]; then
        display_term="$PARSED_TERM"
        filename_term=$(echo "$PARSED_TERM" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
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
    
    # Check line width constraint
    max_line_length=$(echo "$art_output" | wc -L)
    
    if [ "$max_line_length" -le $((MAX_WIDTH + 6)) ]; then
        if [ "$NON_INTERACTIVE" != true ]; then
            if [ -z "$term" ]; then
                gum style --foreground="#00ff00" --bold "🎲 Selected random term: $display_term"
            fi
            gum style --foreground="#00ff00" --bold "✅ Generated ASCII art for term: $display_term (attempt $attempt)"
        fi
        break
    else
        if [ "$NON_INTERACTIVE" != true ]; then
            gum style --foreground="#ff9900" "⚠️  Attempt $attempt: Line too long ($max_line_length chars), retrying with stricter constraint..."
        fi
        attempt=$((attempt + 1))
    fi
done

if [ $attempt -gt $max_attempts ]; then
    gum style --foreground="#ff0000" --bold "❌ Failed to generate ASCII art within width constraints after $max_attempts attempts"
    exit 1
fi



# Create state directory if it doesn't exist
mkdir -p "$HOME/.local/state/reflect"

# Save original output to file (without PC437 conversion for display)
echo "$art_output" > "$HOME/.local/state/reflect/${filename_term}.txt"
if [ "$NON_INTERACTIVE" != true ]; then
    gum style --foreground="#0088ff" "💾 Saved ASCII art to $HOME/.local/state/reflect/${filename_term}.txt"
fi

# Convert to PC437 for printer only
art_output_pc437=$(convert_to_pc437 "$art_output")

# Handle interactive vs non-interactive modes
if [ "$NON_INTERACTIVE" = true ]; then
    # Auto-print in non-interactive mode
    print_to_printer "$art_output"
    
    # Show output
    echo
    echo
    gum style --foreground="#666666" --align="center" "$display_term"
    echo
    echo
    echo
    echo "$art_output"
    echo
    echo
else
    # Default mode - show menu after generation
    while true; do
        echo
        echo
        gum style --foreground="#666666" --align="center" "$display_term"
        echo
        echo
        echo
        echo "$art_output"
        echo
        echo
        
        gum style --foreground="#888888" \
            "• Press any key to exit" \
            "• 'e' to edit with nvim" \
            "• 'r' to refine with expensive cleanup" \
            "• 'p' to print to thermal printer" \
            "• 'f' to add footer"
        read -n 1 -r choice
        echo
        
        case $choice in
            e|E)
                # Edit with nvim
                temp_file=$(mktemp)
                echo "$art_output" > "$temp_file"
                nvim "$temp_file"
                art_output=$(cat "$temp_file")
                rm "$temp_file"
                
                # Convert to PC437 for potential printing
                art_output_pc437=$(convert_to_pc437 "$art_output")
                ;;
            r|R)
                # Run expensive cleanup on current output
                gum style --foreground="#ffaa00" "🔄 Running expensive cleanup pass..."
                art_output=$(cleanup_output "$art_output")
                
                # Convert to PC437 for potential printing
                art_output_pc437=$(convert_to_pc437 "$art_output")
                ;;
            p|P)
                print_to_printer "$art_output"
                break
                ;;
            f|F)
                # Add footer and save to file
                footer=$(generate_footer)
                art_output="$art_output


$footer"
                echo "$art_output" > "$HOME/.local/state/reflect/${filename_term}.txt"
                gum style --foreground="#0088ff" "📄 Added footer and saved to $HOME/.local/state/reflect/${filename_term}.txt"
                
                # Convert to PC437 for potential printing
                art_output_pc437=$(convert_to_pc437 "$art_output")
                ;;
            *)
                break
                ;;
        esac
    done
fi
