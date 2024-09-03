//
//  SettingsView.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 8/30/24.
//

import Foundation
import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    let userDefaultsManager = UserDefaultsManager.shared
    let clipboardManager = ClipboardManager.shared
    let menuManager = MenuManager.shared
    
    @State private var pauseCopying = UserDefaults.standard.bool(forKey: "pauseCopying")
    @State private var pauseCopyingInput = UserDefaults.standard.bool(forKey: "pauseCopying")

    @State private var maxStoreCount = UserDefaults.standard.integer(forKey: "maxStoreCount")
    @State private var maxStoreCountInput = UserDefaults.standard.integer(forKey: "maxStoreCount")
    
    @State private var noDuplicates = UserDefaults.standard.bool(forKey: "noDuplicates")
    @State private var noDuplicatesInput = UserDefaults.standard.bool(forKey: "noDuplicates")
    
    @State private var canCopyFilesOrFolders = UserDefaults.standard.bool(forKey: "canCopyFilesOrFolders")
    @State private var canCopyFilesOrFoldersInput = UserDefaults.standard.bool(forKey: "canCopyFilesOrFolders")
    
    @State private var canCopyImages = UserDefaults.standard.bool(forKey: "canCopyImages")
    @State private var canCopyImagesInput = UserDefaults.standard.bool(forKey: "canCopyImages")

    @State private var pasteWithoutFormatting = UserDefaults.standard.bool(forKey: "pasteWithoutFormatting")
    @State private var pasteWithoutFormattingInput = UserDefaults.standard.bool(forKey: "pasteWithoutFormatting")

    
    
    @State private var darkMode = UserDefaults.standard.bool(forKey: "darkMode")
    @State private var darkModeInput = UserDefaults.standard.bool(forKey: "darkMode")

    @State private var windowWidth = UserDefaults.standard.float(forKey: "windowWidth")
    @State private var windowWidthInput: Float = UserDefaults.standard.float(forKey: "windowWidth")

    @State private var windowHeight = UserDefaults.standard.float(forKey: "windowHeight")
    @State private var windowHeightInput: Float = UserDefaults.standard.float(forKey: "windowHeight")

    @State private var windowLocation = UserDefaults.standard.string(forKey: "windowLocation")
    @State private var windowLocationInput = UserDefaults.standard.string(forKey: "windowLocation")
    
    @State private var windowPopOut = UserDefaults.standard.bool(forKey: "windowPopOut")
    @State private var windowPopOutInput = UserDefaults.standard.bool(forKey: "windowPopOut")

    @State private var canWindowFloat = UserDefaults.standard.bool(forKey: "canWindowFloat")
    @State private var canWindowFloatInput = UserDefaults.standard.bool(forKey: "canWindowFloat")

    @State private var hideWindowWhenNotSelected = UserDefaults.standard.bool(forKey: "hideWindowWhenNotSelected")
    @State private var hideWindowWhenNotSelectedInput = UserDefaults.standard.bool(forKey: "hideWindowWhenNotSelected")

    @State private var windowOnAllDesktops = UserDefaults.standard.bool(forKey: "windowOnAllDesktops")
    @State private var windowOnAllDesktopsInput = UserDefaults.standard.bool(forKey: "windowOnAllDesktops")
    
    
    
    @State var pasteWithoutFormattingShortcut: KeyboardShortcut = UserDefaultsManager.shared.pasteWithoutFormattingShortcut
    @State var pasteWithoutFormattingShortcutInput: KeyboardShortcut = UserDefaultsManager.shared.pasteWithoutFormattingShortcut
    
    @State var toggleWindowShortcut: KeyboardShortcut = UserDefaultsManager.shared.toggleWindowShortcut
    @State var toggleWindowShortcutInput: KeyboardShortcut = UserDefaultsManager.shared.toggleWindowShortcut

    @State var resetWindowShortcut: KeyboardShortcut = UserDefaultsManager.shared.resetWindowShortcut
    @State var resetWindowShortcutInput: KeyboardShortcut = UserDefaultsManager.shared.resetWindowShortcut

    
    @State private var geoWidth: CGFloat = 0.0
    @State private var geoHeight: CGFloat = 0.0
    
    @State private var saved: Bool = false
    @State private var resetSettings: Bool = false
    
    @State private var showingResetAlert: Bool = false

    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                Color.clear
                    .frame(height: 1)
                    .onAppear {
                        self.geoWidth = geometry.size.width
                        self.geoHeight = geometry.size.height
                    }
                    .onChange(of: geometry.size.width) { old, new in
                        self.geoWidth = new
                    }
                    .onChange(of: geometry.size.height) { old, new in
                        self.geoHeight = new
                    }
            }
            .zIndex(-10)
            
            if self.saved {
                ZStack(alignment: .center) {
                    
                    ZStack(alignment: .top) {
                        Rectangle()
                            .foregroundColor(darkMode ? Color(.darkGray) : Color.gray)
                            .cornerRadius(8)
                        Rectangle()
                            .foregroundColor(darkMode ? Color(.darkGray) : Color.gray)
                            .frame(height: 10)
                            .zIndex(1)
                    }
                    Text("Saved!")
                        .font(.subheadline)
                        .bold()
                    
                        .cornerRadius(8)
                        .frame(alignment: .center)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: self.saved)
                // x: frame_width/2  |  y: -(window_height/2 - frame_height)
                .position(x: 90/2, y: -(self.geoHeight/2 - 8))
                .frame(width: 90, height: 24)
                .zIndex(1000)
                
                
                Color.white.opacity(0.1).flash(duration: 0.3)
            }
            
            if self.resetSettings {
                ZStack(alignment: .center) {
                    
                    ZStack(alignment: .top) {
                        Rectangle()
                            .foregroundColor(darkMode ? Color(.darkGray) : Color.gray)
                            .cornerRadius(8)
                        Rectangle()
                            .foregroundColor(darkMode ? Color(.darkGray) : Color.gray)
                            .frame(height: 10)
                            .zIndex(1)
                    }
                    Text("Reset Settings to Default!")
                        .font(.subheadline)
                        .bold()
                    
                        .cornerRadius(8)
                        .frame(alignment: .center)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: self.resetSettings)
                // x: frame_width/2  |  y: -(window_height/2 - frame_height)
                .position(x: 150/2, y: -(self.geoHeight/2 - 8))
                .frame(width: 150, height: 24)
                .zIndex(1000)
                
                
                Color.white.opacity(0.1).flash(duration: 0.3)
            }
            
            VStack {
                TabView {
                    ClipboardSettingsView(pauseCopyingInput: $pauseCopyingInput, maxStoreCountInput: $maxStoreCountInput, noDuplicatesInput: $noDuplicatesInput, canCopyFilesOrFoldersInput: $canCopyFilesOrFoldersInput, canCopyImagesInput: $canCopyImagesInput, pasteWithoutFormattingInput: $pasteWithoutFormattingInput)
                        .tabItem {
                            Text("Clipboard")
                                .help("View Clipboard Related Settings")
                        }

                    
                    WindowSettingsView(darkModeInput: $darkModeInput, windowWidthInput: $windowWidthInput, windowHeightInput: $windowHeightInput, windowLocationInput: $windowLocationInput, windowPopOutInput: $windowPopOutInput, canWindowFloatInput: $canWindowFloatInput, hideWindowWhenNotSelectedInput: $hideWindowWhenNotSelectedInput, windowOnAllDesktopsInput: $windowOnAllDesktopsInput)
                        .tabItem {
                            Text("Window")
                                .help("View Window Settings")
                        }
                    
                    ShortcutsSettingsView(pasteWithoutFormattingShortcutInput: $pasteWithoutFormattingShortcutInput, toggleWindowShortcutInput: $toggleWindowShortcutInput, resetWindowShortcutInput: $resetWindowShortcutInput)
                        .tabItem {
                            Text("Keyboad Shortcuts")
                                .help("View Keyboard Shortcut Settings")
                        }

                }

                ZStack {
                    Button("Reset Settings to Default") {
                        showingResetAlert = true
                    }
                    .padding(.leading, -280)
//                    .position(x: self.geoWidth - 100, y: self.geoHeight/2 - 150)
                    .alert(isPresented: $showingResetAlert) {
                        Alert(
                            title: Text("Confirm Reset Settings to Default"),
                            message: Text("Are you sure you want to reset settings to default?"),
                            primaryButton: .destructive(Text("Reset Settings")) {
                                self.resetSettingsToDefault()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    .help("Reset Settings to Default Button")
                    
                    Button("Save") {
                        self.saveSettings()
                    }
                    .padding(.leading, 500)
                    .help("Save Button")
                    
                }
                .padding(.top, -10)
                .padding(.bottom, -10)

                
                .padding()
                .onChange(of: self.saved) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.saved = false
                    }
                }
                .onChange(of: self.resetSettings) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.resetSettings = false
                    }
                }
            }
            .padding(.top, 20)
            
        }
        .frame(width: 580, height: 500)
        .padding()
        .onAppear() {
            self.setUpKeyboardHandling()
        }
    }
    
    private func handleWindowDidResignKey(_ notification: Notification) {
        print("Window did resign key (unfocused)")
        // App lost focus
        
        print(UserDefaultsManager.shared.hideWindowWhenNotSelected)
        if UserDefaultsManager.shared.hideWindowWhenNotSelected {
            // Check if the current main window is the settings window
            if let mainWindow = NSApplication.shared.mainWindow, mainWindow.title == "ClipboardHistory" {
                print("The main window is the settings window, not hiding it.")
            } else {
                WindowManager.shared.hideWindow()
            }
        }
    }
    
    private func saveSettings() {
        
        UserDefaults.standard.set(pauseCopyingInput, forKey: "pauseCopying")
        UserDefaults.standard.set(maxStoreCountInput, forKey: "maxStoreCount")
        UserDefaults.standard.set(noDuplicatesInput, forKey: "noDuplicates")
        UserDefaults.standard.set(canCopyFilesOrFoldersInput, forKey: "canCopyFilesOrFolders")
        UserDefaults.standard.set(canCopyImagesInput, forKey: "canCopyImages")
        UserDefaults.standard.set(pasteWithoutFormattingInput, forKey: "pasteWithoutFormatting")
        
        UserDefaults.standard.set(darkModeInput, forKey: "darkMode")
        UserDefaults.standard.set(windowWidthInput, forKey: "windowWidth")
        UserDefaults.standard.set(windowHeightInput, forKey: "windowHeight")
        UserDefaults.standard.set(windowLocationInput, forKey: "windowLocation")
        UserDefaults.standard.set(windowPopOutInput, forKey: "windowPopOut")
        UserDefaults.standard.set(canWindowFloatInput, forKey: "canWindowFloat")
        UserDefaults.standard.set(hideWindowWhenNotSelectedInput, forKey: "hideWindowWhenNotSelected")
        UserDefaults.standard.set(windowOnAllDesktopsInput, forKey: "windowOnAllDesktops")
        
        if pasteWithoutFormattingInput {
            //                        print("enabling")
            KeyboardShortcuts.onKeyUp(for: .pasteNoFormatting) {
                clipboardManager.pasteNoFormatting()
            }
        }
        else if !pasteWithoutFormattingInput {
            //                        print("disabling")
            KeyboardShortcuts.disable(.pasteNoFormatting)
        }
        
        userDefaultsManager.pasteWithoutFormattingShortcut = pasteWithoutFormattingShortcutInput
        userDefaultsManager.toggleWindowShortcut = toggleWindowShortcutInput
        userDefaultsManager.resetWindowShortcut = resetWindowShortcutInput
        
        userDefaultsManager.updateAll(savePasteWithoutFormattingShortcut: pasteWithoutFormatting == pasteWithoutFormattingInput)
        
        if hideWindowWhenNotSelected {
            NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification,object: nil,queue: .main) { notification in
                self.handleWindowDidResignKey(notification)
            }
        }
        
        menuManager.updateMainMenu(isCopyingPaused: pauseCopyingInput)
        
        DispatchQueue.main.async {
            self.saved = true
        }
        
        WindowManager.shared.handleResetWindow()
    }
    
    private func resetSettingsToDefault() {
        pauseCopyingInput = false
        maxStoreCountInput = 50
        noDuplicatesInput = true
        canCopyFilesOrFoldersInput = true
        canCopyImagesInput = true
//        pasteWithoutFormattingInput = false // not gonna reset
//        darkModeInput = true // not gonna reset
        windowWidthInput = 300.0
        windowHeightInput = 500.0
        windowLocationInput = "Bottom Right"
        windowPopOutInput = false
        canWindowFloatInput = false
        hideWindowWhenNotSelectedInput = false
        windowOnAllDesktopsInput = true
        
        pasteWithoutFormattingShortcutInput = KeyboardShortcut(modifiers: ["command", "shift"], key: "v")
        toggleWindowShortcutInput = KeyboardShortcut(modifiers: ["command", "shift"], key: "c")
        resetWindowShortcutInput = KeyboardShortcut(modifiers: ["option"], key: "r")
        
        UserDefaults.standard.set(pauseCopyingInput, forKey: "pauseCopying")
        UserDefaults.standard.set(maxStoreCountInput, forKey: "maxStoreCount")
        UserDefaults.standard.set(noDuplicatesInput, forKey: "noDuplicates")
        UserDefaults.standard.set(canCopyFilesOrFoldersInput, forKey: "canCopyFilesOrFolders")
        UserDefaults.standard.set(canCopyImagesInput, forKey: "canCopyImages")
//        UserDefaults.standard.set(pasteWithoutFormattingInput, forKey: "pasteWithoutFormatting") // not gonna reset
        
//        UserDefaults.standard.set(darkModeInput, forKey: "darkMode") // not gonna reset
        UserDefaults.standard.set(windowWidthInput, forKey: "windowWidth")
        UserDefaults.standard.set(windowHeightInput, forKey: "windowHeight")
        UserDefaults.standard.set(windowLocationInput, forKey: "windowLocation")
        UserDefaults.standard.set(windowPopOutInput, forKey: "windowPopOut")
        UserDefaults.standard.set(canWindowFloatInput, forKey: "canWindowFloat")
        UserDefaults.standard.set(hideWindowWhenNotSelectedInput, forKey: "hideWindowWhenNotSelected")
        UserDefaults.standard.set(windowOnAllDesktopsInput, forKey: "windowOnAllDesktops")
        
        userDefaultsManager.pasteWithoutFormattingShortcut = pasteWithoutFormattingShortcutInput
        userDefaultsManager.toggleWindowShortcut = toggleWindowShortcutInput
        userDefaultsManager.resetWindowShortcut = resetWindowShortcutInput
        
        menuManager.updateMainMenu(isCopyingPaused: pauseCopyingInput)
        
        userDefaultsManager.updateAll(savePasteWithoutFormattingShortcut: true)

        
        DispatchQueue.main.async {
            self.resetSettings = true
        }
        
        WindowManager.shared.handleResetWindow()
    }
    
    private func setUpKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.type == .keyDown && !self.showingResetAlert {
                if event.keyCode == 13 && event.modifierFlags.contains(.command) {
                    // handle Cmd + W
                    if let settingsWindow = SettingsWindowManager.shared.settingsWindow, settingsWindow.isKeyWindow {
                        SettingsWindowManager.shared.closeSettingsWindow()
                        return nil
                    }
                }
            }
            return event
        }
    }
}

