//
//  PaletteEditor.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 1/3/24.
//

import SwiftUI

struct PaletteEditor: View {
    
    //binding allows for editing the palette that's calling it, binding looks for where the memory is stored, it never actually equates to anything
    @Binding var palette: Palette
    
    var body: some View {
        //form for forms
        Form {
            
            nameSection
            addEmojisSection
            removeEmojisSection
            
        }
        .navigationTitle("edit \(palette.name)")
        .frame(minWidth: 300, minHeight: 350)
    }
    
    var nameSection: some View {
        Section(header: Text("Name")) {
            // text field allows for direct input and changes
            TextField("", text: $palette.name)
        }
    }
    
    @State private var emojisToAdd = ""
    
    var addEmojisSection: some View {
        Section(header: Text("Add Emojis")) {
            TextField("", text: $emojisToAdd)
                .onChange(of: emojisToAdd) { emojis in
                    addEmojis(emojis)
                }
        }
    }
    
    func addEmojis(_ emojis: String) {
        withAnimation {
            palette.emojis = (emojis + palette.emojis)
                .filter { $0.isEmoji }
                .removingDuplicateCharacters
        }
    }
    
    var removeEmojisSection: some View {
        Section(header: Text("Remove Emoji")) {
            let emojis = palette.emojis.removingDuplicateCharacters.map { String($0) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                ForEach(emojis, id: \.self) { emoji in
                Text(emoji)
                        .onTapGesture {
                            withAnimation {
                                palette.emojis.removeAll(where: {String($0) == emoji })
                            }
                        }
                }
            }
        }
    }
}

//#Preview {
//    PaletteEditor(palette: .constant(PaletteStore(named: "Preview").palette(at: 0)))
//}
