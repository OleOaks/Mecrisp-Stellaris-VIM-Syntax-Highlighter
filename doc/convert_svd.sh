#!/bin/sh
# created for Mecrisp-Stellaris Forth by Matthias Koch
# This script converts an CMSIS-SVD file into multiple VIM files
#   to enable auto-completion and syntax highlighting.
# By Brett Olson "brettolson@cox.net" 2023, released under the MIT License
# 
# Do not run this shell script as sudo. $HOME may resolve to /root and you will get nonexistant folder/file errors
#  
# Modifications to run on FreeBSD
#  1. Replace all literal "	" tabs with \t
#  2. Add -e after all echo commands
#  3. Replace all xmlstarlet commands with xml

# Store the current working directory
current_directory=$(pwd)

# ===========================================================================
#  CHANGE THE FOLLOWING ITEMS TO SWITCH MCU SUPPORT DOCUMENTATION
# ===========================================================================

# Store the directory wher the mcu svd file is stored
svd_directory=~/.vim/doc
#svd_directory=~/.vim/doc

# Select/add the svd filename
#
svd_file=STM32F103.svd
#svd_file=STM32F411.svd
#svd_file=STM32F0x1.svd
#svd_file=STM32G431.svd
#svd_file=STM32H7x3.svd

# Select/add the reference manual page file (the file is read-only and will not be edited by this script)
# You can create your own mapping between register names and PDF Reference Manual
# A stub file is created for you (without page numbers) named blank_refmanualpage_to_register.tsv
# If this is the first time running this script for a new MCU, the file below won't exist. Leave the
#   uncommented item below as-is. After running this script, rename the blank file to name appropriate for your MCU,
#   then fill in the page numbers manually and re-run this script file.
# Page numbers will appear as hyperlinks in the MCU help file
# File format is 'page# <tab> registername'
#
#svd_rm_pages=rm_stm32f0x1.tsv
svd_rm_pages=rm_stm32f103.tsv
#svd_rm_pages=rm_stm32f411.tsv
#svd_rm_pages=rm_stm32g431.tsv

# Select/add the PDF file path that will appear in the page hyperlinks for each register
# Test the hyperlink by pasting the hyperlink below into a web browsesr
#
#svd_rm_pdf=file:///home/brett/.vim/doc/RM0091%20Reference%20manual%20STM32F0xx.pdf
svd_rm_pdf=file:///home/brett/.vim/doc/RM0008%20Reference%20manual%20STM32F10xxx.pdf
#svd_rm_pdf=file:///home/brett/.vim/doc/RM0383%20Reference%20manual%20STM32F411.pdf
#svd_rm_pdf=file:///home/brett/.vim/doc/RM0440%20Reference%20manual%20STM32G4xx.pdf

# ============================================================================
# Store the svd path/file
up="$svd_directory/$svd_file"

# MCU syntax files ( for highlighting )
svd_syntax_peripheral="$HOME/.vim/syntax/mcu/mcu_peripheral.vim"
echo "svd_syntax_peripheral: "$svd_syntax_peripheral
svd_syntax_register="$HOME/.vim/syntax/mcu/mcu_register.vim"
svd_syntax_bitfield="$HOME/.vim/syntax/mcu/mcu_bitfield.vim"

# MCU dictionary files ( for auto-complete )
svd_dictionary_peripheral="$HOME/.vim/words/mcu_peripheral.txt"
svd_dictionary_register="$HOME/.vim/words/mcu_register.txt"
svd_dictionary_bitfield="$HOME/.vim/words/mcu_bitfield.txt"

# MCU bitfield replacements file
svd_replacement_bitfield="$HOME/.vim/doc/mcu_replacement_bitfield.txt"

# MCU help files
svd_help_mcu="$HOME/.vim/doc/mcu.txt"
#if [ -e "$svd_help_mcu" ]; then
if [ "$svd_help_mcu" ]; then
  > "$svd_help_mcu"
else
  touch "$svd_help_mcu"