struct ClipboardSettingsView: View {
    let userDefaultsManager = UserDefaultsManager.shared
    let clipboardManager = ClipboardManager.shared
    let menuManager = MenuManager.shared

    @State private var pauseCopying = UserDefaults.standard.bool(forKey: "pauseCopying")
    @Binding var pauseCopyingInput: Bool

    @State private var maxStoreCount = UserDefaults.standard.integer(forKey: "maxStoreCount")
    @Binding var maxStoreCountInput: Int
    
    @State private var noDuplicates = UserDefaults.standard.bool(forKey: "noDuplicates")
    @Binding var noDuplicatesInput: Bool
    
    @State private var canCopyFilesOrFolders = UserDefaults.standard.bool(forKey: "canCopyFilesOrFolders")
    @Binding var canCopyFilesOrFoldersInput: Bool
    
    @State private var canCopyImages = UserDefaults.standard.bool(forKey: "canCopyImages")
    @Binding var canCopyImagesInput: Bool
    
    @State private var pasteWithoutFormatting = UserDefaults.standard.bool(forKey: "pasteWithoutFormatting")
    @Binding var pasteWithoutFormattingInput: Bool
    
    
    @State private var geoWidth: CGFloat = 0.0
    @State private var geoHeight: CGFloat = 0.0
    
