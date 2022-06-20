# Music

![Screenshot](https://raw.githubusercontent.com/marc2o/Music/main/assets/screenshot.png)

An example of creating sounds and music with [LÖVE](https://love2d.org/), a »framework you can use to make 2D games in Lua.«

Music is created using MML, a simple [Music Macro Language](https://en.wikipedia.org/wiki/Music_Macro_Language). The demo included is based on the »Music« AmigaBASIC demo program from 1985 ([take a look](https://www.youtube.com/watch?v=522uWGQV134)).

The oscillator code is based on the [Denver Synthesizer Library](https://love2d.org/forums/viewtopic.php?t=79499) and the MML parser is a changed and extended version of the one used in [love-mml](https://github.com/GoonHouse/love-mml).

Songs can be saved as AIFF. I have written the save routine from scratch. Just press *s* during playback to toggle saving on exit. The composer and title info, if specified in the mml, will be written to the AIFF as well.

The MML instrucions set is not complete, yet – and not really standard in some aspects.

Open mml files per drag-n-drop on the LÖVE app icon or window while _Music_ is running (as long as your mml file is compatible with this programm, of course 😊). The music file is saved at LÖVE’s default location (see [love.filesystem](https://love2d.org/wiki/love.filesystem)).

## Already implemented

**Entering notes: `<note><sharp/flat><len>`**

**`<note>`** (c, d, e, f, g, a, h or b)

**`<sharp/flat>`** (+ or -)

**`<len>`** (1 … n) ex. 4 is the length of a 1/4 note

If no length is given, the length specified with the length command **`l<len>`** is used.

**Rests or pauses: `r<len>`, `p<len>`**

Either p or r can be used, depending on the MML dialect.

If no length is given, the length specified with the length command **`l<len>`** is used.

Waits **`w<len>`** are treated as rests for now.

**Tempo: `t<bpm>`**

**Default note length: `l<len>`**

**Octave: `o<num>`**

Default octave is 4.

**Octave up: `>`**

**Octave down: `<`**

**Set volume: `v<num>`**

**`<num>`** (value between 0 and 100)

**`<uppercaseChar>`** (A to Z)

A capital letter at the beginning of a new line assigns all following commands to a certain voice. The following example plays the notes at the same time on two voices:

```mml
A cdefg
B cdefg
```

**Set waveform: `@<num>`**

**`<num>`** (1 = SIN, 2 = SAW, 3 = SQR, 4 = TRI, 5 = noise)

**Note tie: `&`**

Ties two of the same of different notes together, e. g. two quarter notes tied two one half note`c4&c4` or two different notes tied together `c&d`.

**Volume envelope: `@v<num> = { <attack> <decay> <sustain> <release> }`**

**`<num>`** (1 to 100)

**`<attack>`** (0 to 100) The time taken for initial run-up of level from nil to peak, beginning when the key is pressed.

**`<decay>`** (0 to 100) The time taken for the subsequent run down from the attack level to the designated sustain level.

**`<sustain>`** (0 to 100) The level during the main sequence of the sound's duration, until the key is released.

**`<release>`** (0 to 100) The time taken for the level to decay from the sustain level to zero after the key is released.

Call `@v<num>` to use the volume envelope


## To do…

* a way of defining LFO macros
* and maybe trying to implement some more of the stuff from [PPMCK MML](https://shauninman.com/assets/downloads/ppmck_guide.html)
