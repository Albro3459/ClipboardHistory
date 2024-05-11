#!/bin/zsh

basePath="$HOME/GitHub/ClipboardHistory"

clipboard_history_file="$basePath/clipboard_history.txt"

lastCopy=""

maxLines=30

startTime=$(date +%s)

while true; do

    currentTime=$(date +%s)

    if (( currentTime - startTime > 600 )); then
        echo "10 minutes have elapsed. Exiting."
        break
    fi
    
    currentCopy=$(pbpaste)

                                        ## -n is to check if not empty
    if [[ "$currentCopy" != "$lastCopy" && -n "$currentCopy" ]]; then
        lastCopy="$currentCopy"

        echo "$currentCopy" >> "$clipboard_history_file"

        lineCount=$(wc -l < "$clipboard_history_file")

        if [[ "$lineCount" -gt "$maxLines" ]]; then

            ## copies the first $maxLines from the file to a temp file
            tail -n $maxLines "$clipboard_history_file" > $basePath/tmp/clipboard_temp.txt

            # replaces the clipboard history file
            mv $basePath/tmp/clipboard_temp.txt "$clipboard_history_file"



        fi

    fi

    sleep 0.42

done
