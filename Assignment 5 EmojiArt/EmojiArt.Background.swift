//
//  EmojiArt.Background.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 1/3/24.
//

import Foundation

extension EmojiArt {
    enum Background: Equatable, Codable {
        case blank
        case url(URL)
        case imageData(Data)
        
        var url: URL? {
            switch self {
            case .url(let url): return url
            default: return nil
            }
        }
        
        var imageData: Data? {
            switch self {
            case .imageData(let data): return data
            default: return nil
            }
        }
    }
}
