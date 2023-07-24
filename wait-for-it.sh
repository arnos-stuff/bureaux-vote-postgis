#!/bin/bash

function shutdown() {
  tput cnorm # reset cursor
}
trap shutdown EXIT

function cursorBack() {
  echo -en "\033[$1D"
}

function waitForIt {
    local LC_CTYPE=C

    local pid=$1 # Process Id of the previous running command

    case $(($RANDOM % 12)) in
    0)
        local spin='⠁⠂⠄⡀⢀⠠⠐⠈'
        local charwidth=3
        ;;
    1)
        local spin='-\|/'
        local charwidth=1
        ;;
    2)
        local spin="▁▂▃▄▅▆▇█▇▆▅▄▃▂▁"
        local charwidth=3
        ;;
    3)
        local spin="▉▊▋▌▍▎▏▎▍▌▋▊▉"
        local charwidth=3
        ;;
    4)
        local spin='←↖↑↗→↘↓↙'
        local charwidth=3
        ;;
    5)
        local spin='▖▘▝▗'
        local charwidth=3
        ;;
    6)
        local spin='┤┘┴└├┌┬┐'
        local charwidth=3
        ;;
    7)
        local spin='◢◣◤◥'
        local charwidth=3
        ;;
    8)
        local spin='◰◳◲◱'
        local charwidth=3
        ;;
    9)
        local spin='◴◷◶◵'
        local charwidth=3
        ;;
    10)
        local spin='◐◓◑◒'
        local charwidth=3
        ;;
    11)
        local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
        local charwidth=3
        ;;
    esac
    local i=0;
    tput civis;
    
    while [ ! "$(sudo docker ps -a -q -f name=$1)" ]; do
        local i=$(((i + $charwidth) % ${#spin}));
        printf "%s Waiting for container to start.." "${spin:$i:$charwidth}";
        cursorBack 34;
        sleep .1;
    done
    cursorBack 34;
    echo "";
    echo "Container Started.";
}

waitForIt "$@"
