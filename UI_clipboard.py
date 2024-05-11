import tkinter as tk
import os

def load_clipboard_history():
    clipboardPath = os.path.expanduser("~/GitHub/ClipboardHistory/clipboard_history.txt")
    try:
        with open(clipboardPath, "r") as file:
            return [line.strip() for line in file.readlines() if line.strip()]
    except FileNotFoundError:
        return []

def update_listbox(listbox):
    stack = load_clipboard_history()
    current_items = list(listbox.get(0, tk.END))
    # If the stack has changed (either new items or items have been removed)
    if current_items != stack[::-1]:
        listbox.delete(0, tk.END)  # Clear the existing content
        for item in reversed(stack):  # Display the stack in reverse order
            listbox.insert(tk.END, item)

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

    # Create and pack a Listbox to show the history
    listbox = tk.Listbox(root, font=('Arial', 12), width=50, height=20)
    listbox.pack(pady=10, padx=10)

    # Initially populate the listbox
    update_listbox(listbox)

    # Schedule the listbox to be updated every 500 milliseconds
    def schedule_update():
        update_listbox(listbox)
        root.after(500, schedule_update)  # Reschedule the update

    schedule_update()  # Start the periodic update

    # Start the GUI event loop
    root.mainloop()

if __name__ == "__main__":
    display_ui()
