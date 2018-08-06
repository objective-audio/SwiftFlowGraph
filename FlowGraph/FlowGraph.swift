//
//  FlowGraph.swift
//

import Foundation

public protocol FlowGraphType {
    associatedtype WaitingState: Hashable
    associatedtype RunningState: Hashable
    associatedtype Event
    
    typealias WaitingHandler = (Event) -> WaitingStateOut<WaitingState, RunningState, Event>
    typealias RunningHandler = (Event) -> RunningStateOut<WaitingState, RunningState, Event>
    typealias State = FlowGraphState<WaitingState, RunningState>
}

public enum FlowGraphState<WaitingState: Hashable, RunningState: Hashable>: Equatable {
    case running(RunningState)
    case waiting(WaitingState)
    
    public static func == (lhs: FlowGraphState, rhs: FlowGraphState) -> Bool {
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

public enum WaitingStateOut<WaitingState: Hashable, RunningState: Hashable, Event> {
    case run(RunningState, Event)
    case wait(WaitingState)
    case stay
}

public enum RunningStateOut<WaitingState: Hashable, RunningState: Hashable, Event> {
    case run(RunningState, Event)
    case wait(WaitingState)
}

public class FlowGraphBuilder<T: FlowGraphType> {
    private var waitingHandlers: [T.WaitingState: T.WaitingHandler] = [:]
    private var runningHandlers: [T.RunningState: T.RunningHandler] = [:]
    
    public init() {}
    
    public func add(waiting state: T.WaitingState, handler: @escaping T.WaitingHandler) {
        if self.waitingHandlers[state] != nil {
            fatalError()
        }
        
        self.waitingHandlers[state] = handler
    }
    
    public func add(running state: T.RunningState, handler: @escaping T.RunningHandler) {
        if self.runningHandlers[state] != nil {
            fatalError()
        }
        
        self.runningHandlers[state] = handler
    }
    
    public func build(initial: T.WaitingState) -> FlowGraph<T> {
        return FlowGraph<T>(initial: initial,
                            waitingHandlers: self.waitingHandlers,
                            runningHandlers: self.runningHandlers)
    }
    
    public func contains(state: T.State) -> Bool {
        switch state {
        case .waiting(let state):
            return self.waitingHandlers.contains { $0.key == state }
        case .running(let state):
            return self.runningHandlers.contains { $0.key == state }
        }
    }
}

public class FlowGraph<T: FlowGraphType> {
    public private(set) var state: T.State
    private var waitingHandlers: [T.WaitingState: T.WaitingHandler] = [:]
    private var runningHandlers: [T.RunningState: T.RunningHandler] = [:]
    private var performing = false;
    
    fileprivate init(initial: T.WaitingState,
                     waitingHandlers: [T.WaitingState: T.WaitingHandler],
                     runningHandlers: [T.RunningState: T.RunningHandler]) {
        self.state = .waiting(initial)
        self.waitingHandlers = waitingHandlers
        self.runningHandlers = runningHandlers
    }
    
    public func run(_ event: T.Event) {
        guard case .waiting(let waitingState) = self.state else {
            print("Ignored an event because state is runnning.")
            return
        }
        
        self.run(waiting: waitingState, event: event)
    }
    
    private func run(waiting state: T.WaitingState, event: T.Event) {
        if self.performing {
            fatalError()
        }
        
        guard let handler = self.waitingHandlers[state] else {
            fatalError()
        }
        
        self.performing = true
        
        let next = handler(event)
        
        self.performing = false
        
        switch next {
        case .run(let state, let event):
            self.state = .running(state)
            self.run(running: state, event: event)
        case .wait(let state):
            self.state = .waiting(state)
        case .stay:
            break
        }
    }
    
    private func run(running state: T.RunningState, event: T.Event) {
        if self.performing {
            fatalError()
        }
        
        guard let handler = self.runningHandlers[state] else {
            fatalError()
        }
        
        self.performing = true
        
        let next = handler(event)
        
        self.performing = false
        
        switch next {
        case .run(let state, let event):
            self.state = .running(state)
            self.run(running: state, event: event)
        case .wait(let state):
            self.state = .waiting(state)
        }
    }
}
