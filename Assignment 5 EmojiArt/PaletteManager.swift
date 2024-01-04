//
//  PaletteManager.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 1/3/24.
//

import SwiftUI

#if os(iOS)
struct PaletteManager: View {
    
    @EnvironmentObject var store: PaletteStore
    // fetch environment variable such as color scheme
    @Environment(\.presentationMode) var presentationMode
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        
        //NavigationView to navigate through the app
        NavigationView {
            List {
                ForEach(store.palettes) { palette in
                    NavigationLink(destination: PaletteEditor(palette: $store.palettes[palette])) {
                        VStack (alignment: .leading) {
                            // if editing make titles bigger
                            Text(palette.name)
                            Text(palette.emojis)
                        }
                        // gesture for edit mode, otherwise inactive
                        .gesture(editMode == .active ? tap : nil)
                    }
                }
                .onDelete { indexSet in
                    store.palettes.remove(atOffsets: indexSet)
                }
                .onMove { indexSet, newOffset in
                    store.palettes.move(fromOffsets: indexSet, toOffset: newOffset)
                }
            }
            .navigationTitle("Manage Palettes")
            // switch title to smaller one within the view
            .navigationBarTitleDisplayMode(.inline)
            // dismiss button
            .dismissable { presentationMode.wrappedValue.dismiss() }
            // edit button
            .toolbar {
                // determine whether toolbar is presented to the user
                ToolbarItem { EditButton() }
            }
            // use environment to control whether the view is in edit mode
            .environment(\.editMode, $editMode)
        }
    }
    
    var tap: some Gesture {
        TapGesture().onEnded {
            print("tap")
        }
    }
}
#endif
