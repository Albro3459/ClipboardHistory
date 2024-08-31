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
    
    var body: some View {
        TabView {
            ClipboardSettingsView()
                .tabItem {
                    Text("Clipboard")
                }
            
            WindowSettingsView()
                .tabItem {
                    Text("Window")
                }
            
            ShortcutsSettingsView()
                .tabItem {
                    Text("Keyboad Shortcuts")
                }
        }
        .frame(width: 580, height: 450)
        .padding()
    }
}

struct ClipboardSettingsView: View {
    let userDefaultsManager = UserDefaultsManager.shared
    let clipboardManager = ClipboardManager.shared
    let menuManager = MenuManager.shared

    @State private var pauseCopying = UserDefaults.standard.bool(forKey: "pauseCopying")
    @State private var maxStoreCount = UserDefaults.standard.integer(forKey: "maxStoreCount")
    @State private var noDuplicates = UserDefaults.standard.bool(forKey: "noDuplicates")
    @State private var canCopyFilesOrFolders = UserDefaults.standard.bool(forKey: "canCopyFilesOrFolders")
    @State private var canCopyImages = UserDefaults.standard.bool(forKey: "canCopyImages")
    @State private var pasteWithoutFormatting = UserDefaults.standard.bool(forKey: "pasteWithoutFormatting")
    
    @State private var darkMode = UserDefaults.standard.bool(forKey: "darkMode")
    @State private var windowWidth = UserDefaults.standard.float(forKey: "windowWidth")
    @State private var windowHeight = UserDefaults.standard.float(forKey: "windowHeight")
    @State private var windowLocation = UserDefaults.standard.string(forKey: "windowLocation")
    @State private var windowPopOut = UserDefaults.standard.bool(forKey: "windowPopOut")
    @State private var onlyPopOutWindow = UserDefaults.standard.bool(forKey: "onlyPopOutWindow")
    @State private var canWindowFloat = UserDefaults.standard.bool(forKey: "canWindowFloat")
    @State private var hideWindowWhenNotSelected = UserDefaults.standard.bool(forKey: "hideWindowWhenNotSelected")
    @State private var windowOnAllDesktops = UserDefaults.standard.bool(forKey: "windowOnAllDesktops")

    @State var pasteWithoutFormattingShortcut: KeyboardShortcut = UserDefaultsManager.shared.pasteWithoutFormattingShortcut
    @State var toggleWindowShortcut: KeyboardShortcut = UserDefaultsManager.shared.toggleWindowShortcut
    @State var resetWindowShortcut: KeyboardShortcut = UserDefaultsManager.shared.resetWindowShortcut
    
    @State private var geoWidth: CGFloat = 0.0
    @State private var geoHeight: CGFloat = 0.0
    
    @State private var saved: Bool = false
    
