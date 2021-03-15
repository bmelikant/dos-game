## README file for my DOS game
### Prerequisites
* The Netwide Assembler (NASM)
* A suitable x86-based MS-DOS system, or DOS machine emulator (DOSBox has been thoroughly tested)
* Test system DOS should support basic int 21h system functions

### Build steps
1. git clone https://github.com/bmelikant/dos-game.git
1. nasm graphics-demo.asm -o graph.com

### To test in DOSBox:
1. Start DOSBox
1. Mount directory containing graph.com as a filesystem (e.g. mount C ~/dosbox-dev)
1. Move to the mounted directory, and run GRAPH.COM!
