#!/bin/zsh

basePath="$HOME/GitHub/ClipboardHistory"
clipboard_history_file="$basePath/clipboard_history.json"
lastCopy=""

maxItems=30  # Number of clipboard items to keep

while true; do
    currentCopy=$(pbpaste)

    if [[ "$currentCopy" != "$lastCopy" && -n "$currentCopy" ]]; then
        lastCopy="$currentCopy"

        # Escape double quotes in the clipboard content
        jsonContent=$(echo "$currentCopy" | jq -Rs .)

        # Prepend the new clipboard content in JSON format
        jq --arg item "$jsonContent" '. | [{content: $item}] + .' "$clipboard_history_file" > "$basePath/tmp.json" && mv "$basePath/tmp.json" "$clipboard_history_file"

        # Keep only the latest $maxItems items
        jq ".[0:$maxItems]" "$clipboard_history_file" > "$basePath/tmp.json" && mv "$basePath/tmp.json" "$clipboard_history_file"
    fi

    sleep 0.5
done
