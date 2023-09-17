" forth.vim - VIM plugin for Mecrisp-Stellaris Forth
" created for Mecrisp-Stellaris Forth by Matthias Koch
" This VIM script sets up the Forth VIM plugin
" By Brett Olson "brettolson@cox.net" 2023, released under the MIT License

set complete+=k
set dictionary+=~/.vim/words/forth.txt
set dictionary+=~/.vim/words/mcu_peripheral.txt
set dictionary+=~/.vim/words/mcu_register.txt
set dictionary+=~/.vim/words/mcu_bitfield.txt

" Recommended install folder for plugin
let s:plugin_path = "~/.vim/ftplugin/forth/"

" Folder where tag syntax file will be created
let s:syntax_path = "~/.vim/syntax/"

" Shell script to create tags from forth files
let s:tagscript_name = "forthtags.sh"

" Shell script to create syntax file from tags
let s:synscript_name = "syntaxtags.sh"


" Define an autocmd group for Forth files
augroup forth_group
   " Remove any existing forth_group autocommands
   autocmd!

   " For forth files only...
   " Set the file type to 'forth' for files with an '.fs' extension
   autocmd BufRead,BufNewFile *.fs set filetype=forth

   " For forth files only...
   " After saving (:w), create forthtags for .fs forth files
   autocmd BufWritePost,BufEnter *.fs call s:RunScript()

augroup END

" Run the Shell script that creates the forthtags and creates the syntax file
function! s:RunScript()
  " Avoid getting 'Press Enter' prompt from the message queue
  let saved_cmdheight = &cmdheight
  let &cmdheight = 2 

  " Get path (don't want filename) of current file
  let current_path = expand('%:p:h')
  let shell_tagsfile = s:plugin_path . s:tagscript_name

  " Create the command to call the forthtags shell command
  " Also include the current file path as an argument to the forthtag script
  let shell_createtags = shell_tagsfile . " " . shellescape(current_path) 

  " Execute the tags shell command, and save any echo output from the shell script
  let output = system(shell_createtags)

  "echom output

   " Prepare for syntax script
   let shell_syntaxfile = s:plugin_path . s:synscript_name
   "let concatenated_args = current_path . " " . s:syntax_path
 
   " Create syntax file for Forth tags
   let shell_createsyntax = shell_syntaxfile . " " . shellescape(current_path)
 
   " Execute the syntax shell command, and save any echo output from the shell script
   let output2 = system(shell_createsyntax)
 
   silent execute "syn on"
 
   silent execute "so ~/.vim/syntax/tags.vim"
   " Print VIM message about results of forthtags
   "echom output2
   "echo "COMPLETE!"
  " Reset the cmdheight to it's previous value
  let &cmdheight = saved_cmdheight
endfunction


