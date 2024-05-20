//
//  backupContentView.swift
//  ClipboardHistory
//
//  Created by Alex Brodsky on 5/19/24.
//

//Backups of ContentView

//struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//
//    @FetchRequest(
//        entity: ClipboardItem.entity(),
//        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
//        animation: .default)
//    private var clipboardItems: FetchedResults<ClipboardItem>
//
//    @State private var showingClearAlert = false
//
//    var body: some View {
//        VStack {
//            VStack {
//                ScrollViewReader { scrollProxy in
//                    List {
//                        ForEach(clipboardItems, id: \.self) { item in
//                            ClipboardItemView(item: item)
//                                .id(item.objectID)
//                        }
//                    }
//                }
//                Spacer()
//            }
//            Button("Clear All") {
//                showingClearAlert = true
//            }
//            .buttonStyle(BorderlessButtonStyle())
//            .padding()
//            .alert(isPresented: $showingClearAlert) {
//                Alert(
//                    title: Text("Confirm Clear"),
//                    message: Text("Are you sure you want to clear all clipboard items?"),
//                    primaryButton: .destructive(Text("Clear")) {
//                        clearClipboardItems()
//                    },
//                    secondaryButton: .cancel()
//                )
//            }
//        }
//    }
//
//    private func clearClipboardItems() {
//        for item in clipboardItems {
//            viewContext.delete(item)
//        }
//        do {
//            try viewContext.save()
//        } catch {
//            print("Error saving managed object context: \(error)")
//        }
//    }
//}



//struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//
//    @FetchRequest(
//        entity: ClipboardItem.entity(),
//        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
//        animation: .default)
//    private var clipboardItems: FetchedResults<ClipboardItem>
//
//    @State private var lastItemID: NSManagedObjectID?
//    @State private var showingClearAlert = false
//
//    var body: some View {
//        VStack {
//            ScrollViewReader { scrollProxy in
//                ScrollView {
//                    VStack(alignment: .leading) {
//                        ForEach(clipboardItems, id: \.self) { item in
//                            ClipboardItemView(item: item)
//                                .id(item.objectID)
//                                .padding(.leading, 10) // Adds padding on the left
//                        }
//                    }
//                    .onAppear {
//                        lastItemID = clipboardItems.first?.objectID
//                    }
//                }
//            }
//            Spacer()
//            Button("Clear All") {
//                showingClearAlert = true
//            }
//            .buttonStyle(BorderlessButtonStyle())
//            .padding()
//            .alert(isPresented: $showingClearAlert) {
//                Alert(
//                    title: Text("Confirm Clear"),
//                    message: Text("Are you sure you want to clear all clipboard items?"),
//                    primaryButton: .destructive(Text("Clear")) {
//                        clearClipboardItems()
//                    },
//                    secondaryButton: .cancel()
//                )
//            }
//        }
//    }
//
//    private func clearClipboardItems() {
//        for item in clipboardItems {
//            viewContext.delete(item)
//        }
//        do {
//            try viewContext.save()
//        } catch {
//            print("Error saving managed object context: \(error)")
//        }
//    }
//}

// NO ANIMATIONS
//struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//
//    @FetchRequest(
//        entity: ClipboardItem.entity(),
//        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
//        animation: nil)
//    private var clipboardItems: FetchedResults<ClipboardItem>
//
//    @State private var scrolledID: NSManagedObjectID?
//    @State private var showingClearAlert = false
//
//    var body: some View {
//        VStack {
//            ScrollView {
//                LazyVStack {
//                    ForEach(clipboardItems, id: \.self) { item in
//                        ClipboardItemView(item: item)
//                            .id(item.objectID)
//                            .padding(.leading, 10)
//                    }
//                }
//                .scrollTargetLayout()
//            }
//            .scrollPosition(id: $scrolledID)
//            Spacer()
//            Button("Clear All") {
//
//                showingClearAlert = true
//            }
//            .buttonStyle(BorderlessButtonStyle())
//            .padding()
//            .alert(isPresented: $showingClearAlert) {
//                Alert(
//                    title: Text("Confirm Clear"),
//                    message: Text("Are you sure you want to clear all clipboard items?"),
//                    primaryButton: .destructive(Text("Clear")) {
//                        clearClipboardItems()
//                    },
//                    secondaryButton: .cancel()
//                )
//            }
//        }
//    }
//
//    private func clearClipboardItems() {
//        for item in clipboardItems {
//            viewContext.delete(item)
//        }
//        do {
//            try viewContext.save()
//        } catch {
//            print("Error saving managed object context: \(error)")
//        }
//    }
//}

