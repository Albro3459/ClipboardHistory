import tkinter as tk
import os
import json

def load_clipboard_history():
    clipboardPath = os.path.expanduser("~/GitHub/ClipboardHistory/clipboard_history.json")
    try:
        with open(clipboardPath, "r") as file:
            data = json.load(file)
            # Load data into a stack, latest entry last
            return [item['content'] for item in reversed(data)]  # Reverse to make latest entry first
    except (FileNotFoundError, json.JSONDecodeError):
        return []

def update_text_widget(text_widget, stack):
    # Get the current contents of the text widget
    current_contents = text_widget.get("1.0", tk.END).strip()
    # Generate the contents that should be displayed from the stack
    new_contents = "\n".join(stack)
    # Only update if there are changes
    if current_contents != new_contents:
        text_widget.delete("1.0", tk.END)  # Clear the existing content
        text_widget.insert(tk.END, new_contents)  # Display the stack in reverse order

def display_ui():
    root = tk.Tk()
    root.title("Clipboard History")

    # Get the screen width and height
    screen_width = root.winfo_screenwidth()
    screen_height = root.winfo_screenheight()

    # Set window size and position (bottom right)
    window_width, window_height = 300, 400
    x = screen_width - window_width
    y = screen_height - window_height

    # Set window properties
    root.geometry(f'{window_width}x{window_height}+{x}+{y}')

    # Create and configure a Text widget for multi-line text display
    text_widget = tk.Text(root, font=('Arial', 12), width=50, height=20, wrap=tk.WORD)
    text_widget.pack(pady=10, padx=10, expand=True, fill=tk.BOTH)

    # Function to check for updates in the clipboard history
    def check_for_updates():
        # Load clipboard history into a stack
        stack = load_clipboard_history()
        # Update the text widget with the new stack
        update_text_widget(text_widget, stack)
        # Schedule this function to run again after 500 milliseconds
        root.after(500, check_for_updates)

    # Start checking for updates
    check_for_updates()

    # Start the GUI event loop
    root.mainloop()

if __name__ == "__main__":
    display_ui()
