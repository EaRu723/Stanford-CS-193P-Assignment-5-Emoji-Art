//
//  PaletteStore.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 12/29/23.
//

import SwiftUI

// Extension on UserDefaults to handle saving and retrieving Palette objects.
extension UserDefaults {
    // Retrieve an array of Palette objects from UserDefaults.
    func palettes(forKey key: String) -> [Palette] {
        if let jsonData = data(forKey: key),
           let decodedPalettes = try? JSONDecoder().decode([Palette].self, from: jsonData) {
            return decodedPalettes
        } else {
            return []
        }
    }
    
    // Save an array of Palette objects to UserDefaults.
    func set(_ palettes: [Palette], forKey key: String) {
        let data = try? JSONEncoder().encode(palettes)
        set(data, forKey: key)
    }
}

// Class to manage a collection of Palette objects.
class PaletteStore: ObservableObject {
    let name: String // Name of the palette store.
    
    // Key for saving palettes in UserDefaults.
    private var userDefaultsKey: String { "PaletteStore:" + name }
    
    // Array of palettes managed by the store.
    var palettes: [Palette] {
        get {
            UserDefaults.standard.palettes(forKey: userDefaultsKey)
        }
        set {
            if !newValue.isEmpty {
                UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
                objectWillChange.send() // Notify observers about the change.
            }
        }
    }
    
    // Initializer for the PaletteStore.
    init(named name: String) {
        self.name = name
        if palettes.isEmpty {
            palettes = Palette.builtins // Use built-in palettes if none are stored.
            if palettes.isEmpty {
                palettes = [Palette(name: "Warning", emojis: "⚠️")] // Default warning palette.
            }
        }
    }
    
    // Published property to track the index of the currently selected palette.
    @Published private var _cursorIndex = 0
    
    // Public getter and setter for cursorIndex, ensuring the index stays within bounds.
    var cursorIndex: Int {
        get { boundsCheckedPaletteIndex(_cursorIndex) }
        set { _cursorIndex = boundsCheckedPaletteIndex(newValue) }
    }
    
    // Method to ensure the index is within the bounds of the palettes array.
    private func boundsCheckedPaletteIndex(_ index: Int) -> Int {
        var index = index % palettes.count
        if index < 0 {
            index += palettes.count
        }
        return index
    }
    
    // MARK: - Adding Palettes
    // Methods to add palettes to the store, avoiding duplication.
    
    func insert(_ palette: Palette, at insertionIndex: Int? = nil) {
        let insertionIndex = boundsCheckedPaletteIndex(insertionIndex ?? cursorIndex)
        if let index = palettes.firstIndex(where: { $0.id == palette.id }) {
            palettes.move(fromOffsets: IndexSet([index]), toOffset: insertionIndex)
            palettes.replaceSubrange(insertionIndex...insertionIndex, with: [palette])
        } else {
            palettes.insert(palette, at: insertionIndex)
        }
    }
    
    // Convenience method to insert a palette by name and emojis.
    func insert(name: String, emojis: String, at index: Int? = nil) {
        insert(Palette(name: name, emojis: emojis), at: index)
    }
    
    // Method to append a palette to the end of the palettes array.
    func append(_ palette: Palette) {
        if let index = palettes.firstIndex(where: { $0.id == palette.id }) {
            if palettes.count == 1 {
                palettes = [palette]
            } else {
                palettes.remove(at: index)
                palettes.append(palette)
            }
        } else {
            palettes.append(palette)
        }
    }
    
    // Convenience method to append a palette by name and emojis.
    func append(name: String, emojis: String) {
        append(Palette(name: name, emojis: emojis))
    }
}
