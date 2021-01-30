# Music

![Screenshot](https://raw.githubusercontent.com/marc2o/Music/main/assets/screenshot.png)

An example of creating sounds and music with [LÖVE](https://love2d.org/).

Music is created using MML, a simple Music Markup Language. The demo included is based on the »Music« AmigaBASIC demo program from 1985.

The oscillator code is based on the [Denver Synthesizer Library](https://love2d.org/forums/viewtopic.php?t=79499) and the MML parser is a changed and extended version of the one used in [love-mml](https://github.com/GoonHouse/love-mml).

MML set is not complete yet. The use of waveforms is done using x followed by a number (1 = sin, 2 = saw, 3 = sqr, 4 = tri and 5 = noise).

Next:
* defining ADSR envelope macros
* a more standard way of using the waveforms
* saving songs as .wav
* …