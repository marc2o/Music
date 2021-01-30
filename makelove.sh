#!/bin/sh
printf "Name your LÖVE app: "
read NAME
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
zip -9 -q -r --exclude=*.sh* $NAME.love .

# create Windows executable on macOS:
# cat love.exe SuperGame.love > SuperGame.exe