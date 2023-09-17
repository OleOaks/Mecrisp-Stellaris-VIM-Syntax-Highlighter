#!/bin/sh
# created for Mecrisp-Stellaris Forth by Matthias Koch
# This script converts an CMSIS-SVD file into multiple VIM files
#   to enable auto-completion and syntax highlighting.
# By Brett Olson "brettolson@cox.net" 2023, released under the MIT License

# Store the current working directory
current_directory=$(pwd)

# Store the svd directory
svd_directory=/home/brett/forth/STM32-Blue-Pill-Book/common/svd2forth-v3-stm32

# Store the svd filename
svd_file=STM32F103xx.svd
#svd_file=STM32H7x3.svd

# Store the svd path/file
up="$svd_directory/$svd_file"

# MCU syntax files ( for highlighting )
svd_syntax_peripheral="$HOME/.vim/syntax/mcu/mcu_peripheral.vim"
svd_syntax_register="$HOME/.vim/syntax/mcu/mcu_register.vim"
svd_syntax_bitfield="$HOME/.vim/syntax/mcu/mcu_bitfield.vim"

# MCU dictionary files ( for auto-complete )
svd_dictionary_peripheral="$HOME/.vim/words/mcu_peripheral.txt"
svd_dictionary_register="$HOME/.vim/words/mcu_register.txt"
svd_dictionary_bitfield="$HOME/.vim/words/mcu_bitfield.txt"

# MCU help files
svd_help_mcu="$HOME/.vim/doc/mcu.txt"
if [ -e "$svd_help_mcu" ]; then
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
# Extract peripheral data from svd file
xml sel -t -m "//peripheral" -v "@derivedFrom" -o "	" -v "name" -o "	" -v "baseAddress" -o "	" -v "normalize-space(description)" -n "$up" > peripheral_raw.tsv
#
# Extract register data from svd file
xml sel -t -m "//register" -v "../../name" -o "	" -v "name" -o "	"  -v "access" -o "	" -v "resetValue" -o "	" -v "addressOffset" -o "	" -v "normalize-space(description)" -n "$up" > register_raw.tsv

# Extract bitfield data from svd file
xml sel -t -m "//field" -v "../../../../name" -o "	" -v "../../name" -o "	" -v "name" -o "	" -v "bitOffset" -o "	" -v "bitWidth" -o "	" -v "access" -o "	" -v "normalize-space(description)" -n "$up" > bitfield_raw.tsv

# Text substitutions for access type, and removing hex value prefixes 0x
tmpfile=$(mktemp)

# =============================================================================
# COPY MISSING DATA FOR @derivedFrom PERIPHERALS
# =============================================================================
#
# Create a peripheral lookup file to help in copying missing data
awk -F '\t' 'BEGIN {OFS=FS} { if ($1=="") { print $2, $2, $3 } else { print $1, $2, $3 }} ' peripheral_raw.tsv > peripheral_lookup.tsv

# Create peripheral file
# Process the output.tmp file to fill in missing information (i.e. description) for "@derivedFrom" peripherals
# Set input file field separator: -F ',' 
# Set output file field spearator:  BEGIN {OFS=FS}
# Create an associative array name lookup, field 4 (desc) of lookup = ? don't know exactly how this works
# If field 1 is a blank line, do nothing except print fields 2, 3, and 4
# If field 1 is not blank, lookup field 1 in field2, print fields 2, 3, and the matching row's field 4
awk -F '\t' 'BEGIN {OFS=FS} NR==FNR {lookup[$2] = $4; next} $1 == "" {print $2, $3, $4; next} {print $2, $3, lookup[$1]}' peripheral_raw.tsv peripheral_raw.tsv > peripheral.tsv

# Create register file
peripheral_lookup="peripheral_lookup.tsv"
register_raw="register_raw.tsv"
output_tsv="register_tmp.tsv"
# Remove the existing output file if it exists
rm -f "$output_tsv"
# Loop through each word in peripheral_lookup.tsv
while IFS=$'\t' read -r derivedFrom peripheral baseAddress ; do
    # Use grep to find all lines from register_raw.tsv that start with the current peripheral
    matches=$(grep "^$derivedFrom	" "$register_raw")
    # Print peripheral and baseAddress from peripheral_raw.tsv and the matching lines from register_raw.tsv to registers.tsv
    echo "$matches" | sed "s/^/$peripheral\t$baseAddress\t/" >> "$output_tsv"
done < "$peripheral_lookup"

