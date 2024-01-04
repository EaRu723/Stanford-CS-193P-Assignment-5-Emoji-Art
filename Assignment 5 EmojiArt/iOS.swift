//
//  iOS.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 1/3/24.
//

import SwiftUI

#if os(iOS)

extension UIImage {
    var imageData: Data? { jpegData(compressionQuality: 1.0) }
}

struct PasteBoard {
    static var imageData: Data? {
        UIPasteboard.general.image?.imageData
    }
    static var imageURL: URL? {
        UIPasteboard.general.url?.imageURL
    }
}

extension View {
    
    func paletteControlButtonStyle() -> some View {
        self
    }
    
    func popoverPadding() -> some View {
        self
    }
    
    @ViewBuilder
    func wrappedInNavigationViewToMakeDismissable (_ dismiss: (() -> Void )?) -> some View {
        // when device isn't ipad return self in Navigation View
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
            NavigationView {
                
                self
                    .navigationBarTitleDisplayMode(.inline)
                    .dismissable(dismiss)
            }
            // stacks views on top of eachother
            .navigationViewStyle(StackNavigationViewStyle())
        } else {
            self
        }
    }
    
    // function for button
    @ViewBuilder
    func dismissable (_ dismiss: (() -> Void)?) -> some View {
        
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss {
            self.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        } else {
            self
        }
    }
}


#endif