fi
svd_help_register="$HOME/.vim/doc/mcu_register.txt"
svd_help_bitfield="$HOME/.vim/doc/mcu_bitfield.txt"

# ./convert_svd.sh
#
echo "Reading "$up

# Uncomment and use the following line to printout the tag structure of the document
# xml el -u $up > output.txt

# =============================================================================
# SELECT XML DATA FROM SVD FIlE
# =============================================================================
#
# Note: In FreeBSD, replace xmlstarlet with xml
#
# Extract peripheral data from svd file
xmlstarlet sel -t -m "//peripheral" -v "@derivedFrom" -o "	" -v "name" -o "	" -v "baseAddress" -o "	" -v "normalize-space(description)" -n "$up" > peripheral_raw.tsv
#
# Extract register data from svd file
xmlstarlet sel -t -m "//register" -v "../../name" -o "	" -v "name" -o "	"  -v "access" -o "	" -v "resetValue" -o "	" -v "addressOffset" -o "	" -v "normalize-space(description)" -n "$up" > register_raw.tsv

# Extract bitfield data from svd file
xmlstarlet sel -t -m "//field" -v "../../../../name" -o "	" -v "../../name" -o "	" -v "name" -o "	" -v "bitOffset" -o "	" -v "bitWidth" -o "	" -v "access" -o "	" -v "normalize-space(description)" -n "$up" > bitfield_raw.tsv

# Text substitutions for access type, and removing hex value prefixes 0x
tmpfile=$(mktemp)

# =============================================================================
# COPY MISSING DATA FOR @derivedFrom PERIPHERALS
# =============================================================================
#
# Create a peripheral lookup file to help in copying missing data
awk -F '	' 'BEGIN {OFS=FS} { if ($1=="") { print $2, $2, $3 } else { print $1, $2, $3 }} ' peripheral_raw.tsv > peripheral_lookup.tsv

# Create peripheral file
# Process the output.tmp file to fill in missing information (i.e. description) for "@derivedFrom" peripherals
# Set input file field separator: -F ',' 
# Set output file field spearator:  BEGIN {OFS=FS}
# Create an associative array name lookup, field 4 (desc) of lookup = ? don't know exactly how this works
# If field 1 is a blank line, do nothing except print fields 2, 3, and 4
# If field 1 is not blank, lookup field 1 in field2, print fields 2, 3, and the matching row's field 4
awk -F '	' 'BEGIN {OFS=FS} NR==FNR {lookup[$2] = $4; next} $1 == "" {print $2, $3, $4; next} {print $2, $3, lookup[$1]}' peripheral_raw.tsv peripheral_raw.tsv > peripheral.tsv

# Create register file
peripheral_lookup="peripheral_lookup.tsv"
register_raw="register_raw.tsv"
#output_tsv="register_tmp.tsv"
peripheral_tmp="peripheral_tmp.tsv"
peripheral_tmp2="peripheral_tmp2.tsv"
peripheral_tmp3="peripheral_tmp3.tsv"
# Remove the existing output file if it exists
#rm -f "$output_tsv"
rm -f "$peripheral_tmp"
# Loop through each word in peripheral_lookup.tsv
while IFS=$'	' read -r derivedFrom peripheral baseAddress ; do
    # Use grep to find all lines from register_raw.tsv that start with the current peripheral
    # echo $derivedFrom ", " $peripheral ", " $baseAddress
    matches=$(grep "^$derivedFrom	" "$register_raw")
    # Print peripheral and baseAddress from peripheral_raw.tsv and the matching lines from register_raw.tsv to registers.tsv
    echo "$matches" | sed "s/^/$peripheral\t$baseAddress\t/" >> "$peripheral_tmp"
done < "$peripheral_lookup"

