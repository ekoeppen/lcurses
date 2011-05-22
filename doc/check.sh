#!/bin/sh

files="index lcurses cui"

while true; do
    update=

    for f in $files; do
        if [ "$f.txt" -nt "$f.html" ]; then
            update=true
        fi
    done

    if [ -n "$update" ]; then
        make
    fi

    sleep 1
done
