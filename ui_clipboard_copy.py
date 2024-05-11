import tkinter as tk
import os

def load_clipboard_history():
    clipboardPath = os.path.expanduser("~/GitHub/Clipboard/clipboard_history.txt")
    
    try:
        with open(clipboardPath, "r") as file:
            return file.readlines()
    except FileNotFoundError:
        return []
    
def build_stack():
    stack = []
    history = load_clipboard_history()
    
    for line in history:
        stack.append(line.strip())  # Strip here to manage newlines early
    
    return stack
        
def display_ui():
    stack = build_stack()
    
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
    while stack:
        curr = stack.pop()  # If you want to reverse order, consider reversing the stack before this loop
        listbox.insert(tk.END, curr)
    listbox.pack(pady=10, padx=10)
    
    
    refresh(root, listbox, stack)
    
    # Start the GUI event loop
    root.mainloop()
    
def refresh(root, listbox, currentStack):
    
    newStack = build_stack()

    new = newStack.pop()
    old = currentStack.pop()
    if (new != old):
        listbox.insert(tk.END, new)
        
    root.after(420, refresh, root, listbox, newStack)


if __name__ == "__main__":
    display_ui()
