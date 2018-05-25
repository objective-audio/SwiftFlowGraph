# FlowGraph

## Example

```swift
class FlowObject {
    enum State {
        case a
        case b
        case c
    }

    enum EventName {
        case toC
        case bToC
        case toA
    }

    typealias Event = (name: EventName, object: FlowObject)

    let graph: FlowGraph<State, Event>

    init() {
        let builder = FlowGraphBuilder<State, Event>()

        builder.add(state: .a) { event in
            switch event.name {
            case .bToC:
                return .run(.b, event)
            case .toC:
                return .wait(.c)
            case .toA:
                return .stay
            }
        }

        builder.add(state: .b) { event in
            event.object.log(text: "call b")

            return .wait(.c)
        }

        builder.add(state: .c) { event in
            switch event.name {
            case .toA:
                return .wait(.a)
            default:
                return .stay
            }
        }

        self.graph = builder.build(initial: .a)
    }

    func receive(_ eventName: EventName) {
        self.graph.run((eventName, self))
    }

    func log(text: String) {
        print("\(text)")
    }
}
```

```swift
let flow = FlowObject()

// state is a

flow.receive(.toC)

// state is c

flow.receive(.toA)

// state is a

flow.receive(.bToC)

// call b
// state is c

flow.receive(.toA)

// state is a
```
