//
//  EmojiArtDocument.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 12/29/23.
//
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

// Extending UTTypes (such as mp3, png) with our own file type
extension UTType {
    static let emojiart = UTType(exportedAs: "Andrea.developer.EmojiArt")
}

// Reference File Document - contains an observable object
class EmojiArtDocument: ReferenceFileDocument {
    
    //UTType requires importing UniformTypeIdentifiers
    static var readableContentTypes = [UTType.emojiart]
    static var writableContentTypes = [UTType.emojiart]
    
    // initialize the document, getting data through jason and fetching background image
    required init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            emojiArt = try EmojiArt(json: data)
            fetchBackgroundImageDataIfNecessary()
        } else {
            // throw an error that the file is corrupted
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    // Func to represent this document's data structure using json
    func snapshot(contentType: UTType) throws -> Data {
        try emojiArt.json()
    }
    
    // File with content that is wrapped by calling snapshot function to autosave
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
    }
    
    // MARK: - Model
    
    @Published private(set) var emojiArt: EmojiArt {
        // If something changed to the model (use didSet):
        didSet {
            // changes the background when we add a new one
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    
    init() {
        emojiArt = EmojiArt()
    }
    
    //MARK: - Get background image
    
    // functions to get background and emojis from model
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    var background: EmojiArt.Background { emojiArt.background }
    
    // var for background image - published to keep track of changes
    @Published var backgroundImage: UIImage?
    
    // Feedback for user as they drop in background image
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    enum BackgroundImageFetchStatus: Equatable {
        case idle
        case fetching
        case failed(URL)
    }
    
    private var backgroundImageFetchCancellable: AnyCancellable?
    
    private func fetchBackgroundImageDataIfNecessary() {
            backgroundImage = nil
            switch emojiArt.background {
                
            case .url(let url):
                
                // change the information status to fetching
                backgroundImageFetchStatus = .fetching
                
                //cancel any other fetches
                backgroundImageFetchCancellable?.cancel()
                
                //URLSession.shared looks up something in the internet and lets you know when it returns data
                let session = URLSession.shared
                //map the data that is returned in the tuple and return an UIImage
                let publisher = session.dataTaskPublisher(for: url)
                    .map { (data, URLResponse) in UIImage(data: data) }
                    //dont report an error, convert it to nil
                    .replaceError(with: nil)
                //return the picture to the main queue
                    .receive(on: DispatchQueue.main)
                
                //apply the image to background image. It will hold onto backgroundImageFetchCancellable as long as it needs
                backgroundImageFetchCancellable = publisher
                    
                    .sink { [weak self] image in
                        self?.backgroundImage = image
                        //update the fetching status
                        self?.backgroundImageFetchStatus = (image != nil ) ? .idle : .failed(url)
                    }
                
            case .imageData(let data):
                backgroundImage = UIImage(data: data)
            case .blank:
                break
            }
        }
    // MARK: - Intent(s)
    
    func setBackground(_ background: EmojiArt.Background, undoManager: UndoManager?) {
        undoablyPerform(operation: "Set Background", with: undoManager) {
            emojiArt.background = background
        }
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat, undoManager: UndoManager?) {
            undoablyPerform(operation: "Add \(emoji)", with: undoManager) {
                emojiArt.addEmoji(emoji, at: location, size: Int(size))
            }
        }

    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            undoablyPerform(operation: "Move", with: undoManager) {
                emojiArt.emojis[index].x += Int(offset.width)
                emojiArt.emojis[index].y += Int(offset.height)
            }
        }
    }


    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            undoablyPerform(operation: "Scale", with: undoManager) {
                emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
            }
        }
    }
    
    func removeEmoji(_ emoji: EmojiArt.Emoji) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis.remove(at: index)
        }
    }
        
    //undo function, saves old state in oldEmojiArt, after an action undo will return to the previous state
    private func undoablyPerform(operation: String, with undoManager: UndoManager? = nil, doit: () -> Void) {
        let oldEmojiArt = emojiArt
        // do the action that is assigned to it
        doit()
        // check the current state
        undoManager?.registerUndo(withTarget: self) { myself in
                // include redo
            myself.undoablyPerform(operation: operation, with: undoManager) {
                myself.emojiArt = oldEmojiArt
            }
        }
        // set the name of the operation for a specific undoable action
        undoManager?.setActionName(operation)
    }
}


