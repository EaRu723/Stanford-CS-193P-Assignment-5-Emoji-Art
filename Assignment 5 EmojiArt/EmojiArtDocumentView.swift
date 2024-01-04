//
//  EmojiArtDocumentView.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 12/29/23.
//

import SwiftUI

// SwiftUI view representing the main UI of the Emoji Art app.
struct EmojiArtDocumentView: View {
    // ViewModel for the Emoji Art document.
    @ObservedObject var document: EmojiArtDocument
    // Get the undoManager from the environment in the view
    @Environment(\.undoManager) var undoManager
    // Scaled metric allows for size adjustment for accessibility features]
    @ScaledMetric var defaultEmojiFontSize: CGFloat = 40
    
    // The body of the view.
    var body: some View {
        VStack(spacing: 0) {
            documentBody // Main content of the document.
            PaletteChooser(emojiFontSize: defaultEmojiFontSize)
        }
    }
    
    // View representing the main content of the document.
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white // Background color.
                OptionalImage(uiImage: document.backgroundImage)
                    .scaleEffect(zoomScale) // Apply zoom scale.
                    .position(convertFromEmojiCoordinates((0,0), in: geometry))
                    .gesture(doubleTapToZoom(in: geometry.size).exclusively(before: deselectEmojiGesture()))
                // conditional if to display spinning wheel as document loads background image
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView()
                        .scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .font(.system(size: fontSize(for: emoji)))
                            .border(emojiIsChosen(emoji) ? .black : .clear)
                            .scaleEffect(zoomScale)
                            .position(position(for: emoji, in: geometry))
                            .gesture(chooseEmojiGesture(emoji).simultaneously(with: panEmojiGesture(emoji)))
                    }
                }
            }
            // doesn't allow the background to extend beyond the containers
            .clipped()
            // we only drop the plain text
            .onDrop(of: [.utf8PlainText, .url, .image], isTargeted: nil) { providers, location in
                return drop(providers: providers, at: location, in: geometry)
            }
            .gesture( setOfChosenEmojis.count > 0 ? emojiZoomGesture() : nil )
            .gesture( setOfChosenEmojis.count == 0 ? panGesture().simultaneously(with: zoomGesture()) : nil )
            
            .alert(item: $alertToShow) { alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchStatus) { status in
                switch status {
                case .failed(let url):
                    showBackgroundImageFetchFailedAlert(url)
                default:
                    break
                }
                
            }
            // zoom in or out to fit image to screen when an object is received
            .onReceive(document.$backgroundImage) { image in
                if autozoom {
                    zoomToFit(image, in: geometry.size)
                }
            }
            .compactableToolbar {
                AnimatedActionButton(title: "Paste Background", systemImage: "doc.on.clipboard") {
                    pasteBackground()
                }
                if Camera.isAvailable {
                    AnimatedActionButton(title: "Take Photo", systemImage: "camera") {
                        backgroundPicker = .camera
                    }
                }
                if PhotoLibrary.isAvailable {
                    AnimatedActionButton(title: "Search Photos", systemImage: "photo") {
                        backgroundPicker = .library
                    }
                }
                if setOfChosenEmojis.count > 0 {
                    removeEmojiIcon
                }
#if os(iOS)
                if let undoManager = undoManager {
                    if undoManager.canUndo {
                        AnimatedActionButton(title: undoManager.undoActionName, systemImage: "arrow.uturn.backward") {
                            undoManager.undo()
                        }
                    }
                    if undoManager.canRedo {
                        AnimatedActionButton(title: undoManager.redoActionName, systemImage: "arrow.ututrn.forward") {
                            undoManager.redo()
                        }
                    }
                }
#endif
            }
            // pull up the camera view
            .sheet(item: $backgroundPicker) { pickerType in
                switch pickerType {
                case .camera: Camera(handlePickedImage: { image in handlePickedBackgroundimage(image) })
                case .library: PhotoLibrary(handlePickedImage: {image in handlePickedBackgroundimage(image) })
                }
            }
        }
    }
    
    //MARK: - Camera
    
    private func handlePickedBackgroundimage(_ image: UIImage?) {
        autozoom = true
        
        if let imageData = image?.imageData {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        }
        
        // get rid of camera view
        backgroundPicker = nil
    }
    
    @State private var backgroundPicker: BackgroundPickerType?
    
    enum BackgroundPickerType: Identifiable {
        case camera
        case library
        var id: BackgroundPickerType { self }
    }
    
    // MARK: - Paste Background
    
    private func pasteBackground() {
            autozoom = true
            if let imageData = PasteBoard.imageData {
                document.setBackground(.imageData(imageData), undoManager: undoManager)
            } else if let url = PasteBoard.imageURL {
                document.setBackground(.url(url), undoManager: undoManager)
            } else {
                alertToShow = IdentifiableAlert(
                    title: "Paste Background",
                    message: "There is no image currently on the pasteboard."
                )
            }
        }
    
    //MARK: - Autozoom
    
    @State private var autozoom = false
    
    @State private var alertToShow: IdentifiableAlert?
    
    private func showBackgroundImageFetchFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(id: "fetch failed: " + url.absoluteString, alert: {
            Alert(
                title: Text("Background Image Fetch"),
                message: Text("Couldn't load image from \(url)."),
                dismissButton: .default(Text("ok"))
            )
        })
    }
    
    // MARK: - Remove
    
    var removeEmojiIcon: some View {
        AnimatedActionButton(title: "Remove Emoji", systemImage: "trash") {
            setOfChosenEmojis.forEach { emoji in
                setOfChosenEmojis.remove(emoji)
                document.removeEmoji(emoji)
            }
        }
    }
    
    // MARK: - Drag and Drop
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        
        // see if dropped object is a url
        var found = providers.loadObjects(ofType: URL.self) { url in
            
            //turns autozoom on to fit the canvas to picture borders
            autozoom = true
            //imageURL is an extension that makes sure that link is an image, cause sometimes its a double url, that contains the owner site and then the path of the image. ImageURL in utility extensions
            document.setBackground(EmojiArt.Background.url(url.imageURL), undoManager: undoManager)
        }
        
        //If not found and url then try this code, look for an image, and then for a string
        // macOS NSImage does not have an NSItemProvider
