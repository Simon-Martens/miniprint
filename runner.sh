#!/bin/bash

# Interactive Command Runner with Template Language
# Usage: ./runner.sh [--minimal] command {input|prompt} ...

show_usage() {
    echo "Usage: $0 [--minimal] [--confirm-exit] [--confirm-edit] -c command @input:prompt@ @choice:text@ @choice:yes:no@ ..."
    echo ""
    echo "Template Language:"
    echo "  @input:prompt@         Interactive input with custom prompt"
    echo "  @choice:text@          Yes/no choice - includes text if yes, nothing if no"
    echo "  @choice:yes_text:no_text@  If/else choice - yes_text if yes, no_text if no"
    echo ""
    echo "Examples:"
    echo "  $0 -c translate @input:Enter word or phrase@"
    echo "  $0 --minimal -c translate @input:Enter word or phrase@"
    echo "  $0 -c ls @choice:-la@ @choice:--color=auto@"
    echo "  $0 --confirm-exit -c curl @choice:-v@ -X POST @input:Enter URL@"
    echo "  $0 --confirm-edit -c echo @choice:Hello:Goodbye@ @input:Enter name@"
    echo ""
    echo "Options:"
    echo "  --minimal          Hide command name and return status"
    echo "  --confirm-exit     Wait for keypress before exiting"
    echo "  --confirm-edit     Allow editing output in nvim with 'e/E', otherwise exit"
    echo "  -c                 Start of command (mandatory)"
    echo ""
    echo "The command follows -c and can contain multiple @input:prompt@ and @choice:...@ placeholders."
    exit 1
}

# Check if arguments are provided
if [ $# -eq 0 ]; then
    show_usage
fi

# Parse runner options first
MINIMAL=false
CONFIRM_EXIT=false
CONFIRM_EDIT=false
COMMAND_FOUND=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --minimal)
            MINIMAL=true
            shift
            ;;
        --confirm-exit)
            CONFIRM_EXIT=true
            shift
            ;;
        --confirm-edit)
            CONFIRM_EDIT=true
            shift
            ;;
        -c)
            COMMAND_FOUND=true
            shift
            break
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Error: Unknown option '$1'. Use -c to start the command."
            show_usage
            ;;
    esac
done

# Check if -c was provided
if [ "$COMMAND_FOUND" = false ]; then
    echo "Error: -c flag is required to specify the command"
    show_usage
fi

