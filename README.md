# MiniPrint

A collection of interactive command-line tools with an advanced command runner system.

## Tools

- **translate**: AI-powered translation tool that automatically detects single words vs phrases and formats output accordingly
- **reflect**: Generates ASCII art from terms using AI, designed for thermal printer output with mystical presentation

## Runner System

The `runner.sh` provides an interactive command execution framework with template language support.

### Usage

```bash
./runner.sh [--minimal] [--confirm-exit] [--confirm-edit] -c command template
```

### Options

- `--minimal` - Hide command name and return status
- `--confirm-exit` - Wait for keypress before exiting  
- `--confirm-edit` - Allow editing output in nvim with 'e/E', otherwise exit immediately
- `-c` - Start of command (mandatory)

### Template Language

- `@input:prompt@` - Interactive input with custom prompt
- `@choice:text@` - Yes/no choice - includes text if yes, nothing if no
- `@choice:yes_text:no_text@` - If/else choice - yes_text if yes, no_text if no

### Examples

```bash
# Simple translation
./runner.sh -c translate @input:Enter word or phrase@

# With minimal output and edit capability
./runner.sh --minimal --confirm-edit -c translate @input:Enter word@

# Multiple inputs and choices
./runner.sh -c curl @choice:-v@ -X POST -d @input:Enter JSON@ @input:Enter URL@

# If/else choices
./runner.sh -c echo @choice:Good morning:Good evening@ @input:Enter name@
```

## Installation

Use `tools/install.sh` to install all scripts to your PATH:

```bash
./tools/install.sh                    # Install to ~/.local/share/omarchy/bin
./tools/install.sh /usr/local/bin     # Install to custom location
```

The installer removes `.sh` extensions and makes scripts executable.
