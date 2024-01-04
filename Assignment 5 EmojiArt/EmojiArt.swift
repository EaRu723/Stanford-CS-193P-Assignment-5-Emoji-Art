//
//  EmojiArt.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 12/29/23.
//

import Foundation

// Defines a struct EmojiArt which conforms to the Codable protocol for encoding and decoding.
struct EmojiArt: Codable {
    // Set initial background as blank
    var background = Background.blank
    var emojis = [Emoji]()
    
    // Nested struct defining an Emoji, conforming to Identifiable and Codable.
    struct Emoji: Identifiable, Hashable, Codable {
        let text: String // The emoji character as a string.
        var x: Int // x-coordinate
        var y: Int // y-coordinate
        var size: Int // Size of the emoji.
        let id: Int // Unique identifier for the emoji.
        
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    // Function to convert the EmojiArt instance into JSON Data.
    func json() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    // Initializer that decodes a given JSON Data into an EmojiArt instance.
    init(json: Data) throws {
        self = try JSONDecoder().decode(EmojiArt.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try EmojiArt(json: data)
    }
    
    // Default initializer.
    init() {
        
    }
    
    // A private variable to generate a unique ID for each emoji.
    private var uniqueEmojiId = 0
    
    // Function to add an emoji to the array with a unique ID, position, and size.
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(
            text: text,
            x: location.x,
            y: location.y,
            size: size,
            id: uniqueEmojiId
        ))
    }
}


