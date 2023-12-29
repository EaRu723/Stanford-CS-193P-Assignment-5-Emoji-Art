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

// Extension on CGOffset (CGSize) to define custom operators.
extension CGOffset {
    // Operator to add two CGOffset values.
    static func +(lhs: CGOffset, rhs: CGOffset) -> CGOffset {
        CGOffset(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    // Compound assignment operator to add and assign a CGOffset value.
    static func +=(lhs: inout CGOffset, rhs: CGOffset) {
        lhs = lhs + rhs
    }
}

// Extension on String for custom functionality.
extension String {
    // Computed property to remove duplicate characters from a string while preserving their order.
    var uniqued: String {
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

// SwiftUI view for an animated action button.
struct AnimatedActionButton: View {
    var title: String? = nil // Optional title for the button.
    var systemImage: String? = nil // Optional system image name for the button.
    var role: ButtonRole? // Optional role to define button's purpose.
    let action: () -> Void // Closure to be executed when the button is tapped.

    // Initializer for the AnimatedActionButton.
    init(_ title: String? = nil,
         systemImage: String? = nil,
         role: ButtonRole? = nil,
         action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    // The body of the AnimatedActionButton view.
    var body: some View {
        Button(role: role) {
            withAnimation {
                action() // Execute the action with animation.
            }
        } label: {
            // Configure the button label based on the provided title and system image.
            if let title, let systemImage {
                Label(title, systemImage: systemImage)
            } else if let title {
                Text(title)
            } else if let systemImage {
                Image(systemName: systemImage)
            }
        }
    }
}
