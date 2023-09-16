# Mecrisp-Stellaris-VIM-Syntax-Highlighter

## ABOUT MECRISP-STELLARIS-VIM

Mecrisp-Stellaris-VIM-Syntax-Highlighter is a forth language plugin for VIM to make coding forth projects faster and easier.

The plugin provides help files for standard Mecrisp-Stellaris words as well as MCU specific peripheral-register-bitfield words.

It also tracks your current project as you create new code and save forth files. It creates syntax highlighting for your project words as well as tag links you can follow to see where your words were defined.

If you need help remembering a word while coding, the plugin provides word-completion lists on demand.

## MAIN FEATURES:

1. Syntax Highlighting
   - All standard Mecrisp-Stellaris words
   - All current project words (from any file or folder listed in your forth.cfg file)
   - All MCU specific peripheral-register-bitfields (swap out the file when changing MCU's)

2. Help files (Ctrl-k to open man pages)
   - All standard Mecrisp-Stellaris words
   - MCU specific Peripheral-register-bitfield

3. Forthtags (Ctrl-] to follow intra-project links)
   - Links to definitions of all project level user created words

4. code-completion - (Ctrl-P on any partial word in insert mode)
   - A dictionary of all standard Mecrisp-Stellaris words
   - A dictionary of current project words
   - A dictionary of MCU specific peripheral-register-bitfields

## SUMMARY:

1. All text in your .fs code should be syntax highlighted, there should be no black/white remaining.
2. For standard Mecrisp words, type `Ctrl-k` to open a help file.
3. For any MCU Peripheral-Register-Bitfield words, type `Ctrl-k` to open a help file.
4. For any forthtags words you've defined in a .fs file, type `Ctrl-]` to jump to it's definition
5. For help completing a word, type Ctrl-p. Works with all word types listed, 2, 3, and 4 above.

## FOLDER STRUCTURE:

 -~
  |- .vim
  |  |   
  |  |- doc                         Folder - **Help files** (use Ctrl-k or ':h yourword')
  |  |  |- mecrisp-stellaris.txt      Standard Forth words help file, comes with package
  |  |  |- mcu.txt                    MCU specific help file (made with `convert_svd.sh`)
  |  |  |- convert_svd.sh             Shell script to create help for your MCU variant
  |  |  |- tags                       VIM tags file generated by `:helptags ALL`
  |  |  |
  |  |- ftplugin                    Folder - FileType plugin 
  |  |  |- forth                      Folder - forth language
  |  |  |  |- forth.vim                 Similar to .vimrc, auto creates forth syntax file
  |  |  |  |- forthtags.sh              Shell script run automatically by forth.vim
  |  |  |  |- syntaxtags.sh             Shell script run automatically by forth.vim
  |  |  |  |- forthtags.cfg             Copy/edit this file to all your project path folders
  |  |  |
  |  |- syntax                      Folder - **Syntax highlighting**
  |  |  |- forth.vim                  Standard Forth words syntax file, comes with package
  |  |  |- tags.vim                   Project specific words, auto created using your forthtags.cfg
  |  |  |- mcu                        Folder - MCU specific 
  |  |  |  |- mcu_bitfield.vim        Syntax definitions file created when you run convert_svd.sh
  |  |  |  |- mcu_peripheral.vim      Syntax definitions file created when you run convert_svd.sh
  |  |  |  |- mcu_register.vim        Syntax definitions file created when you run convert_svd.sh
  |  |  |
  |  |- words                       Folder - **Code-completion** dictionaries
  |  |  |- forth.txt                  Standard Forth words 
  |  |  |- mcu_bitfield.txt           MCU specific bitfields names (made with `convert_svd.sh`)
  |  |  |- mcu_peripheral.txt         MCU specific peripheral names (made with `convert_svd.sh`)
  |  |  |- mcu_register.txt           MCU specific register names (made with `convert_svd.sh`)
  |
  |- (your forth project path)      Folder - The folder where you keep your main project .fs files 
  |  |- forthtags.cfg                 User file with paths/filenames to search for words
  |  |- tags                          Project specific words created by **forthtags.sh**
         +

## INSTALLATION:
  
1. Clone this GIT repository
   - Create a new directory in a convenient location on your computer, but not below ~/.vim/
   - Click the green 'Code' button above, choose SSH, click the copy icon
   - Open a terminal window and navigate to your new folder
   - Enter the GIT clone command along with the copyied SSH text to clone for your operating system
   - Edit your ~/.vimrc file to include these lines
      `syntax on`
      `filetype plugin on`
      `noremap <c-k> :execute "horiz help "`
   - Copy the `~/.vim/ftplugin/forth/forthtags.cfg` file to any folder you will be saving .fs files.
       Edit the file to include files/directories that are used in your project
   - Create an MCU specific set of files for the MCU chip you are working with.
       Edit ~/.vim/doc/convert_svd.sh to change the name of the svd file for your target chip
       
> [!IMPORTANT]
> You must place an edited copy of the `forthags.cfg` file in any folder you save forth .fs files

### Edit your vimrc
  Add the following lines to your `/.vimrc` file

## THINGS THAT HAPPEN AUTO-MAGICALLY:

1. Opening or saving a .fs file executes a script in ~/.vim/ftplugin/forth/forth.vim. 
   - A new tags file is created in your project path with any non-standard forth words
   - A new ~/.vim/syntax/tags file is created with non-standard forth words

-   When creating or reading a .fs file, it's VIM filetype is set to 'forth'.

