//
//  FlowGraph.swift
//

import Foundation

public enum FlowGraphStateOut<State, Event> {
    case run(State, Event)
    case wait(State)
    case stay
}

public class FlowGraphBuilder<State: Hashable, Event> {
    private var handlers: [State: (Event) -> FlowGraphStateOut<State, Event>] = [:]
    
    public func add(state: State, handler: @escaping (Event) -> FlowGraphStateOut<State, Event>) {
        if self.handlers[state] != nil {
            fatalError()
        }
        
        self.handlers[state] = handler
    }
    
    public func build(initial: State) -> FlowGraph<State, Event> {
        return FlowGraph<State, Event>(initial: initial, handlers: self.handlers)
    }
    
    public func contains(state: State) -> Bool {
        return self.handlers.contains { $0.key == state }
    }
}

public class FlowGraph<State: Hashable, Event> {
    public private(set) var state: State
    private let handlers: [State: (Event) -> FlowGraphStateOut<State, Event>]
    private var running = false;
    
    fileprivate init(initial: State, handlers: [State: (Event) -> FlowGraphStateOut<State, Event>]) {
        self.state = initial
        self.handlers = handlers
    }
    
    public func run(_ event: Event) {
        if self.running {
            fatalError()
        }
        
        guard let handler = self.handlers[self.state] else {
            fatalError()
        }
        
        self.running = true
        
        let next = handler(event)
        
        self.running = false
        
        switch next {
        case .run(let state, let event):
            self.state = state
            self.run(event)
        case .wait(let state):
            self.state = state
        case .stay:
            break
        }
    }
}
