" Vim syntax file
" Language:    MECRISP-STELLARIS FORTH
" Current Maintainer:  Brett Olson
" Heavily modified from packaged version by Johan Kotlinski <kotlinski@gmail.com>
" Last Change: 2023-09-16
" By Brett Olson "brettolson@cox.net" 2023, released under the MIT License
" Filenames:   *.fs
"
" Personally, my favorite colorscheme with this syntax is 'Slate'
"
" 
" -----------------------------------------------------------------------------
" Installation
" -----------------------------------------------------------------------------
" 
" 1. Save this file to ~/.vim/syntax/forth.vim
" 
" 2. Optional: Create a new common.vim file for non-standard Mecrisp words you use often.
"              My common includes words for BitManipulations, Dump, Dissassembler, GPIO, etc...
"
"              e.g. syn keyword forthCustomWord bs!        " Syntax for a word to set a bit at position u
"                   syn keyword forthCustomWord bsf        " Syntax for a word to shift a mask pattern into another value
"                   hi def link forthCustomWord Identifier " Assign the Identifier syntax to the forthCustomWorld group
"          
"              Save the common file to ~/.vim/syntax/common.vim
"
"              To include this file, add ':runtime! syntax/common.vim' to the bottom of this file
"
" 3. Optional: Create an new MCU specific .vim file for SVD peripheral-register names
"              I have a specific file for a bluepill, stm32f103c8t6.vim (notice my file is more specific
"                than the general stm32f103 because I want to include only the peripheral-registers
"                that are used on the bluepill. The standard SVD for stmf103 has more peripherals and I don't want to see those
"              
"              e.g. syn keyword ForthConversion GPIOA_CRL
"                   syn keyword ForthConversion RCC_APB2ENR
"                   hi def link Forthconversion Identifier 
"
"              Save the MCU file to ~/.vim/syntax/mcu_name.vim (e.g. stm32f103c8t6.vim)
"
"              To include this file, add ':runtime! syntax/mcu/mcu_name.vim' to the bottom of this file (e.g. syntax/mcu/stm32f103c8t6.vim)
"
" 4. VIM auto-completion: Syntax keywords can be used with VIM auto-completion
"    In insert mode, after typing the first few letters use ctrl-p to popup the auto-completion tool
"

" quit when a syntax file was already loaded
if exists("b:current_syntax")
    finish
endif

let s:cpo_save = &cpo
set cpo&vim

" Synchronization method
syn sync ccomment
syn sync maxlines=400

" Mecrisp-Stellaris forth is case-insensitive
syn case ignore

source ~/.vim/syntax/mcu/mcu_peripheral.vim
source ~/.vim/syntax/mcu/mcu_register.vim
source ~/.vim/syntax/mcu/mcu_bitfield.vim

" Some special, non-FORTH keywords
syn keyword forthTodo contained TODO FIXME XXX

" Characters allowed in keywords
" I don't know if 128-255 are allowed in ANS-FORTH
setlocal iskeyword=!,@,33-35,%,$,38-64,A-Z,91-96,a-z,123-126,128-255

" when wanted, highlight trailing white space
if exists("forth_space_errors")
    if !exists("forth_no_trail_space_error")
        syn match forthSpaceError display excludenl "\s\+$"
    endif
    if !exists("forth_no_tab_space_error")
        syn match forthSpaceError display " \+\t"me=e-1
    endif
endif

" -----------------------------------------------------------------------------
" Keywords
" -----------------------------------------------------------------------------

" Number Bases
syn keyword forthNumberBases BINARY DECIMAL HEX BASE

" Terminal-IO
syn keyword forthTerminalIO EMIT? KEY? KEY EMIT HOOK-EMIT? HOOK-KEY?
syn keyword forthTerminalIO HOOK-KEY HOOK-EMIT SERIAL-EMIT? SERIAL-KEY?
syn keyword forthTerminalIO SERIAL-KEY SERIAL-EMIT HOOK-PAUSE PAUSE

" Character Manipulation
syn keyword forthCharacterManipulation CHAR
syn match forthCharacterManipulation '\<\[CHAR\]'