# =============================================================================
# COPY MISSING DATA FOR @derivedFrom REGISTERS
# =============================================================================
#
# Remove the @derivedFrom peripheral name: register.tsv-->Peripheral(1), BaseAddr(2), Register(3), Access(4), Reset(5), Offset(6), Description(7)
# awk -F '	' 'BEGIN {OFS=FS} {print $1, $2, $4, $5, $6, $7, $8 }' "$peripheral_tmp" > register.tsv
awk -F '	' 'BEGIN {OFS=FS} {print $1, $2, $4, $5, $6, $7, $8 }' "$peripheral_tmp" > "$peripheral_tmp2"

# Calculate absolute register addresss: tempfile--> Peripheral(1), Register(2), BaseAddr(3), Offset(4), AbsAddr(5), Reset(6), Access(7), Description(8)
# awk -F '	' 'BEGIN {OFS=FS} { absAddr = sprintf("%X", $2 + $6); print $1, $3, $2, $6, absAddr, $5, $4, $7 }' register.tsv > "$tmpfile"
# awk -F '	' 'BEGIN {OFS=FS} { absAddr = sprintf("%X", $2 + $6); print $1, $3, $2, $6, absAddr, $5, $4, $7 }' "$peripheral_tmp2" > "$peripheral_tmp3"
# awk -F '	' 'BEGIN {OFS=FS} { absAddr = sprintf("%X", strtonum("0x" $2) + strtonum("0x" $6)); print $1, $3, $2, $6, absAddr, $5, $4, $7 }' "$peripheral_tmp2" > "$peripheral_tmp3"
awk --non-decimal-data -F '	' 'BEGIN {OFS=FS} { absAddr = sprintf("%X", $2 + $6); print $1, $3, $2, $6, absAddr, $5, $4, $7 }' "$peripheral_tmp2" > "$peripheral_tmp3"
#mv "$tmpfile" register.tsv

# Concatenate peripheral-register name: tempfile-->Peripheral(1), Register(2), Per-Reg(3), BaseAddr(4), Offset(5), AbsAddr(6), Reset(7), Access(8), Description(9)
# awk -F '	' 'BEGIN {OFS=FS} { print $1, $2, $1 "_" $2, $3, $4, $5, $6, $7, $8 }' register.tsv > "$tmpfile"
awk -F '	' 'BEGIN {OFS=FS} { print $1, $2, $1 "_" $2, $3, $4, $5, $6, $7, $8 }' "$peripheral_tmp3" > register.tsv
# mv "$tmpfile" register.tsv

# Create a stub file that can be used as the source for register names likned to reference manual page numbers
# After running this script, rename the blank_refmanualpage_to_register.tsv to rm_stm32xxxxx.tsv (replace xxxxx with your MCU)
# Manually insert reference manual page numbers where each register can be found
awk -F '	' '{print "	" $3}' register.tsv > blank_refmanualpage_to_register.tsv

# Create bitfield file
peripheral_lookup="peripheral_lookup.tsv"
bitfield_raw="bitfield_raw.tsv"
output_tsv="bitfield_tmp.tsv"
# Remove the existing output file if it exists
rm -f "$output_tsv"
# Loop through each word in peripheral_lookup.tsv
while IFS=$'	' read -r derivedFrom peripheral baseAddress; do
    # Use grep to find all lines from bitfields_raw.tsv that start with the current peripheral
    matches=$(grep "^$derivedFrom	" "$bitfield_raw")
    # Print peripheral and baseAddress from peripheral_raw.tsv and the matching lines from bitfield_raw.tsv to registers.csv
    # bitfield_tmp.tsv --> Peripheral(1), BaseAddr(2)
    echo "$matches" | sed "s/^/$peripheral\t$baseAddress\t/" >> "$output_tsv"
done < "$peripheral_lookup"

# Remove the @derivedFrom peripheral name
awk -F '	' 'BEGIN {OFS=FS} {print $1, $2, $4, $5, $6, $7, $8, $9 }' "$output_tsv" > bitfield.tsv

# Concatenate peripheral-register name, and peripheral-register-bitfield name
awk -F '	' 'BEGIN {OFS=FS} { print $1, $3, $1 "_" $3, $4, $1 "_" $3 "_" $4, $5, $6, $7, $8 }' bitfield.tsv > "$tmpfile"
mv "$tmpfile" bitfield.tsv

