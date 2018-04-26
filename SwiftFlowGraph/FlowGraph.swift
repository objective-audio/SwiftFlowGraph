//
//  FlowGraph.swift
//

import Foundation

public class FlowGraph<State: Hashable, Event> {
    public enum StateOut {
        case run(State, Event)
        case wait(State)
        case stay
    }
    
    private(set) var state: State
    private var stateHandlers: [State: (Event) -> StateOut] = [:]
    
    public init(initial: State) {
        self.state = initial
    }
    
    public func add(state: State, handler: @escaping (Event) -> StateOut) {
        if self.stateHandlers[state] != nil {
            fatalError()
        }
        
        self.stateHandlers[state] = handler
    }
    
    public func send(event: Event) {
        guard let handler = self.stateHandlers[self.state] else {
            fatalError()
        }
        
        switch handler(event) {
        case .run(let state, let event):
            self.state = state
            self.send(event: event)
        case .wait(let state):
            self.state = state
        case .stay:
            break
        }
    }
    
    public func contains(state: State) -> Bool {
        return self.stateHandlers.contains { $0.key == state }
    }
}
