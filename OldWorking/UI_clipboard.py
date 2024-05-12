import tkinter as tk
import os

def load_clipboard_history():
    clipboardPath = os.path.expanduser("~/GitHub/ClipboardHistory/clipboard_history.txt")
    try:
        with open(clipboardPath, "r") as file:
            return [line.strip() for line in file.readlines() if line.strip()]
    except FileNotFoundError:
        return []

def update_text_widget(text_widget):
    stack = load_clipboard_history()
    current_content = text_widget.get("1.0", tk.END).strip()
    new_content = "\n".join(reversed(stack))
    if current_content != new_content:
        text_widget.delete("1.0", tk.END)  # Clear the existing content
        text_widget.insert(tk.END, new_content)  # Display the stack in reverse order

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

    # Initially populate the text widget
    update_text_widget(text_widget)

    # Schedule the text widget to be updated every 500 milliseconds
    def schedule_update():
        update_text_widget(text_widget)
        root.after(500, schedule_update)  # Reschedule the update

    schedule_update()  # Start the periodic update

    # Start the GUI event loop
    root.mainloop()

if __name__ == "__main__":
    display_ui()