# Process each line in bitfield.tsv, get the absolute address from register.tsv
awk -F'	' 'BEGIN {OFS=FS} NR == FNR { register[$3] = $6; next } { key = $3; if (key in register) { print $1, $2, $3, $4, $5, register[key], $6, $7, $8, $9 } }' register.tsv bitfield.tsv > "$tmpfile"
mv "$tmpfile" bitfield.tsv

awk -F'	' 'BEGIN {OFS=FS} NR == FNR { access = ( $9 == "" ) ? "rw" : $9; print $1, $2, $3, $4, $5, $6, $7, $8, access, $10 }' bitfield.tsv > "$tmpfile"
mv "$tmpfile" bitfield.tsv

# =============================================================================
# REPLACE ACCESS WORDS AND REMOVE HEX PREFIXES
# =============================================================================

sed -e 's/0x//g' peripheral.tsv > "$tmpfile"
mv "$tmpfile" peripheral.tsv

sed -e 's/read-write/rw/g' \
    -e 's/read-only/ro/g' \
    -e 's/write-only/wo/g' \
    -e 's/0x//g' register.tsv > "$tmpfile" 
mv "$tmpfile" register.tsv

sed -e 's/read-write/rw/g' \
    -e 's/read-only/ro/g' \
    -e 's/write-only/wo/g' \
    -e 's/0x//g' bitfield.tsv > "$tmpfile"
mv "$tmpfile" bitfield.tsv


# =============================================================================
# CREATE VIM FILES FOR SYNTAX
# =============================================================================

# Create syntax files
awk -F '	' '{print "syn keyword forthPeripheral " $1} END {print "hi def link forthPeripheral Identifier"}' peripheral.tsv > "$svd_syntax_peripheral"
awk -F '	' '{print "syn keyword forthRegister " $3} END {print "hi def link forthRegister Identifier"}' register.tsv > "$svd_syntax_register"

awk_syntax_bitfield_script='
BEGIN {
  FS = "	";
}
{
  btfld = $5 # Bitfield name
  bw    = $8 # Bit width

  # Bitfield name with no suffix
  print "syn keyword forthBitfield " btfld

  # Bitfield name with ! or !! suffix
  if ( ac != "ro" ) {
    print "syn keyword forthBitfield " btfld "!"
    print "syn keyword forthBitfield " btfld "!!"
  }
 
  # Bitfield name with @ suffix 
  if ( ac != "wo" ) {
    print "syn keyword forthBitfield " btfld "@"
   }
}
END {
  print "hi def link forthBitfield Identifier"
}
'
awk_script_file=$(mktemp)
echo "$awk_syntax_bitfield_script" > "$awk_script_file"

awk -f "$awk_script_file" bitfield.tsv > "$svd_syntax_bitfield"
rm "$awk_script_file"
#awk -F '\t' '{print "syn keyword forthBitfield " $5} END {print "hi def link forthBitfield Identifier"}' bitfield.tsv > "$svd_syntax_bitfield"

#==============================================================================
# CREATE VIM FILES FOR DICTIONARY
# =============================================================================

# Create dictionary files
awk -F '	' '{print $1}' peripheral.tsv > "$svd_dictionary_peripheral"
awk -F '	' '{print $3}' register.tsv > "$svd_dictionary_register"
awk -F '	' '{print $5}' bitfield.tsv > "$svd_dictionary_bitfield"

