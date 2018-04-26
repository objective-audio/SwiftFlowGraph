//
//  SwiftFlowGraphExampleTests.swift
//

import XCTest
@testable import SwiftFlowGraphExample

class FlowGraphTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFlow() {
        enum State: EnumEnumerable {
            case begin
            case zero
            case nonZero
        }
        
        enum Event {
            case none
            case value(Int)
            case bang
        }
        
        let graph = FlowGraph<State, Event>(initial: .begin)
        
        graph.add(state: .begin) { event in
            switch event {
            case .value(let value):
                if value == 0 {
                    return .wait(.zero)
                } else {
                    return .run(.nonZero, .none)
                }
            default:
                return .stay
            }
        }
        
        graph.add(state: .zero) { event in
            switch event {
            case .bang:
                return .wait(.begin)
            default:
                return .stay
            }
        }
        
        graph.add(state: .nonZero) { event in
            return .wait(.begin)
        }
        
        for state in State.cases {
            XCTAssertTrue(graph.contains(state: state))
        }
        
        XCTAssertEqual(graph.state, .begin)
        
        graph.send(event: .value(0))
        
        XCTAssertEqual(graph.state, .zero)
        
        graph.send(event: .value(0))
        
        XCTAssertEqual(graph.state, .zero)
        
        graph.send(event: .bang)
        
        XCTAssertEqual(graph.state, .begin)
        
        graph.send(event: .value(1))
        
        XCTAssertEqual(graph.state, .begin)
    }
    
    func testContains() {
        enum State {
            case first
            case second
        }
        
        let graph = FlowGraph<State, Int>(initial: .first)
        
        graph.add(state: .first) { _ in .stay }
        
        XCTAssertTrue(graph.contains(state: .first))
        XCTAssertFalse(graph.contains(state: .second))
    }
}
