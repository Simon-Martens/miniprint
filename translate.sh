#!/bin/bash

# Check if arguments are provided
if [ $# -eq 0 ]; then
    echo "Usage: ./translate.sh <word or phrase>"
    exit 1
fi

# Get the input text (all arguments combined)
INPUT="$*"

# Run claude with automatic detection and appropriate formatting
claude "Claude, please translate the following text either from the appropriate language (can be German, French, Spanish, Italian, or any western language) to English, or, if the given term already is English, translate it into German. First, automatically determine if this is a single word or a phrase/sentence, then use the appropriate output format. The input text is:

$INPUT

If it's a SINGLE WORD, use this format:

*word* [pronunciation]

firstsynonym [pronunciation1], secondsynonym [pronunciation2] 

One sentence explanation, one sentence example.


Alt: TRANSLATION2 [pronunciation2], TRANSLATION3 [pronunciation3] [use more if appropriate]


If it's a PHRASE or SENTENCE, use this format:

*[main translation]*

Alt:
- [alternative in orignal language] / [alternative translated 1]
- [alternative2 in original language] / [alternative translated 2]
- [alternative3 in original language] / [alternative translated 3]

[Brief explanation of usage context or nuances if relevant. Give a formal example if the usage of the given sentence is informal, offensive or derogatory.]

Do not output anything above or below the specified format. You can use markdown, I will use a markdown renderer to display the output." | fold -s -w 80 | bat -l md --style=plain --paging=never --color=always --decorations=always