    @State private var saved: Bool = false
    
    @State private var itemCountInput: String = ""
    
    var body: some View {
            VStack {
                ScrollView {
                    Form {
                        VStack {
                            Spacer()
                            Spacer()
                            Toggle("Pause Copying?", isOn: $pauseCopyingInput).padding()
                            
                            HStack {
                                Text("Max Number of Items to Store: ")
                                TextField(
                                    "",
                                    text: $itemCountInput
                                )
                                .disableAutocorrection(true)
                                .padding(5)
                                .frame(width: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(itemCountInput.isEmpty ? Color.red : Color.clear, lineWidth: 2)
                                )
                                .onChange(of: itemCountInput) {
                                    if let checkInt = checkItemCount(itemCountInput) {
                                        maxStoreCountInput = min(checkInt, 150) // Ensure maxStoreCount does not exceed 150
                                        itemCountInput = "\(maxStoreCountInput)" // Update the text field with the valid value
                                    } else {
                                        maxStoreCountInput = 0 // or some other default value if the input is invalid
                                    }
                                }
                                .onChange(of: maxStoreCountInput) {
                                    itemCountInput = "\(maxStoreCountInput)"
                                }
                                .onAppear {
                                    itemCountInput = "\(maxStoreCountInput)"
                                }
                            }
                            
                            Toggle("No Duplicate Copies?", isOn: $noDuplicatesInput).padding()
                            Toggle("Can App Hold Files or Folders?", isOn: $canCopyFilesOrFoldersInput).padding()
                            Toggle("Can App Hold Images?", isOn: $canCopyImagesInput).padding()
                            Toggle("Enable Paste Without Formatting?", isOn: $pasteWithoutFormattingInput).padding()
                        }
                    }
                }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    private func checkItemCount(_ itemCount: String) -> Int? {
        // Try to convert the string to an integer
        if let intValue = Int(itemCount), intValue > 0 {
            return intValue
        }
        return nil
    }
}

struct WindowSettingsView: View {
    let userDefaultsManager = UserDefaultsManager.shared
    
    @State private var darkMode = UserDefaults.standard.bool(forKey: "darkMode")
    @Binding var darkModeInput: Bool
    
    @State private var windowWidth = UserDefaults.standard.float(forKey: "windowWidth")
    @Binding var windowWidthInput: Float

    @State private var windowHeight = UserDefaults.standard.float(forKey: "windowHeight")
    @Binding var windowHeightInput: Float

    @State private var windowLocation = UserDefaults.standard.string(forKey: "windowLocation")
    @Binding var windowLocationInput: String!
    
    @State private var windowPopOut = UserDefaults.standard.bool(forKey: "windowPopOut")
    @Binding var windowPopOutInput: Bool

    @State private var canWindowFloat = UserDefaults.standard.bool(forKey: "canWindowFloat")
    @Binding var canWindowFloatInput: Bool

    @State private var hideWindowWhenNotSelected = UserDefaults.standard.bool(forKey: "hideWindowWhenNotSelected")
    @Binding var hideWindowWhenNotSelectedInput: Bool

    @State private var windowOnAllDesktops = UserDefaults.standard.bool(forKey: "windowOnAllDesktops")
    @Binding var windowOnAllDesktopsInput: Bool
    

    @State private var geoWidth: CGFloat = 0.0
    @State private var geoHeight: CGFloat = 0.0
    
    @State private var saved: Bool = false
    
    @State private var isEditingWidth = false

    @State private var isEditingHeight = false

    @State private var isWindowMenuSelected: Bool = false
    
    var body: some View {
        VStack {
            ScrollView {
                Form {
                    VStack {
                        Spacer()
                        Toggle("Dark Mode On?", isOn: $darkModeInput).padding()
                        Text("Might need to restart app for a full visual update")
                            .font(.subheadline)
                            .padding(.top, -20)
                        
                        Spacer()
                        Spacer()
                        
                        Text("Window Width: ")
                        
                        VStack {
                            Slider(
                                value: $windowWidthInput,
                                in: 100...2000,
                                onEditingChanged: { editing in
                                    isEditingWidth = editing
                                }
                            )
                            Text("\(windowWidthInput, specifier: "%.f")")
                                .foregroundColor(isEditingWidth ? .red : .blue)
                        }
                        .frame(width: 500)
                        
                        
                        Spacer()
                        Spacer()
                        
                        Text("Window Height: ")
                        
                        VStack {
                            Slider(
                                value: $windowHeightInput,
                                in: 100...2000,
                                onEditingChanged: { editing in
                                    isEditingHeight = editing
                                }
                            )
                            Text("\(windowHeightInput, specifier: "%.f")")
                                .foregroundColor(isEditingHeight ? .red : .blue)
                        }
                        .frame(width: 500)
                        
                        Spacer()
                        
                        Toggle("Switch Window to Pop Out of Status Bar Icon?", isOn: $windowPopOutInput).padding()
                        
                        
                        Spacer()
                        Spacer()
                        
                        Text("Default Window Location: ")
                            .foregroundColor(windowPopOutInput ? Color.gray : (darkMode ? .white : .primary))
                        Menu {
                            Button(action: {
                                windowLocationInput = "Top Left"
                                isWindowMenuSelected = true
                            }) {
                                Text("Top Left")
                            }
                            Button(action: {
                                windowLocationInput = "Top Right"
                                isWindowMenuSelected = true
                            }) {
                                Text("Top Right")
                            }
                            Button(action: {
                                windowLocationInput = "Center"
                                isWindowMenuSelected = true
                            }) {
                                Text("Center")
                            }
                            Button(action: {
                                windowLocationInput = "Bottom Left"
                                isWindowMenuSelected = true
                            }) {
                                Text("Bottom Left")
                            }
                            Button(action: {
                                windowLocationInput = "Bottom Right"
                                isWindowMenuSelected = true
                            }) {
                                Text("Bottom Right")
                            }
                        } label: {
                            Text((windowLocationInput ?? windowLocation) ?? "Select Window Location")
                                .foregroundColor(windowLocationInput == nil ? .gray : (darkMode ? .white : .primary))
                        }
                        .frame(width: 200)
                        .disabled(windowPopOutInput)
                        .onAppear {
                            windowLocationInput = isWindowMenuSelected ? windowLocationInput : windowLocation
                        }
                        
                        
                        Toggle("Can Window Float?", isOn: $canWindowFloatInput)
                            .foregroundColor(windowPopOutInput ? Color.gray : (darkMode ? .white : .primary))
                            .disabled(windowPopOutInput)
                            .padding()
                        
                        Toggle("**Very Buggy** Hide Window When Not Primary App?", isOn: $hideWindowWhenNotSelectedInput)
                            .foregroundColor(windowPopOutInput ? Color.gray : (darkMode ? .white : .primary))
                            .disabled(windowPopOutInput)
                            .padding()
                        
                        Toggle("Show Window On All Desktops?", isOn: $windowOnAllDesktops)
                            .foregroundColor(windowPopOutInput ? Color.gray : (darkMode ? .white : .primary))
                            .disabled(windowPopOutInput)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    private func checkFloatValue(_ inputString: String) -> Float? {
        // Try to convert the string to an float
        if let floatValue = Float(inputString), floatValue > 0 {
            return floatValue
        }
        return nil
    }
    
    private func handleWindowDidResignKey(_ notification: Notification) {
        print("Window did resign key (unfocused)")
        // App lost focus
        
        print(UserDefaultsManager.shared.hideWindowWhenNotSelected)
        if UserDefaultsManager.shared.hideWindowWhenNotSelected {
            // Check if the current main window is the settings window
            if let mainWindow = NSApplication.shared.mainWindow, mainWindow.title == "ClipboardHistory" {
                print("The main window is the settings window, not hiding it.")
            } else {
                WindowManager.shared.hideWindow()
            }
        }
    }
}

struct ShortcutsSettingsView: View {
    let userDefaultsManager = UserDefaultsManager.shared

    @State var pasteWithoutFormattingShortcut: KeyboardShortcut = UserDefaultsManager.shared.pasteWithoutFormattingShortcut
    @Binding var pasteWithoutFormattingShortcutInput: KeyboardShortcut
    
    @State var toggleWindowShortcut: KeyboardShortcut = UserDefaultsManager.shared.toggleWindowShortcut
    @Binding var toggleWindowShortcutInput: KeyboardShortcut
    
    @State var resetWindowShortcut: KeyboardShortcut = UserDefaultsManager.shared.resetWindowShortcut
    @Binding var resetWindowShortcutInput: KeyboardShortcut
    
    
    @State private var geoWidth: CGFloat = 0.0
    @State private var geoHeight: CGFloat = 0.0
    
    @State private var saved: Bool = false

    var body: some View {
        VStack {
            ScrollView {
                Form {
                    VStack {
                        VStack {
                            Spacer()
                            Text("Paste Without Formatting Shortcut: ")
                            
                            Spacer()
                            
                            CustomShortcutView(shortcut: $pasteWithoutFormattingShortcutInput)
                            
                        }.padding()
                        
                        VStack {
                            Text("Toggle Show/Hide Window Shortcut: ")
                            
                            Spacer()
                            
                            CustomShortcutView(shortcut: $toggleWindowShortcutInput)
                            
                        }.padding()
                        
                        VStack {
                            Text("Reset Window Shortcut: ")
                            
                            Spacer()
                            
                            CustomShortcutView(shortcut: $resetWindowShortcutInput)
                            
                        }.padding()
                        
                        Spacer()
                        
                        Text("Click the Help menu tab or this link for the full list of Keyboard Shortcuts: ")
                        Link("ListOfKeyboardShortcuts", destination: URL(string: "https://github.com/Albro3459/ClipboardHistory/blob/main/ListOfKeyboardShortcuts.md")!)
                        
                        
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct CustomShortcutView : View {
    
    @Binding var shortcut: KeyboardShortcut
    
    @State private var keyInput: String = ""
    
    @State private var tempKey: String = ""
    
    var body: some View {
        HStack {
            KeyboardModifierView(keyModifier: "shift", modifiers: $shortcut.modifiers, isSelected: Binding(
                get: { shortcut.modifiers.contains("shift") },
                set: { isSelected in
                    if isSelected {
                        if !shortcut.modifiers.contains("shift") {
                            shortcut.modifiers.append("shift")
                        }
                    } else {
                        shortcut.modifiers.removeAll { $0 == "shift" }
                    }
                }
            ))
            
            Text("+")
            
            KeyboardModifierView(keyModifier: "control", modifiers: $shortcut.modifiers, isSelected: Binding(
                get: { shortcut.modifiers.contains("control") },
                set: { isSelected in
                    if isSelected {
                        if !shortcut.modifiers.contains("control") {
                            shortcut.modifiers.append("control")
                        }
                    } else {
                        shortcut.modifiers.removeAll { $0 == "control" }
                    }
                }
            ))
            
            Text("+")
            
            KeyboardModifierView(keyModifier: "option", modifiers: $shortcut.modifiers, isSelected: Binding(
                get: { shortcut.modifiers.contains("option") },
                set: { isSelected in
                    if isSelected {
                        if !shortcut.modifiers.contains("option") {
                            shortcut.modifiers.append("option")
                        }
                    } else {
                        shortcut.modifiers.removeAll { $0 == "option" }
                    }
                }
            ))
            
            Text("+")
            
            KeyboardModifierView(keyModifier: "command", modifiers: $shortcut.modifiers, isSelected: Binding(
                get: { shortcut.modifiers.contains("command") },
                set: { isSelected in
                    if isSelected {
                        if !shortcut.modifiers.contains("command") {
                            shortcut.modifiers.append("command")
                        }
                    } else {
                        shortcut.modifiers.removeAll { $0 == "command" }
                    }
                }
            ))
            
            Text("+")

            TextField(
                "Key",
                text: $keyInput
            )
            .disableAutocorrection(true)
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(keyInput.isEmpty ? Color.red : Color.clear, lineWidth: 2)
            )
            .onChange(of: keyInput) {
                let checkedKey = checkKey(keyInput)
                keyInput = checkedKey
                if !checkedKey.isEmpty {
                    shortcut.key = checkedKey
                }
            }
            .onAppear() {
                keyInput = shortcut.key
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func checkKey(_ key: String) -> String {
        guard let firstChar = key.first, firstChar.isASCII else {
            return ""
        }
        let newKey = String(firstChar).lowercased()
        
        return newKey
    }
}

struct KeyboardModifierView : View {
    var keyModifier: String
    @Binding var modifiers: [String]
    @Binding var isSelected: Bool
    
    @State private var selectedItem: String? = nil
    
    var body: some View {
        Menu {
            Button(action: {
                selectedItem = keyModifier
                isSelected = true
                if !modifiers.contains(keyModifier) {
                    modifiers.append(keyModifier)
                }
            }) {
                Text(keyModifier)
            }
            Button(action: {
                if modifiers.count > 1 {
                    selectedItem = nil
                    isSelected = false
                    modifiers.removeAll { $0 == keyModifier }
                }
            }) {
                Text("None")
            }
        } label: {
            Text(selectedItem ?? keyModifier)
                .foregroundColor(selectedItem == nil ? .gray : .primary)
        }
        .onAppear() {
            if isSelected {
                selectedItem = keyModifier
            }
            else {
                selectedItem = nil
            }
        }
    }
}
