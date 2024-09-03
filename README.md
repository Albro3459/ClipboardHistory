## ClipboardHistory, a Mac clipboard history manager like Clipboard History from Windows
#### Download link to try it out! [Google Drive link](https://drive.google.com/drive/folders/1m8X2TRyfuec3BwHg0ln5yIVTkW53AYCk?usp=sharing)

###### btw if you clone the repo to run it, it is in sandbox mode, so some things might break

* scroll to the very bottom for install instructions

* it is fully built by me, Alex Brodsky, in Swift for Mac OS 14.4 
    * I could try lowering the required MacOS version if you want to try the app, email is in bio

* it opens on the bottom right on all the desktop windows by default

* once running, it can be opened and closed with (cmd + shift + c), by default

* click the clipboard status menu bar icon to show the app while running

   * in the app settings > window, you can change the app to pop out of the status bar icon

* use the mouse or arrow keys to select items

* a full list of tips for using the app will be below the screenshots

* it can hold text, images, files and folders. it can even hold groups

* clipboard history is currently limited to 50 items, you can change this in the settings

* coming not so soon!:
    * selecting multiple items at once with cmd or shift click

    * maybe pinning items


### Screenshots:

<div style="display: flex; justify-content: center; align-items: center; flex-wrap: wrap; gap: 40px;">
    <img src="https://github.com/user-attachments/assets/5159adc7-daa6-439a-8380-c28f2f8c5863" alt="example screen shot" height="300"/>
    <img src="https://github.com/user-attachments/assets/0fc2feba-a20e-4bb0-a75e-d8a2747b75ff" alt="example screen shot with open group" height="300"/>
    <img src="https://github.com/user-attachments/assets/816caec4-2adb-4f34-90f7-335faee855d1" alt="example folder search screen shot" height="300"/>
</div>

### Tips for using the app:

* see the ListOfKeyboardShortcuts.md file for the full list of keyboard shortcuts, or scroll to the bottom

* these can be changed:
    - cmd + shift + c: open and close window
    - option + r: reset window
    - cmd + shift + v: paste without formatting

* cmd + shift + c is default for showing/hiding the app
    * also click the menu bar icon to show the app

* use the mouse or arrow keys to select items
    * scroll arrow button, cmd + up/down arrow, or page up/down to scroll up or down

* double-click, enter, or copy button to copy an item/group

* delete button or cmd + delete to delete an item/group

* expand button or right-arrow when selecting group to expand

* expand button or left-arrow on group to contract

* cmd + f to search

* escape takes you out of search or selecting clipboard types

* option + r resets the window size and shows it

* cmd + shift + v for paste without formatting anywhere on your computer!

* the open button next to files and folders opens the file or folder

### Installation Guide:

* this application is set up to only work with MacOS 14.4+
    * if you're on a lower MacOS, email me: brodsky.alex22@gmail.com, and I'll try to a different version

* download the zip from [Google Drive link](https://drive.google.com/drive/folders/1m8X2TRyfuec3BwHg0ln5yIVTkW53AYCk?usp=sharing)

* unzip it

* move it to the applications folder

* open it and you will get a pop up saying Apple can't open it because its from an unidentified developer and it can't be scanned for viruses

    <img src="https://github.com/user-attachments/assets/635ffcaf-9a00-4b14-a456-8fc1a2e759d0" alt="warning screen shot" height="250"/>

* click 'ok'

* open settings > privacy & security, then scroll down to security

    <img src="https://github.com/user-attachments/assets/96da5723-6953-4fc6-9745-cb5244958c98" alt="security" height="180"/>

* click 'open anyway'

* for universal paste without formatting (cmd + shift + v):

    * if you don't want this on you can turn it off in the app's settings under clipboard

    * when you try to paste with (cmd + shift + v):
    <br></br>
    <img src="https://github.com/user-attachments/assets/be187fe0-0a1f-4406-8bc4-cf090e9b9698" alt="accessibility warning" height="150"/>

    * click 'open system settings'
    
    * then in settings >  privacy & security > accessibility, flip the switch next to the clipboard history app
    <br></br>
    <img src="https://github.com/user-attachments/assets/d75a42aa-bec5-4b10-a1f0-e1bc88b2429a" alt="accessibility toggle" height="200"/>

    * you can also click the plus and add the app manually

    * i know, its a lil scary because it says 'control your computer'. its just because it needs to listen to (cmd + shift + v) to paste without formatting.
        * again, you can turn this off in the settings

### Here is a list of all the Keyboard Shortcuts:

 ##### changeable shortcuts:
    - cmd + shift + c: open and close window
    - option + r: reset window
    - cmd + shift + v: paste without formatting

 ##### unchangeable shortcuts:
    - menu options:
      - cmd + ;: Opens the GitHub link
      - cmd + ': Opens the LinkedIn link
      - cmd + ,: Opens the Settings
      - cmd + /: Opens the list of Keyboard Shortcuts
      - cmd + h: hides the app

    - cmd + f: open search
    
    - right arrow: expand group
    - left arrow: contract group
    - up arrow: move up
    - down arrow: move down

    - cmd + c: copy
    - enter || return: copy

    - cmd + enter: open item

    - cmd + delete: delete selected item
    - cmd + shift + delete: clear all items

    - cmd + [: open all groups
    - cmd + ]: close all groups

    - cmd + up: scroll to top
    - page up: scroll to top

    - cmd + down: scroll to bottom
    - page down: scroll to bottom

    - esc: exit search or type selector


<!-- <br />

##### OLD:

need to activate python virtual environment every time with
```sh
source venv/bin/activate
```

to create venv:
```sh
python3 -m venv venv
source venv/bin/activate
pip install pyperclip ## to install pyperclip
```


to deactivate:
```sh
source deactivate
``` -->
