# World

A simple, autonomous ecosystem with living creatures that copulate, fight and die.

## Usage

Fetch the code:

    $ git clone git://github.com/Roman2K/world.git

Run it:

    $ cd world
    $ ruby lib/world.rb

The output should look something like the following, except colored and moving:

    @@@@O@  @   @O@  @@@@@@@Oo@    @
    @@.@  @@@@o@@o@@@@@   @@@@ @@@@@
    o@@oO@.@.@ o@O.O@ @.@O Oo   @ @ 
     @@ @@@@@  @   @@@@o@@ .OO@  @ @
         @  @@@ @@@oO@ @@@o@ @ @@@@ 
    @ @@@ o @@ @ @ @ @@@ @@o@@  @@@ 
    @   @  @  @ @@.@oO@@  @@   @    
    @@ @   @  @@     @@@@@ @ @O@@Oo@
    @@@@ @o@@ O@ooo.@.@   @  @  @ @@
        @@ @o@ o@@     @ @    @@ @  
        @@@@     @  @@   @    @.o@ O
    @ @  @@   @o@@@.O@ @@  @@ @.@  @
      @   @@@@   @    @ O@@@O @ @oo 
    .@ @@  @@@@   O@@@ @ O@o@ @  @@ 
    @  .@@ .@@@@o@ OO @ @@@ @@@ @.@ 
     @    @     @O@o@ @@@o@   @   @@
    --------------------------------
    Total: 309 (m/f: 0.9) | Health: 129.2 (max: 480.2)

The _board_'s height and width can be stretched using the `-h` and `-w` options, respectively. The speed can be controlled with the `-f` option (number of frames per second). For example:

    $ ruby lib/world.rb -w 80 -h 35 -f 20

The above command would set up a 80-column wide, 35-line high board running at 20 FPS.