# =============================================================================
# COPY MISSING DATA FOR @derivedFrom REGISTERS
# =============================================================================
#
# Remove the @derivedFrom peripheral name: register.tsv-->Peripheral(1), BaseAddr(2), Register(3), Access(4), Reset(5), Offset(6), Description(7)
awk -F '\t' 'BEGIN {OFS=FS} {print $1, $2, $4, $5, $6, $7, $8 }' "$output_tsv" > register.tsv

# Calculate absolute register addresss: tempfile--> Peripheral(1), Register(2), BaseAddr(3), Offset(4), AbsAddr(5), Reset(6), Access(7), Description(8)
awk -F '\t' 'BEGIN {OFS=FS} { absAddr = sprintf("%X", $2 + $6); print $1, $3, $2, $6, absAddr, $5, $4, $7 }' register.tsv > "$tmpfile"
mv "$tmpfile" register.tsv

# Concatenate peripheral-register name: tempfile-->Peripheral(1), Register(2), Per-Reg(3), BaseAddr(4), Offset(5), AbsAddr(6), Reset(7), Access(8), Description(9)
awk -F '\t' 'BEGIN {OFS=FS} { print $1, $2, $1 "_" $2, $3, $4, $5, $6, $7, $8 }' register.tsv > "$tmpfile"
mv "$tmpfile" register.tsv

# Create bitfield file
peripheral_lookup="peripheral_lookup.tsv"
bitfield_raw="bitfield_raw.tsv"
output_tsv="bitfield_tmp.tsv"
# Remove the existing output file if it exists
rm -f "$output_tsv"
# Loop through each word in peripheral_lookup.tsv
while IFS=$'\t' read -r derivedFrom peripheral baseAddress; do
    # Use grep to find all lines from bitfields_raw.tsv that start with the current peripheral
    matches=$(grep "^$derivedFrom	" "$bitfield_raw")
    # Print peripheral and baseAddress from peripheral_raw.tsv and the matching lines from bitfield_raw.tsv to registers.csv
    # bitfield_tmp.tsv --> Peripheral(1), BaseAddr(2)
    echo "$matches" | sed "s/^/$peripheral\t$baseAddress\t/" >> "$output_tsv"
done < "$peripheral_lookup"

# Remove the @derivedFrom peripheral name
awk -F '\t' 'BEGIN {OFS=FS} {print $1, $2, $4, $5, $6, $7, $8, $9 }' "$output_tsv" > bitfield.tsv

# Concatenate peripheral-register name, and peripheral-register-bitfield name
awk -F '\t' 'BEGIN {OFS=FS} { print $1, $3, $1 "_" $3, $4, $1 "_" $3 "_" $4, $5, $6, $7, $8 }' bitfield.tsv > "$tmpfile"
mv "$tmpfile" bitfield.tsv

# Process each line in bitfield.tsv, get the absolute address from register.tsv
awk -F'\t' 'BEGIN {OFS=FS} NR == FNR { register[$3] = $6; next } { key = $3; if (key in register) { print $1, $2, $3, $4, $5, register[key], $6, $7, $8, $9 } }' register.tsv bitfield.tsv > "$tmpfile"
mv "$tmpfile" bitfield.tsv

awk -F'\t' 'BEGIN {OFS=FS} NR == FNR { access = ( $9 == "" ) ? "rw" : $9; print $1, $2, $3, $4, $5, $6, $7, $8, access, $10 }' bitfield.tsv > "$tmpfile"
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
awk -F '\t' '{print "syn keyword forthPeripheral " $1} END {print "hi def link forthPeripheral Identifier"}' peripheral.tsv > "$svd_syntax_peripheral"
awk -F '\t' '{print "syn keyword forthRegister " $3} END {print "hi def link forthRegister Identifier"}' register.tsv > "$svd_syntax_register"
awk -F '\t' '{print "syn keyword forthBitfield " $5} END {print "hi def link forthBitfield Identifier"}' bitfield.tsv > "$svd_syntax_bitfield"

#==============================================================================
# CREATE VIM FILES FOR DICTIONARY
# =============================================================================

# Create dictionary files
awk -F '\t' '{print $1}' peripheral.tsv > "$svd_dictionary_peripheral"
awk -F '\t' '{print $3}' register.tsv > "$svd_dictionary_register"
awk -F '\t' '{print $5}' bitfield.tsv > "$svd_dictionary_bitfield"

#==============================================================================
# CREATE VIM FILES FOR HELP
# =============================================================================

# -----------------------------------------------------------------------------
# SECTION: PERIPHERALS
# -----------------------------------------------------------------------------
#
# Create header for peripherals
head_p="*mcu.txt*  Help for $svd_file MCU Peripherals\n\n"
head_p="${head_p}         $svd_file  PERIPHERALS"
head_p="${head_p}          by Brett Olson\n\n"
head_p="${head_p} ------------------------------+-----------+---------------------------------------------------\n"
head_p="${head_p}                    Peripheral | Address   | Description\n"
head_p="${head_p} ------------------------------+-----------+---------------------------------------------------\n"

