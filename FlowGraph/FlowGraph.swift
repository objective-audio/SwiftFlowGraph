//
//  FlowGraph.swift
//

import Foundation

public class FlowGraph<Waiting: Hashable, Running: Hashable, Event> {
    public enum State: Equatable {
        case running(Running)
        case waiting(Waiting)
        
        public static func == (lhs: State, rhs: State) -> Bool {
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
        case run(Running, Event)
        case wait(Waiting)
        case stay
    }
    
    public enum RunningStateOut {
        case run(Running, Event)
        case wait(Waiting)
    }
    
    public typealias WaitingHandler = (Event) -> WaitingStateOut
    public typealias RunningHandler = (Event) -> RunningStateOut
    
    private enum Core {
        case builder(FlowGraphBuilder<Waiting, Running, Event>)
        case runner(FlowGraphRunner<Waiting, Running, Event>)
    }
    
    private var core: Core
    
    public var state: State {
        guard case .runner(let runner) = self.core else {
            fatalError()
        }
        return runner.state
    }
    
    public init() {
        self.core = .builder(FlowGraphBuilder<Waiting, Running, Event>())
    }
    
    public func add(waiting state: Waiting, handler: @escaping WaitingHandler) {
        guard case .builder(let builder) = self.core else {
            fatalError()
        }
        builder.add(waiting: state, handler: handler)
    }
    
    public func add(running state: Running, handler: @escaping RunningHandler) {
        guard case .builder(let builder) = self.core else {
            fatalError()
        }
        builder.add(running: state, handler: handler)
    }
    
    public func contains(state: State) -> Bool {
        guard case .builder(let builder) = self.core else {
            fatalError()
        }
        return builder.contains(state: state)
    }
    
    public func begin(with initial: Waiting) {
        guard case .builder(let builder) = self.core else {
            fatalError()
        }
        self.core = .runner(builder.build(initial: initial))
    }
    
    public func run(_ event: Event) {
        guard case .runner(let runner) = self.core else {
            fatalError()
        }
        runner.run(event)
    }
}

fileprivate class FlowGraphBuilder<WaitingState: Hashable, RunningState: Hashable, Event> {
    fileprivate typealias T = FlowGraph<WaitingState, RunningState, Event>
    
    private var waitingHandlers: [WaitingState: T.WaitingHandler]! = [:]
    private var runningHandlers: [RunningState: T.RunningHandler]! = [:]
    
    fileprivate init() {}
    
    fileprivate func add(waiting state: WaitingState, handler: @escaping T.WaitingHandler) {
        if self.waitingHandlers[state] != nil {
            fatalError()
        }
        
        self.waitingHandlers[state] = handler
    }
    
    fileprivate func add(running state: RunningState, handler: @escaping T.RunningHandler) {
        if self.runningHandlers[state] != nil {
            fatalError()
        }
    
        self.runningHandlers[state] = handler
    }
    
    fileprivate func build(initial: WaitingState) -> FlowGraphRunner<WaitingState, RunningState, Event> {
        let runner = FlowGraphRunner<WaitingState, RunningState, Event>(initial: initial,
                                                                        waitingHandlers: self.waitingHandlers,
                                                                        runningHandlers: self.runningHandlers)
        self.waitingHandlers = nil
        self.runningHandlers = nil
        return runner
    }
    
    fileprivate func contains(state: T.State) -> Bool {
        switch state {
        case .waiting(let state):
            return self.waitingHandlers.contains { $0.key == state }
        case .running(let state):
            return self.runningHandlers.contains { $0.key == state }
        }
    }
}

fileprivate class FlowGraphRunner<WaitingState: Hashable, RunningState: Hashable, Event> {
    fileprivate typealias T = FlowGraph<WaitingState, RunningState, Event>
    fileprivate typealias Builder = FlowGraphBuilder<WaitingState, RunningState, Event>
    
    fileprivate private(set) var state: T.State
    private var waitingHandlers: [WaitingState: T.WaitingHandler]
    private var runningHandlers: [RunningState: T.RunningHandler]
    private var performing = false;
    
    fileprivate init(initial: WaitingState,
                     waitingHandlers: [WaitingState: T.WaitingHandler],
                     runningHandlers: [RunningState: T.RunningHandler]) {
        self.state = .waiting(initial)
        self.waitingHandlers = waitingHandlers
        self.runningHandlers = runningHandlers
    }
    
    fileprivate func run(_ event: Event) {
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
