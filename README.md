## ClipboardHistory, a Mac clipboard history manager inspired by the Windows version

[Demo Video](https://youtu.be/p2S1_Rhee5o)

### Installation Guide:
 * the download link is under the [Releases](https://github.com/Albro3459/ClipboardHistory/releases) tab on GitHub or [Google Drive link](https://drive.google.com/drive/folders/1m8X2TRyfuec3BwHg0ln5yIVTkW53AYCk?usp=sharing) to try it out!
* <details>
    <summary>Installation Guide:</summary>

  * this application is set up to only work with MacOS [14.4](https://github.com/Albro3459/ClipboardHistory/releases/tag/v2.955) or [15.5](https://github.com/Albro3459/ClipboardHistory/releases/tag/macOS15.5)
      * if you're on a lower MacOS, email me: brodsky.alex22@gmail.com, and I'll try to a different version

  * download the zip from the [Releases](https://github.com/Albro3459/ClipboardHistory/releases) tab on GitHub

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
  </details>

* <details>
    <summary>!! **IMPORTANT** Instructions if you want to build the project yourself:</summary>
  
  * you will need XCode, I was originally on Version 15.3, but now I am on 16.4

  * !! **IMPORTANT** if you clone the repo to run it, it is in sandbox mode, so some things will break.
      * to disable the sandbox, you can go to the ClipboardHistory.xcodeproj > Target: ClipboardHistory > Build Settings then search for entitlements and change the debug one to the release one.
      * instead, the downloads from the Releases tab and Google Drive are NOT sandboxed, so everything will work

  * !! **IMPORTANT** before you run anything, in XCode, you have to run the following every time. you also have to run after switching branches because the project is dependent on the KeyboardShortcuts package:
    * Go to File > Packages > click Reset Package Caches
    * Go to File > Packages > click Resolve Package Versions
      * every time you switch branches, you MUST do this again. the project is dependent on the KeyboardShortcuts package
  </details>
  
---

### A summary of why I built this app and what I've learned:
* <details>
  <summary>Summary:</summary>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;As a lifelong Mac user, I never quite realized the benefits of a clipboard manager. That was until my summer internship in 2023, where I heavily used a Windows computer during development and grew to love the built in clipboard manager (WinKey + V). When I transitioned back to my Mac after the summer, I quickly realized my dependence on a clipboard manager and began searching for alternatives on Mac. I researched a few options, but they weren't exactly what I was looking for. I began to plan to build my own, but I lacked any experience with Mac software development.</p>

  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;After starting with a Bash script and a Python UI that was enough for copying text, I realized that I wanted to include screenshots, files, and keyboard shortcuts to fully implement a product. My research led me to Swift, where I could access Apple's APIs and integrate my desired features. I spent my time during the summer, when I wasn't working at my internship, learning Swift and developing a prototype. I asked my friends for ideas about features and designs and eventually it all came together (not without a lot of mistakes). I eventually presented to my class a few weeks ago to get my first few users.

  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;This experience taught me so much about MacOS, Swift, state, and application development, as well as showing me how much I have yet to learn. I was never formally taught best practices for how to manage state and implement views, so I am well aware of my spaghetti code. However, this led to me developing my intuition and problem solving abilities, when it comes to debugging, which I believe is incredibly important as an engineer.
  </details>

---


### Info and about the app:
* <details>
  <summary>Info & About:</summary>

  * the app is fully built by me, Alex Brodsky a CS student, in Swift for Mac OS 14.4 or 15.5
      * I could try lowering the required MacOS version if you want to try the app, my email is brodsky.alex22@gmail.com

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
  </details>

---

### Tips for using the app:
* <details>
    <summary>Tips:</summary>

  * see the ListOfKeyboardShortcuts.md file for the full list of keyboard shortcuts, or scroll to the bottom

  * these can be changed:
      - cmd + shift + c: open and close window
      - option + r: reset window
      - cmd + shift + v: paste without formatting
      - option + shift + c: paste Capitalized text without formatting
      - option + shift + l: paste All Lowercase without formatting
      - option + shift + u: paste All Uppercase without formatting

  * cmd + shift + c is default for showing/hiding the app
      * also click the menu bar icon to show the app

  * use the mouse or arrow keys to select items
      * scroll arrow button, cmd + up/down arrow, or page up/down to scroll up or down

  * double-click, enter, or copy button to copy an item/group

  * delete button or cmd + delete to delete an item/group

  * expand button or right-arrow when selecting group to expand

  * expand button or left-arrow on group to contract

  * cmd + f to search for text, files, folders, and even OCR by searching for text in images

  * escape takes you out of search or selecting clipboard types, or if not selecting anything, it hides the app

  * option + r resets the window size and shows it

  * cmd + shift + v for paste without formatting anywhere on your computer!

  * the open button next to files and folders opens the file, folder, or app
  </details>

---

### Here is a list of all the Keyboard Shortcuts:
* <details>
    <summary>changeable shortcuts:</summary>

      - cmd + shift + c: open and close window
      - option + r: reset window
      - cmd + shift + v: paste without formatting
      - option + shift + c: paste Capitalized text without formatting
      - option + shift + l: paste All Lowercase without formatting
      - option + shift + u: paste All Uppercase without formatting
  </details>

* <details>
    <summary>unchangeable shortcuts:</summary>

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

      - cmd + shift + p: toggle Pause/Resume copying

      - cmd + enter: open item

      - cmd + delete: delete selected item
      - cmd + shift + delete: clear all items

      - cmd + [: open all groups
      - cmd + ]: close all groups

      - cmd + up: scroll to top
      - page up: scroll to top

      - cmd + down: scroll to bottom
      - page down: scroll to bottom

      - esc: exit search or type selector, or if not selecting anything hide the app
  </details>

---

### Screenshots:
<div style="display: flex; justify-content: center; align-items: center; flex-wrap: wrap; gap: 40px;">
    <img src="https://github.com/user-attachments/assets/5159adc7-daa6-439a-8380-c28f2f8c5863" alt="example screen shot" height="300"/>
    <img src="https://github.com/user-attachments/assets/48884218-41e7-4273-bba7-6753feceb33d" alt="example popup window" height="300"/>
    <img src="https://github.com/user-attachments/assets/0fc2feba-a20e-4bb0-a75e-d8a2747b75ff" alt="example screen shot with open group" height="300"/>
    <img src="https://github.com/user-attachments/assets/816caec4-2adb-4f34-90f7-335faee855d1" alt="example folder search screen shot" height="300"/>
</div>