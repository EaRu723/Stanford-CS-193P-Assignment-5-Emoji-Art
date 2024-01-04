//
//  Assignment_5_EmojiArtApp.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 12/29/23.
//

import SwiftUI

@main
struct Emoji_ArtApp: App {
    @StateObject var paletteStore = PaletteStore(named: "Default")
    
    var body: some Scene {
            
            DocumentGroup(newDocument: {EmojiArtDocument()} ) { config in /*config has viewModel we want to use and url to file*/
                EmojiArtDocumentView(document: config.document)
                    .environmentObject(paletteStore)
                //fixes double back buttons
                    .toolbarRole(.automatic)
            }
            
        }
        
    }
