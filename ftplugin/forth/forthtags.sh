#!/bin/sh


# An AWK script used for finding the following types of forth words
# variable, 2variable, constant, 2constant, buffer:, create
#
# The input for this script is a filepath/name
# The output of this script is "word (tab) filepath/name (tab) linenumber"
tag_script=$(cat << 'EOF'
BEGIN {
  OFS = "\t"  # Change output field separator to a tab character
 }
{
  # If any of the keywords are found (but not if it's in a comment) proceed
  if (tolower($0) ~ /^[^\\]*(variable|2variable|constant|2constant|buffer:|create)/) {
    found = 0  # Initialize a variable to keep track of which field contains the word
    line = tolower($0)  # Convert the line to lowercase
    n = split(line, words, " ")  # Split the line into fields

     # Loop through the fields for a keyword, we're looking for the word following this keyword
     for (i = 1; i <= n; i++) {
       if (words[i] == "variable" || words[i] == "2variable" || words[i] == "constant" || words[i] == "2constant" || words[i] == "buffer:" || words[i] == "create") {
         found = i
         break
       }
     }

     # Print the line and the field containing the word
     if (found > 0) {
       print $(found+1),  FILENAME, FNR  # word (tab) filepath/name (tab) linenumber
     }
  }
}
EOF
)

# The ~/.vim/ftplugin/forth.vim file passes in the current .fs file path
filepath="$1"

# forthtags.cfg should already exist in the same folder as the .fs file
#   The user created forthtags.cfg lists the directories and files to be processed for forthtags
configfile="forthtags.cfg"
config="$filepath/$configfile"

# The 'tags' file (no extension) is overwritten with new contents for VIM's tag engine
#   The file is created in the same folder as the .fs file
tags="$filepath/tags"

# Create a new file
>"$tags"

# Process each line of text in the users forthtags.cfg file
while IFS= read -r line; do
  # Trim leading and trailing whitespace
  trimmed="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  # Skip empty lines or lines that start with a comment character (e.g., # for comments)
  [ -z "$(echo "$trimmed" | sed -e 's/^#//')" ] && continue

  current_directory="$filepath"

  # Check if the input path is already an absolute path
  if [ "$trimmed#*/" = "$trimmed" ]; then # This is sh specific, bash would be [[ "$line == /* ]]
    full_path="$trimmed" # Input path is already absolute
  else
    full_path="${current_directory}/${trimmed}" # Convert relative to absolute path
  fi
 
  # Skip lines that are not file or directory
  [ ! -e "$full_path" ] && continue

  # Check if the line represents a file
  if [ -f "$full_path" ]; then
    # Extract variable, 2variable, constant, 2constant, buffer;, and create words
    awk "$tag_script" "$full_path" >> "$tags"
    # Extract (:) definition words
    awk '$1 == ":" { print $2 "\t"  FILENAME "\t" FNR }' "$full_path" >> "$tags"
    continue
  fi
  
   # Check if the current line represents a directory
   if [ -d "$full_path" ]; then
     # Process all files in the directory
     for file in "$full_path"*; do
       if [ -f "$file" ]; then		
         file_extension="${file##*.}"
         if [ "$file_extension" = "fs" ]; then 
           # Extract variable, 2variable, constant, 2constant, buffer;, and create words
           awk "$tag_script" "$file" >> "$tags"
           # Extract (:) definition words
           awk '$1 == ":" { print $2 "\t"  FILENAME "\t" FNR }' "$file" >> "$tags"
         fi
       fi
     done
   fi
done < "$config"