#==============================================================================
# CREATE FORTH BITFIELD NAME REPLACEMENT FILE ( for code substitution )
# =============================================================================
awk_bitfield_script='
BEGIN {
  FS = "	";
  OFS=FS;
}
{
  btfld = $5  # Bitfield name
  addr  = $6  # Register Address
  bo    = $7  # Bit offset
  bw    = $8  # Bit width
  ac    = $9  # Access rights (ro, wo, rw)

  # Bitfield name with no suffix
  if ( bo == 0 )
    print btfld, ""            # Do not bother with LSHIFT if offset is zero
  else
    print btfld, bo " LSHIFT"  # Normal bo with LSHIFT

  # Bitfield name with ! suffix
  if ( ac != "ro" ) {
    if ( bo == 0 )
      print btfld "!", "$" addr " BIS!"
    else
      print btfld "!", bo " LSHIFT $" addr " BIS!"
  }
  
  # Bitfield name with !! suffix (Clear bits first)
  if (ac != "ro" ) {
    if ( bo == 0 ) 
      print btfld "!!", ( 2 ** bw - 1 ) " $" addr " BIC! $" addr " BIS!"
    else
      print btfld "!!", ( 2 ** bw - 1 ) " " bo " LSHIFT $" addr " BIC! " bo " LSHIFT $" addr " BIS!"
  }

  # Bitfield name with @ suffix
  if (ac != "wo" ) {
    if ( bo == 0 )
      print btfld "@", ( 2 ** bw - 1 ) " $" addr " @ AND"
    else
      print btfld "@", ( 2 ** bw - 1 ) " " bo " LSHIFT $" addr " @ AND " bo " RSHIFT"
  }
}
'
awk_script_file=$(mktemp)
echo "$awk_bitfield_script" > "$awk_script_file"

# Create file
awk -F '	' 'BEGIN {OFS=FS} {print $1, "$" $2 }' peripheral.tsv > "$svd_replacement_bitfield"
awk -F '	' 'BEGIN {OFS=FS} {print $3, "$" $6 }' register.tsv >> "$svd_replacement_bitfield"
awk -f "$awk_script_file" bitfield.tsv >> "$svd_replacement_bitfield"
rm "$awk_script_file"

awk -F '	' '{print "s# " $1 " # " $2 " #gi"}' "$svd_replacement_bitfield" > sed_replace_script.sed

#==============================================================================
# CREATE VIM FILES FOR HELP
# =============================================================================

# -----------------------------------------------------------------------------
# SECTION: PERIPHERALS
# -----------------------------------------------------------------------------
#
# Create header for peripherals
periphwidth=$(awk -F '	' -v periph="$peripheral" '(length($1) > max) { max = length($1) } END { print max }' peripheral.tsv)
descwidth=$(awk -F '	' -v periph="$peripheral" '(length($3) > max) { max = length($3) } END { print max }' peripheral.tsv)
periphwidth=$((periphwidth < 12 ? 12 : periphwidth))
periphwidth=$((periphwidth + 2)) # for |'s
descwidth=$((descwidth + 2))
descwidht=$((descwidth < 12 ? 12 : descwidth))
totwidth=$(( 1 + periphwidth + 1 + 11 + 1 + descwidth))

head_p="*mcu.txt*  Help for $svd_file MCU Peripherals\n\n"
head_p="${head_p} PERIPHERALS for $svd_file~\n\n"

# Border line with dashes (-) and pluses (+)
border_p=" $(printf '%.0s-' $(seq "$periphwidth"))+"
border_p="${border_p}-----------+"
border_p="${border_p}$(printf '%.0s-' $(seq "$descwidth"))"

format="%${periphwidth}s | %-9s | %s"
title_p=$(printf "$format" "Peripheral" "Address" " Description")

head_p="${head_p}${border_p}\n"
head_p="${head_p}${title_p}\n"
head_p="${head_p}${border_p}"

#echo -e "${head_p}" >> "$svd_help_mcu"
echo "${head_p}" >> "$svd_help_mcu"

#descwidth=29  # Set your desired value for descwidth
awk -v pw="$periphwidth" -F '	' '{ 
  format = "  %"pw"s | %-9s | %s\n"; 
  printf format, "|" $1 "|", "$" $2, $3
  }' peripheral.tsv >> "$svd_help_mcu"

#echo -e "${border_p}\n\n" >> "$svd_help_mcu"
echo "${border_p}\n\n" >> "$svd_help_mcu"

