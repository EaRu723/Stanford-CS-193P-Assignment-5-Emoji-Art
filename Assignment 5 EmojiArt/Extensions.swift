//
//  Extensions.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 12/29/23.
//

import SwiftUI

// Typealias for CGSize, renaming it as CGOffset for clarity in its usage as an offset.
typealias CGOffset = CGSize

// Extension on CGRect to provide additional functionality.
extension CGRect {
    // Computed property to get the center point of a CGRect.
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    // Initializer to create a CGRect given its center point and size.
    init(center: CGPoint, size: CGSize) {
        self.init(origin: CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2), size: size)
    }
}

extension CGSize {
    // the center point of an area that is our size
    var center: CGPoint {
        CGPoint(x: width/2, y: height/2)
    }
    static func +(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    static func -(lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    static func *(lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    static func /(lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width/rhs, height: lhs.height/rhs)
    }
}

// Extension on String for custom functionality.
extension String {
    // Computed property to remove duplicate characters from a string while preserving their order.
//    var uniqued: String {
//        reduce(into: "") { sofar, element in
//            if !sofar.contains(element) {
//                sofar.append(element)
//            }
//        }
//    }
    var removingDuplicateCharacters: String {
        reduce(into: "") { sofar, element in
            if !sofar.contains(element) {
                sofar.append(element)
            }
        }
    }
}

// Extension on AnyTransition for custom view transitions.
extension AnyTransition {
    // Custom transition that moves the view from the bottom edge when inserted and from the top when removed.
    static let rollUp: AnyTransition = .asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top))

    // Custom transition that moves the view from the top edge when inserted and from the bottom when removed.
    static let rollDown: AnyTransition = .asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom))
}

//// SwiftUI view for an animated action button.
//struct AnimatedActionButton: View {
//    var title: String? = nil // Optional title for the button.
//    var systemImage: String? = nil // Optional system image name for the button.
//    var role: ButtonRole? // Optional role to define button's purpose.
//    let action: () -> Void // Closure to be executed when the button is tapped.
//
//    // Initializer for the AnimatedActionButton.
//    init(_ title: String? = nil,
//         systemImage: String? = nil,
//         role: ButtonRole? = nil,
//         action: @escaping () -> Void
//    ) {
//        self.title = title
//        self.systemImage = systemImage
//        self.role = role
//        self.action = action
//    }
//
//    // The body of the AnimatedActionButton view.
//    var body: some View {
//        Button(role: role) {
//            withAnimation {
//                action() // Execute the action with animation.
//            }
//        } label: {
//            // Configure the button label based on the provided title and system image.
//            if let title, let systemImage {
//                Label(title, systemImage: systemImage)
//            } else if let title {
//                Text(title)
//            } else if let systemImage {
//                Image(systemName: systemImage)
//            }
//        }
//    }
//}

extension Array where Element == NSItemProvider {
    
    func loadObjects<T>(ofType theType: T.Type, firstOnly: Bool = false, using load: @escaping (T) -> Void) -> Bool where T: NSItemProviderReading {
        if let provider = first(where: { $0.canLoadObject(ofClass: theType) }) {
            provider.loadObject(ofClass: theType) { object, error in
                if let value = object as? T {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
                
            }
            return true
        }
        return false
    }
    
    func loadObjects<T>(ofType theType: T.Type, firstOnly: Bool = false, using load: @escaping (T) -> Void) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        if let provider = first(where: { $0.canLoadObject(ofClass: theType) }) {
            let _ = provider.loadObject(ofClass: theType) { object, error in
                if let value = object {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
            }
            return true
        }
        return false
    }
    
    func loadFirstObject<T>(ofType theType: T.Type, using load: @escaping (T) -> Void) -> Bool where T: NSItemProviderReading {
        loadObjects(ofType: theType, firstOnly: true, using: load)
    }
    
    func loadFirstObject<T>(ofType theType: T.Type, using load: @escaping (T) -> Void) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        loadObjects(ofType: theType, firstOnly: true, using: load)
    }
    
}

extension Character {
    var isEmoji: Bool {
        if let firstScalar = unicodeScalars.first,
           firstScalar.properties.isEmoji {
            return (firstScalar.value >= 0x238d || unicodeScalars.count > 1)
        } else {
            return false
        }
    }
}

extension Collection where Element: Identifiable {
    func index(matching element: Element) ->Self.Index? {
        firstIndex(where: { $0.id == element.id })
    }
}

// checks if the link is too long and strips it down if its too long
extension URL {
    var imageURL: URL {
        for query in query?.components(separatedBy: "&") ?? [] {
            let queryComponents = query.components(separatedBy: "=")
            if queryComponents.count == 2 {
                if queryComponents[0] == "imgurl", let url = URL(string: queryComponents[1].removingPercentEncoding ?? "") {
                    return url
                }
            }
        }
        
        return baseURL ?? self
    }
}

// allows for easy access and removal of Published properties
extension RangeReplaceableCollection where Element: Identifiable {
    mutating func remove (_ element: Element) {
        if let index = index(matching: element) {
            remove(at: index)
        }
    }
    
    subscript(_ element: Element) -> Element {
        get {
            if let index = index(matching: element) {
                return self[index]
            } else {
                return element
            }
        }
        set {
            if let index = index(matching: element) {
                replaceSubrange(index...index, with: [newValue])
            }
        }
    }
}

// any codable type can be made rawrepresentable so 'Codable' types can be stored using '@SceneStorage
extension RawRepresentable where Self: Codable {
    public var rawValue: String {
        if let json = try? JSONEncoder().encode(self), let string = String(data: json, encoding: .utf8) {
            return string
        } else {
            return ""
        }
    }
    public init?(rawValue: String) {
        if let value = try? JSONDecoder().decode(Self.self, from: Data(rawValue.utf8)) {
            self = value
        } else {
            return nil
        }
    }
}

extension CGSize: RawRepresentable {}
extension CGFloat: RawRepresentable {}

extension Set where Element: Identifiable {
    mutating func toggleMembership(of element: Element) {
        if let index = index(matching: element) {
            remove(at: index)
        } else {
            insert(element)
        }
    }
}