" Single-Jugglers
syn keyword forthSingleJugglers DEPTH NIP DROP ROT -ROT SWAP TUCK OVER ?DUP
syn keyword forthSingleJugglers DUP PICK >R R> R@ RDROP RDEPTH RPICK ROLL -ROLL

" Double-Jugglers
syn keyword forthDoubleJugglers 2NIP 2DROP 2ROT 2-ROT 2SWAP 2TUCK 2OVER 2DUP 2>R
syn keyword forthDoubleJugglers 2R> 2R@ 2RDROP

" Stack Pointers
syn keyword forthStackPointers SP@ SP! RP@ RP!

" Logic
syn keyword forthLogic ARSHIFT RSHIFT LSHIFT SHR SHL ROR ROL BIC NOT XOR OR
syn keyword forthLogic AND FALSE TRUE CLZ

" Single Number Math
syn keyword forthSingleNumberMath U/MOD /MOD MOD / * MIN MAX UMIN UMAX 2-
syn keyword forthSingleNumberMath 1- 2+ 1+ EVEN 2* 2/ ABS NEGATE - +

" Double Number Math
syn keyword forthDoubleNumberMath UM* UD* UDM* UM/MOD UD/MOD M* M/MOD
syn keyword forthDoubleNumberMath D/MOD D/ */ U*/ */MOD U*/MOD D2* D2/
syn keyword forthDoubleNumberMath DSHL DSHR DABS DNEGATE D- D+ S>D

" Fixed Point Arithmetic
syn keyword forthFixedPointArithmetic F/ F* HOLD< F#S F# F. F.N NUMBER

" Unsigned Comparisons
syn keyword forthUnsignedComparisons U<= U>= U> U< 

" Signed Comparisons
syn keyword forthSignedComparisons <= >= > < 0< 0<> 0= <> =

" Double-Comparisons
syn keyword forthDoubleComparisons DU> DU< D> D< D0< D0= D<> D=

" Bits
syn keyword forthBits CBIT@ HBIT@ BIT@ CXOR! HXOR! XOR! CBIC!
syn keyword forthBits HBIC! BIC! CBIS! HBIS! BIS!

" Memory Status
syn keyword forthMemoryStatus UNUSED

" Memory Access
syn keyword forthMemoryAccess MOVE FILL
syn keyword forthMemoryAccess 2@ 2! @ ! +! H@ H! H+! C@ C! C+!
" 2Constant-Space-WordName
syn match forthMemoryAccess /\s2constant\s\S*/
" Constant-Space-WordName
syn match forthMemoryAccess /\sconstant\s\S*/
" 2VARIABLE-Space-WordName
syn match forthMemoryAccess /\s2variable\s\S*/
" VARIABLE-Space-WordName
syn match forthMemoryAccess /\svariable\s\S*/
" NVARIABLE-Space-WordName
syn match forthMemoryAccess /\snvariable\s\S*/
" BUFFER:-Space-WordName
syn match forthMemoryAccess /\(^\|\s\)buffer:\s\S*/

" String Routines
syn keyword forthStringRoutines TYPE CR BL SPACE SPACES COMPARE ACCEPT
  " Period-DoubleQuote-Space -> anything -> DoubleQuote
syn region forthStringRoutines start=+\.\"\s+ end=+\"+
  " S-DoubleQuote-Space -> anything -> DoubleQuote
syn region forthStringRoutines start=+s\"\s+ end=+\"+

" Counted String Routines
syn keyword forthCountedStringRoutines CTYPE CEXPECT COUNT SKIPSTRING
  " C-DoubleQuote-Space -> anything -> DoubleQuote
syn region forthStringRoutines start=+c\"\s+ end=+\"+

" Pictured Numerical Output
syn keyword forthPicturedNumericalOutput .DIGIT DIGIT HOLD HOLD< SIGN #S f#S #
syn keyword forthPicturedNumericalOutput F# #> <# U. . UD. D.

