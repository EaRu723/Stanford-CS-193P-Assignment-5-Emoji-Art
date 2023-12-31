//
//  UtilityViews.swift
//  Assignment 5 EmojiArt
//
//  Created by Andrea Russo on 1/2/24.
//

import SwiftUI


//take only optional image, if nil ignore the background
struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        if uiImage != nil {
            Image(uiImage: uiImage!)
        }
    }
}

// syntactic sugar
// lots of times we want a simple button
// with just text or a label or a systemImage
// but we want the action it performs to be animated
// (i.e. withAnimation)
// this just makes it easy to create such a button
// and thus cleans up our code

struct AnimatedActionButton: View {
    var title: String? = nil
    var systemImage: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            if title != nil && systemImage != nil {
                Label(title!, systemImage: systemImage!)
            } else if title != nil {
                Text(title!)
            } else if systemImage != nil {
                Image(systemName: systemImage!)
            }
        }
    }
}
// simple struct to make it easier to show configurable Alerts
// just an Identifiable struct that can create an Alert on demand
// use .alert(item: $alertToShow) { theIdentifiableAlert in ... }
// where alertToShow is a Binding<IdentifiableAlert>?
// then any time you want to show an alert
// just set alertToShow = IdentifiableAlert(id: "my alert") { Alert(title: ...) }
// of course, the string identifier has to be unique for all your different kinds of alerts

struct IdentifiableAlert: Identifiable {
    var id: String
    var alert: () -> Alert
    
    init(id: String, alert: @escaping () -> Alert) {
        self.id = id
        self.alert = alert
    }
    
    // L15 convenience init added between L14 and L15
    init(id: String, title: String, message: String) {
        self.id = id
        alert = { Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK"))) }
    }
    
    // L15 convenience init added between L14 and L15
    init(title: String, message: String) {
        self.id = title + message
        alert = { Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK"))) }
    }
}

// a button that does undo (preferred) or redo
// also has a context menu which will display
// the given undo or redo description for each

struct UndoButton: View {
    let undo: String?
    let redo: String?
    
    @Environment(\.undoManager) var undoManager
    
    var body: some View {
        let canUndo = undoManager?.canUndo ?? false
        let canRedo = undoManager?.canRedo ?? false
        if canUndo || canRedo {
            Button {
                if canUndo {
                    undoManager?.undo()
                } else {
                    undoManager?.redo()
                }
            } label: {
                if canUndo {
                    Image(systemName: "arrow.uturn.backward.circle")
                } else {
                    Image(systemName: "arrow.uturn.forward.circle")
                }
            }
                .contextMenu {
                    if canUndo {
                        Button {
                            undoManager?.undo()
                        } label: {
                            Label(undo ?? "Undo", systemImage: "arrow.uturn.backward")
                        }
                    }
                    if canRedo {
                        Button {
                            undoManager?.redo()
                        } label: {
                            Label(redo ?? "Redo", systemImage: "arrow.uturn.forward")
                        }
                    }
                }
        }
    }
}

extension UndoManager {
    var optionalUndoMenuItemTitle: String? {
        canUndo ? undoMenuItemTitle : nil
    }
    var optionalRedoMenuItemTitle: String? {
        canRedo ? redoMenuItemTitle : nil
    }
}


// L15 modifier which replaces uses of .toolbar
// L15 in horizontally compact environments, it puts a single button in the toolbar
// L15 with a context menu containing the items
// L15 (only works on ViewBuilder content, not ToolbarItems content)
extension View {
    func compactableToolbar<Content>(@ViewBuilder content: () -> Content) -> some View where Content: View {
        self.toolbar {
            content().modifier(CompactableIntoContextMenu())
        }
    }
}

// L15 the ViewModifier behind compactableToolbar
// L15 takes a ViewBuilder View and makes either
// L15 a single button with a context menu with the content (if horizontally compact)
// L15 or just returns the content unchanged (if horizontally regular)
struct CompactableIntoContextMenu: ViewModifier {
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var compact: Bool { horizontalSizeClass == .compact }
    #else
    let compact = false
    #endif
    
    func body(content: Content) -> some View {
        if compact {
            //return a single button with a context menu containing content
            Button {
                
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .contextMenu {
                content
            }
        } else {
            content
        }
    }
}
