#!/bin/sh

# This script creates/overwrites a new syntax highlighting file for forthtags
# The existing tag file (no extension) from the filepath is used as a source

# The filepath is passed as an argument from the ~/.vim/ftplugin/forth.vim file
tagpath="$1"

# The tagfile has no file extension
tagfile="$tagpath/tags"
syntaxfile="~/.vim/syntax/tags.vim"

# Expand the tilde ~ to the actual home directory path
expanded_syntaxfile=$(eval echo "$syntaxfile")

# Check if the file exists, and create it if it doesn't
if [ ! -e "$expanded_syntaxfile" ]; then
  touch "$expanded_syntaxfile"
fi

# Redirect the output to the specified file
eval >"$expanded_syntaxfile"

# Copies the words from the previously created forth tagfile
#   creates a syntax entry for each word
awk '{ print "syn keyword forthSyntaxWord", $1 }' "$tagfile" >> "$expanded_syntaxfile"

# Choose what color to make the words in tag file
# Two options:
#
# 1. Use an existing highlight. :highlight will display all available colors
#    In the example below, uncomment or copy, replace 'Underlined' with the name you prefer
#echo "hi def link forthSyntaxWord Underlined" >> "$expanded_syntaxfile"               # 
#
# 2. Use a custom color
#    In the examples below, uncomment or copy, change the guifg color to suit your needs
echo "highlight forthSyntaxWord ctermfg=red guifg=#b623ff" >> "$expanded_syntaxfile"  # purple
#echo "highlight forthSyntaxWord ctermfg=red guifg=#ff55ff" >> "$expanded_syntaxfile"  # pink
#echo "highlight forthSyntaxWord ctermfg=red guifg=#005500" >> "$expanded_syntaxfile"  # green
#echo "highlight forthSyntaxWord ctermfg=red guifg=#ff5500" >> "$expanded_syntaxfile"  # orange

