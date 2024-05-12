#!/bin/zsh

basePath="$HOME/GitHub/ClipboardHistory"

clipboard_history_file="$basePath/clipboard_history.json"

# it needs to start with an empty array for json
if [[ ! -f "$clipboard_history_file" || ! -s "$clipboard_history_file" ]]; then
    echo "[]" > "$clipboard_history_file"
fi

lastCopy=""

maxItems=30

startTime=$(date +%s)

while true; do

    currentTime=$(date +%s)

    if (( currentTime - startTime > 600 )); then
        echo "10 minutes have elapsed. Exiting."
        break
    fi

    currentCopy=$(pbpaste)

    # Proceed if there's new content that's different from the last copied content
    if [[ "$currentCopy" != "$lastCopy" && -n "$currentCopy" ]]; then
        lastCopy="$currentCopy"
        
        # Convert clipboard content to a JSON object
        jsonContent=$(echo "$currentCopy" | jq -Rs '{content: .}')

        # Append the new clipboard content in JSON format
        jq --argjson item "$jsonContent" '. += [$item]' "$clipboard_history_file" > "$basePath/tmp/clipboard_history.json"
        if [[ $? -ne 0 || ! -s "$basePath/tmp/clipboard_history.json" ]]; then
            echo "Failed to append new content."
            continue
        fi
        mv "$basePath/tmp/clipboard_history.json" "$clipboard_history_file"
        
        # Keep only the latest $maxItems entries
        jq ".[-$maxItems:]" "$clipboard_history_file" > "$basePath/tmp/clipboard_history.json"
        if [[ $? -ne 0 || ! -s "$basePath/tmp/clipboard_history.json" ]]; then
            echo "Failed to truncate clipboard entries."
            continue
        fi
        mv "$basePath/tmp/clipboard_history.json" "$clipboard_history_file"

    fi


    sleep 0.5
done
