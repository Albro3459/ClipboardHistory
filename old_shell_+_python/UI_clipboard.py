#!/Users/alexbrodsky/GitHub/ClipboardHistory/old_shell_+_python/venv/bin/python

import tkinter as tk
import tkinter.scrolledtext as scrolledtext
import os
import json
import pyperclip
import platform

def load_clipboard_history():
    clipboardPath = os.path.expanduser("~/GitHub/ClipboardHistory/old_shell_+_python/clipboard_history.json")
    history = []
    try:
        with open(clipboardPath, "r") as file:
            data = json.load(file)
            for item in data:
                full_content = item['content']
                truncated_content = truncate_text(full_content, max_lines=3)
                history.append({'full': full_content, 'truncated': truncated_content})
    except (FileNotFoundError, json.JSONDecodeError):
        pass
    return history

def truncate_text(text, max_lines=3):
    lines = text.split('\n')
    if len(lines) > max_lines:
        return '\n'.join(lines[:max_lines]) + '\n...'
    return text

def copy_to_clipboard(content):
    pyperclip.copy(content)
    print("Copied to clipboard!")

def display_ui():
    root = tk.Tk()
    root.title("Clipboard History")
    screen_width = root.winfo_screenwidth()
    screen_height = root.winfo_screenheight()
    window_width, window_height = 300, 400
    x = screen_width - window_width
    y = screen_height - window_height
    root.geometry(f'{window_width}x{window_height}+{x}+{y}')

    # Create a canvas with a scrollbar
    canvas = tk.Canvas(root, width=280) ## make room for scroll bar
    scrollbar = tk.Scrollbar(root, orient="vertical", command=canvas.yview)
    scrollable_frame = tk.Frame(canvas)

    # Configure the canvas
    scrollable_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
    canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
    canvas.configure(yscrollcommand=scrollbar.set)
    
    def on_mousewheel(event):
        if platform.system() == "Windows":
            canvas.yview_scroll(int(-1*(event.delta/120)), "units")
        else:
            canvas.yview_scroll(int(-1*event.delta), "units")

    canvas.bind_all("<MouseWheel>", on_mousewheel)

    last_history = []

    def update_ui():
        nonlocal last_history
        new_history = load_clipboard_history()

        if new_history != last_history:
            # Clear the existing content if history has changed
            for widget in scrollable_frame.winfo_children():
                widget.destroy()

            # Create new frames with labels and buttons for each item
            for item in reversed(new_history):
                frame = tk.Frame(scrollable_frame)
                text_label = tk.Label(frame, text=item['truncated'], font=('Arial', 12), width=30)
                text_label.pack(side=tk.LEFT, fill=tk.X, expand=True)
                copy_button = tk.Button(frame, text="Copy", width=3, command=lambda content=item['full']: copy_to_clipboard(content))
                copy_button.pack(side=tk.RIGHT)
                frame.pack(fill=tk.X)

            last_history = new_history 

        root.after(500, update_ui)

    update_ui()
    
    canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
    scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
    root.mainloop()

if __name__ == "__main__":
    display_ui()
