//
//  EmojiArtDocumentView.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 12/29/23.
//
//

import SwiftUI

// SwiftUI view representing the main UI of the Emoji Art app.
struct EmojiArtDocumentView: View {
    typealias Emoji = EmojiArt.Emoji // Type alias for Emoji.

    @ObservedObject var document: EmojiArtDocument // ViewModel for the Emoji Art document.

    // Constant for the size of emoji in the palette.
    private let paletteEmojiSize: CGFloat = 40

    // The body of the view.
    var body: some View {
        VStack(spacing: 0) {
            documentBody // Main content of the document.
            PaletteChooser() // Palette for choosing emojis.
                .font(.system(size: paletteEmojiSize))
                .padding(.horizontal)
                .scrollIndicators(.hidden)
        }
    }
    
    // View representing the main content of the document.
    private var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white // Background color.
                documentContents(in: geometry) // Contents of the document.
                    .scaleEffect(zoom * gestureZoom) // Apply zoom scale.
                    .offset(pan + gesturePan) // Apply pan offset.
            }
            .gesture(panGesture.simultaneously(with: zoomGesture)) // Gestures for pan and zoom.
            .dropDestination(for: Sturldata.self) { sturldatas, location in
                return drop(sturldatas, at: location, in: geometry) // Drop handling for adding items.
            }
        }
    }
    
    // Builder to create the contents of the document.
    @ViewBuilder
    private func documentContents(in geometry: GeometryProxy) -> some View {
        AsyncImage(url: document.background) { phase in
            if let image = phase.image { // Display image if loaded.
                image
            } else if let url = document.background { // Handle loading state and errors.
                if phase.error != nil {
                    Text("\(url)")
                } else {
                    ProgressView()
                }
            }
        }
            .position(Emoji.Position.zero.in(geometry)) // Position of the background image.
        ForEach(document.emojis) { emoji in // Iterate over emojis in the document.
            Text(emoji.string) // Display emoji text.
                .font(emoji.font) // Apply font size.
                .position(emoji.position.in(geometry)) // Position the emoji.
        }
    }

    // State variables for zoom and pan gestures.
    @State private var zoom: CGFloat = 1
    @State private var pan: CGOffset = .zero
    
    // Gesture state for dynamic changes in zoom and pan.
    @GestureState private var gestureZoom: CGFloat = 1
    @GestureState private var gesturePan: CGOffset = .zero
    
    // Gesture definition for zooming.
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoom) { inMotionPinchScale, gestureZoom, _ in
                gestureZoom = inMotionPinchScale
            }
            .onEnded { endingPinchScale in
                zoom *= endingPinchScale
            }
    }
    
    // Gesture definition for panning.
    private var panGesture: some Gesture {
        DragGesture()
            .updating($gesturePan) { inMotionDragGestureValue, gesturePan, _ in
                gesturePan = inMotionDragGestureValue.translation
            }
            .onEnded { endingDragGestureValue in
                pan += endingDragGestureValue.translation
            }
    }
    
    // Function to handle dropping URLs and strings onto the canvas.
    private func drop(_ sturldatas: [Sturldata], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        for sturldata in sturldatas {
            switch sturldata {
            case .url(let url):
                document.setBackground(url)
                return true
            case .string(let emoji):
                document.addEmoji(
                    emoji,
                    at: emojiPosition(at: location, in: geometry),
                    size: paletteEmojiSize / zoom
                )
                return true
            default:
                break
            }
        }
        return false
    }
    
    // Calculate the position of the emoji on the canvas based on the drop location.
    private func emojiPosition(at location: CGPoint, in geometry: GeometryProxy) -> Emoji.Position {
        let center = geometry.frame(in: .local).center
        return Emoji.Position(
            x: Int((location.x - center.x - pan.width) / zoom),
            y: Int(-(location.y - center.y - pan.height) / zoom)
        )
    }
}

//#Preview {
//    EmojiArtDocumentView(document: <#EmojiArtDocument#>)
//}
