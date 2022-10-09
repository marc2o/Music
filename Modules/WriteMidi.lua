--[[
                                    ___
       ______    ___    ___   ___  /    \ ___
    _/       \_/    \_/ _  \_/   \_--   /-   \
   /   /  /  /   /  /   /__/  /__/   __/   / /
  /___/__/__/\__/\_/___/   \____/      \____/
  (c) 2020 – 2022 marc2o        \______/
  https://marc2o.github.io

--]]

-- Event Types
local NOTE_OFF           = 0x80
local NOTE_ON            = 0x90
local POLY_AFTERTOUCH    = 0xa0
local CONTROL_CHANGE     = 0xb0
local PROGRAM_CHANGE     = 0xc0
local CHANNEL_AFTERTOUCH = 0xd0
local PITCH_BEND         = 0xe0
local SYSTEM_EXCLUSIVE   = 0xf0

-- Meta Event types
local TEMPO		           = 0x51;
local END_OF_TRACK       = 0x2f;
local SEQUENCE_NUMBER    = 0x00;
local TEXT_EVENT         = 0x01;
local COPYRIGHT_NOTICE   = 0x02;
local SEQUENCE_NAME      = 0x03;
local INSTRUMENT_NAME    = 0x04;
local LYRIC              = 0x05;
local MARKER             = 0x06;
local CUEPOINT           = 0x07;
local CHANNEL_PREFIX     = 0x20;
local SMPTE_OFFSET       = 0x54;
local TIME_SIGNATURE     = 0x58;
local KEY_SIGNATURE      = 0x59;
local SEQUENCER_SPECIFIC = 0x74;
