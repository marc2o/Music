# Music

![Screenshot](https://raw.githubusercontent.com/marc2o/Music/main/assets/screenshot.png)

An example of creating sounds and music with [LÖVE](https://love2d.org/), a »framework you can use to make 2D games in Lua.«

Music is created using MML, a simple [Music Macro Language](https://en.wikipedia.org/wiki/Music_Macro_Language). The demo included is based on the »Music« AmigaBASIC demo program from 1985 ([take a look](https://www.youtube.com/watch?v=522uWGQV134)).

The oscillator code is based on the [Denver Synthesizer Library](https://love2d.org/forums/viewtopic.php?t=79499) and the MML parser is a changed and extended version of the one used in [love-mml](https://github.com/GoonHouse/love-mml).

The MML instrucions set is not complete, yet – and not really standard.

## Already implemented

**Entering notes: `<note><sharp/flat><len>`**

**`<note>`** (a, b, c, d, e, f, g, h or b)

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

**`<num>`** (value between 0 and 15)

**Set waveform: `@<num>`**

**`<num>`** (1 = SIN, 2 = SAW, 3 = SQR, 4 = TRI, 5 = noise)


## To do…

* defining ADSR envelope macros using `@EN<num> = { t t v t }` syntax
* saving songs as .wav
* a way of defining LFO macros
* and maybe trying to implement some of the stuff from [PPMCK MML](https://shauninman.com/assets/downloads/ppmck_guide.html)
