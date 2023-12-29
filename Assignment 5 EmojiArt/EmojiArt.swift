//
//  EmojiArt.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 12/29/23.
//

import Foundation

// Defines a struct EmojiArt which conforms to the Codable protocol for encoding and decoding.
struct EmojiArt: Codable {
    // An optional URL to represent the background image.
    var background: URL?

    // An array of Emoji, initially empty. It's marked as private(set) to restrict modifications from outside of the struct.
    private(set) var emojis = [Emoji]()

    // Function to convert the EmojiArt instance into JSON Data.
    func json() throws -> Data {
        let encoded = try JSONEncoder().encode(self)
        print("EmojiArt = \(String(data: encoded, encoding: .utf8) ?? "nil")")
        return encoded
    }

    // Initializer that decodes a given JSON Data into an EmojiArt instance.
    init(json: Data) throws {
        self = try JSONDecoder().decode(EmojiArt.self, from: json)
    }

    // Default initializer.
    init() {
        
    }

    // A private variable to generate a unique ID for each emoji.
    private var uniqueEmojiId = 0

    // Function to add an emoji to the array with a unique ID, position, and size.
    mutating func addEmoji(_ emoji: String, at position: Emoji.Position, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(
            string: emoji,
            position: position,
            size: size,
            id: uniqueEmojiId
        ))
    }

    // Subscript to get or set an emoji by its ID.
    subscript(_ emojiId: Emoji.ID) -> Emoji? {
        if let index = index(of: emojiId) {
            return emojis[index]
        } else {
            return nil
        }
    }

    // Subscript to get or set an emoji by its Emoji instance.
    subscript(_ emoji: Emoji) -> Emoji {
        get {
            if let index = index(of: emoji.id) {
                return emojis[index]
            } else {
                return emoji // should probably throw error
            }
        }
        set {
            if let index = index(of: emoji.id) {
                emojis[index] = newValue
            }
        }
    }

    // Private helper function to find the index of an emoji by its ID.
    private func index(of emojiId: Emoji.ID) -> Int? {
        emojis.firstIndex(where: { $0.id == emojiId })
    }

    // Nested struct defining an Emoji, conforming to Identifiable and Codable.
    struct Emoji: Identifiable, Codable {
        let string: String // The emoji character as a string.
        var position: Position // Position of the emoji.
        var size: Int // Size of the emoji.
        var id: Int // Unique identifier for the emoji.

        // Nested struct defining the position of an emoji.
        struct Position: Codable {
            var x: Int // x-coordinate
            var y: Int // y-coordinate

            // Static property to represent a zero position.
            static let zero = Self(x: 0, y: 0)
        }
    }
}