echo -e "${head_p}" >> "$svd_help_mcu"

#awk -F '\t' '{print "     |" $1 "|	" $2 "	" $3}' peripheral.tsv >> "$svd_help_mcu"
awk -F '\t' 'NR==FNR { printf "  %30s | %-9s | %s\n", "|" $1 "| ", "$" $2 , $3 }' peripheral.tsv peripheral.tsv >> "$svd_help_mcu"
#awk -F '\t' 'NR==FNR {w = length($1) > w ? length($1) : w; next} {$1 = "|" $1 "|"} { $1 = sprintf("%*s", w+5, $1)} { print "   " $1 " | $" $2 " | " $3 }' peripheral.tsv peripheral.tsv >> "$svd_help_mcu"
#awk -F '\t' 'NR==FNR {w = length($1) > w ? length($1) : w; next} {print $0 }' peripheral.tsv peripheral.tsv >> "$svd_help_mcu"

# -----------------------------------------------------------------------------
# SECTION: REGISTERS
# -----------------------------------------------------------------------------
#
# Function to create a register entry
create_register_table() {
  local input_line="$1"
  peripheral=$(echo "$input_line" | awk -F '\t' '{print $1}')
  baseAddress=$(echo "$input_line" | awk -F '\t' '{print "$" $2}')
  description=$(echo "$input_line" | awk -F '\t' '{print $3}')

  # Create header for registes
  head_r=" ==========================================================================================================\n\n"
  head_r="${head_r} REGISTERS\n\n"
  head_r="${head_r} MCU:          $svd_file\n"
  head_r="${head_r} Peripheral:   *$peripheral*\n"
  head_r="${head_r} BaseAddress:  $baseAddress\n"
  head_r="${head_r} Description:  $description\n\n"
  head_r="${head_r} ---------------------------+----+-----------+--------+-----------+-----------------------------------------\n"
  head_r="${head_r}                   Register | Ac | Reset     | Offset | Address   | Description\n"
  head_r="${head_r} ---------------------------+----+-----------+--------+-----------+-----------------------------------------\n"
  
  echo -e "${head_r}" >> "$svd_help_mcu"
  
  #awk -v search="$peripheral" -F '\t' '$1 == search { $1 = sprintf("%-*s", 9, $1) " |" $1 "|" $2 "| | " $3 " | " $4 " | " $5 " | " $6}' register.tsv >> "$svd_help_mcu"
  awk -v search="$peripheral" -F '\t' '$1 == search { printf "  %27s | %-2s | %-9s | %-4s   | %-9s | %s\n", "|" $3 "|", $8, "$" $7, "$" $5, "$" $6, $9}' register.tsv >> "$svd_help_mcu"
  #awk -F '\t' 'NR==FNR {w = length($1) > w ? length($1) : w; next} {$1 = "|" $1 "|"} { $1 = sprintf("%-*s", w+5, $1)} { print "   " $1 " | " $2 " | " $3 }' peripheral.tsv peripheral.tsv >> "$svd_help_mcu"
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
  peripheral=$(echo "$input_line" | awk -F '\t' '{print $1}')
  register=$(echo "$input_line" | awk -F '\t' '{print $2}')
  address=$(echo "$input_line" | awk -F '\t' '{print "$" $6}')
  reset=$(echo "$input_line" | awk -F '\t' '{print "$" $7}')
  description=$(echo "$input_line" | awk -F '\t' '{print $9}')
  peripheralregister=$(echo "$input_line" | awk -F '\t' '{print $3}')
  
  # Create header for registes
  head_b=" BITFIELDS~\n\n"
  head_b="${head_b} Peripheral:  |$peripheral|\n"
  head_b="${head_b} Register:    *$peripheralregister*\n"
  head_b="${head_b} Address:     $address\n"
  head_b="${head_b} Reset:       $reset\n"
  head_b="${head_b} Description: $description\n"
  head_b="${head_b} MCU:         $svd_file\n"
  head_b="${head_b} -------------------------+----+----+----+-----------------------------------------\n"
  head_b="${head_b}                 Bitfield | bo | bw | ac | Description\n"
  head_b="${head_b} -------------------------+----+----+----+-----------------------------------------\n"

  echo -e "${head_b}" >> "$svd_help_mcu"
  
  #awk -v search="$peripheral" -F '\t' '$1 == search { $1 = sprintf("%-*s", 9, $1) " |" $1 "|" $2 "| | " $3 " | " $4 " | " $5 " | " $6}' register.tsv >> "$svd_help_mcu"
  awk -v search="$peripheralregister" -F '\t' '$3 == search { printf "   %24s | %-2s | %-2s | %-2s | %s\n", "*" $5 "*", $7, $8, $9, $10}' bitfield.tsv >> "$svd_help_mcu"
  #awk -F '\t' 'NR==FNR {w = length($1) > w ? length($1) : w; next} {$1 = "|" $1 "|"} { $1 = sprintf("%-*s", w+5, $1)} { print "   " $1 " | " $2 " | " $3 }' peripheral.tsv peripheral.tsv >> "$svd_help_mcu"
  create_bitfield_graphic "$input_line"

}