" Deep Insights
syn keyword forthDeepInsights WORDS LIST .S U.S H.S HEX.

" User Input and Interpretation
syn keyword forthUserInputInterpretation QUERY TIB CURRENT-SOURCE TSOURCE SOURCE
syn keyword forthUserInputInterpretation >IN TOKEN PARSE EVALUATE INTERPRET
syn keyword forthUserInputInterpretation QUIT HOOK-QUIT

" Dictionay Expansion
syn keyword forthDictionaryExpansion ALIGN ALIGNED CELL+ CELLS ALLOT HERE , <>,
syn keyword forthDictionaryExpansion H, COMPILETORAM? COMPILETORAM
syn keyword forthDictionaryExpansion COMPILETOFLASH FORGETRAM

" Speciality
syn keyword forthSpeciality STRING, LITERAL, INLINE, CALL, JUMP, CJUMP, RET,
syn keyword forthSpeciality FLASHVAR-HERE DICTIONARYSTART DICTIONARYNEXT

" Special Words Depending on MCU Capabilities
syn keyword forthMCUDependent C, HALIGN MOVWMOVT, REGISTERLITERAL, 12BITENCODING
syn keyword forthMCUDependent ERASEFLASH ERASEFLASHFROM FLASHPAGEERASE HFLASH!

" Flags and Inventory
syn keyword forthFlagsAndInventory SMUDGE INLINE IMMEDIATE COMPILEONLY
syn keyword forthFlagsAndInventory SETFLAGS NAME FIND

" Folding
syn keyword forthFolding 0-FOLDABLE 1-FOLDABLE 2-FOLDABLE 3-FOLDABLE 4-FOLDABLE
syn keyword forthFolding 5-FOLDABLE 6-FOLDABLE 7-FOLDABLE 

" Compiler Essentials
syn keyword forthCompilerEssentials EXECUTE RECURSE ' ['] POSTPONE <BUILDS DOES>
syn keyword forthCompilerEssentials STATE 
    " Left square bracket, right square bracket, semicolon, or colon
syn match forthCompilerEssentials '\<[:;[\]]\>'
    " LeftBracket-Apostrophe-RightBracket
