//
//  PaletteChooser.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 12/29/23.
//

import SwiftUI

// SwiftUI view for choosing and managing emoji palettes.
struct PaletteChooser: View {
    @EnvironmentObject var store: PaletteStore // Access to the shared PaletteStore environment object.
    
    // The body of the PaletteChooser view.
    var body: some View {
        HStack {
            chooser // A subview for choosing palettes.
            view(for: store.palettes[store.cursorIndex]) // Displays the currently selected palette.
        }
        .clipped() // Clips the view to its bounding frame.
    }
    
    // Subview for palette selection and context menu actions.
    private var chooser: some View {
        AnimatedActionButton(systemImage: "paintpalette") {
            store.cursorIndex += 1 // Change the cursor index to cycle through palettes.
        }
        .contextMenu { // Context menu for additional actions.
            AnimatedActionButton("New", systemImage: "plus") {
                store.insert(name: "Math", emojis: "+−×÷∝∞") // Action to insert a new palette.
            }
            AnimatedActionButton("Delete", systemImage: "minus.circle", role: .destructive) {
                store.palettes.remove(at: store.cursorIndex) // Action to delete the current palette.
            }
        }
    }
    
    // Function to create a view for a given palette.
    private func view(for palette: Palette) -> some View {
        HStack {
            Text(palette.name) // Displays the name of the palette.
            ScrollingEmojis(palette.emojis) // A scrolling view of the emojis in the palette.
        }
        .id(palette.id) // Assigns an ID to the view for identification.
        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top))) // Transition effects for the view.
    }
}


struct ScrollingEmojis: View {
    let emojis: [String] // Array of emoji strings.
    
    // Initializer converts a string of emojis into an array of unique emoji strings.
    init(_ emojis: String) {
        self.emojis = emojis.uniqued.map(String.init)
    }
    
    // The body of the ScrollingEmojis view.
    var body: some View {
        ScrollView(.horizontal) { // A horizontal scroll view.
            HStack {
                ForEach(emojis, id: \.self) { emoji in // Iterates over each emoji in the array.
                    Text(emoji) // Displays the emoji.
                        .draggable(emoji) // Makes the emoji draggable.
                }
            }
        }
    }
}

#Preview {
    PaletteChooser()
}
