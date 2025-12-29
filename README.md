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


### Tilemap Editor
The tilemap editor will allow you to load tiles into memory for editing. Controls are:

'w','a','s','d': Change the current pixel on the tile. Edits take place on the selected pixel
left, right arrow: select new color from palette
spacebar: switch the color of the current pixel to the selected color