syn match forthCompilerEssentials +\<\['\]\>+
    " Colon-Space-WordName
syn match forthColonDef /^:\s*\S*/
    " Create-Space-WordName
syn match forthMemoryAccess /\screate\s\S*/

" Decisions
syn keyword forthDecisions THEN ELSE IF

" Case
syn keyword forthCase CASE OF ?OF ENDOF ENDCASE

" IndefiniteLoops
syn keyword forthIndefiniteLoops REPEAT WHILE UNTIL AGAIN BEGIN

" DefiniteLoops
syn keyword forthDefiniteLoops I J K UNLOOP EXIT LEAVE +LOOP LOOP ?DO DO

" Common Hardware Access
syn keyword forthHardwareAccess RESET DINT EINT EINT? NOP IPSR UNHANDLED
syn keyword forthHardwareAccess IRQ-SYSTICK IRQ-FAULT IRQ-COLLECTION

" IRQs
syn keyword forthHardwareAccess irq-systick
syn keyword forthHardwareAccess irq-fault
syn keyword forthHardwareAccess irq-collection
syn keyword forthHardwareAccess irq-rtc
syn keyword forthHardwareAccess irq-exti0
syn keyword forthHardwareAccess irq-exti1
syn keyword forthHardwareAccess irq-exti2
syn keyword forthHardwareAccess irq-exti3
syn keyword forthHardwareAccess irq-exti4
syn keyword forthHardwareAccess irq-adc
syn keyword forthHardwareAccess irq-exti5
syn keyword forthHardwareAccess irq-tim1brk
syn keyword forthHardwareAccess irq-tim1up
syn keyword forthHardwareAccess irq-tim1trg
syn keyword forthHardwareAccess irq-tim1cc
syn keyword forthHardwareAccess irq-tim2
syn keyword forthHardwareAccess irq-tim3
syn keyword forthHardwareAccess irq-tim4
syn keyword forthHardwareAccess irq-i2c1ev
syn keyword forthHardwareAccess irq-i2c1er
syn keyword forthHardwareAccess irq-i2c2ev
syn keyword forthHardwareAccess irq-i2c2er
syn keyword forthHardwareAccess irq-spi1
syn keyword forthHardwareAccess irq-spi2
syn keyword forthHardwareAccess irq-usart1
syn keyword forthHardwareAccess irq-usart2
syn keyword forthHardwareAccess irq-usart3
syn keyword forthHardwareAccess irq-exti10
syn keyword forthHardwareAccess irq-rtcalarm
syn keyword forthHardwareAccess irq-usbwkup
syn keyword forthHardwareAccess irq-tim5
syn keyword forthHardwareAccess irq-spi3
syn keyword forthHardwareAccess irq-uart4
syn keyword forthHardwareAccess irq-uart5
syn keyword forthHardwareAccess irq-tim6
syn keyword forthHardwareAccess irq-tim7
syn keyword forthHardwareAccess irq-usbfs

" -----------------------------------------------------------------------------
" SPECIAL
" -----------------------------------------------------------------------------

" char
syn match forthCharOps '\<char\s\S\s'
syn match forthCharOps '\<\[char\]\s\S\s'

" numbers
syn match forthInteger '\<-\=[0-9]\+.\=\>'
syn match forthInteger '\<&-\=[0-9]\+.\=\>'
syn match forthInteger '\<#-\=[0-9]\+.\=\>'

" hex, binary, and fixedpoint, the '$' is for Mecrisp-Stellaris 
syn match forthInteger '\<\$\x*\x\+\>'
syn match forthInteger '\<%[0-1]*[0-1]\+\>'
syn match forthFixed '\<-\=\d*,\d*\>'

" Stack definition comment
syn match forthStackDef /(.*)/

" Comments
syn match forthComment '\\\(\s.*\)\=$' contains=@Spell,forthTodo,forthSpaceError


" -----------------------------------------------------------------------------
" ASSIGN COLORS
" -----------------------------------------------------------------------------

" Define the default highlighting.
hi def link forthTodo Todo

hi def link forthNumberBases Debug
hi def link forthTerminalIO Identifier
hi def link forthCharacterManipulation String
hi def link forthSingleJugglers Define
hi def link forthDoubleJugglers Define
hi def link forthStackPointers Define
hi def link forthLogic Operator
hi def link forthSingleNumberMath Operator
hi def link forthDoubleNumberMath Operator
hi def link forthFixedPointArithmetic Operator
hi def link forthUnsignedComparisons Repeat
hi def link forthSignedComparisons Repeat
hi def link forthDoubleComparisons Repeat
hi def link forthBits Operator
hi def link forthMemoryStatus Function
hi def link forthMemoryAccess Structure
hi def link forthStringRoutines String
hi def link forthCountedStringRoutines String
hi def link forthPicturedNumericalOutput String
hi def link forthDeepInsights Debug
hi def link forthUserInputInterpretation Statement
hi def link forthDictionaryExpansion Function
hi def link forthSpeciality Function
hi def link forthMCUDependent Function
hi def link forthFlagsAndInventory Function
hi def link forthFolding Statement
hi def link forthCompilerEssentials Structure
hi def link forthDecisions Conditional
hi def link forthCase Conditional
hi def link forthIndefiniteLoops Repeat
hi def link forthDefiniteLoops Repeat
hi def link forthHardwareAccess Identifier

hi def link forthCharOps Character
hi def link forthInteger Number
hi def link forthFixed Structure
hi def link forthComment Comment
hi def link forthString String

hi def link forthCustomWord Function
hi def link forthCMSIS Constant
hi def link forthColonDef Structure
hi def link forthStackDef Tag

" Include common non-Mecrisp standard words
:runtime! syntax/common.vim

" Include chip specific cmsis
:runtime! syntax/mcu/stm32f103c8t6.vim

":unlet b:current_syntax

let b:current_syntax = "forth"
 
let &cpo = s:cpo_save
unlet s:cpo_save

