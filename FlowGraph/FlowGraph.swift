//
//  FlowGraph.swift
//

import Foundation

public struct FlowGraphType<WaitingState: Hashable, RunningState: Hashable, Event> {
    public enum State: Equatable {
        case running(RunningState)
        case waiting(WaitingState)
        
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
    
    public enum WaitingStateOut {
        case run(RunningState, Event)
        case wait(WaitingState)
        case stay
    }
    
    public enum RunningStateOut {
        case run(RunningState, Event)
        case wait(WaitingState)
    }
    
    public typealias WaitingHandler = (Event) -> WaitingStateOut
    public typealias RunningHandler = (Event) -> RunningStateOut
}

public class FlowGraphBuilder<WaitingState: Hashable, RunningState: Hashable, Event> {
    public typealias T = FlowGraphType<WaitingState, RunningState, Event>
    
    private var waitingHandlers: [WaitingState: T.WaitingHandler] = [:]
    private var runningHandlers: [RunningState: T.RunningHandler] = [:]
    
    public init() {}
    
    public func add(waiting state: WaitingState, handler: @escaping T.WaitingHandler) {
        if self.waitingHandlers[state] != nil {
            fatalError()
        }
        
        self.waitingHandlers[state] = handler
    }
    
    public func add(running state: RunningState, handler: @escaping T.RunningHandler) {
        if self.runningHandlers[state] != nil {
            fatalError()
        }
    
        self.runningHandlers[state] = handler
    }
    
    public func build(initial: WaitingState) -> FlowGraph<WaitingState, RunningState, Event> {
        return FlowGraph<WaitingState, RunningState, Event>(initial: initial,
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

public class FlowGraph<WaitingState: Hashable, RunningState: Hashable, Event> {
    public typealias T = FlowGraphType<WaitingState, RunningState, Event>
    public typealias Builder = FlowGraphBuilder<WaitingState, RunningState, Event>
    
    public private(set) var state: T.State
    private var waitingHandlers: [WaitingState: T.WaitingHandler] = [:]
    private var runningHandlers: [RunningState: T.RunningHandler] = [:]
    private var performing = false;
    
    fileprivate init(initial: WaitingState,
                     waitingHandlers: [WaitingState: T.WaitingHandler],
                     runningHandlers: [RunningState: T.RunningHandler]) {
        self.state = .waiting(initial)
        self.waitingHandlers = waitingHandlers
        self.runningHandlers = runningHandlers
    }
    
    public func run(_ event: Event) {
        guard case .waiting(let waitingState) = self.state else {
            print("Ignored an event because state is runnning.")
            return
        }
        
        self.run(waiting: waitingState, event: event)
    }
    
    private func run(waiting state: WaitingState, event: Event) {
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
    
    private func run(running state: RunningState, event: Event) {
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
