//
//  FlowGraph.swift
//

import Foundation

public enum FlowGraphWaitStateOut<WaitState, RunState, Event> {
    case run(RunState, Event)
    case wait(WaitState)
    case stay
}

public enum FlowGraphRunStateOut<WaitState, RunState, Event> {
    case run(RunState, Event)
    case wait(WaitState)
}

public struct FlowGraphType<WaitState: Hashable, RunState: Hashable, Event> {
    public enum State: Equatable {
        case running(RunState)
        case waiting(WaitState)
        
        public static func == (lhs: FlowGraphType.State, rhs: FlowGraphType.State) -> Bool {
            switch (lhs, rhs) {
            case (.waiting(let lhsState), .waiting(let rhsState)):
                return lhsState == rhsState
            case (.running(let lhsState), .running(let rhsState)):
                return lhsState == rhsState
            default:
                return false
            }
        }
    }
    
    public typealias WaitStateOut = FlowGraphWaitStateOut<WaitState, RunState, Event>
    public typealias WaitHandler = (Event) -> WaitStateOut
    
    public typealias RunStateOut = FlowGraphRunStateOut<WaitState, RunState, Event>
    public typealias RunHandler = (Event) -> RunStateOut
}

public class FlowGraphBuilder<WaitState: Hashable, RunState: Hashable, Event> {
    public typealias T = FlowGraphType<WaitState, RunState, Event>
    
    private var waitHandlers: [WaitState: T.WaitHandler] = [:]
    private var runHandlers: [RunState: T.RunHandler] = [:]
    
    public init() {
    }
    
    public func add(waiting state: WaitState, handler: @escaping T.WaitHandler) {
        if self.waitHandlers[state] != nil {
            fatalError()
        }
        
        self.waitHandlers[state] = handler
    }
    
    public func add(running state: RunState, handler: @escaping T.RunHandler) {
        if self.runHandlers[state] != nil {
            fatalError()
        }
    
        self.runHandlers[state] = handler
    }
    
    public func build(initial: WaitState) -> FlowGraph<WaitState, RunState, Event> {
        return FlowGraph<WaitState, RunState, Event>(initial: initial, waitHandlers: self.waitHandlers, runHandlers: self.runHandlers)
    }
    
    public func contains(state: T.State) -> Bool {
        switch state {
        case .waiting(let waitState):
            return self.waitHandlers.contains { $0.key == waitState }
        case .running(let runState):
            return self.runHandlers.contains { $0.key == runState }
        }
    }
}

public class FlowGraph<WaitState: Hashable, RunState: Hashable, Event> {
    public typealias T = FlowGraphType<WaitState, RunState, Event>
    
    public private(set) var state: T.State
    private var waitHandlers: [WaitState: T.WaitHandler] = [:]
    private var runHandlers: [RunState: T.RunHandler] = [:]
    private var running = false;
    
    fileprivate init(initial: WaitState, waitHandlers: [WaitState: T.WaitHandler], runHandlers: [RunState: T.RunHandler]) {
        self.state = .waiting(initial)
        self.waitHandlers = waitHandlers
        self.runHandlers = runHandlers
    }
    
    public func run(_ event: Event) {
        guard case .waiting(let waitState) = self.state else {
            fatalError()
        }
        
        self.run(state: waitState, event: event)
    }
    
    private func run(state: WaitState, event: Event) {
        if self.running {
            fatalError()
        }
        
        guard let handler = self.waitHandlers[state] else {
            fatalError()
        }
        
        self.running = true
        
        let next = handler(event)
        
        self.running = false
        
        switch next {
        case .run(let state, let event):
            self.state = .running(state)
            self.run(state: state, event: event)
        case .wait(let state):
            self.state = .waiting(state)
        case .stay:
            break
        }
    }
    
    private func run(state: RunState, event: Event) {
        if self.running {
            fatalError()
        }
        
        guard let handler = self.runHandlers[state] else {
            fatalError()
        }
        
        self.running = true
        
        let next = handler(event)
        
        self.running = false
        
        switch next {
        case .run(let state, let event):
            self.state = .running(state)
            self.run(state: state, event: event)
        case .wait(let state):
            self.state = .waiting(state)
        }
    }
}