#if os(iOS)
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    autozoom = true
                    document.setBackground(.imageData(data), undoManager: undoManager)
                }
            }
        }
#endif
        
        if !found {
            // check if the providers have a string. this function is in extensions in utility extensions and operates using objective c asynchronously
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(String(emoji), at: convertToEmojiCoordinates(location, in: geometry), size: defaultEmojiFontSize / zoomScale, undoManager: undoManager )
                }
            }
        }
        
        return found
    }
    
    //MARK: - Positioning/Sizing Emoji
    
    private func position(for emoji:EmojiArt.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        
        let center = geometry.frame(in: .local).center
        
        let location = CGPoint(
            // tracks if picture was fragged or zommed with panOffset and zoomScale
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return(Int(location.x), Int(location.y))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        
        // get the geometric center
        let center = geometry.frame(in: .local).center
        
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    private func fontSize(for emoji: EmojiArt.Emoji) -> CGFloat {
        CGFloat(emoji.size) * (emojiIsChosen(emoji) ? emojiZoomScale : 1)
    }
    
    // MARK: - Selecting and de-selecting emoji
    
    @State private var setOfChosenEmojis: Set<EmojiArt.Emoji> = []
    
    private func chooseEmojiGesture (_ emoji: EmojiArt.Emoji) -> some Gesture {
        TapGesture()
            .onEnded{
                setOfChosenEmojis.toggleMembership(of: emoji)
            }
    }
    
    private func emojiIsChosen(_ emoji: EmojiArt.Emoji) -> Bool {
        setOfChosenEmojis.contains(where: {$0.id == emoji.id})
    }
    
    private func deselectEmojiGesture() -> some Gesture {
        TapGesture()
            .onEnded {
                setOfChosenEmojis.removeAll()
            }
    }
    
    //MARK: Panning emojis
    
    @GestureState private var gesturePanEmojiOffset: CGSize = CGSize.zero
    
    private func panEmojiGesture(_ emoji: EmojiArt.Emoji) -> some Gesture {
        DragGesture()
            .updating($gesturePanEmojiOffset) { latestDragGestureValue, gesturePanEmojiOffset, _ in
                
                moveChosenEmojis(by: latestDragGestureValue.translation / zoomScale - gesturePanEmojiOffset, emoji)
                gesturePanEmojiOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                moveChosenEmojis(by: (gesturePanEmojiOffset / zoomScale), emoji)
            }
    }
    
    private func moveChosenEmojis(by offset: CGSize, _ emoji: EmojiArt.Emoji) {
        
        if setOfChosenEmojis.first(where: {$0.id == emoji.id}) != nil {
            setOfChosenEmojis.forEach { emoji in
                document.moveEmoji(emoji, by: offset, undoManager: undoManager)
            }
        } else {
            document.moveEmoji(document.emojis.first(where: {$0.id == emoji.id})!, by: offset, undoManager: undoManager)
        }
    }
    
    // MARK: - Panning
    
    // when not panning the var is equal tozero
    @SceneStorage("EmojiArtDocumentView.steadyStatePanOffset") private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        // you cannot add sizes by default, therefore there is an extension in utility extensions to handle adding. zoomScale adds additional dimention if we are already zoomed in
        ( steadyStatePanOffset + gesturePanOffset ) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ /*(transaction)*/ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                //translation is a special function that can be called on the argument to the closure in this partricular case that returns the distance the finger followed from the start position. Next we are /dividing that by scale we are zoomed in and adding it to already set orientation on the screen
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    // MARK: - Emoji Zoom
    
    @GestureState private var gestureEmojiZoomScale: CGFloat = 1
    
    private var emojiZoomScale: CGFloat {
        gestureEmojiZoomScale
    }
    
    private func emojiZoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureEmojiZoomScale) { latestGestureScale, gestureEmojiZoomScale, _ in gestureEmojiZoomScale = latestGestureScale}
            .onEnded { gestureScaleAtEnd in
                scaleChosenEmoji(by: gestureScaleAtEnd)
            }
    }
    
    private func scaleChosenEmoji(by scale: CGFloat) {
        setOfChosenEmojis.forEach { emoji in
            document.scaleEmoji(emoji, by: scale, undoManager: undoManager)
        }
    }
    
    //MARK: - Zoom
    
    // contemporary state sets the scale of the background image to 1 by default
    @SceneStorage("EmojiArtdocumentView.steadyStateZoomScale") private var steadyStateZoomScale: CGFloat = 1
    // gesture state which changes as you pinch
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        //zoom scale changes as pinch gesture changes, by default 1* 1 =1
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        // for pinching
        MagnificationGesture()
        //$gesturezoomscale is what we track during the gesture. latestGestureScale is the latest value telling how far are fingers apart(constantly updating), gestureZoomScale(ourGestureStateInOut) updates the @GestureState gestureZoomScale
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in gestureZoomScale = latestGestureScale
            }
        //gestureScaleAtEnd is a special argument to this function, which tells how far are the fingers comapred to the beginning of the gesture
            .onEnded{ gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
            }
    }
    
    private func doubleTapToZoom (in size: CGSize) -> some Gesture {
        // double tap
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            // get the size difference between image and container size
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            // if dragged before, double tapping sets panOffset back to zero
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
}
//#Preview {
//    EmojiArtDocumentView(document: <#EmojiArtDocument#>)
//}