    @State private var itemCountInput: String = ""
    
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
                            .foregroundColor(Color(.darkGray))
                            .cornerRadius(8)
                        Rectangle()
                            .foregroundColor(Color(.darkGray))
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
                .position(x: 90/2, y: -(self.geoHeight/2 + 22))
                .frame(width: 90, height: 24)
                .zIndex(5)
                
                
                Color.white.opacity(0.1).flash(duration: 0.3)
            }
            
            VStack {
                ScrollView {
                    Form {
                        VStack {
                            Spacer()
                            Toggle("Pause Copying?", isOn: $pauseCopying).padding()
                            
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
                                        maxStoreCount = min(checkInt, 150) // Ensure maxStoreCount does not exceed 150
                                        itemCountInput = "\(maxStoreCount)" // Update the text field with the valid value
                                    } else {
                                        maxStoreCount = 0 // or some other default value if the input is invalid
                                    }
                                }
                                .onAppear {
                                    itemCountInput = "\(maxStoreCount)"
                                }
                            }
                            
                            
                            Toggle("No Duplicate Copies?", isOn: $noDuplicates).padding()
                            Toggle("Can App Hold Files or Folders?", isOn: $canCopyFilesOrFolders).padding()
                            Toggle("Can App Hold Images?", isOn: $canCopyImages).padding()
                            Toggle("Enable Paste Without Formatting?", isOn: $pasteWithoutFormatting).padding()
                        }
                    }
                }
                Button("Save") {
                    UserDefaults.standard.set(pauseCopying, forKey: "pauseCopying")
                    UserDefaults.standard.set(maxStoreCount, forKey: "maxStoreCount")
                    UserDefaults.standard.set(noDuplicates, forKey: "noDuplicates")
                    UserDefaults.standard.set(canCopyFilesOrFolders, forKey: "canCopyFilesOrFolders")
                    UserDefaults.standard.set(canCopyImages, forKey: "canCopyImages")
                    UserDefaults.standard.set(pasteWithoutFormatting, forKey: "pasteWithoutFormatting")
                    if pasteWithoutFormatting {
                        print("enabling")
                        KeyboardShortcuts.onKeyUp(for: .pasteNoFormatting) {
                            clipboardManager.pasteNoFormatting()
                        }
                    }
                    else if !pasteWithoutFormatting {
                        print("disabling")
                        KeyboardShortcuts.disable(.pasteNoFormatting)
                    }
                    
                    userDefaultsManager.updateAll(saveShortcuts: false)
                    
                    menuManager.updateMainMenu(isCopyingPaused: pauseCopying)
                    
                    DispatchQueue.main.async {
                        self.saved = true
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: self.saved) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.saved = false
                }
            }
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
    
    @State private var pauseCopying = UserDefaults.standard.bool(forKey: "pauseCopying")
    @State private var maxStoreCount = UserDefaults.standard.integer(forKey: "maxStoreCount")
    @State private var noDuplicates = UserDefaults.standard.bool(forKey: "noDuplicates")
    @State private var canCopyFilesOrFolders = UserDefaults.standard.bool(forKey: "canCopyFilesOrFolders")
    @State private var canCopyImages = UserDefaults.standard.bool(forKey: "canCopyImages")
    @State private var pasteWithoutFormatting = UserDefaults.standard.bool(forKey: "pasteWithoutFormatting")
    
    @State private var darkMode = UserDefaults.standard.bool(forKey: "darkMode")
    @State private var windowWidth = UserDefaults.standard.float(forKey: "windowWidth")
    @State private var windowHeight = UserDefaults.standard.float(forKey: "windowHeight")
    @State private var windowLocation = UserDefaults.standard.string(forKey: "windowLocation")
    @State private var windowPopOut = UserDefaults.standard.bool(forKey: "windowPopOut")
    @State private var onlyPopOutWindow = UserDefaults.standard.bool(forKey: "onlyPopOutWindow")
    @State private var canWindowFloat = UserDefaults.standard.bool(forKey: "canWindowFloat")
    @State private var hideWindowWhenNotSelected = UserDefaults.standard.bool(forKey: "hideWindowWhenNotSelected")
    @State private var windowOnAllDesktops = UserDefaults.standard.bool(forKey: "windowOnAllDesktops")

    @State private var geoWidth: CGFloat = 0.0
    @State private var geoHeight: CGFloat = 0.0
    
    @State private var saved: Bool = false
    
    @State private var widthInput: Float = UserDefaults.standard.float(forKey: "windowWidth")
    @State private var isEditingWidth = false

    @State private var heightInput: Float = UserDefaults.standard.float(forKey: "windowHeight")
    @State private var isEditingHeight = false

    @State private var windowLocationInput = UserDefaults.standard.string(forKey: "windowLocation")
    @State private var isWindowMenuSelected: Bool = false
    
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
                            .foregroundColor(Color(.darkGray))
                            .cornerRadius(8)
                        Rectangle()
                            .foregroundColor(Color(.darkGray))
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
                .position(x: 90/2, y: -(self.geoHeight/2 + 22))
                .frame(width: 90, height: 24)
                .zIndex(5)
                
                
                Color.white.opacity(0.1).flash(duration: 0.3)
            }
            VStack {
                ScrollView {
                    Form {
                        VStack {
                            Spacer()
                            Toggle("Dark Mode On?", isOn: $darkMode).padding()
                            
                            Text("Window Width: ")
                            
                            VStack {
                                Slider(
                                    value: $widthInput,
                                    in: 100...2000,
                                    onEditingChanged: { editing in
                                        isEditingWidth = editing
                                    }
                                )
                                Text("\(widthInput, specifier: "%.f")")
                                    .foregroundColor(isEditingWidth ? .red : .blue)
                            }
                            .frame(width: 500)
                            
                            
                            Spacer()
                            Spacer()
                            
                            Text("Window Height: ")
                            
                            VStack {
                                Slider(
                                    value: $heightInput,
                                    in: 100...2000,
                                    onEditingChanged: { editing in
                                        isEditingHeight = editing
                                    }
                                )
                                Text("\(heightInput, specifier: "%.f")")
                                    .foregroundColor(isEditingHeight ? .red : .blue)
                            }
                            .frame(width: 500)
                            
                            
                            
                            Spacer()
                            Text("Default Window Location: ")
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
                                    .foregroundColor(windowLocationInput == nil ? .gray : .primary)
                            }
                            .frame(width: 200)
                            .onAppear {
                                windowLocationInput = isWindowMenuSelected ? windowLocationInput : windowLocation
                            }
                            
                            
                            //                        Toggle("Pop Out Window From Menu Bar Icon?", isOn: $windowPopOut).padding()
                            //                        Toggle("ONLY Pop Out Window From Menu Bar Icon?", isOn: $onlyPopOutWindow).padding()
                            
                            Toggle("Can Window Float?", isOn: $canWindowFloat).padding()
                            Toggle("**Very Buggy** Hide Window When Not Primary App?", isOn: $hideWindowWhenNotSelected).padding()
                            Toggle("Show Window On All Desktops?", isOn: $windowOnAllDesktops).padding()
                        }
                        
                        
                    }
                }
                Button("Save") {
                    UserDefaults.standard.set(darkMode, forKey: "darkMode")
                    
                    windowWidth = widthInput
                    UserDefaults.standard.set(windowWidth, forKey: "windowWidth")
                    
                    windowHeight = heightInput
                    UserDefaults.standard.set(windowHeight, forKey: "windowHeight")
                    
                    windowLocation = windowLocationInput
                    UserDefaults.standard.set(windowLocation, forKey: "windowLocation")
                    UserDefaults.standard.set(windowPopOut, forKey: "windowPopOut")
                    UserDefaults.standard.set(onlyPopOutWindow, forKey: "onlyPopOutWindow")
                    UserDefaults.standard.set(canWindowFloat, forKey: "canWindowFloat")
                    UserDefaults.standard.set(hideWindowWhenNotSelected, forKey: "hideWindowWhenNotSelected")
                    UserDefaults.standard.set(windowOnAllDesktops, forKey: "windowOnAllDesktops")
                    
                    if pasteWithoutFormatting {
                        print("enabling")
                        KeyboardShortcuts.onKeyUp(for: .pasteNoFormatting) {
                            ClipboardManager.shared.pasteNoFormatting()
                        }
                    }
                    else if !pasteWithoutFormatting {
                        print("disabling")
                        KeyboardShortcuts.disable(.pasteNoFormatting)
                    }
                    
                    if hideWindowWhenNotSelected {
                        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification,object: nil,queue: .main) { notification in
                            handleWindowDidResignKey(notification)
                        }
                    }
                    
                    userDefaultsManager.updateAll(saveShortcuts: true)
                    
                    MenuManager.shared.updateMainMenu(isCopyingPaused: pauseCopying)
                    
                    DispatchQueue.main.async {
                        self.saved = true
                    }
                    
                    WindowManager.shared.resetWindow()
                    
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: self.saved) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.saved = false
                }
            }
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
    
    @State private var pauseCopying = UserDefaults.standard.bool(forKey: "pauseCopying")
    @State private var maxStoreCount = UserDefaults.standard.integer(forKey: "maxStoreCount")
    @State private var noDuplicates = UserDefaults.standard.bool(forKey: "noDuplicates")
    @State private var canCopyFilesOrFolders = UserDefaults.standard.bool(forKey: "canCopyFilesOrFolders")
    @State private var canCopyImages = UserDefaults.standard.bool(forKey: "canCopyImages")
    @State private var pasteWithoutFormatting = UserDefaults.standard.bool(forKey: "pasteWithoutFormatting")
    
    @State private var darkMode = UserDefaults.standard.bool(forKey: "darkMode")
    @State private var windowWidth = UserDefaults.standard.float(forKey: "windowWidth")
    @State private var windowHeight = UserDefaults.standard.float(forKey: "windowHeight")
    @State private var windowLocation = UserDefaults.standard.string(forKey: "windowLocation")
    @State private var windowPopOut = UserDefaults.standard.bool(forKey: "windowPopOut")
    @State private var onlyPopOutWindow = UserDefaults.standard.bool(forKey: "onlyPopOutWindow")
    @State private var canWindowFloat = UserDefaults.standard.bool(forKey: "canWindowFloat")
    @State private var hideWindowWhenNotSelected = UserDefaults.standard.bool(forKey: "hideWindowWhenNotSelected")
    @State private var windowOnAllDesktops = UserDefaults.standard.bool(forKey: "windowOnAllDesktops")

    @State var pasteWithoutFormattingShortcut: KeyboardShortcut = UserDefaultsManager.shared.pasteWithoutFormattingShortcut
    @State var toggleWindowShortcut: KeyboardShortcut = UserDefaultsManager.shared.toggleWindowShortcut
    @State var resetWindowShortcut: KeyboardShortcut = UserDefaultsManager.shared.resetWindowShortcut
    
    @State private var geoWidth: CGFloat = 0.0
    @State private var geoHeight: CGFloat = 0.0
    
    @State private var saved: Bool = false

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
                            .foregroundColor(Color(.darkGray))
                            .cornerRadius(8)
                        Rectangle()
                            .foregroundColor(Color(.darkGray))
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
                .position(x: 90/2, y: -(self.geoHeight/2 + 22))
                .frame(width: 90, height: 24)
                .zIndex(5)
                
                
                Color.white.opacity(0.1).flash(duration: 0.3)
            }
            VStack {
                ScrollView {
                    Form {
                        VStack {
                            VStack {
                                Spacer()
                                Text("Paste Without Formatting Shortcut: ")
                                
                                Spacer()
                                
                                CustomShortcutView(shortcut: $pasteWithoutFormattingShortcut)
                                
                            }.padding()
                            
                            VStack {
                                Spacer()
                                Text("Toggle Show/Hide Window Shortcut: ")
                                
                                Spacer()
                                
                                CustomShortcutView(shortcut: $toggleWindowShortcut)
                                
                            }.padding()
                            
                            VStack {
                                Spacer()
                                Text("Reset Window Shortcut: ")
                                
                                Spacer()
                                
                                CustomShortcutView(shortcut: $resetWindowShortcut)
                                
                            }.padding()
                            
                            
                        }
                    }
                }
                Spacer()
                Button("Save") {
                    if pasteWithoutFormatting {
                        print("enabling")
                        KeyboardShortcuts.onKeyUp(for: .pasteNoFormatting) {
                            ClipboardManager.shared.pasteNoFormatting()
                        }
                    }
                    else if !pasteWithoutFormatting {
                        print("disabling")
                        KeyboardShortcuts.disable(.pasteNoFormatting)
                    }
                    
                    userDefaultsManager.pasteWithoutFormattingShortcut = pasteWithoutFormattingShortcut
                    userDefaultsManager.toggleWindowShortcut = toggleWindowShortcut
                    userDefaultsManager.resetWindowShortcut = resetWindowShortcut
                    
                    UserDefaultsManager.shared.updateAll(saveShortcuts: true)
                    
                    MenuManager.shared.updateMainMenu(isCopyingPaused: pauseCopying)
                    
                    DispatchQueue.main.async {
                        self.saved = true
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: self.saved) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.saved = false
                }
            }
        }
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
            Text(selectedItem ?? "None")
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
