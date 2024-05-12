#!/Users/alexbrodsky/GitHub/ClipboardHistory/venv/bin/python

import tkinter as tk
import tkinter.scrolledtext as scrolledtext
import os
import json
import pyperclip
import platform

def load_clipboard_history():
    clipboardPath = os.path.expanduser("~/GitHub/ClipboardHistory/clipboard_history.json")
    history = []  # Initialize history at the start to ensure it exists
    try:
        with open(clipboardPath, "r") as file:
            data = json.load(file)
            for item in data:
                full_content = item['content']
                truncated_content = truncate_text(full_content, max_lines=3)
                history.append({'full': full_content, 'truncated': truncated_content})
    except (FileNotFoundError, json.JSONDecodeError):
        pass  # If an error occurs, history remains empty
    return history

def truncate_text(text, max_lines=3):
    lines = text.split('\n')
    if len(lines) > max_lines:
        return '\n'.join(lines[:max_lines]) + '\n...'
    return text

# def update_text_widget(text_widget, history):
#     current_contents = text_widget.get("1.0", tk.END).strip()
#     new_contents = "\n".join(item['truncated'] for item in reversed(history))
#     if current_contents != new_contents:
#         text_widget.delete("1.0", tk.END)  # Clear the existing content
#         text_widget.insert(tk.END, new_contents)  # Display the truncated stack


def copy_to_clipboard(content):
    pyperclip.copy(content)
    print("Copied to clipboard!")

def display_ui():
    root = tk.Tk()
    root.title("Clipboard History")
    # root.geometry('300x400')  # Adjusted the total width to 300 pixels
    screen_width = root.winfo_screenwidth()
    screen_height = root.winfo_screenheight()
    window_width, window_height = 300, 400
    x = screen_width - window_width
    y = screen_height - window_height
    root.geometry(f'{window_width}x{window_height}+{x}+{y}')

    # Create a canvas with a scrollbar
    canvas = tk.Canvas(root, width=280)  # Specify width to ensure canvas does not grow beyond 300px
    scrollbar = tk.Scrollbar(root, orient="vertical", command=canvas.yview)
    scrollable_frame = tk.Frame(canvas)

    # Configure the canvas
    scrollable_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
    canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
    canvas.configure(yscrollcommand=scrollbar.set)
    
    # Function to handle mouse wheel scrolling
    def on_mousewheel(event):
        if platform.system() == "Windows":
            canvas.yview_scroll(int(-1*(event.delta/120)), "units")
        else:
            canvas.yview_scroll(int(-1*event.delta), "units")

    # Bind the mouse wheel event to the canvas
    canvas.bind_all("<MouseWheel>", on_mousewheel)

    last_history = []  # Store the last known state of the history

    def update_ui():
        nonlocal last_history
        new_history = load_clipboard_history()

        # Compare new history with the last known history
        if new_history != last_history:
            # Clear the existing content if history has changed
            for widget in scrollable_frame.winfo_children():
                widget.destroy()

            # Create new frames with labels and buttons for each item
            for item in reversed(new_history):
                frame = tk.Frame(scrollable_frame)
                text_label = tk.Label(frame, text=item['truncated'], font=('Arial', 12), width=30)  # Adjust width
                text_label.pack(side=tk.LEFT, fill=tk.X, expand=True)
                copy_button = tk.Button(frame, text="Copy", width=3, command=lambda content=item['full']: copy_to_clipboard(content))  # Adjust width
                copy_button.pack(side=tk.RIGHT)
                frame.pack(fill=tk.X)

            last_history = new_history  # Update the last known history

        root.after(500, update_ui)

    update_ui()  # Start checking for updates
    canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
    scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
    root.mainloop()

if __name__ == "__main__":
    display_ui()