create_bitfield_graphic() {
  minchar=4
  # Create file limited to this register. Include name, bitoffsest, bitwidth, access. Also, calculate min char needed for each name
  awk -v search="$peripheralregister" -v minwidth="$minchar" -F '\t' '$3 == search { numcells = $8; minavail = numcells * minwidth; nameneed = length($4) + 2; max = ( minavail > nameneed ) ? minavail : nameneed; newcellsize = int(max / numcells); print $4, $7, $8, $9, newcellsize }' bitfield.tsv > bit_tmp.txt

  # Sort rows in bit_tmp.txt ascending by bit offset. SVD is inconsistent and lists bitfields in both directions
  sort -t' ' -k2,2n bit_tmp.txt > sorted_data.txt
  mv sorted_data.txt bit_tmp.txt


  cellwidth=0
  cellwidth=$(awk 'NR==FNR {w = $5 > w ? $5 : w; next} END { print w }' bit_tmp.txt)

  # Add rows for reserved sections to bit_tmp.txt
  bitdata=""
  file="bits.txt"
  if [ -e "$file" ]; then
    > "$file"
  else
    touch "$file"
  fi
  cursor=0
  newbo=0
  newbw=0

  while IFS=" " read -r name bo bw ac _; do
    #left=$((bo + bw))
    #newbo="$bo"
    if [ "$bo" -gt "$cursor" ]; then # Bits were skipped, add a reserved section
      newbo="$cursor"
      newbw=$(( bo - cursor ))
      #if [ ( "$bo" -lt 16 ) && ( $ 
      #cursor="$newbo"
      if [ "$newbo" -le 15 ] && [ $(( newbw + newbo )) -gt 16 ]; then # If reserved crosses 16, split around 16
        bitdata="${bitdata}res $newbo $(( 16 - newbo )) $ac\n"
        bitdata="${bitdata}res 16 $(( bo - 16 )) $newbw $ac\n"
      else
        bitdata="${bitdata}res $newbo $newbw $ac\n"
      fi
      #cursor=$(( cursor + newbw )) 
    else
    fi
    if [ "$bo" -le 15 ] && [ $(( bo + bw )) -gt 16 ]; then # If named crosses 16, split around 16 
      bitdata="${bitdata}$name $bo $(( 16 - bo )) $ac\n"
      bitdata="${bitdata}$name 16 $(( bo + bw - 16 )) $ac\n"
    else
      bitdata="${bitdata}$name $bo $bw $ac\n"
    fi
    cursor=$(( bo + bw ))
  done < bit_tmp.txt

  # Check if we are on the last line
  if [ "$cursor" -lt 31 ]; then # Add reserved section at end
    newbw=$(( 32 - cursor ))
    if [ "$cursor" -le 15 ] && [ $(( newbw + cursor )) -gt 16 ]; then # Split at 16
      bitdata="${bitdata}res $cursor $(( 16 - cursor )) $ac\n"
      bitdata="${bitdata}res 16 16 $ac\n"
    else
      bitdata="${bitdata}res $cursor $newbw $ac\n"
    fi
  fi

  echo -e "${bitdata}" >> "$file"

  #awk '{ print $0}' bits.txt >> "$svd_help_mcu"

  # Print high 16 bits of word
  echo -e "" >> "$svd_help_mcu"
  
  count=16


  # Generate bit number labels
  split_column=$(( (cellwidth + 1) * 16 ))
  #echo -e "spit_column=$split_column" >> "$svd_help_mcu"
  bit_labels=""
  # Generate bit labels
  for i in $(seq 0 31); do
    len="${#i}"  
    width=$(((cellwidth - len) / 2 + len))
    remain=$((cellwidth - width))
    bit_labels="$(printf ' %*s%*s' "$width" "$i" "$remain" " ")${bit_labels}"
  done
  #echo -e "$bit_labels" >> "$svd_help_mcu"
  
  bit_bar="+"
  bit_name="|"
  bit_access="|"
  midbit_bar="+"

  # Generate top/bottom bar
  for i in $(seq 0 31); do
    for j in $(seq 1 $cellwidth); do
      bit_bar="${bit_bar}-"
    done
    bit_bar="${bit_bar}+"
  done

  # Generate bit names
  # Read each line from the bit_tmp.txt file
  while IFS=" " read -r name bo bw ac _; do
    #echo "line=$name,$bo,$bw, $cellwidth" >> "$svd_help_mcu"
      total_width=$((((cellwidth + 1) * bw) ))
      name_len="${#name}"
      ac_len="${#ac}"
      rtpad_name=$(( (total_width - name_len) / 2 ))
      ltpad_name=$(( total_width - name_len - rtpad_name - 1))
      rtpad_ac=$(( (total_width - ac_len) / 2 ))
      ltpad_ac=$(( total_width - ac_len - rtpad_ac - 1))
      space_width=$((cellwidth * bw + bw - 1))
      if [ "$name" = "res" ]; then # print midbit_bar res, leave name and access empty
        bit_name="|$(printf "%-${space_width}s" "")${bit_name}"
        bit_access="|$(printf "%-${space_width}s" "")${bit_access}"
        midbit_bar="+$(printf "%-*s%s%*s" "$ltpad_name" " " "$name" "$rtpad_name")${midbit_bar}"
      else # print name and ac, leave midbit_bar empty
        bit_name="|$(printf "%-*s%s%*s" "$ltpad_name" " " "$name" "$rtpad_name")${bit_name}"
        bit_access="|$(printf "%-*s%s%*s" "$ltpad_ac" " " "$ac" "$rtpad_ac")${bit_access}"
        dash_width=$((cellwidth * bw + bw - 1))
        for j in $(seq 1 $dash_width); do
          midbit_bar="-${midbit_bar}"
        done
        midbit_bar="+${midbit_bar}"
      fi
  done < bits.txt

  bit_labels_high="$(echo "$bit_labels" | cut -c 1-$split_column)"
  bit_bar_high="$(echo "$bit_bar" | cut -c 1-$split_column)+"
  bit_name_high="$(echo "$bit_name" | cut -c 1-$split_column)|"
  midbit_bar_high="$(echo "$midbit_bar" | cut -c 1-$split_column)|"
  bit_access_high="$(echo "$bit_access" | cut -c 1-$split_column)|"
  bit_bar_high="$(echo "$bit_bar" | cut -c 1-$split_column)+"

  bit_labels_low="$(echo "$bit_labels" | cut -c $((split_column+1))-)"
  bit_bar_low="$(echo "$bit_bar" | cut -c $((split_column+1))-)"
  bit_name_low="$(echo "$bit_name" | cut -c $((split_column+1))-)"
  midbit_bar_low="$(echo "$midbit_bar" | cut -c $((split_column+1))-)"
  bit_access_low="$(echo "$bit_access" | cut -c $((split_column+1))-)"
  bit_bar_low="$(echo "$bit_bar" | cut -c $((split_column+1))-)"

  high="${bit_labels_high}\n"
  high="${high}${bit_bar_high}\n"
  high="${high}${bit_name_high}\n"
  high="${high}${midbit_bar_high}\n"
  high="${high}${bit_access_high}\n"
  high="${high}${bit_bar_high}\n"
  high="${high}\n"

  low="${bit_labels_low}\n"
  low="${low}${bit_bar_low}\n"
  low="${low}${bit_name_low}\n"
  low="${low}${midbit_bar_low}\n"
  low="${low}${bit_access_low}\n"
  low="${low}${bit_bar_low}\n"
  low="${low}\n"

  echo -e "${high}${low}" >> "$svd_help_mcu"
}

# Loop through each bitfield
file_in="register.tsv"
line_number=0
while IFS= read -r line; do
  create_bitfield_table "$line"
done < "$file_in"


# Create footer for help file
echo -e "\n\n\n# vim: ts=4 filetype=help" >> "$svd_help_mcu"

#==============================================================================
# CLEANUP TEMPORARY FILES
# =============================================================================

rm -f sorted_data.tmp
rm -f peripheral_lookup.tsv
rm -f peripheral_raw.tsv
rm -f peripheral.tsv
rm -f register_raw.tsv
rm -f register_tmp.tsv
rm -f register.tsv
rm -f bitfield_raw.tsv
rm -f bitfield_tmp.tsv
rm -f bitfield.tsv
rm -f bit_tmp.txt
rm -f bits.txt

