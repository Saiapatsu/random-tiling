# RotMG tiling preview script for GIMP

Generates a mock image of how a solid patch of the selected tiles would look like in RotMG.

![Usage example](https://i.imgur.com/37AYNs2.png)

## Setup

* Open the GIMP Script-Fu folder (usually %appdata%\GIMP\2.10\scripts).
* Download [the script (random-tiling.scm)](https://raw.githubusercontent.com/Saiapatsu/random-tiling/master/random-tiling.scm) and place it there.
* Create a folder named `images`, download [hash512.png from releases](https://github.com/Saiapatsu/random-tiling/releases/latest/download/hash512.png) and place it there.
* If GIMP is running, refresh scripts (Filters > Script-Fu > Refresh Scripts).

hash512.png was created with gen-tilehash.lua. It requires Lua 5.3 and ImageMagick.

## Usage

Arrange your tiles horizontally or vertically on one layer, select them and run the script. A new image will be created.

Each tile is assumed to be square; rectangular tiles are not supported.

The resulting image is "rendered", i.e. scaled and rotated. You can Undo to undo this.

The placement of the tiles will likely have noticeable diagonal patterns. This is (hopefully) consistent with how the game places tiles with RandomTexture.
