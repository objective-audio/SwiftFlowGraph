# FlowGraph

## Installation with CocoaPods

Add the pods that you want to install. You can include a Pod in your Podfile like this:

```ruby
pod 'FlowGraph'
```

Install the pods.

```
$ pod install
```

## SwiftPM

```swift
// package.swift

import PackageDescription

let package = Package(
    name: "Sample",
    dependencies: [
        .package(url: "https://github.com/objective-audio/SwiftFlowGraph.git", from: "0.3.0")
    ],
    targets: [
        .target(
            name: "Sample",
            dependencies: ["FlowGraph"]),
    ]
)
```

## Example

```swift
import FlowGraph

class Door {
    private(set) var isOpen: Bool = false {
        didSet {
            print("isOpen \(self.isOpen)")
        }
    }

    private enum WaitingState {
        case closed
        case opened
    }

    private enum RunningState {
        case opening
        case closing
    }

    enum EventKind {
        case open
        case close
    }

    private typealias Event = (kind: EventKind, object: Door)

    private let graph = FlowGraph<WaitingState, RunningState, Event>()

    init() {
        self.graph.add(waiting: .closed) { event in
            if case .open = event.kind {
                return .run(.opening, event)
            } else {
                return .stay
            }
        }

        self.graph.add(waiting: .opened) { event in
            if case .close = event.kind {
                return .run(.closing, event)
            } else {
                return .stay
            }
        }

        self.graph.add(running: .opening) { event in
            event.object.isOpen = true
            return .wait(.opened)
        }

        self.graph.add(running: .closing) { event in
            event.object.isOpen = false
            return .wait(.closed)
        }

        self.graph.begin(with: .closed)
    }

    func run(_ kind: EventKind) {
        self.graph.run((kind, self))
    }
}
```

```swift
let door = Door()

door.run(.open)

// 'isOpen true'

door.run(.close)

// 'isOpen false'

door.run(.close)

// Do nothing
```