# -----------------------------------------------------------------------------
# SECTION: REGISTERS
# -----------------------------------------------------------------------------
#
# Function to create a register entry
create_register_table() {
  local input_line="$1"
  peripheral=$(echo "$input_line" | awk -F '	' '{print $1}')
  baseAddress=$(echo "$input_line" | awk -F '	' '{print "$" $2}')
  description=$(echo "$input_line" | awk -F '	' '{print $3}')
  regwidth=$(awk -F '	' -v periph="$peripheral" '$1 == periph && (length($3) > max) { max = length($3) } END { print max }' register.tsv)
  descwidth=$(awk -F '	' -v periph="$peripheral" '$1 == periph && (length($9) > max) { max = length($9) } END { print max }' register.tsv)
  regwidth=$((regwidth < 9 ? 9 : regwidth))
  regwidth=$((regwidth + 2)) # for |'s
  descwidth=$((descwidth + 2))
  descwidht=$((descwidth < 12 ? 12 : descwidth))
  totwidth=$(( 1 + regwidth + 1 + 4 + 1 + 11 + 1 + 8 + 1 + 11 + 1 + descwidth))

  #topbar=$(printf '=%.0s' $(seq 1 "$totwidth"))

  head_r=""
  head_r="${head_r}\n\n"
  head_r="${head_r} REGISTERS~\n\n"
  head_r="${head_r} MCU:          $svd_file\n"
  head_r="${head_r} Peripheral:   *$peripheral*"
  head_r="${head_r} BaseAddress:  $baseAddress\n"
  head_r="${head_r} Description:  $description\n\n"

  # Border line with dashes (-) and pluses (+)
  border_r=" $(printf '%.0s-' $(seq "$regwidth"))+"
  border_r="${border_r}----+-----------+--------+-----------+"
  border_r="${border_r}$(printf '%.0s-' $(seq "$descwidth"))"

  format="%${regwidth}s | %-2s | %-9s | %-6s | %-9s | %s"
  title_r=$(printf "$format" "Register" "ac" "Reset" "Offset"  "Address" " Description")

  head_r="${head_r}${border_r}\n"
  head_r="${head_r}${title_r}\n"
  head_r="${head_r}${border_r}"
  
  # echo -e "${head_r}" >> "$svd_help_mcu"
  echo "${head_r}" >> "$svd_help_mcu"
  
  #descwidth=29  # Set your desired value for descwidth
  awk -v search="$peripheral" -v rw="$regwidth" -F '	' '$1 == search { 
    format = "  %"rw"s | %-2s | %-9s | %-4s   | %-9s | %s\n"; 
    printf format, "|" $3 "|", $8, "$" $7, "$" $5, "$" $6, $9
    }' register.tsv >> "$svd_help_mcu"

  #echo -e "${border_r}" >> "$svd_help_mcu"
  #echo -e " (ac) Access rights\n\n" >> "$svd_help_mcu"
  echo "${border_r}" >> "$svd_help_mcu"
  echo " (ac) Access rights\n\n" >> "$svd_help_mcu"
}

# Loop through each register
file_in="peripheral.tsv"
line_number=0
while IFS= read -r line; do
  create_register_table "$line"
done < "$file_in"