# Everything remaining is the command template
if [ $# -eq 0 ]; then
    echo "Error: No command provided after -c"
    show_usage
fi

COMMAND_TEMPLATE="$*"

# Extract all @input:prompt@ patterns from the command template
extract_inputs() {
    local template="$1"
    # Use grep to find all @input:...@ patterns
    echo "$template" | grep -oE '@input:[^@]+@' | sed 's/@input://g' | sed 's/@//g'
}

# Extract all @choice:text@ or @choice:yes:no@ patterns from the command template
extract_choices() {
    local template="$1"
    # Use grep to find all @choice:...@ patterns
    echo "$template" | grep -oE '@choice:[^@]+@' | sed 's/@choice://g' | sed 's/@//g'
}

# Get list of prompts from the template
# Use mapfile to avoid word splitting
mapfile -t PROMPTS < <(extract_inputs "$COMMAND_TEMPLATE")
mapfile -t CHOICES < <(extract_choices "$COMMAND_TEMPLATE")

# Check if gum is available when inputs or choices are required
if [ ${#PROMPTS[@]} -gt 0 ] || [ ${#CHOICES[@]} -gt 0 ]; then
    if ! command -v gum &> /dev/null; then
        echo "Error: gum is required for interactive inputs but not found."
        echo "Install gum: https://github.com/charmbracelet/gum"
        exit 1
    fi
fi

# Collect inputs using gum
USER_INPUTS=()
for prompt in "${PROMPTS[@]}"; do
    echo ""
    input=$(gum input --placeholder "$prompt")
    if [ $? -ne 0 ]; then
        echo "Input cancelled."
        exit 1
    fi
    USER_INPUTS+=("$input")
done

# Collect choices using gum
USER_CHOICES=()
for choice_spec in "${CHOICES[@]}"; do
    echo ""
    # Check if it's a two-part choice (yes:no) or single choice
    if [[ "$choice_spec" == *":"* ]]; then
        # Split on the first colon to get yes and no parts
        yes_part="${choice_spec%%:*}"
        no_part="${choice_spec#*:}"
        
        if gum confirm "Choose '$yes_part' or '$no_part'?"; then
            USER_CHOICES+=("$yes_part")
        else
            USER_CHOICES+=("$no_part")
        fi
    else
        # Single choice - include text or nothing
        if gum confirm "Include '$choice_spec'?"; then
            USER_CHOICES+=("$choice_spec")
        else
            USER_CHOICES+=("")
        fi
    fi
done

# Build final command by replacing patterns with user inputs and choices
FINAL_COMMAND="$COMMAND_TEMPLATE"

# Replace each @input:prompt@ pattern with the corresponding user input
for i in "${!USER_INPUTS[@]}"; do
    # Find the i-th @input:...@ pattern and replace it with the user input
    PATTERN=$(echo "$COMMAND_TEMPLATE" | grep -oE '@input:[^@]+@' | sed -n "$((i+1))p")
    if [ -n "$PATTERN" ]; then
        # Escape special characters in the pattern for sed
        ESCAPED_PATTERN=$(echo "$PATTERN" | sed 's/[[\.*^$()+?{|]/\\&/g')
        # Replace the pattern with the user input (properly quoted)
        FINAL_COMMAND=$(echo "$FINAL_COMMAND" | sed "s/$ESCAPED_PATTERN/'${USER_INPUTS[$i]}'/")
    fi
done

# Replace each @choice:text@ pattern with the corresponding user choice
for i in "${!USER_CHOICES[@]}"; do
    # Find the i-th @choice:...@ pattern and replace it with the user choice
    PATTERN=$(echo "$COMMAND_TEMPLATE" | grep -oE '@choice:[^@]+@' | sed -n "$((i+1))p")
    if [ -n "$PATTERN" ]; then
        # Escape special characters in the pattern for sed
        ESCAPED_PATTERN=$(echo "$PATTERN" | sed 's/[[\.*^$()+?{|]/\\&/g')
        # Replace the pattern with the user choice (or empty string)
        FINAL_COMMAND=$(echo "$FINAL_COMMAND" | sed "s/$ESCAPED_PATTERN/${USER_CHOICES[$i]}/")
    fi
done

# Clear screen and show what we're about to run (unless minimal)
clear

if [ "$MINIMAL" = false ]; then
    if command -v gum &> /dev/null; then
        gum style --foreground "#00ff87" "Running: $FINAL_COMMAND"
    else
        echo "Running: $FINAL_COMMAND"
    fi
    echo ""
fi

# Add padding and spacing to command output
echo ""
# Capture raw output to temp file for potential editing
TEMP_OUTPUT=$(mktemp)
TEMP_RAW=$(mktemp)
eval "$FINAL_COMMAND" | tee >(sed 's/\x1b\[[0-9;]*m//g' > "$TEMP_RAW") | sed 's/^/  /'
EXIT_CODE=${PIPESTATUS[0]}
echo ""

if [ "$MINIMAL" = false ]; then
    if command -v gum &> /dev/null; then
        if [ $EXIT_CODE -eq 0 ]; then
            gum style --foreground "#50fa7b" "✓ Command completed successfully"
        else
            gum style --foreground "#ff5555" "✗ Command failed (exit code: $EXIT_CODE)"
        fi
    else
        if [ $EXIT_CODE -eq 0 ]; then
            echo "✓ Command completed successfully"
        else
            echo "✗ Command failed (exit code: $EXIT_CODE)"
        fi
    fi
    echo ""
fi

# Handle exit behavior based on flags
if [ "$CONFIRM_EDIT" = true ]; then
    if command -v gum &> /dev/null; then
        gum style --foreground "#6272a4" "Press 'e/E' to edit output in nvim, or any other key to exit..."
    else
        echo "Press 'e/E' to edit output in nvim, or any other key to exit..."
    fi
    
    read -n 1 -s key
    if [[ "$key" == "e" || "$key" == "E" ]]; then
        if command -v nvim &> /dev/null; then
            nvim "$TEMP_RAW"
        else
            echo "nvim not found. Output saved to: $TEMP_RAW"
            read -n 1 -s
        fi
    fi
elif [ "$CONFIRM_EXIT" = true ]; then
    if command -v gum &> /dev/null; then
        gum style --foreground "#6272a4" "Press any key to exit..."
    else
        echo "Press any key to exit..."
    fi
    read -n 1 -s
fi

# Clean up temp files
rm -f "$TEMP_OUTPUT" "$TEMP_RAW"
