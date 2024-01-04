//
//  PaletteChooser.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 12/29/23.
//

import SwiftUI

// SwiftUI view for choosing and managing emoji palettes.
struct PaletteChooser: View {
    
    var emojiFontSize: CGFloat = 40
    var emojiFont: Font { .system(size: emojiFontSize)}
    
    @EnvironmentObject var store: PaletteStore
    
    // saves palette information if app is killed
    @SceneStorage("PaletteChooser.chosenPaletteIndex") private var chosenPaletteIndex = 0
    
    // The body of the PaletteChooser view.
    var body: some View {
        HStack {
            paletteControlButton // A subview for choosing palettes.
            body(for: store.palette(at: chosenPaletteIndex))
        }
        .clipped() // Clips the view to its bounding frame.
    }
    
    // Subview for palette selection and context menu actions.
    private var paletteControlButton: some View {
        Button {
            withAnimation {
                chosenPaletteIndex = (chosenPaletteIndex + 1) % store.palettes.count
            }
        } label: {
            Image(systemName: "paintpalette")
        }
        .font(emojiFont)
        .paletteControlButtonStyle()
        .contextMenu { contextMenu }
    }
    
    @ViewBuilder
    var contextMenu: some View {
        AnimatedActionButton(title: "Edit", systemImage: "pencil") {
            paletteToEdit = store.palette(at: chosenPaletteIndex)
        }
        AnimatedActionButton(title: "New", systemImage: "plus") {
            store.insertPalette(named: "New", emojis: "", at: chosenPaletteIndex)
            paletteToEdit = store.palette(at: chosenPaletteIndex)
        }
        AnimatedActionButton(title: "Delete", systemImage: "minus.circle") {
            chosenPaletteIndex = store.removePalette(at: chosenPaletteIndex)
        }
        
        #if os(iOS)
        AnimatedActionButton(title: "Manager", systemImage: "slider.vertical.3") {
            managing = true
        }
        #endif
        
        gotoMenu
    }
    
    var gotoMenu: some View {
        Menu {
            ForEach (store.palettes) { palette in
                AnimatedActionButton(title: palette.name) {
                    if let index = store.palettes.index(matching: palette) {
                                            chosenPaletteIndex = index
                    }
                }
            }
        } label: {
            Label("Go To", systemImage: "text.insert")
        }
    }
    
    // Function to create a view for a given palette.
    func body(for palette: Palette) -> some View {
            HStack {
                Text(palette.name)
                ScrollingEmojis(emojis: palette.emojis)
                    .font(emojiFont)
            }
            //adding id to make the view identifiable, if it changes, the whole HStack changes, which allows for transition to work on an entire stack and not just the emojis
            .id(palette.id)
            .transition(rollTransition)
            //.sheet is for a new blank view over the view, .popover is the same but smaller and with arrow pointing at origin. The other option is using nil or object method instead of false/true
            .popover(item: $paletteToEdit) { palette in
                PaletteEditor(palette: $store.palettes[palette])
                //on mac add padding
                    .popoverPadding()
                    .wrappedInNavigationViewToMakeDismissable { paletteToEdit = nil }
            }
            .sheet(isPresented: $managing) {
                PaletteManager()
            }
    }
    
    
    @State private var managing = false
    @State private var paletteToEdit: Palette?
    
    var rollTransition: AnyTransition {
        AnyTransition.asymmetric(insertion: .offset(x: 0, y: emojiFontSize), removal: .offset(x: 0, y: -emojiFontSize))
    }
    
}

struct ScrollingEmojis: View {
    
    let emojis: String
    
    // The body of the ScrollingEmojis view.
    var body: some View {
        
        ScrollView(.horizontal) { // A horizontal scroll view.
            HStack {
                ForEach(emojis.removingDuplicateCharacters.map {String($0)}, id: \.self ) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString)}
                }
            }
        }
    }
    
}

#Preview {
    PaletteChooser()
}