# -----------------------------------------------------------------------------
# SECTION: BITFIELDS
# -----------------------------------------------------------------------------
#
create_bitfield_table() {
  local input_line="$1"
  peripheral=$(echo "$input_line" | awk -F '	' '{print $1}')
  register=$(echo "$input_line" | awk -F '	' '{print $2}')
  address=$(echo "$input_line" | awk -F '	' '{print "$" $6}')
  reset=$(echo "$input_line" | awk -F '	' '{print "$" $7}')
  description=$(echo "$input_line" | awk -F '	' '{print $9}')
  peripheralregister=$(echo "$input_line" | awk -F '	' '{print $3}')
  page=$(awk -F '	' -v preg="$peripheralregister" '$2 == preg {print $1; exit}' $svd_rm_pages)
  refmanual="$svd_rm_pdf#page=$page" 

  bitwidth=$(awk -F '	' -v register="$peripheralregister" '$3 == register && (length($5) > max) { max = length($5) } END { print max }' bitfield.tsv)
  descwidth=$(awk -F '	' -v register="$peripheralregister" '$3 == register && (length($10) > max) { max = length($10) } END { print max }' bitfield.tsv)
  bitwidth=$((bitwidth < 9 ? 9 : bitwidth))
  bitwidth=$((bitwidth + 2)) # for |'s
  descwidth=$((descwidth + 2))
  descwidth=$((descwidth < 12 ? 12 : descwidth))
  totwidth=$(( 1 + bitwidth + 1 + 4 + 1 + 4 + 1 + 4 + 1 + 4 + 1 + descwidth))
  
  #topbar=$(printf '=%.0s' $(seq 1 "$totwidth"))

  head_b="\n\n"
  #head_b="${head_r} $topbar\n\n"

  head_b=" BITFIELDS~\n\n"
  head_b="${head_b} Peripheral:  |$peripheral|\n"
  head_b="${head_b} Register:    *$peripheralregister*\n"
  head_b="${head_b} Address:     $address\n"
  head_b="${head_b} Reset:       $reset\n"
  head_b="${head_b} Description: $description\n"
  head_b="${head_b} MCU:         $svd_file\n"
  head_b="${head_b} Ref Manual:  $refmanual\n"
  head_b="${head_b}              (place cursor on hyperlink, type 'gx' to follow)\n\n"

  # Border line with dashes (-) and pluses (+)
  border_b=" $(printf '%.0s-' $(seq "$bitwidth"))+"
  border_b="${border_b}----+----+----+----+"
  border_b="${border_b}$(printf '%.0s-' $(seq "$descwidth"))"

  format="%${bitwidth}s | %-2s | %-2s | %-2s | %-2s | %s"
  title_b=$(printf "$format" "Bitfield" "bo" "bw" "be"  "ac" "Description")

  head_b="${head_b}${border_b}\n"
  head_b="${head_b}${title_b}\n"
  head_b="${head_b}${border_b}"

#  echo -e "${head_b}" >> "$svd_help_mcu"
  echo "${head_b}" >> "$svd_help_mcu"
  
  awk -v search="$peripheralregister" -v bw="$bitwidth" -F '	' '$3 == search { 
    format = "  %"bw"s | %-2s | %-2s | %-2s | %-2s | %s\n"; 
    printf format, "*" $5 "*", $7, $8, $7 + $8 - 1, $9, $10
    }' bitfield.tsv >> "$svd_help_mcu"

#  echo -e "${border_b}" >> "$svd_help_mcu"
#  echo -e " (bo) bit offset, (bw) bitwidth, (be) bit end, (ac) access rights\n\n" >> "$svd_help_mcu"
  echo "${border_b}" >> "$svd_help_mcu"
  echo " (bo) bit offset, (bw) bitwidth, (be) bit end, (ac) access rights\n\n" >> "$svd_help_mcu"
}

# Loop through each bitfield
file_in="register.tsv"
line_number=0
while IFS= read -r line; do
  create_bitfield_table "$line"
done < "$file_in"


# Create footer for help file
#echo -e "\n\n\n# vim: ts=4 filetype=help" >> "$svd_help_mcu"
echo "\n\n\n# vim: ts=4 filetype=help" >> "$svd_help_mcu"

#==============================================================================
# CLEANUP TEMPORARY FILES
# =============================================================================

rm -f sorted_data.tmp
rm -f peripheral_lookup.tsv
rm -f peripheral_raw.tsv
rm -f peripheral_tmp.tsv
rm -f peripheral_tmp2.tsv
rm -f peripheral_tmp3.tsv
rm -f peripheral.tsv
rm -f register_raw.tsv
rm -f register_tmp.tsv
rm -f register.tsv
rm -f bitfield_raw.tsv
rm -f bitfield_tmp.tsv
rm -f bitfield.tsv
rm -f bit_tmp.txt
rm -f bits.txt
rm -f mcu_replacement_bitfield.txt