## VIM KEYSTROKES TO LEARN ( This plugin only relies on built-in VIM keystrokes ):

  1. Beginner - Must know
     A. `Ctrl-k`  - Open help for specific word
     B. `Ctrl-p`  - Start code-completion
     C. `Ctrl-]`  - Follow forthtag link to definition of custom word
     D. `:q`      - Close a help file that was opened

  2. Intermediate - Helpful to know
     A. Ctrl-y  - Closes code-completion without changing your word
     B. Ctrl-n  - Use Ctrl-n immediately after Ctrl-p to deselect, allows you to continue typing and auto update code-completion
     C. Ctrl-n  - Use Ctrl-n and Ctrl-p to navigate up/down in the code-completion popup
     D. Ctrl-o  - After using Ctrl-] to follow a link, uste Ctrl-o to jump back to where you called the link

What happens automatically and what needs to be done by you?


Description:

Documentation(help): (~/.vim/doc/)
  
  mecrisp-stellaris.txt
    Documentation for all standard Mecrisp-Stellaris words
    Ctrl-k on any mecrisp word to open this help file, or
    :h mec(risp-stellaris.txt) to open this help file

  MCU specific (e.g. stm32f103c8t6.txt)
    contains help file for peripheral-register or peripheral-register-bitfield
    Create an MCU specific help file using the appropriate CMSIS.SVD file and 
      running convert_svd.sh from a terminal shell
    Ctrl-k on any MCU specific peripheral-register word, or
    :h stm32 to open this help file

  tags ( no extension )
    Contains all help file help file links
    If any help file is changed/created, run 
       ':helptags ALL' to re-create help tags

  brett.txt

forthtags: (~/.vim/ftplugin)
  
  
  forth.vim

# FAQ:

### Q. What if I don't like your colorscheme?
A. Any colorscheme can be used. Make a permanent change by adding or modifying your .vimrc with 'colorscheme slate'. Change slate to whatever colorscheme you want.

### Q. I've tried different colorschemes and still don't like your colors, what can I do?
A. Change it:
   1. For standard Mecrisp words, you can modify the ~/.vim/syntax/forth.vim file. The words are grouped together similar to the sourceforge dictionary. You can change how the words are grouped by moving the words around or creating a new group name. You can also change which colorscheme keywords are assigned to the forth word groups at the bottom of the file. To see all available syntax options for your colorscheme, type ':highlight' in VIM.
   2. For your project specific words, I've chosen to apply a specific color, instead of relying on a colorscheme. You can edit the color (or assign to a colorscheme keyword) by editing the last part of the '~/.vim/ftplugin/forth/syntaxtags.sh' file. I left a few commented lines that offer some other colors, but feel free to create your own.

### Q. In the standard Mecrisp word help file, why do all of the examples have 'TODO'?
A. A long term goal of mine is to add example code snippets and informative discussions to the help file, but it will be an ongoing project!

### Q. When using Ctrl-k on some forth words, why does VIM help open instead of forth help?
A. Some of the simpler forth words like 'DO' have the same help keywords as VIM, and therefore open VIM help instead. A direct way of opening standard Mecrisp help is to type ':h mecrisp-stellaris.txt' or better, type ':h mec' to open the Mecrisp help file with links to all the word groups.

### Q. I change projects often while working, do I need to change any settings when switching files?
A. No, when you open or save a .fs file, the plugin will use the files current path to read your forthtags.cfg file and automatically generate new syntax and forthtags specific to that path. This means you can have as many .fs files as you want open in VIM at the same time, they can even be from different projects/folders. However, any folder you open an .fs file from should have a copy/edited version of the forthtags.cfg file. For example, if I'm working out a project directory called /myproject, I have a forthtags.cfg file with a line for './' which covers any .fs file in the same directory. The .cfg file also include specific files from my common folder that I want included in the project. When I edit a file from the /common folder (where I save common .fs files for most all of my projects), that /common folder has a copy of the forthtags.cfg with just a single line './'. Think of the forthtags.cfg as similar to an 'include' statement, it's job is to tell the plugin where to find all the words you want highlighted and tagged when working in that file.

### Q. What happens if I don't have a forthtags.cfg for the directory my .fs file is saved to?
A. Without the forthtags.cfg, the plugin has no idea where else to look for words you want included in your project, therefore you will see uncolored text for words that are not highlighted by the plugin. Also, if you Ctrl-] on any uncolored word, nothing will happen because there is no forthtag associtated with that word. All the helpfiles will still work for standard mecrisp and MCU specific words.

### Q. Wow! I like having help files for Forth - Can I do the same with my own notes for topics specific to me?
A. Of course! I maintain a 'brett.txt' file in the ~/.vim/doc folder. I type ':h brett.txt' on the command line in VIM and it opens my personal help file. Or, I can type any topic I've defined and use Ctrl-k to open the help file. You can see all of the forth help files as well as your personal file when you type ':help' and G to the bottom of the VIM help where it lists links to all the custom help files. If you edit a help file, you need to tell VIM to update the helptags by typing ':helptags ALL' which will regenerate all the tags. I've included a skeleton version of my personal help file with this plugin, you can just copy or rename it. The help file needs a specific first and last line in the file, it will be obvious when you edit my file. To create help links that will be opened with Ctrl-k, put asterisks at the beginning and end of the word in the help file: e.g. *myTopic*. To link to other topics within the help files, put pipes on either side of the word: e.g. |myTopic|. To follow a link type Ctrl-].

### Q. What happened to the built-in VIM syntax highlighting for forth?
A. This plugin takes priority. The built-in VIM forth syntax highlighter is made for GForth therefore many of the Mecrisp words were missing.

### Q. I'd rather use vscode, is this plugin available for vscode?
A. Sorry, not from me, and I'm not aware of any others. One of the original reasons I switched to VIM is because the vscode built-in forth syntax was much worse than the built-in VIM syntax highlighting.



The syntax folder should be saved to the ~/.vim/ folder. e.g. ~/.vim/syntax should contain the forth.vim file