//WORKING!!! but cant use clipboardItems.count anymore since I am trying to limit to 30 items

//struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    @FetchRequest(
//        entity: ClipboardItem.entity(),
//        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
//        animation: nil)
//    private var clipboardItems: FetchedResults<ClipboardItem>
//
//    @State private var showingClearAlert = false
//    @State private var atTopOfList = true
//
//    var body: some View {
//        VStack {
//            ScrollView {
//                // Tracking scroll position directly within the GeometryReader
//                GeometryReader { geometry in
//                    Color.clear.onChange(of: geometry.frame(in: .named("ScrollViewArea")).minY) { oldValue, newValue in
//                        atTopOfList = newValue >= 0
////                        print(atTopOfList)
//                    }
//                }
//                .frame(height: 0)
//
//                LazyVStack {
//                    ForEach(clipboardItems, id: \.self) { item in
//                        ClipboardItemView(item: item)
//                            .id(item.objectID)
//                            .padding(.leading, 10)
//                    }
//                }
//                .animation(atTopOfList ? .default : nil, value: clipboardItems.count)
//            }
//            .coordinateSpace(name: "ScrollViewArea")
//            Spacer()
//            Button("Clear All") {
//                showingClearAlert = true
//            }
//            .buttonStyle(BorderlessButtonStyle())
//            .padding()
//            .alert(isPresented: $showingClearAlert) {
//                Alert(
//                    title: Text("Confirm Clear"),
//                    message: Text("Are you sure you want to clear all clipboard items?"),
//                    primaryButton: .destructive(Text("Clear")) {
//                        clearClipboardItems()
//                    },
//                    secondaryButton: .cancel()
//                )
//            }
//        }
//    }
//
//    private func clearClipboardItems() {
//        for item in clipboardItems {
//            viewContext.delete(item)
//        }
//        do {
//            try viewContext.save()
//        } catch let error {
//            print("Error saving managed object context: \(error)")
//        }
//    }
//}


//FINAL
//struct ContentView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    @FetchRequest(
//        entity: ClipboardItem.entity(),
//        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)],
//        animation: nil)
//    private var clipboardItems: FetchedResults<ClipboardItem>
//
//    @State private var showingClearAlert = false
//    @State private var atTopOfList = true
//    @State private var topItemID: NSManagedObjectID? = nil  // Track the ID of the first item
//    
//    var body: some View {
//        VStack {
//            ScrollView {
//                GeometryReader { geometry in
//                    Color.clear.onChange(of: geometry.frame(in: .named("ScrollViewArea")).minY) { oldValue, newValue in
//                        atTopOfList = newValue >= 0
////                        print(atTopOfList)
//                    }
//                }
//                .frame(height: 0)
//
//                LazyVStack {
//                    ForEach(clipboardItems, id: \.self) { item in
//                        ClipboardItemView(item: item)
//                            .id(item.objectID)
//                            .padding(.leading, 10)
//                            .animation(atTopOfList ? .default : nil, value: clipboardItems.first?.objectID)
//
//                    }
//                }
//            }
//            .coordinateSpace(name: "ScrollViewArea")
//            Spacer()
//            Button("Clear All") {
//                showingClearAlert = true
//            }
//            .buttonStyle(BorderlessButtonStyle())
//            .padding()
//            .alert(isPresented: $showingClearAlert) {
//                Alert(
//                    title: Text("Confirm Clear"),
//                    message: Text("Are you sure you want to clear all clipboard items?"),
//                    primaryButton: .destructive(Text("Clear")) {
//                        clearClipboardItems()
//                    },
//                    secondaryButton: .cancel()
//                )
//            }
//        }
//    }
//
//    private func clearClipboardItems() {
//        for item in clipboardItems {
//            viewContext.delete(item)
//        }
//        do {
//            try viewContext.save()
//        } catch let error {
//            print("Error saving managed object context: \(error)")
//        }
//    }
//}
